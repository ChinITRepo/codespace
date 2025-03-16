#!/bin/bash
# Compile setup.c for Unix-like systems (Linux, macOS)

echo "Compiling setup.c for Unix..."

# Check if GCC is available
if ! command -v gcc &> /dev/null; then
    echo "GCC not found. You need to install GCC."
    echo "You can install it via:"
    
    # Determine the OS
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "- Homebrew: brew install gcc"
    elif [[ -f /etc/debian_version ]]; then
        echo "- Debian/Ubuntu: sudo apt-get install build-essential"
    elif [[ -f /etc/redhat-release ]]; then
        echo "- RHEL/CentOS: sudo yum groupinstall 'Development Tools'"
    else
        echo "- Please install GCC using your system's package manager"
    fi
    
    exit 1
fi

# Compile the program
gcc -o setup_bin setup.c

if [ $? -ne 0 ]; then
    echo "Compilation failed."
    exit 1
else
    echo "Compilation successful. You can now run ./setup_bin"
    
    # Make it executable
    chmod +x setup_bin
fi 