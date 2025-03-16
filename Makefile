# Infrastructure Automation Framework - Universal Makefile
# This Makefile provides a universal interface for setup and operations
# across all platforms (Windows, Linux, macOS)

# Detect OS
ifeq ($(OS),Windows_NT)
    DETECTED_OS := Windows
    RM := del /Q
    MKDIR := mkdir
    CP := copy
    SETUP_EXEC := .\setup.exe
    PS_EXEC := powershell -ExecutionPolicy Bypass -File .\setup.ps1
    COMPILE := gcc -o setup.exe setup.c
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Darwin)
        DETECTED_OS := macOS
    else
        DETECTED_OS := Linux
    endif
    RM := rm -f
    MKDIR := mkdir -p
    CP := cp
    SETUP_EXEC := ./setup
    SHELL_EXEC := ./setup.sh
    COMPILE := gcc -o setup_bin setup.c
endif

# Default target
.PHONY: all
all: setup

# Setup target - detects platform and runs appropriate setup
.PHONY: setup
setup:
	@echo "Starting Infrastructure Automation Framework setup ($(DETECTED_OS))"
ifeq ($(DETECTED_OS),Windows)
	@echo "Running Windows setup..."
	$(PS_EXEC) $(ARGS)
else
	@echo "Running Unix setup..."
	$(SHELL_EXEC) $(ARGS)
endif

# Compile universal setup executable
.PHONY: compile
compile:
	@echo "Compiling universal setup executable for $(DETECTED_OS)..."
	$(COMPILE)
ifeq ($(DETECTED_OS),Windows)
	@echo "Compiled to setup.exe"
else
	@echo "Compiled to setup_bin"
endif

# Make setup script executable on Unix
.PHONY: chmod
chmod:
ifneq ($(DETECTED_OS),Windows)
	@echo "Making setup scripts executable..."
	chmod +x setup.sh
	chmod +x setup
endif

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning up build artifacts..."
ifeq ($(DETECTED_OS),Windows)
	if exist setup.exe $(RM) setup.exe
else
	$(RM) setup_bin
endif

# Install dependencies
.PHONY: deps
deps:
	@echo "Installing dependencies for $(DETECTED_OS)..."
ifeq ($(DETECTED_OS),Windows)
	$(PS_EXEC) -SkipDeps:$${false}
else
	$(SHELL_EXEC) --skip-deps=false
endif

# Configure SSH
.PHONY: ssh
ssh:
	@echo "Setting up SSH for $(DETECTED_OS)..."
ifeq ($(DETECTED_OS),Windows)
	$(PS_EXEC) -SetupSSH
else
	$(SHELL_EXEC) --setup-ssh
endif

# Install PowerShell Core
.PHONY: pwsh
pwsh:
	@echo "Installing PowerShell Core for $(DETECTED_OS)..."
ifeq ($(DETECTED_OS),Windows)
	$(PS_EXEC) -InstallPwsh
else
	$(SHELL_EXEC) --install-pwsh
endif

# Help target
.PHONY: help
help:
	@echo "Infrastructure Automation Framework - Makefile Targets"
	@echo ""
	@echo "Usage: make [target] [ARGS=\"arguments\"]"
	@echo ""
	@echo "Targets:"
	@echo "  setup       Run the appropriate setup for your platform (default)"
	@echo "  compile     Compile the universal setup executable"
	@echo "  chmod       Make setup scripts executable (Unix only)"
	@echo "  clean       Clean build artifacts"
	@echo "  deps        Install dependencies"
	@echo "  ssh         Configure SSH"
	@echo "  pwsh        Install PowerShell Core"
	@echo "  help        Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make setup ARGS=\"--mode prod --cloud aws\""
	@echo "  make setup ARGS=\"-Mode prod -Cloud aws\"    (Windows)"
	@echo ""
	@echo "Detected OS: $(DETECTED_OS)" 