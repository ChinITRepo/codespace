#!/usr/bin/env python3
"""
Infrastructure Automation Framework - Controller Management Script

This script helps manage infrastructure across different environments
from a controller/workstation setup.
"""

import os
import sys
import argparse
import subprocess
import json
import shutil
import logging
from pathlib import Path
from datetime import datetime

# Configure logging
log_dir = Path("logs")
log_dir.mkdir(exist_ok=True)
log_file = log_dir / f"controller_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("controller")

# Constants
CONTROLLER_DIR = Path("controller")
ENVIRONMENTS_DIR = CONTROLLER_DIR / "environments"
INVENTORIES_DIR = CONTROLLER_DIR / "inventories"
TERRAFORM_DIR = CONTROLLER_DIR / "terraform"
ANSIBLE_DIR = CONTROLLER_DIR / "ansible"
CLOUD_DIR = CONTROLLER_DIR / "cloud"
SSH_DIR = CONTROLLER_DIR / "ssh"

def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Infrastructure Automation Controller")
    parser.add_argument("command", choices=[
        "init", "use-env", "setup-ssh", "setup-cloud", 
        "terraform", "ansible", "inventory", "discover",
        "generate-config", "help"
    ], help="Command to execute")
    
    parser.add_argument("--env", default="dev", 
                        help="Environment (dev, test, prod, etc.)")
    parser.add_argument("--cloud", choices=["aws", "azure", "gcp", "all"], 
                        help="Cloud provider for operations")
    parser.add_argument("--tf-action", choices=["init", "plan", "apply", "destroy", "validate", "output"],
                        help="Terraform action to perform")
    parser.add_argument("--playbook", 
                        help="Ansible playbook to run")
    parser.add_argument("--ssh-key", default=str(Path.home() / ".ssh" / "id_rsa"),
                        help="Path to SSH private key")
    parser.add_argument("--force", action="store_true",
                        help="Force overwrite of existing files")
    parser.add_argument("--remote-user", default="ansible",
                        help="Default remote user for SSH connections")
    parser.add_argument("args", nargs=argparse.REMAINDER,
                        help="Additional arguments to pass to underlying commands")
    
    return parser.parse_args()

def run_command(cmd, cwd=None, shell=False, capture_output=True):
    """Run a command and return its output."""
    logger.info(f"Running: {' '.join(cmd) if isinstance(cmd, list) else cmd}")
    
    try:
        if capture_output:
            if shell:
                result = subprocess.run(cmd, shell=True, text=True, 
                                    check=True, cwd=cwd,
                                    stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            else:
                result = subprocess.run(cmd, text=True, check=True, cwd=cwd,
                                    stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            logger.info(f"Command succeeded")
            return True, result.stdout
        else:
            if shell:
                subprocess.run(cmd, shell=True, cwd=cwd, check=True)
            else:
                subprocess.run(cmd, cwd=cwd, check=True)
            logger.info(f"Command succeeded")
            return True, ""
    except subprocess.CalledProcessError as e:
        logger.error(f"Command failed: {e}")
        if capture_output:
            logger.error(f"Error output: {e.stderr}")
            return False, e.stderr
        return False, str(e)

def init_controller():
    """Initialize the controller environment."""
    logger.info("Initializing controller environment...")
    
    # Create controller directory structure
    CONTROLLER_DIR.mkdir(exist_ok=True)
    ENVIRONMENTS_DIR.mkdir(exist_ok=True)
    INVENTORIES_DIR.mkdir(exist_ok=True)
    TERRAFORM_DIR.mkdir(exist_ok=True)
    ANSIBLE_DIR.mkdir(exist_ok=True)
    CLOUD_DIR.mkdir(exist_ok=True)
    SSH_DIR.mkdir(exist_ok=True)
    
    # Create default environment directories
    for env in ["dev", "test", "prod"]:
        (ENVIRONMENTS_DIR / env).mkdir(exist_ok=True)
        (INVENTORIES_DIR / env).mkdir(exist_ok=True)
        (TERRAFORM_DIR / env).mkdir(exist_ok=True)
    
    # Create default environment config files
    for env in ["dev", "test", "prod"]:
        env_config_file = ENVIRONMENTS_DIR / env / "config.yml"
        if not env_config_file.exists():
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
            logger.info(f"Created environment config: {env_config_file}")
    
    # Create default Ansible inventory files
    for env in ["dev", "test", "prod"]:
        inv_file = INVENTORIES_DIR / env / "hosts.yml"
        if not inv_file.exists():
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
            logger.info(f"Created inventory file: {inv_file}")
    
    # Create Ansible configuration
    ansible_cfg = ANSIBLE_DIR / "ansible.cfg"
    if not ansible_cfg.exists():
        with open(ansible_cfg, "w") as f:
            f.write("""# Infrastructure Automation Framework - Controller Ansible Configuration

[defaults]
inventory           = ../inventories/current
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
log_path = ../logs/ansible.log

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
ssh_args = -F ../ssh/config -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r
retries = 3
""")
        logger.info(f"Created Ansible config: {ansible_cfg}")
    
    # Create SSH config
    ssh_config = SSH_DIR / "config"
    if not ssh_config.exists():
        with open(ssh_config, "w") as f:
            f.write("""# Infrastructure Automation Framework - SSH Configuration

# Default options for all hosts
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ServerAliveInterval 60

# Example environment-specific configurations
# Uncomment and modify as needed

# Development Environment
#Host *.dev
#    User ansible
#    IdentityFile ~/.ssh/id_rsa
#    ProxyJump bastion.dev

# Test Environment
#Host *.test
#    User ansible
#    IdentityFile ~/.ssh/id_rsa
#    ProxyJump bastion.test

# Production Environment
#Host *.prod
#    User ansible
#    StrictHostKeyChecking yes
#    UserKnownHostsFile ~/.ssh/known_hosts
#    IdentityFile ~/.ssh/id_rsa
#    ProxyJump bastion.prod

# Example Bastion Hosts
#Host bastion.dev
#    HostName 203.0.113.10
#    User admin
#    IdentityFile ~/.ssh/bastion_key

#Host bastion.test
#    HostName 203.0.113.11
#    User admin
#    IdentityFile ~/.ssh/bastion_key

#Host bastion.prod
#    HostName 203.0.113.12
#    User admin
#    IdentityFile ~/.ssh/bastion_key
""")
        logger.info(f"Created SSH config: {ssh_config}")
    
    # Create cloud provider directories
    for provider in ["aws", "azure", "gcp"]:
        provider_dir = CLOUD_DIR / provider
        provider_dir.mkdir(exist_ok=True)
        
        if provider == "aws":
            config_template = provider_dir / "config_template"
            if not config_template.exists():
                with open(config_template, "w") as f:
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
            
            credentials_template = provider_dir / "credentials_template"
            if not credentials_template.exists():
                with open(credentials_template, "w") as f:
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
    
    # Create Terraform backend configs
    for env in ["dev", "test", "prod"]:
        env_dir = TERRAFORM_DIR / env
        backend_file = env_dir / "backend.tf"
        if not backend_file.exists():
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
            logger.info(f"Created Terraform backend config: {backend_file}")
        
        provider_file = env_dir / "provider.tf"
        if not provider_file.exists():
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
            logger.info(f"Created Terraform provider config: {provider_file}")
    
    # Create a current environment symlink
    current_link = INVENTORIES_DIR / "current"
    if not current_link.exists():
        try:
            # Windows doesn't support symlinks without special privileges
            if os.name == 'nt':  # Windows
                # Use directory junction instead (similar to symlink)
                run_command(f"mklink /J {current_link} {INVENTORIES_DIR / 'dev'}", shell=True)
            else:
                # Create symbolic link on Unix systems
                os.symlink("dev", current_link)
            logger.info("Set 'dev' as current environment")
        except Exception as e:
            logger.error(f"Could not create current environment link: {e}")
    
    logger.info("Controller initialization completed successfully!")
    print("Controller environment initialized successfully! Use 'controller.py help' for available commands.")
    return True

def use_environment(env):
    """Switch to using a specific environment."""
    env_dir = ENVIRONMENTS_DIR / env
    inv_dir = INVENTORIES_DIR / env
    
    if not env_dir.exists():
        logger.error(f"Environment '{env}' does not exist")
        return False
    
    if not inv_dir.exists():
        logger.error(f"Inventory for environment '{env}' does not exist")
        return False
    
    current_link = INVENTORIES_DIR / "current"
    
    # Remove existing link
    if current_link.exists():
        if current_link.is_symlink():
            os.unlink(current_link)
        elif os.path.isdir(current_link):
            # On Windows, might be a directory junction
            if os.name == 'nt':
                run_command(f"rmdir {current_link}", shell=True)
            else:
                shutil.rmtree(current_link)
    
    # Create new link
    try:
        if os.name == 'nt':  # Windows
            run_command(f"mklink /J {current_link} {inv_dir}", shell=True)
        else:
            os.symlink(env, current_link)
        logger.info(f"Switched to '{env}' environment")
        print(f"Switched to '{env}' environment")
        return True
    except Exception as e:
        logger.error(f"Failed to switch environment: {e}")
        return False

def setup_ssh(args):
    """Set up SSH keys and config for remote access."""
    ssh_key_path = Path(args.ssh_key)
    controller_ssh_dir = SSH_DIR
    
    # Check if SSH key exists
    if not ssh_key_path.exists():
        logger.info(f"SSH key not found at {ssh_key_path}, generating new key pair...")
        
        # Generate key pair
        ssh_key_dir = ssh_key_path.parent
        ssh_key_dir.mkdir(exist_ok=True, parents=True)
        
        # Run ssh-keygen
        if os.name == 'nt':  # Windows
            cmd = f'ssh-keygen -t rsa -b 4096 -f "{ssh_key_path}" -N ""'
        else:
            cmd = f'ssh-keygen -t rsa -b 4096 -f "{ssh_key_path}" -N ""'
        
        success, output = run_command(cmd, shell=True)
        if not success:
            logger.error(f"Failed to generate SSH key: {output}")
            return False
        
        logger.info(f"Generated new SSH key at {ssh_key_path}")
    
    # Update SSH config with correct key path
    ssh_config = controller_ssh_dir / "config"
    if ssh_config.exists():
        with open(ssh_config, "r") as f:
            config_content = f.read()
        
        # Update IdentityFile paths if different from default
        if "~/.ssh/id_rsa" in config_content and str(ssh_key_path) != "~/.ssh/id_rsa":
            config_content = config_content.replace("~/.ssh/id_rsa", str(ssh_key_path))
            
            with open(ssh_config, "w") as f:
                f.write(config_content)
            
            logger.info(f"Updated SSH config with key path: {ssh_key_path}")
    
    # Display public key for user to deploy to servers
    public_key_path = Path(f"{ssh_key_path}.pub")
    if public_key_path.exists():
        with open(public_key_path, "r") as f:
            public_key = f.read().strip()
        
        print("\nPublic SSH key for deployment to servers:")
        print("=" * 70)
        print(public_key)
        print("=" * 70)
        print(f"\nAdd this public key to authorized_keys on your servers")
        print(f"or use it with your cloud provider's key management.")
    
    logger.info("SSH setup completed successfully")
    return True

def setup_cloud(args):
    """Set up cloud provider credentials and configuration."""
    if not args.cloud:
        logger.error("Please specify a cloud provider with --cloud")
        return False
    
    providers = ["aws", "azure", "gcp"] if args.cloud == "all" else [args.cloud]
    
    for provider in providers:
        logger.info(f"Setting up {provider} credentials...")
        provider_dir = CLOUD_DIR / provider
        
        if not provider_dir.exists():
            logger.error(f"{provider} configuration directory not found")
            continue
        
        if provider == "aws":
            aws_dir = Path.home() / ".aws"
            aws_dir.mkdir(exist_ok=True)
            
            config_template = provider_dir / "config_template"
            credentials_template = provider_dir / "credentials_template"
            
            if not config_template.exists() or not credentials_template.exists():
                logger.error("AWS configuration templates not found")
                continue
            
            # Copy templates if they don't exist or force is specified
            config_file = aws_dir / "config"
            credentials_file = aws_dir / "credentials"
            
            if not config_file.exists() or args.force:
                shutil.copy(config_template, config_file)
                logger.info(f"Created/updated AWS config at {config_file}")
            else:
                logger.info(f"AWS config already exists at {config_file}")
            
            if not credentials_file.exists() or args.force:
                shutil.copy(credentials_template, credentials_file)
                logger.info(f"Created/updated AWS credentials at {credentials_file}")
            else:
                logger.info(f"AWS credentials already exist at {credentials_file}")
            
            print(f"\nAWS configuration files created/updated:")
            print(f"  - Config: {config_file}")
            print(f"  - Credentials: {credentials_file}")
            print(f"\nPlease edit these files with your AWS credentials")
            print(f"For multi-environment support, use named profiles (dev, test, prod)")
        
        elif provider == "azure":
            # Azure CLI handles credentials differently, we'll use environment variables
            azure_env_file = provider_dir / "azure.env.template"
            
            if not azure_env_file.exists():
                with open(azure_env_file, "w") as f:
                    f.write("""# Azure credentials environment variables
# Copy to .env and fill in your values

# Service Principal authentication
export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"

# For developer authentication with user account, remove the above and use:
# export ARM_USE_CLI=true
""")
            
            azure_env_dest = CONTROLLER_DIR / "azure.env"
            if not azure_env_dest.exists() or args.force:
                shutil.copy(azure_env_file, azure_env_dest)
                logger.info(f"Created/updated Azure environment file at {azure_env_dest}")
            else:
                logger.info(f"Azure environment file already exists at {azure_env_dest}")
            
            print(f"\nAzure configuration created:")
            print(f"  - Environment file: {azure_env_dest}")
            print(f"\nPlease edit this file with your Azure credentials")
            print(f"To use for Terraform, run: source {azure_env_dest}")
            print(f"You can also authenticate using 'az login' for interactive sessions")
        
        elif provider == "gcp":
            # GCP typically uses service account JSON files
            gcp_sa_dir = provider_dir / "service-accounts"
            gcp_sa_dir.mkdir(exist_ok=True)
            
            gcp_env_file = provider_dir / "gcp.env.template"
            
            if not gcp_env_file.exists():
                with open(gcp_env_file, "w") as f:
                    f.write("""# Google Cloud credentials environment variables
# Copy to .env and fill in your values

# Set this to the path of your service account key file
export GOOGLE_APPLICATION_CREDENTIALS="./controller/cloud/gcp/service-accounts/your-service-account.json"
export GOOGLE_PROJECT="your-project-id"
export GOOGLE_REGION="us-central1"
export GOOGLE_ZONE="us-central1-a"
""")
            
            gcp_env_dest = CONTROLLER_DIR / "gcp.env"
            if not gcp_env_dest.exists() or args.force:
                shutil.copy(gcp_env_file, gcp_env_dest)
                logger.info(f"Created/updated GCP environment file at {gcp_env_dest}")
            else:
                logger.info(f"GCP environment file already exists at {gcp_env_dest}")
            
            print(f"\nGCP configuration created:")
            print(f"  - Environment file: {gcp_env_dest}")
            print(f"  - Service account directory: {gcp_sa_dir}")
            print(f"\nPlease:")
            print(f"1. Place your service account JSON files in {gcp_sa_dir}")
            print(f"2. Edit the environment file with your GCP project details")
            print(f"3. To use for Terraform, run: source {gcp_env_dest}")
            print(f"You can also authenticate using 'gcloud auth application-default login' for interactive sessions")
    
    logger.info("Cloud provider setup completed successfully")
    return True

def run_terraform(args):
    """Run Terraform commands for a specific environment."""
    if not args.tf_action:
        logger.error("Please specify a Terraform action with --tf-action")
        return False
    
    env = args.env
    env_dir = TERRAFORM_DIR / env
    
    if not env_dir.exists():
        logger.error(f"Terraform directory for environment '{env}' not found")
        return False
    
    # Build terraform command
    tf_cmd = ["terraform", args.tf_action]
    
    # Add any additional arguments
    if args.args:
        tf_cmd.extend(args.args)
    
    # Run terraform command
    success, output = run_command(tf_cmd, cwd=env_dir, capture_output=False)
    return success

def run_ansible(args):
    """Run Ansible commands for a specific environment."""
    if not args.playbook:
        logger.error("Please specify an Ansible playbook with --playbook")
        return False
    
    env = args.env
    
    # Switch to the right environment first
    use_environment(env)
    
    playbook_path = Path(args.playbook)
    if not playbook_path.exists():
        logger.error(f"Playbook not found: {playbook_path}")
        return False
    
    # Build ansible command
    ansible_cmd = ["ansible-playbook", str(playbook_path)]
    
    # Add any additional arguments
    if args.args:
        ansible_cmd.extend(args.args)
    
    # Run ansible command
    success, output = run_command(ansible_cmd, cwd=ANSIBLE_DIR, capture_output=False)
    return success

def show_inventory(args):
    """Show the inventory for a specific environment."""
    env = args.env
    inv_file = INVENTORIES_DIR / env / "hosts.yml"
    
    if not inv_file.exists():
        logger.error(f"Inventory file for environment '{env}' not found")
        return False
    
    print(f"\nInventory for {env} environment:")
    print("=" * 70)
    
    with open(inv_file, "r") as f:
        print(f.read())
    
    return True

def discover_network(args):
    """Run network discovery for a specific environment."""
    env = args.env
    
    # Switch to the right environment
    use_environment(env)
    
    # Check if discovery script exists
    discovery_script = Path("discovery/network_scan.py")
    if not discovery_script.exists():
        logger.error("Network discovery script not found")
        return False
    
    # Create output directory
    output_dir = Path("discovery/output") / env
    output_dir.mkdir(exist_ok=True, parents=True)
    
    # Build discovery command
    discover_cmd = [
        sys.executable,
        str(discovery_script),
        "--output-dir", str(output_dir)
    ]
    
    # Add any additional arguments
    if args.args:
        discover_cmd.extend(args.args)
    
    # Run discovery
    print(f"\nRunning network discovery for {env} environment...")
    success, output = run_command(discover_cmd, capture_output=False)
    
    if success:
        # Generate inventory
        generate_cmd = [
            sys.executable,
            "discovery/generate_inventory.py",
            "--input-dir", str(output_dir),
            "--output-file", str(INVENTORIES_DIR / env / "discovered_hosts.yml")
        ]
        
        success, _ = run_command(generate_cmd)
        if success:
            print(f"Discovery completed. Generated inventory: {INVENTORIES_DIR / env / 'discovered_hosts.yml'}")
    
    return success

def generate_config_files(args):
    """Generate configuration files by templating."""
    env = args.env
    env_dir = ENVIRONMENTS_DIR / env
    
    if not env_dir.exists():
        logger.error(f"Environment '{env}' not found")
        return False
    
    env_config_file = env_dir / "config.yml"
    if not env_config_file.exists():
        logger.error(f"Configuration file for environment '{env}' not found")
        return False
    
    # Read environment config
    try:
        import yaml
        with open(env_config_file, "r") as f:
            config = yaml.safe_load(f)
    except Exception as e:
        logger.error(f"Failed to read environment config: {e}")
        return False
    
    # Process templates
    templates_dir = Path("templates")
    if not templates_dir.exists():
        logger.error("Templates directory not found")
        return False
    
    output_dir = env_dir / "generated"
    output_dir.mkdir(exist_ok=True)
    
    print(f"\nGenerating configuration files for {env} environment...")
    
    # Process Terraform templates
    tf_templates_dir = templates_dir / "terraform"
    if tf_templates_dir.exists():
        for template_file in tf_templates_dir.glob("**/*.tf.tmpl"):
            # Calculate relative path from template dir
            rel_path = template_file.relative_to(tf_templates_dir)
            output_file = output_dir / "terraform" / rel_path.with_suffix("")
            
            # Create parent directories
            output_file.parent.mkdir(exist_ok=True, parents=True)
            
            # Read template
            with open(template_file, "r") as f:
                template_content = f.read()
            
            # Simple templating (replace variables)
            for key, value in config.get("variables", {}).items():
                template_content = template_content.replace(f"{{{{ {key} }}}}", str(value))
            
            # Write output file
            with open(output_file, "w") as f:
                f.write(template_content)
            
            logger.info(f"Generated: {output_file}")
            print(f"  - {output_file}")
    
    # Process Ansible templates
    ansible_templates_dir = templates_dir / "ansible"
    if ansible_templates_dir.exists():
        for template_file in ansible_templates_dir.glob("**/*.yml.tmpl"):
            # Calculate relative path from template dir
            rel_path = template_file.relative_to(ansible_templates_dir)
            output_file = output_dir / "ansible" / rel_path.with_suffix("")
            
            # Create parent directories
            output_file.parent.mkdir(exist_ok=True, parents=True)
            
            # Read template
            with open(template_file, "r") as f:
                template_content = f.read()
            
            # Simple templating (replace variables)
            for key, value in config.get("variables", {}).items():
                template_content = template_content.replace(f"{{{{ {key} }}}}", str(value))
            
            # Write output file
            with open(output_file, "w") as f:
                f.write(template_content)
            
            logger.info(f"Generated: {output_file}")
            print(f"  - {output_file}")
    
    print(f"\nGenerated files have been placed in: {output_dir}")
    return True

def show_help():
    """Show help information."""
    help_text = """
Infrastructure Automation Controller - Help

This script helps manage infrastructure across different environments.

Usage: python controller.py COMMAND [OPTIONS]

Commands:
  init              Initialize the controller environment
  use-env           Switch to a specific environment
  setup-ssh         Configure SSH keys and settings
  setup-cloud       Configure cloud provider credentials
  terraform         Run Terraform commands
  ansible           Run Ansible playbooks
  inventory         Show environment inventory
  discover          Run network discovery
  generate-config   Generate config files from templates
  help              Show this help information

Options:
  --env ENV         Environment to use (dev, test, prod, etc.)
  --cloud PROVIDER  Cloud provider to configure (aws, azure, gcp, all)
  --tf-action ACTION Terraform action (init, plan, apply, destroy, etc.)
  --playbook PATH   Path to Ansible playbook
  --ssh-key PATH    Path to SSH private key
  --force           Force overwrite of existing files
  --remote-user USER Default remote user for SSH connections

Examples:
  python controller.py init
  python controller.py use-env --env=prod
  python controller.py setup-ssh --ssh-key=~/.ssh/infra_key
  python controller.py setup-cloud --cloud=aws
  python controller.py terraform --env=dev --tf-action=plan
  python controller.py ansible --env=prod --playbook=playbooks/deploy.yml
  python controller.py inventory --env=test
  python controller.py discover --env=dev
  python controller.py generate-config --env=prod
"""
    print(help_text)
    return True

def main():
    """Main function."""
    args = parse_args()
    
    # Process command
    if args.command == "init":
        return init_controller()
    elif args.command == "use-env":
        return use_environment(args.env)
    elif args.command == "setup-ssh":
        return setup_ssh(args)
    elif args.command == "setup-cloud":
        return setup_cloud(args)
    elif args.command == "terraform":
        return run_terraform(args)
    elif args.command == "ansible":
        return run_ansible(args)
    elif args.command == "inventory":
        return show_inventory(args)
    elif args.command == "discover":
        return discover_network(args)
    elif args.command == "generate-config":
        return generate_config_files(args)
    elif args.command == "help":
        return show_help()
    else:
        logger.error(f"Unknown command: {args.command}")
        show_help()
        return False

if __name__ == "__main__":
    sys.exit(0 if main() else 1) 