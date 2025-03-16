#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows laptop setup script for infrastructure automation engineers.
.DESCRIPTION
    This script configures a Windows laptop for infrastructure automation work.
    It installs essential tools, configures SSH, sets up Git, and prepares the
    development environment for cloud infrastructure management.
.PARAMETER SkipTools
    Skip installation of development tools
.PARAMETER SkipSSH
    Skip SSH configuration
.PARAMETER SkipAWS
    Skip AWS CLI and configuration
.PARAMETER SkipGit
    Skip Git configuration
.PARAMETER CustomInstallPath
    Custom path for tool installations
.EXAMPLE
    .\windows-laptop-setup.ps1
.EXAMPLE
    .\windows-laptop-setup.ps1 -SkipAWS -CustomInstallPath "D:\DevTools"
#>
param (
    [switch]$SkipTools,
    [switch]$SkipSSH,
    [switch]$SkipAWS,
    [switch]$SkipGit,
    [string]$CustomInstallPath
)

# Setup variables
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue" # Speeds up downloads
$installPath = if ($CustomInstallPath) { $CustomInstallPath } else { "$env:USERPROFILE\InfraTools" }
$logFile = "$installPath\setup_log.txt"

# Create install directory
if (-not (Test-Path $installPath)) {
    New-Item -Path $installPath -ItemType Directory | Out-Null
}

# Log function
function Write-Log {
    param (
        [string]$Message,
        [switch]$IsError
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    
    # Output to console
    if ($IsError) {
        Write-Host $logMessage -ForegroundColor Red
    } else {
        Write-Host $logMessage -ForegroundColor Green
    }
    
    # Write to log file
    Add-Content -Path $logFile -Value $logMessage
}

Write-Log "Starting Windows laptop setup for infrastructure automation"
Write-Log "Install path: $installPath"

# Check for Chocolatey and install if not present
if (-not $SkipTools) {
    Write-Log "Checking for Chocolatey package manager..."
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Log "Installing Chocolatey package manager..."
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            Write-Log "Chocolatey installed successfully"
        } catch {
            Write-Log "Failed to install Chocolatey: $_" -IsError
            exit 1
        }
    } else {
        Write-Log "Chocolatey is already installed"
    }

    # Install essential tools with Chocolatey
    Write-Log "Installing essential development tools..."
    $tools = @(
        "vscode",
        "git",
        "terraform",
        "awscli",
        "azure-cli",
        "googlechrome",
        "notepadplusplus",
        "7zip",
        "putty",
        "winscp",
        "postman",
        "python3",
        "nodejs-lts",
        "powershell-core"
    )

    foreach ($tool in $tools) {
        Write-Log "Installing $tool..."
        try {
            choco install $tool -y | Out-Null
            Write-Log "$tool installed successfully"
        } catch {
            Write-Log "Failed to install $($tool): $_" -IsError
        }
    }

    # Install VSCode extensions
    Write-Log "Installing VSCode extensions..."
    $extensions = @(
        "hashicorp.terraform",
        "ms-vscode.powershell",
        "ms-python.python",
        "redhat.vscode-yaml",
        "amazonwebservices.aws-toolkit-vscode",
        "ms-azuretools.vscode-azureterraform",
        "ms-vscode-remote.remote-ssh"
    )

    foreach ($extension in $extensions) {
        Write-Log "Installing VSCode extension: $extension..."
        try {
            & code --install-extension $extension | Out-Null
            Write-Log "VSCode extension $extension installed successfully"
        } catch {
            Write-Log "Failed to install VSCode extension $($extension): $_" -IsError
        }
    }
}

# Configure SSH
if (-not $SkipSSH) {
    Write-Log "Configuring SSH..."
    
    # Ensure OpenSSH is installed
    $sshFeatures = @("OpenSSH.Client")
    foreach ($feature in $sshFeatures) {
        if ((Get-WindowsCapability -Online | Where-Object Name -like "OpenSSH.Client*").State -ne "Installed") {
            Write-Log "Installing OpenSSH Client..."
            Add-WindowsCapability -Online -Name "OpenSSH.Client~~~~0.0.1.0" | Out-Null
            Write-Log "OpenSSH Client installed successfully"
        } else {
            Write-Log "OpenSSH Client is already installed"
        }
    }

    # Generate SSH key if it doesn't exist
    $sshDir = "$env:USERPROFILE\.ssh"
    if (-not (Test-Path "$sshDir\id_ed25519")) {
        Write-Log "Generating SSH key..."
        
        # Create .ssh directory if it doesn't exist
        if (-not (Test-Path $sshDir)) {
            New-Item -Path $sshDir -ItemType Directory | Out-Null
        }
        
        # Generate SSH key
        $email = Read-Host "Enter your email for SSH key"
        & ssh-keygen -t ed25519 -C $email -f "$sshDir\id_ed25519" -N '""'
        
        # Configure SSH agent
        Write-Log "Setting up SSH agent..."
        $sshAgentScript = '# Start SSH Agent' + [Environment]::NewLine
        $sshAgentScript += '$env:GIT_SSH = "C:/Windows/System32/OpenSSH/ssh.exe"' + [Environment]::NewLine + [Environment]::NewLine
        $sshAgentScript += '$sshAgent = Get-Service ssh-agent' + [Environment]::NewLine
        $sshAgentScript += 'if ($sshAgent.Status -ne "Running") {' + [Environment]::NewLine
        $sshAgentScript += '    Start-Service ssh-agent' + [Environment]::NewLine
        $sshAgentScript += '    Write-Host "SSH agent started" -ForegroundColor Green' + [Environment]::NewLine
        $sshAgentScript += '} else {' + [Environment]::NewLine
        $sshAgentScript += '    Write-Host "SSH agent is already running" -ForegroundColor Green' + [Environment]::NewLine
        $sshAgentScript += '}' + [Environment]::NewLine + [Environment]::NewLine
        $sshAgentScript += '# Add SSH key to agent' + [Environment]::NewLine
        $sshAgentScript += 'ssh-add $env:USERPROFILE\.ssh\id_ed25519 2>$null' + [Environment]::NewLine
        $sshAgentScript += 'if ($?) {' + [Environment]::NewLine
        $sshAgentScript += '    Write-Host "SSH key added to agent" -ForegroundColor Green' + [Environment]::NewLine
        $sshAgentScript += '} else {' + [Environment]::NewLine
        $sshAgentScript += '    Write-Host "SSH key already in agent or failed to add" -ForegroundColor Yellow' + [Environment]::NewLine
        $sshAgentScript += '}'
        
        # Add SSH agent startup to PowerShell profile
        $profilePath = $PROFILE
        if (-not (Test-Path $profilePath)) {
            New-Item -Path $profilePath -ItemType File -Force | Out-Null
        }
        
        Add-Content -Path $profilePath -Value $sshAgentScript
        Write-Log "SSH agent setup added to PowerShell profile: $profilePath"
        
        # Display public key
        Write-Log "Your SSH public key (add this to your Git provider and infrastructure):"
        Get-Content "$sshDir\id_ed25519.pub" | Write-Host -ForegroundColor Cyan
    } else {
        Write-Log "SSH key already exists at $sshDir\id_ed25519"
    }
}

# Configure AWS CLI
if (-not $SkipAWS) {
    Write-Log "Configuring AWS CLI..."
    
    # Check if AWS CLI is installed
    if (Get-Command aws -ErrorAction SilentlyContinue) {
        # Create AWS config directory if it doesn't exist
        $awsDir = "$env:USERPROFILE\.aws"
        if (-not (Test-Path $awsDir)) {
            New-Item -Path $awsDir -ItemType Directory | Out-Null
        }
        
        # Check if AWS is already configured
        if (-not (Test-Path "$awsDir\credentials")) {
            Write-Log "Setting up AWS credentials..."
            Write-Host "Please enter your AWS credentials:" -ForegroundColor Yellow
            $awsAccessKey = Read-Host "AWS Access Key ID"
            $awsSecretKey = Read-Host "AWS Secret Access Key" -AsSecureString
            $awsRegion = Read-Host "Default AWS Region (e.g., us-east-1)"
            $awsProfile = Read-Host "AWS Profile Name (default if empty)"
            
            if (-not $awsProfile) {
                $awsProfile = "default"
            }
            
            # Convert secure string to plain text
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($awsSecretKey)
            $awsSecretKeyPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            
            # Create credentials file
            $credentialsContent = "[$awsProfile]" + [Environment]::NewLine
            $credentialsContent += "aws_access_key_id = $awsAccessKey" + [Environment]::NewLine
            $credentialsContent += "aws_secret_access_key = $awsSecretKeyPlain"
            
            # Create config file
            $configContent = "[$awsProfile]" + [Environment]::NewLine
            $configContent += "region = $awsRegion" + [Environment]::NewLine
            $configContent += "output = json"
            
            Set-Content -Path "$awsDir\credentials" -Value $credentialsContent
            Set-Content -Path "$awsDir\config" -Value $configContent
            
            Write-Log "AWS CLI configured successfully for profile: $awsProfile"
        } else {
            Write-Log "AWS credentials already configured"
        }
    } else {
        Write-Log "AWS CLI not found. Skipping AWS configuration." -IsError
    }
}

# Configure Git
if (-not $SkipGit) {
    Write-Log "Configuring Git..."
    
    # Check if Git is installed
    if (Get-Command git -ErrorAction SilentlyContinue) {
        # Set up Git configuration if not already configured
        $gitName = git config --global user.name
        $gitEmail = git config --global user.email
        
        if (-not $gitName -or -not $gitEmail) {
            Write-Host "Please enter your Git configuration:" -ForegroundColor Yellow
            $name = Read-Host "Your Name"
            $email = Read-Host "Your Email"
            
            git config --global user.name "$name"
            git config --global user.email "$email"
            
            # Configure Git defaults
            git config --global core.autocrlf true
            git config --global init.defaultBranch main
            git config --global pull.rebase false
            
            Write-Log "Git configured successfully for user: $name <$email>"
        } else {
            Write-Log "Git already configured for user: $gitName <$gitEmail>"
        }
        
        # Create global .gitignore
        $globalGitignore = "$env:USERPROFILE\.gitignore"
        if (-not (Test-Path $globalGitignore)) {
            $gitignoreContent = "# Windows" + [Environment]::NewLine
            $gitignoreContent += "Thumbs.db" + [Environment]::NewLine
            $gitignoreContent += "desktop.ini" + [Environment]::NewLine
            $gitignoreContent += "`$RECYCLE.BIN/" + [Environment]::NewLine + [Environment]::NewLine
            $gitignoreContent += "# macOS" + [Environment]::NewLine
            $gitignoreContent += ".DS_Store" + [Environment]::NewLine
            $gitignoreContent += ".AppleDouble" + [Environment]::NewLine
            $gitignoreContent += ".LSOverride" + [Environment]::NewLine + [Environment]::NewLine
            $gitignoreContent += "# Linux" + [Environment]::NewLine
            $gitignoreContent += "*~" + [Environment]::NewLine
            $gitignoreContent += ".directory" + [Environment]::NewLine + [Environment]::NewLine
            $gitignoreContent += "# IDE files" + [Environment]::NewLine
            $gitignoreContent += ".idea/" + [Environment]::NewLine
            $gitignoreContent += ".vscode/" + [Environment]::NewLine
            $gitignoreContent += "*.sublime-*" + [Environment]::NewLine
            $gitignoreContent += ".vs/" + [Environment]::NewLine + [Environment]::NewLine
            $gitignoreContent += "# Environment files" + [Environment]::NewLine
            $gitignoreContent += ".env" + [Environment]::NewLine
            $gitignoreContent += ".env.local" + [Environment]::NewLine
            $gitignoreContent += ".env.*.local" + [Environment]::NewLine + [Environment]::NewLine
            $gitignoreContent += "# Terraform" + [Environment]::NewLine
            $gitignoreContent += ".terraform/" + [Environment]::NewLine
            $gitignoreContent += "terraform.tfstate" + [Environment]::NewLine
            $gitignoreContent += "terraform.tfstate.backup" + [Environment]::NewLine
            $gitignoreContent += "terraform.tfvars" + [Environment]::NewLine
            $gitignoreContent += "*.tfvars" + [Environment]::NewLine
            $gitignoreContent += ".terraform.lock.hcl" + [Environment]::NewLine + [Environment]::NewLine
            $gitignoreContent += "# AWS" + [Environment]::NewLine
            $gitignoreContent += ".aws-credentials"
            
            Set-Content -Path $globalGitignore -Value $gitignoreContent
            git config --global core.excludesfile $globalGitignore
            
            Write-Log "Global .gitignore created at: $globalGitignore"
        }
    } else {
        Write-Log "Git not found. Skipping Git configuration." -IsError
    }
}

# Create repository directory
$repoDir = "$env:USERPROFILE\Repositories"
if (-not (Test-Path $repoDir)) {
    New-Item -Path $repoDir -ItemType Directory | Out-Null
    Write-Log "Created repository directory: $repoDir"
}

# Clone infrastructure automation repository if it doesn't exist
$infraRepoPath = "$repoDir\infrastructure-automation"
if (-not (Test-Path $infraRepoPath) -and (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Do you want to clone the infrastructure automation repository? (Y/N)" -ForegroundColor Yellow
    $cloneRepo = Read-Host
    
    if ($cloneRepo -eq "Y" -or $cloneRepo -eq "y") {
        $repoUrl = Read-Host "Enter the Git repository URL"
        
        try {
            Push-Location $repoDir
            git clone $repoUrl infrastructure-automation
            Pop-Location
            Write-Log "Successfully cloned infrastructure automation repository to: $infraRepoPath"
        } catch {
            Write-Log "Failed to clone repository: $_" -IsError
        }
    }
}

# Create shortcut to infrastructure automation tools
$shortcutPath = "$env:USERPROFILE\Desktop\Infrastructure Automation.lnk"
if (-not (Test-Path $shortcutPath)) {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = if (Test-Path $infraRepoPath) { $infraRepoPath } else { $installPath }
    $Shortcut.Save()
    Write-Log "Created desktop shortcut: $shortcutPath"
}

# Setup complete
Write-Log "Windows laptop setup completed successfully!"
Write-Log "Please restart your computer to ensure all changes take effect."
Write-Host "Setup log saved to: $logFile" -ForegroundColor Cyan 