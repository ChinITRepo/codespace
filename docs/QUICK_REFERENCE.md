# Infrastructure Automation Framework - Quick Reference

This document provides quick one-liners and essential commands for using the infrastructure automation framework across different devices and environments.

## Framework Installation

### Windows (PowerShell)

```powershell
# Install in controller mode
iex "& {$(irm https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/bootstrap.ps1)} -Mode controller"
```

### Linux/macOS (Bash)

```bash
# Install in controller mode
curl -fsSL https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/bootstrap.sh | bash -s -- --controller
```

## Client Device Setup

### Windows Laptop Setup

```powershell
# Direct execution (requires downloading the script first)
.\windows-laptop-setup.ps1

# One-liner for remote execution
iex "& {$(irm https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/client-devices/windows-laptop-setup.ps1)}"

# With custom parameters
iex "& {$(irm https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/client-devices/windows-laptop-setup.ps1)} -SkipAWS -CustomInstallPath 'D:\DevTools'"
```

### macOS Setup

```bash
# Direct execution
curl -fsSL https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/client-devices/macos-setup.sh | bash

# With specific options
curl -fsSL https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/client-devices/macos-setup.sh | bash -s -- --no-homebrew
```

### Linux Setup

```bash
# Direct execution
curl -fsSL https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/client-devices/linux-setup.sh | bash

# With specific options
curl -fsSL https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/client-devices/linux-setup.sh | bash -s -- --distro ubuntu
```

### Mobile Device Setup

```bash
# Generate Android guide
curl -fsSL https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/client-devices/mobile-setup.sh | bash -s -- --platform android --action guide

# Generate iOS guide
curl -fsSL https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/client-devices/mobile-setup.sh | bash -s -- --platform ios --action guide

# Configure backend for mobile access
curl -fsSL https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/client-devices/mobile-setup.sh | bash -s -- --platform android --action config --api-host api.example.com
```

## SSH Agent Setup for Windows

```powershell
# Setup SSH agent
iex "& {$(irm https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/ssh-agent-setup.ps1)}"

# Or using batch file after download
.\start-ssh-agent.bat
```

## Common Controller Commands

```bash
# Initialize the controller
python controller.py init

# Show help
python controller.py help

# Deploy tier1 core infrastructure
python controller.py deploy tier1-core --env dev

# Deploy log management
python controller.py deploy tier2-services/log_management --env dev

# Run discovery
python controller.py discover --type network --output json
```

## Terraform Direct Commands

```bash
# Initialize Terraform
cd tier1-core && terraform init

# Plan deployment
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Destroy infrastructure
terraform destroy
```

For more detailed instructions, refer to the [INSTALL.md](../INSTALL.md) file and the README files in each module directory. 