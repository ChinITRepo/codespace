# Installing the Infrastructure Automation Framework

The Infrastructure Automation Framework supports Git-based installation methods to accommodate different environments and workflows.

## One-Line Installation

### For Windows Systems (PowerShell):

```powershell
# Basic installation
iex (irm https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/bootstrap.ps1)

# Install in controller mode
iex "& {$(irm https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/bootstrap.ps1)} -Mode controller"
```

### For Linux/macOS Systems (Bash):

```bash
# Basic installation
curl -fsSL https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/bootstrap.sh | bash

# Install in controller mode
curl -fsSL https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/bootstrap.sh | bash -s -- --controller
```

## Git-Based Installation

For direct installation using Git:

```bash
# Clone the repository
git clone https://github.com/ChinITRepo/infrastructure-automation.git

# Navigate to the directory
cd infrastructure-automation

# Run setup script
# Windows
.\setup.ps1

# Linux/macOS
./setup.sh
```

## Working with Private Repository

Since this is a private repository, you'll need to authenticate:

### Personal Access Token (PAT)

1. Create a token in GitHub:
   - Go to GitHub → Settings → Developer settings → Personal access tokens
   - Generate new token with "repo" permissions
   - Copy the token

2. Clone with token:
   ```bash
   git clone https://YOUR_TOKEN@github.com/ChinITRepo/infrastructure-automation.git
   ```

3. Or update existing repository:
   ```bash
   git remote set-url origin https://YOUR_TOKEN@github.com/ChinITRepo/infrastructure-automation.git
   ```

4. For one-liner installation with token:

   **Windows:**
   ```powershell
   iex "& {$(irm https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/bootstrap.ps1)} -Token 'YOUR_TOKEN'"
   ```

   **Linux/macOS:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/ChinITRepo/infrastructure-automation/main/bootstrap.sh | bash -s -- --token=YOUR_TOKEN
   ```

### SSH Authentication

1. Generate SSH key (if you don't have one):
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. Add SSH key to GitHub:
   - Copy your public key: `cat ~/.ssh/id_ed25519.pub`
   - Go to GitHub → Settings → SSH and GPG keys → New SSH key
   - Paste and save your key

3. Clone with SSH:
   ```bash
   git clone git@github.com:ChinITRepo/infrastructure-automation.git
   ```

4. Or update existing repository:
   ```bash
   git remote set-url origin git@github.com:ChinITRepo/infrastructure-automation.git
   ```

## Git Workflow After Installation

### Managing Your Infrastructure Code

```bash
# Pull latest changes
git pull origin main

# Create a feature branch
git checkout -b feature/new-module

# Make your changes
# ...

# Commit changes
git add .
git commit -m "Added new infrastructure module"

# Push to remote
git push origin feature/new-module

# After code review, merge to main
git checkout main
git merge feature/new-module
git push origin main
```

### Working with Environments

```bash
# Initialize controller environment
python controller.py init

# Create environment-specific configuration
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
vi terraform/environments/dev/terraform.tfvars

# Commit your configuration
git add terraform/environments/dev/terraform.tfvars
git commit -m "Updated development environment configuration"
git push origin main
```

## Configuration Options

### Bootstrap Parameters

#### PowerShell (Windows):
- `-RepoUrl <url>` - Git repository URL
- `-Token <token>` - GitHub personal access token
- `-Mode <mode>` - Setup mode (dev, prod, controller)
- `-InstallDir <dir>` - Installation directory

#### Bash (Linux/macOS):
- `--repo=<url>` - Git repository URL
- `--token=<token>` - GitHub personal access token
- `--mode=<mode>` - Setup mode (dev, prod, controller)
- `--dir=<dir>` - Installation directory

## Troubleshooting

### Git Authentication Issues

If you encounter authentication issues:

```bash
# Check your remote URL
git remote -v

# Update with token for HTTPS
git remote set-url origin https://YOUR_TOKEN@github.com/ChinITRepo/infrastructure-automation.git

# Or update with SSH
git remote set-url origin git@github.com:ChinITRepo/infrastructure-automation.git
```

### Git User Configuration

Ensure your Git user is configured:

```bash
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"
```

### Git SSL Verification Issues

If you have SSL certificate issues:

```bash
# Windows
git config --global http.sslBackend schannel

# Linux/macOS
git config --global http.sslVerify true
```

## Next Steps

After installation completes:

1. Initialize the controller (if in controller mode):
   ```bash
   python controller.py init
   ```

2. Configure your cloud provider credentials:
   ```bash
   python controller.py setup-cloud --cloud=aws
   ```

3. Apply your infrastructure:
   ```bash
   python controller.py terraform --env=dev --tf-action=apply
   ```

4. Commit your changes:
   ```bash
   git add .
   git commit -m "Applied infrastructure changes"
   git push origin main
   ``` 