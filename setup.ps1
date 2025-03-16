# Infrastructure Automation Framework - Setup Script (Windows)
# This script is a wrapper around the Python setup script for Windows users

param (
    [ValidateSet('dev', 'prod')]
    [string]$Mode = 'dev',
    
    [ValidateSet('aws', 'azure', 'gcp', 'all', 'none')]
    [string]$Cloud = 'all',
    
    [switch]$Force,
    
    [switch]$SkipDeps,
    
    [string]$EnvFile = '.env',

    [switch]$SetupSSH,
    
    [ValidateSet('winget', 'choco', 'auto')]
    [string]$PackageManager = 'auto',
    
    [switch]$InstallPwsh
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# Ensure required directories exist
$LogDir = Join-Path -Path $ScriptDir -ChildPath 'logs'
if (-not (Test-Path -Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory | Out-Null
}

# Log file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path -Path $LogDir -ChildPath "setup_$timestamp.log"

# Function to log messages
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to console with color
    switch ($Level) {
        'INFO' { Write-Host $Message -ForegroundColor Cyan }
        'WARNING' { Write-Host $Message -ForegroundColor Yellow }
        'ERROR' { Write-Host $Message -ForegroundColor Red }
    }
    
    # Write to log file
    Add-Content -Path $logFile -Value $logMessage
}

# Check Windows version for winget availability
function Test-WingetSupport {
    $osVersion = [Environment]::OSVersion.Version
    
    # Winget is available on Windows 10 1709 (build 16299) or later
    if ($osVersion.Major -lt 10 -or ($osVersion.Major -eq 10 -and $osVersion.Build -lt 16299)) {
        Write-Log "Windows version does not support winget (Windows 10 1709 or later required)" -Level "WARNING"
        return $false
    }
    
    return $true
}

# Function to check if a package manager is available
function Get-AvailablePackageManager {
    # If user specified a package manager, try to use it
    if ($PackageManager -ne 'auto') {
        if ($PackageManager -eq 'winget' -and (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Log "Using winget as package manager as specified"
            return 'winget'
        }
        elseif ($PackageManager -eq 'choco' -and (Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Log "Using Chocolatey as package manager as specified"
            return 'choco'
        }
        elseif ($PackageManager -eq 'winget' -and (Test-WingetSupport)) {
            Write-Log "Winget specified but not found. Will try to install it"
            return 'install-winget'
        }
        elseif ($PackageManager -eq 'choco') {
            Write-Log "Chocolatey specified but not found. Will try to install it"
            return 'install-choco'
        }
    }
    
    # Auto-detect package manager
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Log "Detected winget package manager"
        return 'winget'
    }
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Log "Detected Chocolatey package manager"
        return 'choco'
    }
    elseif (Test-WingetSupport) {
        Write-Log "No package manager found. Will try to install winget"
        return 'install-winget'
    }
    else {
        Write-Log "No package manager found. Will try to install Chocolatey"
        return 'install-choco'
    }
}

# Function to install winget
function Install-Winget {
    Write-Log "Installing winget..." -Level "INFO"
    
    try {
        # Check if Microsoft.VCLibs.140.00.UWPDesktop is installed
        if (-not (Get-AppxPackage -Name Microsoft.VCLibs.140.00.UWPDesktop)) {
            Write-Log "Installing Microsoft.VCLibs.140.00.UWPDesktop dependency..."
            $vcLibsUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
            $vcLibsFile = Join-Path -Path $env:TEMP -ChildPath "Microsoft.VCLibs.x64.14.00.Desktop.appx"
            Invoke-WebRequest -Uri $vcLibsUrl -OutFile $vcLibsFile
            Add-AppxPackage -Path $vcLibsFile
        }
        
        # Download and install the latest version of winget
        $wingetUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        $wingetFile = Join-Path -Path $env:TEMP -ChildPath "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetFile
        Add-AppxPackage -Path $wingetFile
        
        # Check if installation was successful
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Log "Winget installed successfully" -Level "INFO"
            return $true
        }
        else {
            Write-Log "Winget installation failed" -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Winget installation failed: $_" -Level "ERROR"
        return $false
    }
}

# Function to install Chocolatey
function Install-Chocolatey {
    Write-Log "Installing Chocolatey..." -Level "INFO"
    
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        
        # Check if installation was successful
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Log "Chocolatey installed successfully" -Level "INFO"
            return $true
        }
        else {
            Write-Log "Chocolatey installation failed" -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Chocolatey installation failed: $_" -Level "ERROR"
        return $false
    }
}

# Function to install a package using available package manager
function Install-Package {
    param (
        [string]$PackageName,
        [string]$WingetId = "", # Optional: specific ID for winget
        [string]$ChocoId = ""   # Optional: specific ID for Chocolatey
    )
    
    $packageManager = Get-AvailablePackageManager
    
    if ($packageManager -eq 'install-winget') {
        if (-not (Install-Winget)) {
            $packageManager = 'install-choco'
        }
        else {
            $packageManager = 'winget'
        }
    }
    
    if ($packageManager -eq 'install-choco') {
        if (-not (Install-Chocolatey)) {
            Write-Log "Failed to install any package manager. Cannot install $PackageName" -Level "ERROR"
            return $false
        }
        else {
            $packageManager = 'choco'
        }
    }
    
    Write-Log "Installing $PackageName using $packageManager..."
    
    try {
        if ($packageManager -eq 'winget') {
            $actualId = if ($WingetId) { $WingetId } else { $PackageName }
            winget install --id $actualId --accept-source-agreements --accept-package-agreements
        }
        elseif ($packageManager -eq 'choco') {
            $actualId = if ($ChocoId) { $ChocoId } else { $PackageName }
            choco install $actualId -y
        }
        
        Write-Log "$PackageName installed successfully" -Level "INFO"
        return $true
    }
    catch {
        Write-Log "$PackageName installation failed: $_" -Level "ERROR"
        return $false
    }
}

# Function to check if Python is installed
function Check-Python {
    try {
        $pythonVersion = python --version 2>$null
        if ($pythonVersion -match 'Python 3\.') {
            Write-Log "Found $pythonVersion" -Level "INFO"
            return $true
        }
        Write-Log "Python 3.x is required but not found." -Level "WARNING"
        return $false
    }
    catch {
        Write-Log "Python 3.x is required but not found." -Level "WARNING"
        return $false
    }
}

# Function to install Python using available package manager
function Install-Python {
    Write-Log "Installing Python 3..." -Level "INFO"
    return Install-Package -PackageName "Python3" -WingetId "Python.Python.3" -ChocoId "python3"
}

# Function to check if PowerShell Core (pwsh) is installed
function Check-Pwsh {
    try {
        if (Get-Command pwsh -ErrorAction SilentlyContinue) {
            $pwshVersion = pwsh -Command { $PSVersionTable.PSVersion.ToString() }
            Write-Log "Found PowerShell Core version: $pwshVersion" -Level "INFO"
            return $true
        }
        Write-Log "PowerShell Core (pwsh) not found." -Level "WARNING"
        return $false
    }
    catch {
        Write-Log "PowerShell Core (pwsh) not found." -Level "WARNING"
        return $false
    }
}

# Function to install PowerShell Core
function Install-PwshCore {
    Write-Log "Installing PowerShell Core..." -Level "INFO"
    return Install-Package -PackageName "PowerShell" -WingetId "Microsoft.PowerShell" -ChocoId "powershell-core"
}

# Function to set up SSH
function Setup-SSH {
    Write-Log "Setting up SSH..." -Level "INFO"
    
    $sshPath = "$env:USERPROFILE\.ssh"
    
    # Create .ssh directory if it doesn't exist
    if (-not (Test-Path -Path $sshPath)) {
        New-Item -Path $sshPath -ItemType Directory | Out-Null
        Write-Log "Created .ssh directory" -Level "INFO"
    }
    
    # Check if ssh-keygen is available
    if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
        Write-Log "Installing OpenSSH Client..." -Level "INFO"
        
        # Try to install using Windows Features first
        try {
            Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
            Write-Log "OpenSSH Client installed via Windows Capability" -Level "INFO"
        }
        catch {
            # Fall back to package manager
            if (-not (Install-Package -PackageName "OpenSSH" -ChocoId "openssh")) {
                Write-Log "Failed to install OpenSSH Client. SSH setup cancelled." -Level "ERROR"
                return $false
            }
        }
    }
    
    # Generate SSH key if it doesn't exist
    $sshKeyFile = Join-Path -Path $sshPath -ChildPath "id_rsa"
    if (-not (Test-Path -Path $sshKeyFile)) {
        $keyComment = "infrastructure-automation-$env:COMPUTERNAME"
        Write-Log "Generating SSH key pair..." -Level "INFO"
        
        try {
            Start-Process -FilePath "ssh-keygen" -ArgumentList "-t", "rsa", "-b", "4096", "-C", "`"$keyComment`"", "-f", "`"$sshKeyFile`"", "-N", "`"`"" -NoNewWindow -Wait
            Write-Log "SSH key pair generated successfully" -Level "INFO"
        }
        catch {
            Write-Log "Failed to generate SSH key pair: $_" -Level "ERROR"
            return $false
        }
    }
    else {
        Write-Log "SSH key pair already exists" -Level "INFO"
    }
    
    # Create basic SSH config if it doesn't exist
    $sshConfigFile = Join-Path -Path $sshPath -ChildPath "config"
    if (-not (Test-Path -Path $sshConfigFile)) {
        $sshConfig = @"
# Infrastructure Automation Framework - SSH Configuration

Host *
    ServerAliveInterval 60
    ServerAliveCountMax 30
    StrictHostKeyChecking ask
    IdentitiesOnly yes
    IdentityFile ~/.ssh/id_rsa

# Add your host configurations below:
# Host example-host
#   HostName example.com
#   User username
#   Port 22
"@
        $sshConfig | Out-File -FilePath $sshConfigFile -Encoding utf8
        Write-Log "Created SSH config file" -Level "INFO"
    }
    
    # Ensure proper permissions on the .ssh directory
    icacls $sshPath /inheritance:r
    icacls $sshPath /grant:r "${env:USERNAME}:(OI)(CI)F"
    Write-Log "Set secure permissions on .ssh directory" -Level "INFO"
    
    Write-Log "SSH setup completed successfully" -Level "INFO"
    
    # Display the public key
    $publicKeyFile = "$sshKeyFile.pub"
    if (Test-Path -Path $publicKeyFile) {
        $publicKey = Get-Content -Path $publicKeyFile
        Write-Host "`nYour SSH public key is:" -ForegroundColor Green
        Write-Host $publicKey -ForegroundColor Yellow
        Write-Host "You can add this key to your Git repositories and servers for authentication.`n" -ForegroundColor Green
    }
    
    return $true
}

# Startup banner
Write-Host "`n-----------------------------------------" -ForegroundColor Cyan
Write-Host "Infrastructure Automation Framework Setup" -ForegroundColor Cyan
Write-Host "-----------------------------------------`n" -ForegroundColor Cyan

Write-Log "Starting setup script in $Mode mode" -Level "INFO"

# Check if Python is installed, and install if needed
if (-not (Check-Python)) {
    $installPython = Read-Host "Python 3.x is required. Do you want to install it now? (Y/N)"
    if ($installPython -eq 'Y' -or $installPython -eq 'y') {
        if (-not (Install-Python)) {
            Write-Log "Failed to install Python. Please install Python 3.8 or higher manually." -Level "ERROR"
            exit 1
        }
    }
    else {
        Write-Log "Python 3 is required to run the setup script. Please install Python 3.8 or higher and try again." -Level "ERROR"
        exit 1
    }
}

# Check if PowerShell Core is requested
if ($InstallPwsh -and -not (Check-Pwsh)) {
    Write-Log "PowerShell Core (pwsh) will be installed as requested" -Level "INFO"
    if (-not (Install-PwshCore)) {
        Write-Log "Failed to install PowerShell Core. You can install it manually later." -Level "WARNING"
    }
}

# Setup SSH if requested
if ($SetupSSH) {
    if (-not (Setup-SSH)) {
        Write-Log "SSH setup encountered issues. You may need to set it up manually." -Level "WARNING"
    }
}

# Build arguments for the Python script
$pythonArgs = @("$ScriptDir\setup.py")

if ($Mode) {
    $pythonArgs += "--mode"
    $pythonArgs += $Mode
}

if ($Cloud) {
    $pythonArgs += "--cloud"
    $pythonArgs += $Cloud
}

if ($Force) {
    $pythonArgs += "--force"
}

if ($SkipDeps) {
    $pythonArgs += "--skip-deps"
}

if ($EnvFile) {
    $pythonArgs += "--env-file"
    $pythonArgs += $EnvFile
}

# Run the Python setup script
Write-Log "Running Infrastructure Automation Framework setup script..." -Level "INFO"
try {
    & python $pythonArgs
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nSetup completed successfully!" -ForegroundColor Green
        Write-Host "You can now start using the Infrastructure Automation Framework." -ForegroundColor Green
        Write-Host "Refer to the README.md for next steps." -ForegroundColor Green
        
        Write-Log "Setup completed successfully!" -Level "INFO"
    }
    else {
        Write-Host "`nSetup failed with exit code $LASTEXITCODE" -ForegroundColor Red
        Write-Host "Check the logs directory for more information." -ForegroundColor Yellow
        
        Write-Log "Setup failed with exit code $LASTEXITCODE" -Level "ERROR"
    }
}
catch {
    Write-Host "`nAn error occurred during setup: $_" -ForegroundColor Red
    Write-Host "Check the logs directory for more information." -ForegroundColor Yellow
    
    Write-Log "An error occurred during setup: $_" -Level "ERROR"
} 