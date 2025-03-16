#!/usr/bin/env python3
"""
Infrastructure Automation Framework - Universal Setup Script

This script works on Windows, Linux, and macOS using Python.
It detects the operating system and runs the appropriate commands.
"""

import os
import sys
import platform
import subprocess
import shutil
import argparse
from pathlib import Path
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
logger = logging.getLogger("setup_universal")

# Detect operating system
OS_TYPE = platform.system()
IS_WINDOWS = OS_TYPE == "Windows"
IS_LINUX = OS_TYPE == "Linux"
IS_MACOS = OS_TYPE == "Darwin"

# Get script directory
SCRIPT_DIR = Path(__file__).parent.absolute()

def run_command(cmd, shell=False, check=False):
    """Run a command and return success flag and output."""
    logger.info(f"Running command: {cmd}")
    try:
        if isinstance(cmd, list):
            cmd_str = " ".join(cmd)
        else:
            cmd_str = cmd
            
        if IS_WINDOWS and not shell:
            # On Windows, subprocess works better with shell=True for many commands
            result = subprocess.run(cmd, shell=True, check=check, text=True,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        else:
            result = subprocess.run(cmd, shell=shell, check=check, text=True,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        if result.returncode == 0:
            logger.info(f"Command succeeded: {cmd_str}")
            return True, result.stdout.strip()
        else:
            logger.error(f"Command failed: {cmd_str}")
            logger.error(f"Error output: {result.stderr}")
            return False, result.stderr.strip()
    except Exception as e:
        logger.error(f"Exception running command: {cmd_str}")
        logger.error(f"Error: {str(e)}")
        return False, str(e)

def check_command_exists(command):
    """Check if a command exists in the system."""
    if IS_WINDOWS:
        check_cmd = f"where {command}"
    else:
        check_cmd = f"which {command}"
    
    try:
        result = subprocess.run(check_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return result.returncode == 0
    except:
        return False

def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Infrastructure Automation Framework Setup")
    parser.add_argument("--mode", choices=["dev", "prod"], default="dev",
                        help="Setup mode (default: dev)")
    parser.add_argument("--cloud", choices=["aws", "azure", "gcp", "all", "none"], default="all",
                        help="Cloud providers to configure (default: all)")
    parser.add_argument("--force", action="store_true",
                        help="Force reinstallation of components")
    parser.add_argument("--skip-deps", action="store_true",
                        help="Skip dependency installation")
    parser.add_argument("--env-file", default=".env",
                        help="Environment file path (default: .env)")
    parser.add_argument("--setup-ssh", action="store_true",
                        help="Configure SSH keys and settings")
    parser.add_argument("--install-pwsh", action="store_true",
                        help="Install PowerShell Core (pwsh)")
    
    return parser.parse_args()

def run_platform_specific_setup(args):
    """Run the platform-specific setup script with the given arguments."""
    if IS_WINDOWS:
        # Build PowerShell arguments
        ps_args = []
        
        if args.mode:
            ps_args.extend(["-Mode", args.mode])
        
        if args.cloud:
            ps_args.extend(["-Cloud", args.cloud])
        
        if args.force:
            ps_args.append("-Force")
        
        if args.skip_deps:
            ps_args.append("-SkipDeps")
        
        if args.env_file:
            ps_args.extend(["-EnvFile", args.env_file])
        
        if args.setup_ssh:
            ps_args.append("-SetupSSH")
        
        if args.install_pwsh:
            ps_args.append("-InstallPwsh")
        
        # Construct the full PowerShell command
        setup_ps1 = str(SCRIPT_DIR / "setup.ps1")
        powershell_cmd = ["powershell", "-ExecutionPolicy", "Bypass", "-File", setup_ps1] + ps_args
        
        logger.info("Running Windows setup script...")
        success, output = run_command(powershell_cmd)
        
        if not success:
            logger.error("Windows setup script failed.")
            return False
    else:
        # Build shell script arguments
        sh_args = []
        
        if args.mode:
            sh_args.extend(["--mode", args.mode])
        
        if args.cloud:
            sh_args.extend(["--cloud", args.cloud])
        
        if args.force:
            sh_args.append("--force")
        
        if args.skip_deps:
            sh_args.append("--skip-deps")
        
        if args.env_file:
            sh_args.extend(["--env-file", args.env_file])
        
        if args.setup_ssh:
            sh_args.append("--setup-ssh")
        
        if args.install_pwsh:
            sh_args.append("--install-pwsh")
        
        # Construct the full shell command
        setup_sh = str(SCRIPT_DIR / "setup.sh")
        
        # Make sure the script is executable
        try:
            os.chmod(setup_sh, 0o755)
        except Exception as e:
            logger.warning(f"Could not make setup.sh executable: {str(e)}")
        
        shell_cmd = [setup_sh] + sh_args
        
        logger.info("Running Unix setup script...")
        success, output = run_command(shell_cmd)
        
        if not success:
            logger.error("Unix setup script failed.")
            return False
    
    return True

def print_banner():
    """Print the setup banner."""
    banner = """
-----------------------------------------
Infrastructure Automation Framework Setup
-----------------------------------------
"""
    print(banner)
    logger.info("Starting universal setup script")

def main():
    """Main setup function."""
    # Print banner
    print_banner()
    
    # Parse arguments
    args = parse_args()
    
    # Log platform information
    logger.info(f"Detected operating system: {OS_TYPE}")
    
    # Run the platform-specific setup script
    if run_platform_specific_setup(args):
        logger.info("Setup completed successfully!")
        print("\nSetup completed successfully!")
        print("You can now start using the Infrastructure Automation Framework.")
        print("Refer to the README.md for next steps.")
    else:
        logger.error("Setup failed.")
        print("\nSetup failed.")
        print("Check the logs directory for more information.")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main()) 