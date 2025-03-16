#!/bin/bash
# macOS Setup Script for Infrastructure Automation Engineers
# This script configures a macOS system for infrastructure development and management

set -e

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="$HOME/macos_setup_log.txt"
INSTALL_DIR="$HOME/InfraTools"

# Ensure install directory exists
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

log "Starting macOS setup for infrastructure automation"
log "Install directory: $INSTALL_DIR"
log "Log file: $LOG_FILE"

# Check for Homebrew and install if not present
if ! command -v brew &> /dev/null; then
    log "Installing Homebrew package manager..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to path based on chip architecture
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    log "Homebrew installed successfully" "success"
else
    log "Homebrew is already installed"
fi

# Install essential CLI tools
log "Installing essential command line tools..."
brew update

# Essential tools array
cli_tools=(
    "git"
    "terraform"
    "awscli"
    "azure-cli"
    "google-cloud-sdk"
    "python"
    "node"
    "jq"
    "wget"
    "curl"
    "htop"
    "tree"
    "tmux"
    "vim"
    "bash"
    "grep"
    "openssh"
    "ansible"
    "kubernetes-cli"
    "helm"
)

for tool in "${cli_tools[@]}"; do
    log "Installing $tool..."
    if brew list "$tool" &>/dev/null; then
        log "$tool is already installed, upgrading if needed..."
        brew upgrade "$tool" &>/dev/null || true
    else
        brew install "$tool" || log "Failed to install $tool" "error"
    fi
done

log "CLI tools installation complete" "success"

# Install GUI applications
log "Installing GUI applications..."

# GUI apps array
gui_apps=(
    "visual-studio-code"
    "iterm2"
    "docker"
    "postman"
    "google-chrome"
    "slack"
    "rectangle"
)

for app in "${gui_apps[@]}"; do
    log "Installing $app..."
    if brew list --cask "$app" &>/dev/null; then
        log "$app is already installed, upgrading if needed..."
        brew upgrade --cask "$app" &>/dev/null || true
    else
        brew install --cask "$app" || log "Failed to install $app" "error"
    fi
done

log "GUI applications installation complete" "success"

# Configure Git
log "Configuring Git..."
if ! git config --global user.name &>/dev/null; then
    read -p "Enter your name for Git: " git_name
    git config --global user.name "$git_name"
    log "Git name set to: $git_name"
else
    log "Git name already configured as: $(git config --global user.name)"
fi

if ! git config --global user.email &>/dev/null; then
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
# macOS system files
.DS_Store
.AppleDouble
.LSOverride
Icon
._*
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent

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
    if [ -f "$HOME/.zshrc" ]; then
        PROFILE="$HOME/.zshrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        PROFILE="$HOME/.bash_profile"
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

# Configure AWS CLI
log "Configuring AWS CLI..."
if command -v aws &>/dev/null; then
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

# Configure VSCode extensions
if command -v code &>/dev/null; then
    log "Installing VSCode extensions..."
    
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
        log "Installing VSCode extension: $extension..."
        code --install-extension "$extension" || log "Failed to install extension: $extension" "warning"
    done
    
    log "VSCode extensions installed" "success"
else
    log "VSCode not found, skipping extension installation" "warning"
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

# macOS specific configurations
log "Configuring macOS settings..."

# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles YES

# Show path bar in Finder
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar in Finder
defaults write com.apple.finder ShowStatusBar -bool true

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Enable snap-to-grid for desktop icons
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Save screenshots to the desktop
defaults write com.apple.screencapture location -string "$HOME/Desktop"

# Save screenshots in PNG format
defaults write com.apple.screencapture type -string "png"

# Set a fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Restart affected applications
for app in "Finder" "Dock"; do
    killall "${app}" &> /dev/null
done

log "macOS settings configured" "success"

# Setup complete
log "macOS setup completed successfully!" "success"
log "Please restart your terminal or computer to ensure all changes take effect."

# Display final message
cat << EOL

${GREEN}========================================================
macOS setup for infrastructure automation is complete!
========================================================${NC}

${YELLOW}Next steps:${NC}
1. Restart your terminal to apply all changes
2. Add your SSH key to your Git providers (GitHub, GitLab, etc.)
3. Verify AWS CLI configuration with 'aws sts get-caller-identity'
4. Check the log file at $LOG_FILE for any warnings or errors

${GREEN}Happy infrastructure building!${NC}
EOL 