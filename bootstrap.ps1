# Infrastructure Automation Framework - Bootstrap Installer (PowerShell)
# This script clones the repository and runs the setup process
# It can be run directly via: iex (irm https://example.com/bootstrap.ps1)

[CmdletBinding()]
param(
    [string]$RepoUrl = "https://github.com/ChinITRepo/infrastructure-automation.git",
    [string]$Version = "latest",  # Can be a specific tag like "v1.0.0" or "latest" for the default branch
    [string]$Branch = "main",     # Branch to use if version is "latest"
    [string]$InstallDir = "$HOME\infrastructure-automation",
    [string]$Token = "",          # Git access token for private repositories
    [ValidateSet("dev", "prod", "controller")]
    [string]$Mode = "dev",        # Setup mode: dev, prod, or controller
    [switch]$Controller,          # Shorthand for -Mode controller
    [switch]$Help
)

# Use Controller switch if specified
if ($Controller) {
    $Mode = "controller"
}

# Show help if requested
if ($Help) {
    Write-Host "Infrastructure Automation Framework - Bootstrap Installer"
    Write-Host ""
    Write-Host "Usage: .\bootstrap.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -RepoUrl <URL>        Git repository URL (default: $RepoUrl)"
    Write-Host "  -Version <VERSION>    Specific version to install (tag or 'latest')"
    Write-Host "  -Branch <BRANCH>      Branch to use if version is 'latest' (default: $Branch)"
    Write-Host "  -InstallDir <DIR>     Installation directory (default: $InstallDir)"
    Write-Host "  -Token <TOKEN>        Git access token for private repositories"
    Write-Host "  -Mode <MODE>          Setup mode: dev, prod, or controller (default: $Mode)"
    Write-Host "  -Controller           Shorthand for -Mode controller"
    Write-Host "  -Help                 Show this help message"
    Write-Host ""
    Write-Host "Example:"
    Write-Host "  .\bootstrap.ps1 -Version v1.0.0 -Controller"
    Write-Host "  iex (irm https://example.com/bootstrap.ps1) -Controller"
    exit 0
}

# Function to show banner
function Show-Banner {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║                                                            ║" -ForegroundColor Blue
    Write-Host "║            Infrastructure Automation Framework              ║" -ForegroundColor Blue
    Write-Host "║                    Bootstrap Installer                     ║" -ForegroundColor Blue
    Write-Host "║                                                            ║" -ForegroundColor Blue
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

# Function to log messages
function Write-Log {
    param (
        [ValidateSet('Info', 'Warn', 'Error')]
        [string]$Level = "Info",
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    switch ($Level) {
        "Info" { Write-Host "[INFO] $Message" -ForegroundColor Green }
        "Warn" { Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
        "Error" { Write-Host "[ERROR] $Message" -ForegroundColor Red }
    }
}

# Function to check if a command exists
function Test-CommandExists {
    param ([string]$Command)
    
    $exists = $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
    return $exists
}

# Show banner
Show-Banner

# Check for Git
if (-not (Test-CommandExists "git")) {
    Write-Log -Level Error -Message "Git is required but not installed. Please install Git and try again."
    exit 1
}

Write-Log -Level Info -Message "Using Git repository: $RepoUrl"
Write-Log -Level Info -Message "Installing version: $Version"
Write-Log -Level Info -Message "Installation directory: $InstallDir"

# Create installation directory if it doesn't exist
if (-not (Test-Path -Path $InstallDir)) {
    Write-Log -Level Info -Message "Creating installation directory..."
    New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
}
else {
    Write-Log -Level Warn -Message "Installation directory already exists. Will update if it's a Git repository."
}

# Format repository URL with token if provided
$AuthRepoUrl = $RepoUrl
if (-not [string]::IsNullOrEmpty($Token)) {
    # Extract domain from URL
    if ($RepoUrl -match "^https://([^/]+)/") {
        $domain = $matches[1]
        # Replace https://domain.com with https://token@domain.com
        $AuthRepoUrl = $RepoUrl -replace "https://$domain", "https://$Token@$domain"
        Write-Log -Level Info -Message "Using authentication for private repository"
    }
    else {
        Write-Log -Level Warn -Message "Could not parse repository URL, using token as is"
    }
}

# Clone or update the repository
if (Test-Path -Path "$InstallDir\.git") {
    Write-Log -Level Info -Message "Updating existing repository..."
    Set-Location -Path $InstallDir
    
    # Save the current branch or tag
    $currentRef = $null
    try {
        $currentRef = git symbolic-ref --short HEAD 2>$null
    }
    catch {
        try {
            $currentRef = git describe --tags --exact-match 2>$null
        }
        catch {
            $currentRef = git rev-parse HEAD
        }
    }
    
    # Update repository
    git fetch --all
    
    # If a specific version was requested, check it out
    if ($Version -ne "latest") {
        Write-Log -Level Info -Message "Checking out version $Version..."
        $tagsExist = git tag -l | Select-String -Pattern "^$Version$" -Quiet
        
        if ($tagsExist) {
            git checkout $Version
        }
        else {
            Write-Log -Level Error -Message "Version $Version not found. Available versions:"
            git tag -l
            exit 1
        }
    }
    else {
        # Otherwise use the default branch
        Write-Log -Level Info -Message "Checking out default branch $Branch..."
        git checkout $Branch
        git pull origin $Branch
    }
}
else {
    Write-Log -Level Info -Message "Cloning repository..."
    
    # For a specific version, clone the repository and checkout the tag
    if ($Version -ne "latest") {
        git clone --depth 1 --branch $Version $AuthRepoUrl $InstallDir
    }
    else {
        git clone --branch $Branch $AuthRepoUrl $InstallDir
    }
    
    Set-Location -Path $InstallDir
}

# Check for a release directory with pre-built executables
if (Test-Path -Path "$InstallDir\release") {
    Write-Log -Level Info -Message "Found release directory, checking for pre-built executables..."
    
    # Determine OS and architecture
    $osType = "windows"
    $arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" }
    
    # Check for OS-specific pre-built executables
    if (Test-Path -Path "$InstallDir\release\$osType-$arch\setup.exe") {
        Write-Log -Level Info -Message "Found pre-built executable for $osType-$arch"
        Copy-Item -Path "$InstallDir\release\$osType-$arch\setup.exe" -Destination "$InstallDir\setup.exe"
    }
}

# Run the appropriate setup script
Write-Log -Level Info -Message "Starting setup process in $Mode mode..."

if (Test-Path -Path "$InstallDir\setup.exe") {
    Write-Log -Level Info -Message "Running pre-built setup executable..."
    & "$InstallDir\setup.exe" -Mode $Mode $args
}
else {
    Write-Log -Level Info -Message "Running PowerShell setup script..."
    & "$InstallDir\setup.ps1" -Mode $Mode $args
}

Write-Log -Level Info -Message "Bootstrap process completed successfully!"
Write-Log -Level Info -Message "The framework is installed at: $InstallDir"

if ($Mode -eq "controller") {
    Write-Log -Level Info -Message "Controller mode is set up. Use 'python controller.py init' to initialize the controller."
    Write-Log -Level Info -Message "Then use 'python controller.py help' for available commands."
} else {
    Write-Log -Level Info -Message "You can now use the infrastructure automation framework"
} 