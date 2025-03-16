# Infrastructure Automation Framework

A comprehensive infrastructure automation framework optimized for scalability, security, and multi-platform compatibility.

## Quick Start Installation

### One-Line Installation

#### Windows (PowerShell):
```powershell
# Basic installation
iex (irm https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/bootstrap.ps1)

# With controller mode
iex "& {$(irm https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/bootstrap.ps1)} -Mode controller"
```

#### Linux/macOS (Bash):
```bash
# Basic installation
curl -fsSL https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/bootstrap.sh | bash

# With controller mode
curl -fsSL https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/bootstrap.sh | bash -s -- --controller
```

### Client Device Setup

For setting up client devices (laptops, tablets, and phones) to work with the infrastructure:

#### Windows Laptop:
```powershell
iex "& {$(irm https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/client-devices/windows-laptop-setup.ps1)}"
```

#### macOS:
```bash
curl -fsSL https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/client-devices/macos-setup.sh | bash
```

#### Mobile (Android/iOS):
```bash
# Generate setup guides
curl -fsSL https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/client-devices/mobile-setup.sh | bash -s -- --platform android --action guide
```

For detailed installation instructions and more one-liners, see [Quick Reference](docs/QUICK_REFERENCE.md) and [INSTALL.md](INSTALL.md).

## Overview

This framework automates infrastructure provisioning and management across various platforms (Windows, Linux, macOS, cloud, on-prem) with a focus on security, scalability, and self-healing capabilities.

## Core Features

- Infrastructure as Code with Terraform and Git-based version control
- Cross-platform deployment (Windows, Linux, macOS)
- Centralized logging and monitoring
- Security and secret management
- Self-healing and dynamic reconfiguration
- Controller mode for managing multiple environments

## Git-Based Workflow

The framework uses Git for version control, enabling:

1. **Versioned Infrastructure**: Track all changes to infrastructure code
2. **CI/CD Integration**: Automated testing and deployment pipelines
3. **Collaborative Development**: Pull requests and code reviews
4. **Environment Branching**: Separate branches for dev, test, and production
5. **Rollbacks**: Easy reversion to previous states

```bash
# Create a new feature branch
git checkout -b feature/new-service

# Make changes to infrastructure code
# ...

# Commit changes
git add terraform/modules/new-service
git commit -m "Add new service module"

# Push changes
git push origin feature/new-service

# Merge to main after review
git checkout main
git merge feature/new-service
git push origin main
```

## System Architecture

The framework follows a tiered approach to ensure efficient scaling, security, and modularity:

| Tier | Purpose | Key Components |
|------|---------|----------------|
| Tier 0: Discovery & Assessment | Identifies & evaluates devices for automation readiness | Network scanning, DHCP logs, hardware assessment |
| Tier 1: Core Infrastructure | Establishes networking, security, storage, and virtualization | VLANs, Firewalls, VPN, Storage, Proxmox |
| Tier 2: Essential Services | Provides automation, monitoring, and access control | Ansible, Vault, Prometheus, Cloudflare Tunnel, Syslog |
| Tier 3: Application Services | Supports business, media, and cloud services | Nextcloud, ERP, ARR Stack, AI workloads |
| Tier 4: High-Performance & Specialized Services | Handles resource-intensive workloads | AI models, Game Servers, Advanced Security |

## Controller/Workstation Mode

The controller mode provides a Git-integrated experience for managing infrastructure from your laptop or workstation:

```bash
# Clone the repository 
git clone https://github.com/ChinITRepo/infrastructure-automation.git

# Set up controller mode
cd infrastructure-automation
./setup.sh --controller   # Linux/macOS
.\setup.ps1 -Controller   # Windows

# Initialize the controller environment
python controller.py init

# Pull latest changes
git pull origin main

# Switch between environments
python controller.py use-env --env=dev
python controller.py use-env --env=prod

# Apply infrastructure changes
python controller.py terraform --env=dev --tf-action=apply

# Push local changes back to repository
git add .
git commit -m "Updated dev environment configuration"
git push origin main
```

### Controller Directory Structure

The controller mode creates a Git-friendly directory structure:

```
controller/
├── ansible/         # Ansible configuration
├── cloud/           # Cloud provider configurations
├── environments/    # Environment configurations
│   ├── dev/
│   ├── test/
│   └── prod/
├── inventories/     # Ansible inventories
├── ssh/             # SSH configuration
└── terraform/       # Terraform configurations
```

## Deployment

After setting up the environment:

```bash
# Pull latest changes
git pull origin main

# Configure environment variables
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
vim terraform/environments/dev/terraform.tfvars

# Apply infrastructure changes
cd terraform/environments/dev
terraform init
terraform plan
terraform apply

# Commit configuration changes
git add terraform/environments/dev/terraform.tfvars
git commit -m "Update dev environment configuration"
git push origin main
```

## Directory Structure

```
infrastructure-automation/
├── ansible/                # Ansible configuration
├── terraform/              # Terraform IaC
│   ├── modules/            # Reusable modules
│   └── environments/       # Environment-specific configs
├── discovery/              # Discovery tools
├── setup.py                # Cross-platform setup script
├── setup.ps1               # Windows setup wrapper
├── setup.sh                # Linux/macOS setup wrapper
└── vault/                  # Vault configuration
```

## License

[Add your license information here]

## Contributors

[Add contributors information here] 