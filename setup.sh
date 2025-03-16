#!/bin/bash
# Infrastructure Automation Framework - Setup Script (Linux/macOS)
# This script is a wrapper around the Python setup script for Linux and macOS users

# Set error handling
set -e

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Default values
MODE="dev"
CLOUD="all"
FORCE=false
SKIP_DEPS=false
ENV_FILE=".env"
SETUP_SSH=false
INSTALL_PWSH=false

# Set up logging
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/setup_${TIMESTAMP}.log"

# Function to log messages
log() {
  local level="$1"
  local message="$2"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  
  # Write to log file
  echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
  
  # Write to console with color
  case "$level" in
    "INFO")
      echo -e "\033[0;36m$message\033[0m"
      ;;
    "WARNING")
      echo -e "\033[0;33m$message\033[0m"
      ;;
    "ERROR")
      echo -e "\033[0;31m$message\033[0m"
      ;;
    *)
      echo "$message"
      ;;
  esac
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="$2"
      if [[ "$MODE" != "dev" && "$MODE" != "prod" ]]; then
        log "ERROR" "Error: Mode must be 'dev' or 'prod'"
        exit 1
      fi
      shift 2
      ;;
    --cloud)
      CLOUD="$2"
      if [[ "$CLOUD" != "aws" && "$CLOUD" != "azure" && "$CLOUD" != "gcp" && "$CLOUD" != "all" && "$CLOUD" != "none" ]]; then
        log "ERROR" "Error: Cloud must be 'aws', 'azure', 'gcp', 'all', or 'none'"
        exit 1
      fi
      shift 2
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --skip-deps)
      SKIP_DEPS=true
      shift
      ;;
    --env-file)
      ENV_FILE="$2"
      shift 2
      ;;
    --setup-ssh)
      SETUP_SSH=true
      shift
      ;;
    --install-pwsh)
      INSTALL_PWSH=true
      shift
      ;;
    --help)
      echo "Infrastructure Automation Framework - Setup Script"
      echo ""
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --mode <dev|prod>          Setup mode (default: dev)"
      echo "  --cloud <aws|azure|gcp|all|none>  Cloud providers to configure (default: all)"
      echo "  --force                    Force reinstallation of components"
      echo "  --skip-deps                Skip dependency installation"
      echo "  --env-file <file>          Environment file path (default: .env)"
      echo "  --setup-ssh                Configure SSH keys and settings"
      echo "  --install-pwsh             Install PowerShell Core (pwsh)"
      echo "  --help                     Show this help message"
      exit 0
      ;;
    *)
      log "ERROR" "Error: Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Function to check if Python is installed
check_python() {
  if command -v python3 &>/dev/null; then
    python_version=$(python3 --version 2>&1)
    log "INFO" "Found $python_version"
    return 0
  else
    log "WARNING" "Python 3 is required but not found."
    return 1
  fi
}

# Function to install Python
install_python() {
  log "INFO" "Installing Python 3..."
  
  # Detect OS
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    if ! command -v brew &>/dev/null; then
      log "INFO" "Homebrew not found. Installing..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install python3
  elif [[ -f /etc/debian_version ]]; then
    # Debian/Ubuntu
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip
  elif [[ -f /etc/redhat-release ]]; then
    # RHEL/CentOS
    sudo yum install -y python3 python3-pip
  else
    log "ERROR" "Unsupported OS. Please install Python 3.8 or higher manually."
    return 1
  fi
  
  # Verify Python installation
  check_python
  return $?
}

# Function to check if PowerShell Core is installed
check_pwsh() {
  if command -v pwsh &>/dev/null; then
    pwsh_version=$(pwsh --version | head -n 1)
    log "INFO" "Found PowerShell Core: $pwsh_version"
    return 0
  else
    log "WARNING" "PowerShell Core (pwsh) not found."
    return 1
  fi
}

# Function to install PowerShell Core
install_pwsh() {
  log "INFO" "Installing PowerShell Core..."
  
  # Detect OS
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    if ! command -v brew &>/dev/null; then
      log "INFO" "Homebrew not found. Installing..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install --cask powershell
  elif [[ -f /etc/debian_version ]]; then
    # Debian/Ubuntu
    # Update package list and install prerequisites
    sudo apt-get update
    sudo apt-get install -y wget apt-transport-https software-properties-common
    
    # Download Microsoft repository GPG keys
    wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
    
    # Register Microsoft repository GPG keys
    sudo dpkg -i packages-microsoft-prod.deb
    
    # Update package list
    sudo apt-get update
    
    # Install PowerShell
    sudo apt-get install -y powershell
    
    # Clean up
    rm packages-microsoft-prod.deb
  elif [[ -f /etc/redhat-release ]]; then
    # RHEL/CentOS
    # Register the Microsoft RedHat repository
    curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
    
    # Install PowerShell
    sudo yum install -y powershell
  else
    log "ERROR" "Unsupported OS for PowerShell Core installation. Please install manually."
    return 1
  fi
  
  # Verify PowerShell installation
  check_pwsh
  return $?
}

# Function to set up SSH
setup_ssh() {
  log "INFO" "Setting up SSH..."
  
  SSH_DIR="$HOME/.ssh"
  
  # Create .ssh directory if it doesn't exist
  if [ ! -d "$SSH_DIR" ]; then
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    log "INFO" "Created .ssh directory"
  fi
  
  # Check if ssh-keygen is available
  if ! command -v ssh-keygen &>/dev/null; then
    log "INFO" "Installing OpenSSH client..."
    
    if [[ "$(uname)" == "Darwin" ]]; then
      # macOS - OpenSSH should be already installed
      log "WARNING" "OpenSSH client not found. Please install it manually."
      return 1
    elif [[ -f /etc/debian_version ]]; then
      # Debian/Ubuntu
      sudo apt-get update
      sudo apt-get install -y openssh-client
    elif [[ -f /etc/redhat-release ]]; then
      # RHEL/CentOS
      sudo yum install -y openssh-clients
    else
      log "ERROR" "Unsupported OS. Please install OpenSSH client manually."
      return 1
    fi
  fi
  
  # Generate SSH key if it doesn't exist
  SSH_KEY_FILE="$SSH_DIR/id_rsa"
  if [ ! -f "$SSH_KEY_FILE" ]; then
    log "INFO" "Generating SSH key pair..."
    KEY_COMMENT="infrastructure-automation-$(hostname)"
    
    ssh-keygen -t rsa -b 4096 -C "$KEY_COMMENT" -f "$SSH_KEY_FILE" -N ""
    log "INFO" "SSH key pair generated successfully"
  else
    log "INFO" "SSH key pair already exists"
  fi
  
  # Create basic SSH config if it doesn't exist
  SSH_CONFIG_FILE="$SSH_DIR/config"
  if [ ! -f "$SSH_CONFIG_FILE" ]; then
    cat > "$SSH_CONFIG_FILE" << EOL
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
EOL
    chmod 600 "$SSH_CONFIG_FILE"
    log "INFO" "Created SSH config file"
  fi
  
  # Set proper permissions
  chmod 600 "$SSH_KEY_FILE"
  chmod 644 "$SSH_KEY_FILE.pub"
  
  log "INFO" "SSH setup completed successfully"
  
  # Display the public key
  if [ -f "$SSH_KEY_FILE.pub" ]; then
    PUBLIC_KEY=$(cat "$SSH_KEY_FILE.pub")
    echo -e "\n\033[0;32mYour SSH public key is:\033[0m"
    echo -e "\033[0;33m$PUBLIC_KEY\033[0m"
    echo -e "\033[0;32mYou can add this key to your Git repositories and servers for authentication.\033[0m\n"
  fi
  
  return 0
}

# Startup banner
echo -e "\n\033[0;36m-----------------------------------------\033[0m"
echo -e "\033[0;36mInfrastructure Automation Framework Setup\033[0m"
echo -e "\033[0;36m-----------------------------------------\033[0m\n"

log "INFO" "Starting setup script in $MODE mode"

# Check if Python is installed, and install if needed
if ! check_python; then
  read -p "Python 3 is required. Do you want to install it now? (y/n) " install_python_response
  if [[ "$install_python_response" =~ ^[Yy]$ ]]; then
    if ! install_python; then
      log "ERROR" "Failed to install Python. Please install Python 3.8 or higher manually."
      exit 1
    fi
  else
    log "ERROR" "Python 3 is required to run the setup script. Please install Python 3.8 or higher and try again."
    exit 1
  fi
fi

# Install PowerShell Core if requested
if [[ "$INSTALL_PWSH" == true ]] && ! check_pwsh; then
  log "INFO" "PowerShell Core (pwsh) will be installed as requested"
  if ! install_pwsh; then
    log "WARNING" "Failed to install PowerShell Core. You can install it manually later."
  fi
fi

# Setup SSH if requested
if [[ "$SETUP_SSH" == true ]]; then
  if ! setup_ssh; then
    log "WARNING" "SSH setup encountered issues. You may need to set it up manually."
  fi
fi

# Build arguments for the Python script
PYTHON_ARGS=("$SCRIPT_DIR/setup.py")

if [[ -n "$MODE" ]]; then
  PYTHON_ARGS+=("--mode" "$MODE")
fi

if [[ -n "$CLOUD" ]]; then
  PYTHON_ARGS+=("--cloud" "$CLOUD")
fi

if [[ "$FORCE" == true ]]; then
  PYTHON_ARGS+=("--force")
fi

if [[ "$SKIP_DEPS" == true ]]; then
  PYTHON_ARGS+=("--skip-deps")
fi

if [[ -n "$ENV_FILE" ]]; then
  PYTHON_ARGS+=("--env-file" "$ENV_FILE")
fi

# Run the Python setup script
log "INFO" "Running Infrastructure Automation Framework setup script..."
if python3 "${PYTHON_ARGS[@]}"; then
  echo -e "\n\033[0;32mSetup completed successfully!\033[0m"
  echo -e "\033[0;32mYou can now start using the Infrastructure Automation Framework.\033[0m"
  echo -e "\033[0;32mRefer to the README.md for next steps.\033[0m"
  
  log "INFO" "Setup completed successfully!"
else
  echo -e "\n\033[0;31mSetup failed.\033[0m"
  echo -e "\033[0;33mCheck the logs directory for more information.\033[0m"
  
  log "ERROR" "Setup failed with exit code $?"
  exit 1
fi 