#!/usr/bin/env python3
"""
Infrastructure Automation Framework - Setup Script

This script detects the operating system, installs required dependencies,
and configures the project environment for development or deployment.
"""

import os
import sys
import platform
import subprocess
import shutil
import json
import re
from pathlib import Path
import argparse
import logging
from datetime import datetime

# Configure logging
log_dir = Path("logs")
log_dir.mkdir(exist_ok=True)
log_file = log_dir / f"setup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("setup")

# Project paths
PROJECT_ROOT = Path(__file__).parent.absolute()
TERRAFORM_DIR = PROJECT_ROOT / "terraform"
ANSIBLE_DIR = PROJECT_ROOT / "ansible"
DISCOVERY_DIR = PROJECT_ROOT / "discovery"

# Dependency versions
TERRAFORM_VERSION = "1.5.7"
ANSIBLE_VERSION = "2.15.4"
PWSH_VERSION = "7.3.6"
PYTHON_MIN_VERSION = (3, 8)

# Required tools by platform
REQUIRED_TOOLS = {
    "common": ["python3", "pip3", "git"],
    "Windows": ["choco", "pwsh", "az"],
    "Linux": ["apt-get", "curl", "wget", "unzip", "jq"],
    "Darwin": ["brew", "curl", "wget", "unzip", "jq"]
}

# Required Python packages
REQUIRED_PYTHON_PACKAGES = [
    "boto3>=1.26.0",
    "azure-cli>=2.40.0",
    "google-cloud-storage>=2.0.0",
    "python-nmap>=0.7.1",
    "paramiko>=2.10.1",
    "scapy>=2.4.5",
    "rich>=12.0.0",
    "pyyaml>=6.0",
    "tabulate>=0.8.9"
]

def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Infrastructure Automation Framework Setup")
    parser.add_argument("--mode", choices=["dev", "prod", "controller"], default="dev",
                        help="Setup mode (dev, prod, or controller). Controller mode sets up a management workstation.")
    parser.add_argument("--cloud", choices=["aws", "azure", "gcp", "all", "none"], default="all",
                        help="Cloud providers to configure.")
    parser.add_argument("--force", action="store_true",
                        help="Force reinstallation of components.")
    parser.add_argument("--env-file", default=".env",
                        help="Path to environment file.")
    parser.add_argument("--skip-deps", action="store_true",
                        help="Skip dependency installation.")
    parser.add_argument("--setup-ssh", action="store_true",
                        help="Configure SSH keys and settings.")
    parser.add_argument("--install-pwsh", action="store_true",
                        help="Install PowerShell Core (pwsh).")
    parser.add_argument("--profile", default="default",
                        help="Profile name for configurations and credentials.")
    parser.add_argument("--environments", default="all",
                        help="Comma-separated list of environments to configure (dev,test,prod,etc.)")
    parser.add_argument("--vault-password-file", 
                        help="Path to the Ansible Vault password file.")
    
    return parser.parse_args()

def detect_os():
    """Detect the operating system."""
    system = platform.system()
    
    if system == "Windows":
        return "Windows"
    elif system == "Darwin":
        return "Darwin"  # macOS
    elif system == "Linux":
        # Detect Linux distribution
        try:
            with open("/etc/os-release") as f:
                os_release = f.read()
                if "ID=ubuntu" in os_release or "ID=debian" in os_release:
                    return "Ubuntu/Debian"
                elif "ID=centos" in os_release or "ID=rhel" in os_release:
                    return "RHEL/CentOS"
                else:
                    return "Linux"
        except FileNotFoundError:
            return "Linux"
    else:
        return "Unknown"

def check_python_version():
    """Check if Python version meets requirements."""
    current_version = sys.version_info[:2]
    if current_version < PYTHON_MIN_VERSION:
        logger.error(f"Python {PYTHON_MIN_VERSION[0]}.{PYTHON_MIN_VERSION[1]} or higher is required. "
                    f"Current version: {current_version[0]}.{current_version[1]}")
        return False
    return True

def run_command(command, shell=False, cwd=None):
    """Run a command and return the result."""
    try:
        if isinstance(command, str) and not shell:
            command = command.split()
        
        logger.debug(f"Running command: {command}")
        result = subprocess.run(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
            shell=shell,
            cwd=cwd
        )
        
        if result.returncode != 0:
            logger.warning(f"Command failed with exit code {result.returncode}")
            logger.warning(f"stderr: {result.stderr}")
            return False, result.stdout
        
        return True, result.stdout
    except Exception as e:
        logger.error(f"Error running command: {e}")
        return False, str(e)

def check_tool_installed(tool):
    """Check if a tool is installed and available on the PATH."""
    if tool in ["pip3", "pip"]:
        try:
            subprocess.run([sys.executable, "-m", "pip", "--version"], 
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            return True
        except:
            return False
    
    try:
        if platform.system() == "Windows":
            result = subprocess.run(["where", tool], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        else:
            result = subprocess.run(["which", tool], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return result.returncode == 0
    except:
        return False

def install_dependencies(os_type, args):
    """Install required dependencies based on OS."""
    if args.skip_deps:
        logger.info("Skipping dependency installation as requested")
        return True
    
    success = True
    logger.info(f"Installing dependencies for {os_type}...")
    
    # Check and install common tools
    for tool in REQUIRED_TOOLS["common"]:
        if not check_tool_installed(tool) or args.force:
            logger.info(f"Installing {tool}...")
            success = install_tool(tool, os_type) and success
    
    # Check and install OS-specific tools
    if os_type in REQUIRED_TOOLS:
        for tool in REQUIRED_TOOLS[os_type]:
            if not check_tool_installed(tool) or args.force:
                logger.info(f"Installing {tool}...")
                success = install_tool(tool, os_type) and success
    
    # Install Terraform if needed
    if not check_tool_installed("terraform") or args.force:
        logger.info(f"Installing Terraform {TERRAFORM_VERSION}...")
        success = install_terraform(os_type) and success
    
    # Install Ansible if needed
    if not check_tool_installed("ansible") or args.force:
        logger.info(f"Installing Ansible {ANSIBLE_VERSION}...")
        success = install_ansible(os_type) and success
    
    # Install Python packages
    logger.info("Installing required Python packages...")
    for package in REQUIRED_PYTHON_PACKAGES:
        logger.info(f"Installing {package}...")
        pkg_name = package.split(">=")[0]
        success = install_python_package(pkg_name, args.force) and success
    
    return success

def install_tool(tool, os_type):
    """Install a specific tool based on the operating system."""
    if os_type == "Windows":
        if tool == "choco":
            # Check if Chocolatey is installed
            if not check_tool_installed("choco"):
                logger.info("Installing Chocolatey...")
                cmd = 'powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString(\'https://chocolatey.org/install.ps1\'))"'
                return run_command(cmd, shell=True)[0]
            return True
        elif tool in ["git", "pwsh", "az"]:
            return run_command(f"choco install {tool} -y", shell=True)[0]
    
    elif os_type == "Ubuntu/Debian" or os_type == "Linux":
        if tool == "python3":
            return run_command("apt-get update && apt-get install -y python3 python3-pip", shell=True)[0]
        elif tool in ["curl", "wget", "unzip", "jq", "git"]:
            return run_command(f"apt-get update && apt-get install -y {tool}", shell=True)[0]
    
    elif os_type == "RHEL/CentOS":
        if tool == "python3":
            return run_command("yum install -y python3 python3-pip", shell=True)[0]
        elif tool in ["curl", "wget", "unzip", "jq", "git"]:
            return run_command(f"yum install -y {tool}", shell=True)[0]
    
    elif os_type == "Darwin":
        if tool == "brew":
            if not check_tool_installed("brew"):
                logger.info("Installing Homebrew...")
                cmd = '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
                return run_command(cmd, shell=True)[0]
            return True
        elif tool in ["curl", "wget", "unzip", "jq", "git"]:
            return run_command(f"brew install {tool}", shell=True)[0]
        elif tool == "python3":
            return run_command("brew install python3", shell=True)[0]
    
    logger.warning(f"Don't know how to install {tool} on {os_type}")
    return False

def install_terraform(os_type):
    """Install Terraform."""
    if os_type == "Windows":
        return run_command(f"choco install terraform --version={TERRAFORM_VERSION} -y", shell=True)[0]
    
    elif os_type == "Ubuntu/Debian" or os_type == "Linux":
        commands = [
            "apt-get update",
            "apt-get install -y gnupg software-properties-common curl",
            "curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -",
            "apt-add-repository \"deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
            "apt-get update",
            f"apt-get install -y terraform={TERRAFORM_VERSION}"
        ]
        for cmd in commands:
            success, _ = run_command(cmd, shell=True)
            if not success:
                return False
        return True
    
    elif os_type == "RHEL/CentOS":
        commands = [
            "yum install -y yum-utils",
            "yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo",
            f"yum install -y terraform-{TERRAFORM_VERSION}"
        ]
        for cmd in commands:
            success, _ = run_command(cmd, shell=True)
            if not success:
                return False
        return True
    
    elif os_type == "Darwin":
        return run_command(f"brew install terraform@{TERRAFORM_VERSION}", shell=True)[0]
    
    return False

def install_ansible(os_type):
    """Install Ansible."""
    if os_type == "Windows":
        # On Windows, Ansible is installed via pip
        return run_command(f"pip install ansible=={ANSIBLE_VERSION}", shell=True)[0]
    
    elif os_type == "Ubuntu/Debian" or os_type == "Linux":
        commands = [
            "apt-get update",
            "apt-get install -y software-properties-common",
            "apt-add-repository --yes --update ppa:ansible/ansible",
            f"apt-get install -y ansible"
        ]
        for cmd in commands:
            success, _ = run_command(cmd, shell=True)
            if not success:
                return False
        return True
    
    elif os_type == "RHEL/CentOS":
        commands = [
            "yum install -y epel-release",
            f"yum install -y ansible"
        ]
        for cmd in commands:
            success, _ = run_command(cmd, shell=True)
            if not success:
                return False
        return True
    
    elif os_type == "Darwin":
        return run_command("brew install ansible", shell=True)[0]
    
    return False

def install_pwsh(os_type):
    """Install PowerShell Core."""
    logger.info(f"Installing PowerShell Core {PWSH_VERSION}...")
    
    if os_type == "Windows":
        # On Windows, PowerShell Core is installed via package manager (Chocolatey or winget)
        return run_command(f"choco install powershell-core -y", shell=True)[0]
    
    elif os_type == "Ubuntu/Debian" or os_type == "Linux":
        try:
            # Download and install the Microsoft repository GPG key
            apt_transport_https_cmd = "apt-get update && apt-get install -y apt-transport-https"
            run_command(apt_transport_https_cmd, shell=True)
            
            # Get the Ubuntu or Debian version
            get_version_cmd = "lsb_release -rs"
            success, version = run_command(get_version_cmd, shell=True)
            if not success:
                version = "20.04"  # Default to Ubuntu 20.04 if we can't determine version
            
            # Download the Microsoft repository GPG keys
            wget_cmd = f"wget -q https://packages.microsoft.com/config/ubuntu/{version}/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb"
            run_command(wget_cmd, shell=True)
            
            # Register the Microsoft repository GPG keys
            dpkg_cmd = "dpkg -i /tmp/packages-microsoft-prod.deb"
            run_command(dpkg_cmd, shell=True)
            
            # Update the list of products
            apt_update_cmd = "apt-get update"
            run_command(apt_update_cmd, shell=True)
            
            # Install PowerShell
            install_cmd = "apt-get install -y powershell"
            return run_command(install_cmd, shell=True)[0]
        except Exception as e:
            logger.error(f"Failed to install PowerShell Core: {e}")
            return False
    
    elif os_type == "RHEL/CentOS":
        try:
            # Register the Microsoft RedHat repository
            curl_cmd = "curl https://packages.microsoft.com/config/rhel/7/prod.repo | tee /etc/yum.repos.d/microsoft.repo"
            run_command(curl_cmd, shell=True)
            
            # Install PowerShell
            yum_cmd = "yum install -y powershell"
            return run_command(yum_cmd, shell=True)[0]
        except Exception as e:
            logger.error(f"Failed to install PowerShell Core: {e}")
            return False
    
    elif os_type == "Darwin":
        return run_command("brew install --cask powershell", shell=True)[0]
    
    return False

def install_python_package(package, force=False):
    """Install a Python package using pip."""
    cmd = [sys.executable, "-m", "pip", "install", "--upgrade"]
    if force:
        cmd.append("--force-reinstall")
    cmd.append(package)
    
    success, _ = run_command(cmd)
    return success

def setup_cloud_provider(provider, args):
    """Set up cloud provider specific configuration."""
    logger.info(f"Setting up {provider} configuration...")
    
    if provider == "aws":
        # Check for AWS credentials
        aws_access_key = input("Enter AWS Access Key ID (leave blank to skip): ").strip()
        if aws_access_key:
            aws_secret_key = input("Enter AWS Secret Access Key: ").strip()
            aws_region = input("Enter AWS Region (default: us-west-2): ").strip() or "us-west-2"
            
            # Create AWS credentials
            aws_dir = Path.home() / ".aws"
            aws_dir.mkdir(exist_ok=True)
            
            with open(aws_dir / "credentials", "w") as f:
                f.write("[default]\n")
                f.write(f"aws_access_key_id = {aws_access_key}\n")
                f.write(f"aws_secret_access_key = {aws_secret_key}\n")
            
            with open(aws_dir / "config", "w") as f:
                f.write("[default]\n")
                f.write(f"region = {aws_region}\n")
                f.write("output = json\n")
            
            logger.info("AWS credentials configured")
        else:
            logger.info("Skipping AWS configuration")
    
    elif provider == "azure":
        # Check for Azure CLI
        if check_tool_installed("az"):
            logger.info("Running Azure login...")
            run_command("az login", shell=True)
            logger.info("Azure credentials configured")
        else:
            logger.warning("Azure CLI not found. Please install it and run 'az login' manually")
    
    elif provider == "gcp":
        # Check for GCP credentials
        gcp_key_file = input("Enter path to GCP credentials JSON file (leave blank to skip): ").strip()
        if gcp_key_file:
            gcp_key_path = Path(gcp_key_file).expanduser().absolute()
            if gcp_key_path.exists():
                # Set environment variable
                os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(gcp_key_path)
                
                # Also save to environment file
                with open(args.env_file, "a") as f:
                    f.write(f"GOOGLE_APPLICATION_CREDENTIALS={gcp_key_path}\n")
                
                logger.info("GCP credentials configured")
            else:
                logger.error(f"GCP credentials file not found: {gcp_key_path}")
        else:
            logger.info("Skipping GCP configuration")

def initialize_terraform(args):
    """Initialize Terraform directories."""
    logger.info("Initializing Terraform...")

    # Create environments if they don't exist
    env_dir = TERRAFORM_DIR / "environments"
    for env in ["dev", "test", "prod"]:
        env_path = env_dir / env
        env_path.mkdir(exist_ok=True, parents=True)
        
        # Create basic terraform files if they don't exist
        main_tf = env_path / "main.tf"
        if not main_tf.exists():
            with open(main_tf, "w") as f:
                f.write(f"""/**
 * Infrastructure Automation Framework
 * Environment: {env}
 */

terraform {{
  required_version = ">= {TERRAFORM_VERSION}"
  
  required_providers {{
    aws = {{
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }}
    azurerm = {{
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }}
    google = {{
      source  = "hashicorp/google"
      version = "~> 4.0"
    }}
  }}
  
  backend "local" {{
    path = "terraform.tfstate"
  }}
}}

# Use appropriate provider blocks based on your cloud target
provider "aws" {{
  region = var.aws_region
  # Uncomment to use specific profile
  # profile = var.aws_profile
}}

# provider "azurerm" {{
#   features {{}}
#   subscription_id = var.azure_subscription_id
# }}

# provider "google" {{
#   project = var.gcp_project_id
#   region  = var.gcp_region
# }}

# Import core infrastructure module
module "tier1_core" {{
  source = "../../modules/tier1-core"
  
  environment = var.environment
  cloud_provider = var.cloud_provider
  # Add other variables as needed
}}

# Import essential services module
module "tier2_services" {{
  source = "../../modules/tier2-services"
  
  environment = var.environment
  cloud_provider = var.cloud_provider
  vpc_id = module.tier1_core.vpc_id
  private_subnet_ids = module.tier1_core.private_subnet_ids
  public_subnet_ids = module.tier1_core.public_subnet_ids
  
  # Log management configuration
  deploy_syslog_server = var.deploy_syslog_server
  syslog_instance_type = var.syslog_instance_type
  log_retention_days = var.log_retention_days
  
  # Add other variables as needed
}}
""")
        
        variables_tf = env_path / "variables.tf"
        if not variables_tf.exists():
            with open(variables_tf, "w") as f:
                f.write(f"""/**
 * Infrastructure Automation Framework
 * Environment: {env} - Variables
 */

variable "environment" {{
  description = "Environment name"
  type        = string
  default     = "{env}"
}}

variable "cloud_provider" {{
  description = "Cloud provider to use (aws, azure, gcp, or none for on-prem)"
  type        = string
  default     = "aws"
  
  validation {{
    condition     = contains(["aws", "azure", "gcp", "none"], var.cloud_provider)
    error_message = "Valid values for cloud_provider are: aws, azure, gcp, or none."
  }}
}}

# AWS specific variables
variable "aws_region" {{
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}}

variable "aws_profile" {{
  description = "AWS CLI profile name"
  type        = string
  default     = "default"
}}

# Azure specific variables
variable "azure_subscription_id" {{
  description = "Azure subscription ID"
  type        = string
  default     = ""
}}

variable "azure_location" {{
  description = "Azure location/region"
  type        = string
  default     = "eastus"
}}

# GCP specific variables
variable "gcp_project_id" {{
  description = "GCP project ID"
  type        = string
  default     = ""
}}

variable "gcp_region" {{
  description = "GCP region"
  type        = string
  default     = "us-central1"
}}

# Tier 2 Services configuration
variable "deploy_syslog_server" {{
  description = "Whether to deploy a dedicated syslog server"
  type        = bool
  default     = true
}}

variable "syslog_instance_type" {{
  description = "Instance type for the syslog server"
  type        = string
  default     = "t3.medium"
}}

variable "log_retention_days" {{
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}}
""")
        
        terraform_tfvars = env_path / "terraform.tfvars.example"
        if not terraform_tfvars.exists():
            with open(terraform_tfvars, "w") as f:
                f.write(f"""# Infrastructure Automation Framework
# Environment: {env} - Terraform Variables
# Rename this file to terraform.tfvars and adjust the values as needed

environment = "{env}"
cloud_provider = "aws"  # aws, azure, gcp, or none

# AWS configuration
aws_region = "us-west-2"
aws_profile = "default"

# Azure configuration
# azure_subscription_id = "your-subscription-id"
# azure_location = "eastus"

# GCP configuration
# gcp_project_id = "your-project-id"
# gcp_region = "us-central1"

# Tier 2 Services configuration
deploy_syslog_server = true
syslog_instance_type = "t3.medium"  # AWS instance type
log_retention_days = 30
""")

    return True

def initialize_ansible(args):
    """Initialize Ansible directories and configuration."""
    logger.info("Initializing Ansible...")
    
    # Ensure vault directory exists
    vault_dir = ANSIBLE_DIR / "group_vars" / "all"
    vault_dir.mkdir(exist_ok=True, parents=True)
    
    # Create vault password file if it doesn't exist
    vault_pass_file = PROJECT_ROOT / ".vault_pass"
    if not vault_pass_file.exists():
        import random
        import string
        
        # Generate a random password
        password = ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(32))
        
        with open(vault_pass_file, "w") as f:
            f.write(password)
        
        os.chmod(vault_pass_file, 0o600)  # Set secure permissions
        logger.info(f"Created vault password file: {vault_pass_file}")
    
    # Create an encrypted vault file if it doesn't exist
    vault_file = vault_dir / "vault.yml"
    vault_example = vault_dir / "vault.yml.example"
    
    if not vault_file.exists() and vault_example.exists():
        logger.info("Creating encrypted vault file from example...")
        success, _ = run_command(["ansible-vault", "create", str(vault_file), 
                               "--vault-password-file", str(vault_pass_file)], 
                              cwd=str(PROJECT_ROOT))
        if not success:
            logger.warning("Failed to create encrypted vault file. You may need to create it manually.")
    
    return True

def initialize_discovery(args):
    """Initialize discovery components."""
    logger.info("Initializing discovery components...")
    
    # Create output directory
    output_dir = DISCOVERY_DIR / "output"
    output_dir.mkdir(exist_ok=True, parents=True)
    
    # Install discovery requirements
    requirements_file = DISCOVERY_DIR / "requirements.txt"
    if requirements_file.exists():
        logger.info("Installing discovery requirements...")
        run_command([sys.executable, "-m", "pip", "install", "-r", str(requirements_file)])
    
    return True

def setup_controller_mode(args):
    """Set up a controller/workstation for managing remote infrastructure."""
    logging.info("Setting up controller/workstation mode...")
    
    # Always install core tools for controller mode
    os_type = detect_os()
    
    # Core dependencies
    logging.info("Installing core dependencies for controller...")
    install_dependencies(os_type, args)
    
    # Set up directory structure
    logging.info("Setting up controller directory structure...")
    os.makedirs("controller/environments", exist_ok=True)
    os.makedirs("controller/ssh", exist_ok=True)
    os.makedirs("controller/credentials", exist_ok=True)
    os.makedirs("controller/config", exist_ok=True)
    
    # Create environment config templates
    environments = args.environments.split(",") if args.environments != "all" else ["dev", "test", "prod"]
    
    for env in environments:
        env_dir = f"controller/environments/{env}"
        os.makedirs(env_dir, exist_ok=True)
        
        # Create environment-specific config file if it doesn't exist
        env_config_file = f"{env_dir}/config.yml"
        if not os.path.exists(env_config_file):
            with open(env_config_file, "w") as f:
                f.write(f"""# Infrastructure Automation Framework - {env.upper()} Environment Configuration
---
environment_name: {env}
cloud_provider: aws  # Change as needed (aws, azure, gcp, none)

# Network configuration
vpc_cidr: 10.0.0.0/16
subnet_configuration:
  public:
    - 10.0.1.0/24
    - 10.0.2.0/24
  private:
    - 10.0.3.0/24
    - 10.0.4.0/24

# Service configuration
deploy:
  log_management: true
  monitoring: true
  identity_management: false
  secret_management: false

# Environment-specific variables
variables:
  log_retention_days: 30
  syslog_instance_type: t3.medium
  enable_cloudwatch: true
""")
    
    # Create Ansible inventory templates
    os.makedirs("controller/inventories", exist_ok=True)
    for env in environments:
        inv_dir = f"controller/inventories/{env}"
        os.makedirs(inv_dir, exist_ok=True)
        
        # Create environment-specific inventory file if it doesn't exist
        inv_file = f"{inv_dir}/hosts.yml"
        if not os.path.exists(inv_file):
            with open(inv_file, "w") as f:
                f.write(f"""# Infrastructure Automation Framework - {env.upper()} Environment Inventory
---
all:
  children:
    # Tier 1: Core Infrastructure
    tier1_core:
      children:
        network:
          hosts:
            # Add network hosts here
        storage:
          hosts:
            # Add storage hosts here
            
    # Tier 2: Essential Services
    tier2_services:
      children:
        log_management:
          hosts:
            # Example syslog server (uncomment and modify as needed)
            # syslog-{env}:
            #   ansible_host: 10.0.1.10
        monitoring:
          hosts:
            # Add monitoring hosts here
            
  # Common variables
  vars:
    ansible_user: ansible
    ansible_python_interpreter: /usr/bin/python3
    environment: {env}
""")
    
    # Setup cloud provider configs
    if args.cloud != "none":
        setup_cloud_provider_configs(args)
    
    # Setup SSH if requested
    if args.setup_ssh:
        setup_controller_ssh()
    
    # Setup ansible.cfg for controller
    create_controller_ansible_config()
    
    # Setup multiple Terraform backends
    setup_terraform_backends(environments)
    
    logging.info("Controller mode setup complete!")
    logging.info(f"Your workstation is ready to manage infrastructure for environments: {', '.join(environments)}")
    logging.info("To use with a specific environment: ./controller.py --env=dev [command]")

def setup_cloud_provider_configs(args):
    """Set up cloud provider configurations for controller mode."""
    cloud_providers = ["aws", "azure", "gcp"] if args.cloud == "all" else [args.cloud]
    
    os.makedirs("controller/cloud", exist_ok=True)
    
    for provider in cloud_providers:
        if provider == "none":
            continue
            
        provider_dir = f"controller/cloud/{provider}"
        os.makedirs(provider_dir, exist_ok=True)
        
        if provider == "aws":
            # Create AWS config templates
            with open(f"{provider_dir}/config_template", "w") as f:
                f.write("""[default]
region = us-west-2
output = json

[profile dev]
region = us-west-2
output = json

[profile test]
region = us-east-1
output = json

[profile prod]
region = us-east-1
output = json
""")
            
            with open(f"{provider_dir}/credentials_template", "w") as f:
                f.write("""[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY

[dev]
aws_access_key_id = DEV_ACCESS_KEY
aws_secret_access_key = DEV_SECRET_KEY

[test]
aws_access_key_id = TEST_ACCESS_KEY
aws_secret_access_key = TEST_SECRET_KEY

[prod]
aws_access_key_id = PROD_ACCESS_KEY
aws_secret_access_key = PROD_SECRET_KEY
""")
            
            logging.info(f"Created AWS configuration templates in {provider_dir}")
            logging.info("To configure AWS credentials, edit the files and run: ./controller.py setup-aws")
            
        elif provider == "azure":
            # Create Azure config template
            with open(f"{provider_dir}/config_template.json", "w") as f:
                f.write("""{
  "environments": {
    "dev": {
      "subscription_id": "YOUR_DEV_SUBSCRIPTION_ID",
      "tenant_id": "YOUR_DEV_TENANT_ID",
      "client_id": "YOUR_DEV_CLIENT_ID",
      "client_secret": "YOUR_DEV_CLIENT_SECRET"
    },
    "test": {
      "subscription_id": "YOUR_TEST_SUBSCRIPTION_ID",
      "tenant_id": "YOUR_TEST_TENANT_ID",
      "client_id": "YOUR_TEST_CLIENT_ID",
      "client_secret": "YOUR_TEST_CLIENT_SECRET"
    },
    "prod": {
      "subscription_id": "YOUR_PROD_SUBSCRIPTION_ID",
      "tenant_id": "YOUR_PROD_TENANT_ID",
      "client_id": "YOUR_PROD_CLIENT_ID",
      "client_secret": "YOUR_PROD_CLIENT_SECRET"
    }
  }
}""")
            
            logging.info(f"Created Azure configuration template in {provider_dir}")
            logging.info("To configure Azure credentials, edit the file and run: ./controller.py setup-azure")
            
        elif provider == "gcp":
            # Create GCP config template directory
            os.makedirs(f"{provider_dir}/service-accounts", exist_ok=True)
            
            with open(f"{provider_dir}/config_template.json", "w") as f:
                f.write("""{
  "environments": {
    "dev": {
      "project_id": "your-dev-project",
      "service_account_file": "service-accounts/dev.json",
      "region": "us-central1",
      "zone": "us-central1-a"
    },
    "test": {
      "project_id": "your-test-project",
      "service_account_file": "service-accounts/test.json",
      "region": "us-east1",
      "zone": "us-east1-b"
    },
    "prod": {
      "project_id": "your-prod-project",
      "service_account_file": "service-accounts/prod.json",
      "region": "us-east1",
      "zone": "us-east1-c"
    }
  }
}""")
            
            logging.info(f"Created GCP configuration template in {provider_dir}")
            logging.info("To configure GCP: Place service account JSON files in the service-accounts directory and run: ./controller.py setup-gcp")

def setup_controller_ssh():
    """Set up SSH keys and configurations for controller mode."""
    ssh_dir = "controller/ssh"
    os.makedirs(ssh_dir, exist_ok=True)
    
    # Generate SSH key if it doesn't exist
    key_file = f"{ssh_dir}/id_rsa"
    if not os.path.exists(key_file):
        logging.info("Generating SSH key pair for controller...")
        
        os_type = detect_os()
        if os_type == "windows":
            # PowerShell approach for Windows
            run_command(["powershell", "-Command", f"ssh-keygen -t rsa -b 4096 -f {key_file} -N '\"\"'"])
        else:
            # Unix approach
            run_command(["ssh-keygen", "-t", "rsa", "-b", "4096", "-f", key_file, "-N", ""])
        
        logging.info(f"SSH key pair generated at {key_file}")
    
    # Create SSH config template
    ssh_config_file = f"{ssh_dir}/config"
    if not os.path.exists(ssh_config_file):
        with open(ssh_config_file, "w") as f:
            f.write("""# Infrastructure Automation Framework - SSH Configuration

# Default options for all hosts
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    IdentityFile %d/id_rsa
    ServerAliveInterval 60

# Example environment-specific configurations
# Uncomment and modify as needed

# Development Environment
#Host *.dev
#    User ansible
#    ProxyJump bastion.dev

# Test Environment
#Host *.test
#    User ansible
#    ProxyJump bastion.test

# Production Environment
#Host *.prod
#    User ansible
#    StrictHostKeyChecking yes
#    UserKnownHostsFile ~/.ssh/known_hosts
#    ProxyJump bastion.prod

# Example Bastion Hosts
#Host bastion.dev
#    HostName 203.0.113.10
#    User admin
#    IdentityFile %d/bastion_key

#Host bastion.test
#    HostName 203.0.113.11
#    User admin
#    IdentityFile %d/bastion_key

#Host bastion.prod
#    HostName 203.0.113.12
#    User admin
#    IdentityFile %d/bastion_key
""")
        
        logging.info(f"SSH config template created at {ssh_config_file}")
        logging.info("Edit this file to configure SSH access to your environments")

def create_controller_ansible_config():
    """Create Ansible configuration for controller mode."""
    ansible_dir = "controller/ansible"
    os.makedirs(ansible_dir, exist_ok=True)
    
    # Create ansible.cfg
    ansible_cfg_file = f"{ansible_dir}/ansible.cfg"
    if not os.path.exists(ansible_cfg_file):
        with open(ansible_cfg_file, "w") as f:
            f.write("""# Infrastructure Automation Framework - Controller Ansible Configuration

[defaults]
inventory           = ./inventories/current
remote_tmp          = ~/.ansible/tmp
local_tmp           = ~/.ansible/tmp
forks               = 20
sudo_user           = root
ask_sudo_pass       = False
ask_pass            = False
transport           = smart
gathering           = smart
host_key_checking   = False
timeout             = 60
remote_user         = ansible
interpreter_python  = auto_silent

# Fact caching
fact_caching            = jsonfile
fact_caching_connection = ./.facts_cache
fact_caching_timeout    = 7200

# Improve playbook execution output
stdout_callback = yaml

# Logging
log_path = ./logs/ansible.log

# Plugin configurations
callback_whitelist = timer, profile_tasks

[inventory]
enable_plugins = yaml, ini, host_list

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
ssh_args = -F ./ssh/config -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r
retries = 3
""")
        
        logging.info(f"Ansible config created at {ansible_cfg_file}")
    
    # Create a symbolic link script or batch file to use the right inventory
    if detect_os() == "windows":
        with open(f"{ansible_dir}/use-environment.bat", "w") as f:
            f.write("""@echo off
REM Switch to using a specific environment's inventory
REM Usage: use-environment.bat [dev|test|prod]

IF "%1"=="" (
    echo Error: Please specify an environment [dev^|test^|prod]
    exit /b 1
)

IF NOT EXIST "inventories\\%1" (
    echo Error: Environment '%1' does not exist
    exit /b 1
)

IF EXIST "inventories\\current" (
    rmdir "inventories\\current"
)

mklink /D "inventories\\current" "inventories\\%1"
echo Switched to %1 environment
""")
    else:
        with open(f"{ansible_dir}/use-environment.sh", "w") as f:
            f.write("""#!/bin/bash
# Switch to using a specific environment's inventory
# Usage: ./use-environment.sh [dev|test|prod]

if [ -z "$1" ]; then
    echo "Error: Please specify an environment [dev|test|prod]"
    exit 1
fi

if [ ! -d "inventories/$1" ]; then
    echo "Error: Environment '$1' does not exist"
    exit 1
fi

if [ -L "inventories/current" ]; then
    rm "inventories/current"
elif [ -e "inventories/current" ]; then
    rm -rf "inventories/current"
fi

ln -s "$1" "inventories/current"
echo "Switched to $1 environment"
""")
        # Make the script executable
        os.chmod(f"{ansible_dir}/use-environment.sh", 0o755)

def setup_terraform_backends(environments):
    """Set up Terraform backend configurations for different environments."""
    terraform_dir = "controller/terraform"
    os.makedirs(terraform_dir, exist_ok=True)
    
    for env in environments:
        env_dir = f"{terraform_dir}/{env}"
        os.makedirs(env_dir, exist_ok=True)
        
        # Create backend configuration
        backend_file = f"{env_dir}/backend.tf"
        if not os.path.exists(backend_file):
            with open(backend_file, "w") as f:
                f.write(f"""# Terraform backend configuration for {env} environment

terraform {{
  backend "s3" {{
    bucket         = "tfstate-{env}-example"
    key            = "terraform/{env}/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks-{env}"
    encrypt        = true
    # profile      = "{env}"  # Uncomment to use a specific AWS profile
  }}
}}

# Alternative Azure backend (uncomment to use)
# terraform {{
#   backend "azurerm" {{
#     resource_group_name  = "tfstate-{env}"
#     storage_account_name = "tfstate{env}example"
#     container_name       = "tfstate"
#     key                  = "terraform/{env}/terraform.tfstate"
#   }}
# }}

# Alternative GCP backend (uncomment to use)
# terraform {{
#   backend "gcs" {{
#     bucket = "tfstate-{env}-example"
#     prefix = "terraform/{env}"
#   }}
# }}

# Alternative local backend (uncomment to use)
# terraform {{
#   backend "local" {{
#     path = "terraform.tfstate"
#   }}
# }}
""")
        
        # Create provider configuration
        provider_file = f"{env_dir}/provider.tf"
        if not os.path.exists(provider_file):
            with open(provider_file, "w") as f:
                f.write(f"""# Provider configuration for {env} environment

# AWS provider configuration
provider "aws" {{
  region  = "us-west-2"
  # profile = "{env}"  # Uncomment to use a specific AWS profile
  
  default_tags {{
    tags = {{
      Environment = "{env}"
      ManagedBy   = "terraform"
      Project     = "infrastructure-automation"
    }}
  }}
}}

# Azure provider configuration (uncomment to use)
# provider "azurerm" {{
#   features {{}}
#   subscription_id = "..."
#   tenant_id       = "..."
#   client_id       = "..."
#   client_secret   = "..."
# }}

# GCP provider configuration (uncomment to use)
# provider "google" {{
#   credentials = file("path/to/service-account-key.json")
#   project     = "your-{env}-project"
#   region      = "us-central1"
#   zone        = "us-central1-a"
# }}
""")
    
    # Create a script to initialize backends
    if detect_os() == "windows":
        with open(f"{terraform_dir}/init-environment.bat", "w") as f:
            f.write("""@echo off
REM Initialize Terraform for a specific environment
REM Usage: init-environment.bat [dev|test|prod]

IF "%1"=="" (
    echo Error: Please specify an environment [dev^|test^|prod]
    exit /b 1
)

IF NOT EXIST "%1" (
    echo Error: Environment '%1' does not exist
    exit /b 1
)

cd %1
terraform init -reconfigure
echo Terraform initialized for %1 environment
""")
    else:
        with open(f"{terraform_dir}/init-environment.sh", "w") as f:
            f.write("""#!/bin/bash
# Initialize Terraform for a specific environment
# Usage: ./init-environment.sh [dev|test|prod]

if [ -z "$1" ]; then
    echo "Error: Please specify an environment [dev|test|prod]"
    exit 1
fi

if [ ! -d "$1" ]; then
    echo "Error: Environment '$1' does not exist"
    exit 1
fi

cd "$1"
terraform init -reconfigure
echo "Terraform initialized for $1 environment"
""")
        # Make the script executable
        os.chmod(f"{terraform_dir}/init-environment.sh", 0o755)

def main():
    """Main setup function."""
    # Parse command line arguments
    args = parse_args()
    
    # Configure logging
    log_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "logs")
    os.makedirs(log_dir, exist_ok=True)
    
    log_file = os.path.join(log_dir, f"setup_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.log")
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )
    
    # Banner
    logging.info("=" * 60)
    logging.info("Infrastructure Automation Framework Setup")
    logging.info("=" * 60)
    
    # Detect OS
    os_type = detect_os()
    logging.info(f"Detected OS: {os_type}")
    
    # Check Python version
    check_python_version()
    
    # Check if pwsh should be installed
    if args.install_pwsh:
        install_pwsh(os_type)
    
    # Special handling for controller mode
    if args.mode == "controller":
        setup_controller_mode(args)
        logging.info("Controller setup completed successfully!")
        return 0
    
    # Otherwise run normal setup
    
    # ... existing main function code ...
    
    logging.info("Setup completed successfully!")
    return 0

# Create a controller management script
def create_controller_script():
    """Create a script to manage the controller environment."""
    with open("controller.py", "w") as f:
        f.write("""#!/usr/bin/env python3
\"\"\"
Infrastructure Automation Framework - Controller Management Script

This script helps manage infrastructure across different environments
from a controller/workstation setup.
\"\"\"

import os
import sys
import argparse
import subprocess
import json
import shutil
from pathlib import Path

def parse_args():
    \"\"\"Parse command line arguments.\"\"\"
    parser = argparse.ArgumentParser(description="Infrastructure Automation Controller")
    parser.add_argument("command", choices=[
        "use-env", "init", "plan", "apply", "destroy", 
        "setup-aws", "setup-azure", "setup-gcp",
        "run-playbook", "inventory", "help"
    ], help="Command to execute")
    parser.add_argument("--env", default="dev", 
                        help="Environment (dev, test, prod)")
    parser.add_argument("--cloud", choices=["aws", "azure", "gcp"], 
                        help="Cloud provider for certain operations")
    parser.add_argument("args", nargs=argparse.REMAINDER,
                        help="Additional arguments to pass to the command")
    
    return parser.parse_args()

def run_command(cmd, cwd=None, shell=False):
    \"\"\"Run a command and return its output.\"\"\"
    print(f"Running: {' '.join(cmd) if isinstance(cmd, list) else cmd}")
    
    try:
        if shell:
            result = subprocess.run(cmd, shell=True, text=True, 
                                  check=True, cwd=cwd,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        else:
            result = subprocess.run(cmd, text=True, check=True, cwd=cwd,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error: {e.stderr}")
        return False, e.stderr

def use_environment(env):
    \"\"\"Switch to using a specific environment.\"\"\"
    # Check if environment exists
    env_dir = Path(f"controller/environments/{env}")
    if not env_dir.exists():
        print(f"Error: Environment '{env}' does not exist")
        return False
    
    # Set up Ansible inventory link
    ansible_dir = Path("controller/ansible")
    inv_dir = Path(f"controller/inventories/{env}")
    current_link = Path("controller/inventories/current")
    
    if current_link.exists():
        if current_link.is_symlink():
            os.unlink(current_link)
        else:
            shutil.rmtree(current_link)
    
    # Create link based on OS
    if os.name == 'nt':  # Windows
        run_command(f"mklink /D {current_link} {inv_dir}", shell=True)
    else:  # Unix
        os.symlink(env, current_link)
    
    print(f"Switched to {env} environment")
    return True

def terraform_command(args):
    \"\"\"Run a Terraform command for a specific environment.\"\"\"
    env = args.env
    tf_dir = Path(f"controller/terraform/{env}")
    
    if not tf_dir.exists():
        print(f"Error: Terraform configuration for environment '{env}' not found")
        return False
    
    # Determine the Terraform command
    tf_cmd = args.command
    if tf_cmd == "init":
        cmd = ["terraform", "init", "-reconfigure"]
    elif tf_cmd == "plan":
        cmd = ["terraform", "plan"]
    elif tf_cmd == "apply":
        cmd = ["terraform", "apply"]
    elif tf_cmd == "destroy":
        cmd = ["terraform", "destroy"]
    else:
        print(f"Error: Unsupported Terraform command '{tf_cmd}'")
        return False
    
    # Add any additional arguments
    if args.args:
        cmd.extend(args.args)
    
    # Run the Terraform command
    success, output = run_command(cmd, cwd=tf_dir)
    if success:
        print(output)
    
    return success

def setup_cloud_provider(args):
    \"\"\"Set up cloud provider credentials and configuration.\"\"\"
    provider = args.cloud
    if not provider:
        print("Error: --cloud provider is required (aws, azure, or gcp)")
        return False
    
    if provider == "aws":
        return setup_aws()
    elif provider == "azure":
        return setup_azure()
    elif provider == "gcp":
        return setup_gcp()
    else:
        print(f"Error: Unsupported cloud provider '{provider}'")
        return False

def setup_aws():
    \"\"\"Set up AWS credentials and configuration.\"\"\"
    aws_dir = Path("controller/cloud/aws")
    
    if not aws_dir.exists():
        print("Error: AWS configuration directory not found")
        return False
    
    # Check for template files
    config_template = aws_dir / "config_template"
    creds_template = aws_dir / "credentials_template"
    
    if not config_template.exists() or not creds_template.exists():
        print("Error: AWS configuration templates not found")
        return False
    
    # Create AWS config directory
    aws_config_dir = Path.home() / ".aws"
    aws_config_dir.mkdir(exist_ok=True)
    
    # Copy templates if config files don't exist
    config_file = aws_config_dir / "config"
    creds_file = aws_config_dir / "credentials"
    
    if not config_file.exists():
        shutil.copy(config_template, config_file)
        print(f"Created AWS config file at {config_file}")
    else:
        print(f"AWS config file already exists at {config_file}")
        print("Please edit it manually to add your environments")
    
    if not creds_file.exists():
        shutil.copy(creds_template, creds_file)
        print(f"Created AWS credentials file at {creds_file}")
    else:
        print(f"AWS credentials file already exists at {creds_file}")
        print("Please edit it manually to add your credentials")
    
    print("AWS setup completed. Please edit the config and credentials files with your AWS information.")
    return True

def setup_azure():
    \"\"\"Set up Azure credentials and configuration.\"\"\"
    azure_dir = Path("controller/cloud/azure")
    
    if not azure_dir.exists():
        print("Error: Azure configuration directory not found")
        return False
    
    # Check for template file
    config_template = azure_dir / "config_template.json"
    
    if not config_template.exists():
        print("Error: Azure configuration template not found")
        return False
    
    # Create Azure config directory
    azure_config_dir = Path.home() / ".azure"
    azure_config_dir.mkdir(exist_ok=True)
    
    # Copy template if config file doesn't exist
    config_file = azure_config_dir / "credentials.json"
    
    if not config_file.exists():
        shutil.copy(config_template, config_file)
        print(f"Created Azure credentials file at {config_file}")
    else:
        print(f"Azure credentials file already exists at {config_file}")
        print("Please edit it manually to add your environments")
    
    print("Azure setup completed. Please edit the credentials file with your Azure information.")
    print("You can also run 'az login' to authenticate with Azure CLI.")
    return True

def setup_gcp():
    \"\"\"Set up GCP credentials and configuration.\"\"\"
    gcp_dir = Path("controller/cloud/gcp")
    
    if not gcp_dir.exists():
        print("Error: GCP configuration directory not found")
        return False
    
    # Check for template file
    config_template = gcp_dir / "config_template.json"
    
    if not config_template.exists():
        print("Error: GCP configuration template not found")
        return False
    
    # Create GCP config directory
    gcp_config_dir = Path.home() / ".config" / "gcloud"
    gcp_config_dir.mkdir(parents=True, exist_ok=True)
    
    # Copy template if config file doesn't exist
    config_file = gcp_dir / "config.json"
    
    if not config_file.exists():
        shutil.copy(config_template, config_file)
        print(f"Created GCP config file at {config_file}")
    else:
        print(f"GCP config file already exists at {config_file}")
        print("Please edit it manually to add your environments")
    
    # Remind about service account files
    sa_dir = gcp_dir / "service-accounts"
    sa_dir.mkdir(exist_ok=True)
    
    print("GCP setup completed.")
    print(f"Please place your service account JSON files in {sa_dir}")
    print("You can also run 'gcloud auth login' to authenticate with GCP CLI.")
    return True

def run_ansible_playbook(args):
    \"\"\"Run an Ansible playbook for a specific environment.\"\"\"
    env = args.env
    ansible_dir = Path("controller/ansible")
    
    if not ansible_dir.exists():
        print("Error: Ansible configuration directory not found")
        return False
    
    # Ensure we're using the right environment
    use_environment(env)
    
    # Check if a playbook was specified
    if not args.args:
        print("Error: Please specify a playbook to run")
        print("Usage: ./controller.py run-playbook --env=dev path/to/playbook.yml")
        return False
    
    # Build the ansible-playbook command
    playbook = args.args[0]
    extra_args = args.args[1:] if len(args.args) > 1 else []
    
    cmd = ["ansible-playbook", playbook]
    cmd.extend(extra_args)
    
    # Run the playbook
    success, output = run_command(cmd, cwd=ansible_dir)
    if success:
        print(output)
    
    return success

def show_inventory(args):
    \"\"\"Show the Ansible inventory for a specific environment.\"\"\"
    env = args.env
    inv_file = Path(f"controller/inventories/{env}/hosts.yml")
    
    if not inv_file.exists():
        print(f"Error: Inventory file for environment '{env}' not found")
        return False
    
    # Show inventory
    with open(inv_file, 'r') as f:
        print(f.read())
    
    return True

def show_help():
    \"\"\"Show help information.\"\"\"
    help_text = \"\"\"
Infrastructure Automation Controller - Help

Usage: ./controller.py COMMAND [OPTIONS] [ARGS]

Commands:
  use-env         Switch to a specific environment
  init            Initialize Terraform for an environment
  plan            Create a Terraform plan for an environment
  apply           Apply Terraform changes to an environment
  destroy         Destroy Terraform-managed infrastructure in an environment
  setup-aws       Set up AWS credentials and configuration
  setup-azure     Set up Azure credentials and configuration
  setup-gcp       Set up GCP credentials and configuration
  run-playbook    Run an Ansible playbook on an environment
  inventory       Show the Ansible inventory for an environment
  help            Show this help information

Options:
  --env=ENV       Specify the environment (dev, test, prod)
  --cloud=CLOUD   Specify the cloud provider (aws, azure, gcp)

Examples:
  ./controller.py use-env --env=dev
  ./controller.py init --env=prod
  ./controller.py plan --env=test
  ./controller.py apply --env=prod
  ./controller.py setup-aws --cloud=aws
  ./controller.py run-playbook --env=dev playbooks/setup.yml
  ./controller.py inventory --env=prod
    \"\"\"
    print(help_text)
    return True

def main():
    \"\"\"Main function.\"\"\"
    args = parse_args()
    
    # Process commands
    if args.command == "use-env":
        return use_environment(args.env)
    elif args.command in ["init", "plan", "apply", "destroy"]:
        return terraform_command(args)
    elif args.command in ["setup-aws", "setup-azure", "setup-gcp"]:
        args.cloud = args.command.split("-")[1]
        return setup_cloud_provider(args)
    elif args.command == "run-playbook":
        return run_ansible_playbook(args)
    elif args.command == "inventory":
        return show_inventory(args)
    elif args.command == "help":
        return show_help()
    else:
        print(f"Error: Unsupported command '{args.command}'")
        show_help()
        return False

if __name__ == "__main__":
    sys.exit(0 if main() else 1)
""")
    
    # Make the script executable on Unix
    if detect_os() != "windows":
        os.chmod("controller.py", 0o755)

# Ensure controller.py is created in main
def main():
    # ... existing main code ...
    
    # Special handling for controller mode
    if args.mode == "controller":
        setup_controller_mode(args)
        create_controller_script()  # Create the controller management script
        logging.info("Controller setup completed successfully!")
        return 0
    
    # ... rest of existing main code ...

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logger.info("Setup interrupted by user.")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Setup failed: {e}")
        sys.exit(1) 