#!/bin/bash
# Infrastructure Automation Framework - Bootstrap Installer
# This script clones the repository and runs the setup process
# It can be run directly via: curl -fsSL https://example.com/bootstrap.sh | bash

set -e

# Configuration
REPO_URL="https://github.com/ChinITRepo/infrastructure-automation.git"
DEFAULT_BRANCH="main"
INSTALL_DIR="$HOME/infrastructure-automation"
VERSION="latest"  # Can be a specific tag like "v1.0.0" or "latest" for the default branch
SETUP_MODE="dev"  # Can be "dev", "prod", or "controller"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to show banner
show_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║            Infrastructure Automation Framework              ║"
    echo "║                    Bootstrap Installer                     ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function to check if a command exists
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# Function to log messages
log() {
    local level="$1"
    local message="$2"
    
    case "$level" in
        "info")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        "warn")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "error")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo=*)
            REPO_URL="${1#*=}"
            shift
            ;;
        --version=*)
            VERSION="${1#*=}"
            shift
            ;;
        --branch=*)
            DEFAULT_BRANCH="${1#*=}"
            shift
            ;;
        --dir=*)
            INSTALL_DIR="${1#*=}"
            shift
            ;;
        --token=*)
            GIT_TOKEN="${1#*=}"
            shift
            ;;
        --mode=*)
            SETUP_MODE="${1#*=}"
            shift
            ;;
        --controller)
            SETUP_MODE="controller"
            shift
            ;;
        --help)
            show_banner
            echo "Usage: bootstrap.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --repo=URL        Git repository URL (default: $REPO_URL)"
            echo "  --version=VERSION Specific version to install (tag or 'latest')"
            echo "  --branch=BRANCH   Branch to use if version is 'latest' (default: $DEFAULT_BRANCH)"
            echo "  --dir=DIR         Installation directory (default: $INSTALL_DIR)"
            echo "  --token=TOKEN     Git access token for private repositories"
            echo "  --mode=MODE       Setup mode: dev, prod, or controller (default: $SETUP_MODE)"
            echo "  --controller      Shorthand for --mode=controller"
            echo "  --help            Show this help message"
            echo ""
            echo "Example:"
            echo "  curl -fsSL https://example.com/bootstrap.sh | bash -s -- --version=v1.0.0 --controller"
            exit 0
            ;;
        *)
            log "warn" "Unknown option: $1"
            shift
            ;;
    esac
done

# Show banner
show_banner

# Check for Git
if ! check_command git; then
    log "error" "Git is required but not installed. Please install Git and try again."
    exit 1
fi

log "info" "Using Git repository: $REPO_URL"
log "info" "Installing version: $VERSION"
log "info" "Installation directory: $INSTALL_DIR"

# Create installation directory if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
    log "info" "Creating installation directory..."
    mkdir -p "$INSTALL_DIR"
else
    log "warn" "Installation directory already exists. Will update if it's a Git repository."
fi

# Format repository URL with token if provided
if [ -n "$GIT_TOKEN" ]; then
    # Extract domain from URL
    if [[ "$REPO_URL" =~ ^https://([^/]+)/ ]]; then
        DOMAIN="${BASH_REMATCH[1]}"
        # Replace https://domain.com with https://token@domain.com
        AUTH_REPO_URL="${REPO_URL/https:\/\/$DOMAIN/https:\/\/$GIT_TOKEN@$DOMAIN}"
        log "info" "Using authentication for private repository"
    else
        log "warn" "Could not parse repository URL, using token as is"
        AUTH_REPO_URL="$REPO_URL"
    fi
else
    AUTH_REPO_URL="$REPO_URL"
fi

# Clone or update the repository
if [ -d "$INSTALL_DIR/.git" ]; then
    log "info" "Updating existing repository..."
    cd "$INSTALL_DIR"
    
    # Save the current branch or tag
    CURRENT_REF=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || git rev-parse HEAD)
    
    # Update repository
    git fetch --all
    
    # If a specific version was requested, check it out
    if [ "$VERSION" != "latest" ]; then
        log "info" "Checking out version $VERSION..."
        if git tag -l | grep -q "^$VERSION$"; then
            git checkout "$VERSION"
        else
            log "error" "Version $VERSION not found. Available versions:"
            git tag -l
            exit 1
        fi
    else
        # Otherwise use the default branch
        log "info" "Checking out default branch $DEFAULT_BRANCH..."
        git checkout "$DEFAULT_BRANCH"
        git pull origin "$DEFAULT_BRANCH"
    fi
else
    log "info" "Cloning repository..."
    
    # For a specific version, clone the repository and checkout the tag
    if [ "$VERSION" != "latest" ]; then
        git clone --depth 1 --branch "$VERSION" "$AUTH_REPO_URL" "$INSTALL_DIR"
    else
        git clone --branch "$DEFAULT_BRANCH" "$AUTH_REPO_URL" "$INSTALL_DIR"
    fi
    
    cd "$INSTALL_DIR"
fi

# Check for a release directory with pre-built executables
if [ -d "$INSTALL_DIR/release" ]; then
    log "info" "Found release directory, checking for pre-built executables..."
    
    # Determine OS and architecture
    OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    # Map architecture to common names
    case "$ARCH" in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7*)
            ARCH="arm"
            ;;
    esac
    
    # Check for OS-specific pre-built executables
    if [ -f "$INSTALL_DIR/release/$OS_TYPE-$ARCH/setup" ]; then
        log "info" "Found pre-built executable for $OS_TYPE-$ARCH"
        cp "$INSTALL_DIR/release/$OS_TYPE-$ARCH/setup" "$INSTALL_DIR/setup_bin"
        chmod +x "$INSTALL_DIR/setup_bin"
    fi
fi

# Run the appropriate setup script
log "info" "Starting setup process in $SETUP_MODE mode..."

case "$(uname -s)" in
    Linux*|Darwin*)
        # Make sure the script is executable
        chmod +x "$INSTALL_DIR/setup.sh"
        
        if [ -f "$INSTALL_DIR/setup_bin" ]; then
            log "info" "Running pre-built setup executable..."
            "$INSTALL_DIR/setup_bin" --mode "$SETUP_MODE" "$@"
        elif [ -f "$INSTALL_DIR/setup" ]; then
            log "info" "Running universal setup script..."
            chmod +x "$INSTALL_DIR/setup"
            "$INSTALL_DIR/setup" --mode "$SETUP_MODE" "$@"
        else
            log "info" "Running setup script for Unix..."
            "$INSTALL_DIR/setup.sh" --mode "$SETUP_MODE" "$@"
        fi
        ;;
    MINGW*|MSYS*|CYGWIN*|Windows*)
        log "info" "Running setup script for Windows..."
        if [ -f "$INSTALL_DIR/setup.exe" ]; then
            "$INSTALL_DIR/setup.exe" -Mode "$SETUP_MODE" "$@"
        else
            powershell -ExecutionPolicy Bypass -File "$INSTALL_DIR/setup.ps1" -Mode "$SETUP_MODE" "$@"
        fi
        ;;
    *)
        log "error" "Unsupported operating system: $(uname -s)"
        exit 1
        ;;
esac

log "info" "Bootstrap process completed successfully!"
log "info" "The framework is installed at: $INSTALL_DIR"

if [ "$SETUP_MODE" = "controller" ]; then
    log "info" "Controller mode is set up. Use 'python controller.py init' to initialize the controller."
    log "info" "Then use 'python controller.py help' for available commands."
else
    log "info" "You can now use the infrastructure automation framework"
fi 