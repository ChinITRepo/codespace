# SSH Agent Setup Script for Windows
# This script configures SSH agent to cache your passphrase

# Function to ensure SSH agent is running and configured properly
function Initialize-SshAgent {
    # Check if OpenSSH is available
    $sshExe = "$env:WINDIR\System32\OpenSSH\ssh.exe"
    if (-not (Test-Path $sshExe)) {
        Write-Host "OpenSSH not found in standard location. Checking alternative paths..." -ForegroundColor Yellow
        $sshExe = (Get-Command ssh -ErrorAction SilentlyContinue).Source
        if (-not $sshExe) {
            Write-Host "OpenSSH is not installed or not in PATH. Please install OpenSSH." -ForegroundColor Red
            return $false
        }
    }

    # Set SSH environment variables
    $env:GIT_SSH = $sshExe

    # Start SSH Agent (method 1 - Windows service)
    try {
        $sshAgent = Get-Service ssh-agent -ErrorAction Stop
        if ($sshAgent.Status -ne 'Running') {
            Write-Host "Starting SSH agent service..." -ForegroundColor Yellow
            Start-Service ssh-agent -ErrorAction Stop
            Write-Host "SSH agent service started successfully" -ForegroundColor Green
        } else {
            Write-Host "SSH agent service is already running" -ForegroundColor Green
        }
        
        # Set automatic startup
        if ($sshAgent.StartType -ne 'Automatic') {
            Set-Service ssh-agent -StartupType Automatic
            Write-Host "SSH agent service set to start automatically" -ForegroundColor Green
        }
        
        return $true
    }
    catch {
        Write-Host "Could not start SSH agent as a service. Trying alternative method..." -ForegroundColor Yellow
        
        # Method 2 - Start SSH Agent as a process
        try {
            # Get the SSH agent environment variables
            $sshAgentOutput = & ssh-agent
            
            # Parse and set the environment variables
            $sshAgentOutput | ForEach-Object {
                if ($_ -match '([A-Z_]+)=([^;]+);') {
                    $envVarName = $matches[1]
                    $envVarValue = $matches[2]
                    [Environment]::SetEnvironmentVariable($envVarName, $envVarValue, "Process")
                    Write-Host "Set $envVarName = $envVarValue" -ForegroundColor Green
                }
            }
            
            return $true
        }
        catch {
            Write-Host "Failed to start SSH agent: $_" -ForegroundColor Red
            return $false
        }
    }
}

# Function to add SSH key to the agent
function Add-SshKey {
    param (
        [string]$keyPath = "$HOME\.ssh\id_ed25519"
    )
    
    if (-not (Test-Path $keyPath)) {
        Write-Host "SSH key not found at: $keyPath" -ForegroundColor Red
        return $false
    }
    
    Write-Host "Adding SSH key to agent: $keyPath" -ForegroundColor Yellow
    
    $result = ssh-add $keyPath 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SSH key added successfully!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Failed to add SSH key. Error: $result" -ForegroundColor Red
        return $false
    }
}

# Function to test SSH connection to GitHub
function Test-GitHubConnection {
    Write-Host "`nTesting SSH connection to GitHub..." -ForegroundColor Yellow
    try {
        $output = ssh -T git@github.com 2>&1
        if ($output -match "successfully authenticated") {
            Write-Host "Successfully authenticated to GitHub!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "GitHub connection test returned unexpected result: $output" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "GitHub connection test failed: $_" -ForegroundColor Red
        return $false
    }
}

# Function to create a PowerShell profile with SSH agent configuration
function Set-PowerShellProfile {
    $profileContent = @"
# SSH Agent Configuration
# This will ensure SSH agent is running in each PowerShell session

# Set SSH executable path
`$env:GIT_SSH = "`$env:WINDIR\System32\OpenSSH\ssh.exe"

# Check if SSH agent is running and start it if needed
try {
    `$sshAgent = Get-Service ssh-agent -ErrorAction Stop
    if (`$sshAgent.Status -ne 'Running') {
        Start-Service ssh-agent
        Write-Host "Started SSH agent service" -ForegroundColor Green
    }
} catch {
    Write-Host "Could not start SSH agent as a service. SSH keys may need to be added manually." -ForegroundColor Yellow
}

# Optional: Remind user if this is a new session
Write-Host "SSH agent is configured. Use ssh-add to add keys if needed." -ForegroundColor Cyan
"@

    $profilePaths = @(
        "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1",  # PowerShell 7
        "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"  # Windows PowerShell
    )

    foreach ($profilePath in $profilePaths) {
        $profileDir = Split-Path $profilePath -Parent
        
        if (-not (Test-Path $profileDir)) {
            New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
        }
        
        if (-not (Test-Path $profilePath)) {
            New-Item -Path $profilePath -ItemType File -Force | Out-Null
            Add-Content -Path $profilePath -Value $profileContent
            Write-Host "Created PowerShell profile at: $profilePath" -ForegroundColor Green
        } else {
            if (-not (Get-Content $profilePath | Select-String -Pattern "SSH Agent Configuration")) {
                Add-Content -Path $profilePath -Value "`n$profileContent"
                Write-Host "Added SSH agent configuration to existing profile at: $profilePath" -ForegroundColor Green
            } else {
                Write-Host "SSH agent configuration already exists in profile at: $profilePath" -ForegroundColor Yellow
            }
        }
    }
}

# Create a batch file to easily start SSH agent from command prompt
function Create-SshAgentBatchFile {
    $batchPath = ".\start-ssh-agent.bat"
    $batchContent = @"
@echo off
echo Starting SSH agent and adding keys...
powershell -ExecutionPolicy Bypass -File "%~dp0ssh-agent-setup.ps1"
echo.
echo If successful, your SSH keys should now be loaded in the agent.
echo You can now use Git commands without entering your passphrase again.
pause
"@

    Set-Content -Path $batchPath -Value $batchContent
    Write-Host "Created batch file for easy SSH agent startup: $batchPath" -ForegroundColor Green
}

# Main execution
Write-Host "=== SSH Agent Setup Script for GitHub ===" -ForegroundColor Cyan
Write-Host "This script will configure SSH agent to remember your passphrase" -ForegroundColor Cyan
Write-Host "-----------------------------------------------" -ForegroundColor Cyan

# Step 1: Initialize SSH agent
$agentInitialized = Initialize-SshAgent
if (-not $agentInitialized) {
    Write-Host "Failed to initialize SSH agent. Aborting." -ForegroundColor Red
    exit 1
}

# Step 2: Add SSH key to agent
$keyAdded = Add-SshKey
if (-not $keyAdded) {
    Write-Host "Failed to add SSH key to agent. Please check error messages above." -ForegroundColor Red
}

# Step 3: Test GitHub connection
$connectionTested = Test-GitHubConnection
if (-not $connectionTested) {
    Write-Host "GitHub connection test was not successful. Please check error messages above." -ForegroundColor Yellow
}

# Step 4: Configure PowerShell profile
Set-PowerShellProfile

# Step 5: Create batch file for easy startup
Create-SshAgentBatchFile

# Final instructions
Write-Host "`n=== SSH Agent Setup Complete ===" -ForegroundColor Cyan
Write-Host "To automatically load your SSH keys in new sessions:" -ForegroundColor White
Write-Host "1. Open a new PowerShell window (your profile will automatically configure SSH agent)" -ForegroundColor White
Write-Host "2. From a regular command prompt, run 'start-ssh-agent.bat'" -ForegroundColor White
Write-Host "`nYou can now use Git with SSH without entering your passphrase repeatedly!" -ForegroundColor Green 