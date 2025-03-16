#!/bin/bash
# Linux Setup Script for Infrastructure Automation Engineers
# This script configures a Linux system for infrastructure development and management
# Supports Ubuntu, Debian, Fedora, and CentOS/RHEL

set -e

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="$HOME/linux_setup_log.txt"
INSTALL_DIR="$HOME/InfraTools"

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    DISTRO_VERSION=$VERSION_ID
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    DISTRO=$DISTRIB_ID
    DISTRO_VERSION=$DISTRIB_RELEASE
else
    DISTRO=$(uname -s)
    DISTRO_VERSION=$(uname -r)
fi

# Create install directory
mkdir -p "$INSTALL_DIR"

# Log function
log() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local message="$1"
    local type="$2"
    
    case "$type" in
        "error")
            echo -e "${RED}[$timestamp] ERROR: $message${NC}"
            echo "[$timestamp] ERROR: $message" >> "$LOG_FILE"
            ;;
        "warning")
            echo -e "${YELLOW}[$timestamp] WARNING: $message${NC}"
            echo "[$timestamp] WARNING: $message" >> "$LOG_FILE"
            ;;
        "success")
            echo -e "${GREEN}[$timestamp] SUCCESS: $message${NC}"
            echo "[$timestamp] SUCCESS: $message" >> "$LOG_FILE"
            ;;
        *)
            echo -e "${BLUE}[$timestamp] INFO: $message${NC}"
            echo "[$timestamp] INFO: $message" >> "$LOG_FILE"
            ;;
    esac
}

# Function to install packages based on distribution
install_package() {
    local package=$1
    
    log "Installing $package..."
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt-get install -y $package || log "Failed to install $package" "error"
            ;;
        fedora)
            sudo dnf install -y $package || log "Failed to install $package" "error"
            ;;
        centos|rhel|rocky|almalinux)
            sudo yum install -y $package || log "Failed to install $package" "error"
            ;;
        *)
            log "Unsupported distribution for automatic installation: $DISTRO" "error"
            log "Please install $package manually"
            return 1
            ;;
    esac
    
    log "$package installed successfully" "success"
    return 0
}

# Function to update package repositories
update_repos() {
    log "Updating package repositories..."
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt-get update
            ;;
        fedora)
            sudo dnf check-update || true
            ;;
        centos|rhel|rocky|almalinux)
            sudo yum check-update || true
            ;;
        *)
            log "Unsupported distribution for repository update: $DISTRO" "error"
            return 1
            ;;
    esac
    
    log "Package repositories updated" "success"
    return 0
}

# Start setup
log "Starting Linux setup for infrastructure automation"
log "Detected distribution: $DISTRO $DISTRO_VERSION"
log "Install directory: $INSTALL_DIR"
log "Log file: $LOG_FILE"

# Check for sudo access
if ! sudo -v; then
    log "This script requires sudo access." "error"
    exit 1
fi

# Update package repositories
update_repos

# Install basic development packages
log "Installing basic development tools..."

case $DISTRO in
    ubuntu|debian)
        PACKAGES=(
            "build-essential"
            "git"
            "curl"
            "wget"
            "vim"
            "unzip"
            "python3"
            "python3-pip"
            "jq"
            "tmux"
            "net-tools"
            "tree"
            "htop"
            "gnupg2"
            "apt-transport-https"
            "ca-certificates"
            "software-properties-common"
        )
        ;;
    fedora)
        PACKAGES=(
            "git"
            "curl"
            "wget"
            "vim"
            "unzip"
            "python3"
            "python3-pip"
            "jq"
            "tmux"
            "net-tools"
            "tree"
            "htop"
            "gnupg2"
            "dnf-plugins-core"
            "development-tools"
        )
        ;;
    centos|rhel|rocky|almalinux)
        PACKAGES=(
            "git"
            "curl"
            "wget"
            "vim"
            "unzip"
            "python3"
            "python3-pip"
            "jq"
            "tmux"
            "net-tools"
            "tree"
            "htop"
            "gnupg2"
            "yum-utils"
            "make"
            "gcc"
            "gcc-c++"
        )
        ;;
    *)
        log "Unsupported distribution: $DISTRO" "error"
        log "Skipping package installation"
        PACKAGES=()
        ;;
esac

for package in "${PACKAGES[@]}"; do
    install_package "$package"
done

log "Basic development tools installed" "success"

# Install AWS CLI
log "Installing AWS CLI..."
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "$INSTALL_DIR/awscliv2.zip"
    unzip -q "$INSTALL_DIR/awscliv2.zip" -d "$INSTALL_DIR"
    sudo "$INSTALL_DIR/aws/install"
    rm "$INSTALL_DIR/awscliv2.zip"
    log "AWS CLI installed successfully" "success"
else
    log "AWS CLI is already installed"
fi

# Install Terraform
log "Installing Terraform..."
if ! command -v terraform &> /dev/null; then
    case $DISTRO in
        ubuntu|debian)
            wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
            sudo apt-get update && sudo apt-get install -y terraform
            ;;
        fedora|centos|rhel|rocky|almalinux)
            sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/$([ "$DISTRO" = "fedora" ] && echo "fedora" || echo "RHEL")/hashicorp.repo
            if [ "$DISTRO" = "fedora" ]; then
                sudo dnf install -y terraform
            else
                sudo yum install -y terraform
            fi
            ;;
        *)
            # Generic installation for other distributions
            TF_VERSION="1.5.5"
            wget -q "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip" -O "$INSTALL_DIR/terraform.zip"
            unzip -q "$INSTALL_DIR/terraform.zip" -d "$INSTALL_DIR/bin"
            sudo mv "$INSTALL_DIR/bin/terraform" /usr/local/bin/
            rm "$INSTALL_DIR/terraform.zip"
            ;;
    esac
    
    log "Terraform installed successfully" "success"
else
    log "Terraform is already installed"
fi

# Install Docker
log "Installing Docker..."
if ! command -v docker &> /dev/null; then
    case $DISTRO in
        ubuntu|debian)
            curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$DISTRO $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        fedora)
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        centos|rhel|rocky|almalinux)
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        *)
            log "Unsupported distribution for Docker installation: $DISTRO" "error"
            log "Please install Docker manually"
            ;;
    esac
    
    # Start and enable Docker
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    log "Docker installed successfully. You may need to log out and back in for the docker group to take effect." "success"
else
    log "Docker is already installed"
fi

# Install VS Code if GUI is available
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    log "Installing Visual Studio Code..."
    if ! command -v code &> /dev/null; then
        case $DISTRO in
            ubuntu|debian)
                wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
                sudo install -o root -g root -m 644 /tmp/microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
                sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
                sudo apt-get update
                sudo apt-get install -y code
                ;;
            fedora)
                sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
                sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
                sudo dnf install -y code
                ;;
            centos|rhel|rocky|almalinux)
                sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
                sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
                sudo yum install -y code
                ;;
            *)
                log "Unsupported distribution for VS Code installation: $DISTRO" "error"
                log "Please install VS Code manually"
                ;;
        esac
        
        log "Visual Studio Code installed successfully" "success"
        
        # Install VS Code extensions if VS Code is installed
        if command -v code &> /dev/null; then
            log "Installing VS Code extensions..."
            
            extensions=(
                "hashicorp.terraform"
                "ms-python.python"
                "ms-azuretools.vscode-docker"
                "redhat.vscode-yaml"
                "amazonwebservices.aws-toolkit-vscode"
                "ms-vscode-remote.remote-ssh"
                "golang.go"
                "ms-kubernetes-tools.vscode-kubernetes-tools"
                "redhat.ansible"
            )
            
            for extension in "${extensions[@]}"; do
                code --install-extension "$extension" || log "Failed to install VS Code extension: $extension" "warning"
            done
            
            log "VS Code extensions installed" "success"
        fi
    else
        log "Visual Studio Code is already installed"
    fi
else
    log "No display detected. Skipping Visual Studio Code installation." "warning"
fi

# Configure SSH
log "Configuring SSH..."
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    log "Generating SSH key..."
    
    # Create .ssh directory with correct permissions if it doesn't exist
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    # Generate SSH key
    read -p "Enter your email for SSH key: " ssh_email
    ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519"
    
    # Start SSH agent and add key
    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/id_ed25519"
    
    # Add SSH configuration to shell profile
    if [ -f "$HOME/.bashrc" ]; then
        PROFILE="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        PROFILE="$HOME/.bash_profile"
    elif [ -f "$HOME/.zshrc" ]; then
        PROFILE="$HOME/.zshrc"
    else
        PROFILE="$HOME/.profile"
    fi
    
    # Check if SSH agent configuration already exists
    if ! grep -q "ssh-agent" "$PROFILE"; then
        cat >> "$PROFILE" << EOL

# Start SSH agent
if [ -z "\$SSH_AUTH_SOCK" ]; then
   # Check for a currently running instance of the agent
   RUNNING_AGENT="\$(ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]')"
   if [ "\$RUNNING_AGENT" = "0" ]; then
        # Launch a new instance of the agent
        ssh-agent -s &> /dev/null
   fi
   eval \$(ssh-agent -s)
   ssh-add "\$HOME/.ssh/id_ed25519" 2>/dev/null
fi
EOL
        log "SSH agent configuration added to $PROFILE" "success"
    fi
    
    # Display the public key
    log "Your SSH public key (add this to GitHub/GitLab/etc.):"
    cat "$HOME/.ssh/id_ed25519.pub"
else
    log "SSH key already exists"
fi

# Configure Git
log "Configuring Git..."
if ! git config --global user.name &> /dev/null; then
    read -p "Enter your name for Git: " git_name
    git config --global user.name "$git_name"
    log "Git name set to: $git_name"
else
    log "Git name already configured as: $(git config --global user.name)"
fi

if ! git config --global user.email &> /dev/null; then
    read -p "Enter your email for Git: " git_email
    git config --global user.email "$git_email"
    log "Git email set to: $git_email"
else
    log "Git email already configured as: $(git config --global user.email)"
fi

# Additional Git configurations
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.editor "vim"

# Create global .gitignore
if [ ! -f "$HOME/.gitignore_global" ]; then
    cat > "$HOME/.gitignore_global" << EOL
# Linux system files
*~
.fuse_hidden*
.directory
.Trash-*
.nfs*

# IDE files
.idea/
.vscode/
*.sublime-project
*.sublime-workspace
*.code-workspace

# Environment files
.env
.env.local
.env.*.local
.envrc
.direnv

# AWS
.aws-credentials
.aws/credentials
.aws/config

# Terraform
.terraform/
terraform.tfstate
terraform.tfstate.backup
*.tfvars
.terraform.lock.hcl

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
*.egg-info/
.installed.cfg
*.egg
venv/
.venv/
ENV/

# Node.js
node_modules/
npm-debug.log
yarn-debug.log
yarn-error.log
EOL

    git config --global core.excludesfile "$HOME/.gitignore_global"
    log "Global gitignore created and configured" "success"
else
    log "Global gitignore already exists"
fi

# Configure AWS CLI
log "Configuring AWS CLI..."
if command -v aws &> /dev/null; then
    if [ ! -f "$HOME/.aws/credentials" ]; then
        mkdir -p "$HOME/.aws"
        chmod 700 "$HOME/.aws"
        
        read -p "Do you want to configure AWS CLI now? (y/n): " configure_aws
        if [[ "$configure_aws" =~ ^[Yy]$ ]]; then
            log "Setting up AWS credentials..."
            read -p "AWS Access Key ID: " aws_access_key
            read -p "AWS Secret Access Key: " aws_secret_key
            read -p "Default region name (e.g., us-east-1): " aws_region
            read -p "Default output format (json/text/table) [json]: " aws_output
            
            if [ -z "$aws_output" ]; then
                aws_output="json"
            fi
            
            # Create credentials file
            cat > "$HOME/.aws/credentials" << EOL
[default]
aws_access_key_id = $aws_access_key
aws_secret_access_key = $aws_secret_key
EOL
            
            # Create config file
            cat > "$HOME/.aws/config" << EOL
[default]
region = $aws_region
output = $aws_output
EOL
            
            chmod 600 "$HOME/.aws/credentials"
            chmod 600 "$HOME/.aws/config"
            
            log "AWS CLI configured successfully" "success"
        else
            log "AWS CLI configuration skipped" "warning"
        fi
    else
        log "AWS credentials already configured"
    fi
else
    log "AWS CLI not found" "warning"
fi

# Create repository directory
REPO_DIR="$HOME/Repositories"
if [ ! -d "$REPO_DIR" ]; then
    mkdir -p "$REPO_DIR"
    log "Created repository directory: $REPO_DIR" "success"
fi

# Clone infrastructure automation repository if requested
read -p "Do you want to clone the infrastructure automation repository? (y/n): " clone_repo
if [[ "$clone_repo" =~ ^[Yy]$ ]]; then
    read -p "Enter the Git repository URL: " repo_url
    
    pushd "$REPO_DIR" > /dev/null
    git clone "$repo_url" infrastructure-automation || log "Failed to clone repository" "error"
    popd > /dev/null
    
    log "Repository cloned to $REPO_DIR/infrastructure-automation" "success"
fi

# Setup complete
log "Linux setup completed successfully!" "success"
log "Please restart your terminal or computer to ensure all changes take effect."

# Display final message
cat << EOL

${GREEN}========================================================
Linux setup for infrastructure automation is complete!
========================================================${NC}

${YELLOW}Next steps:${NC}
1. Restart your terminal to apply all changes
2. Add your SSH key to your Git providers (GitHub, GitLab, etc.)
3. Verify AWS CLI configuration with 'aws sts get-caller-identity'
4. Check the log file at $LOG_FILE for any warnings or errors

${GREEN}Happy infrastructure building!${NC}
EOL 