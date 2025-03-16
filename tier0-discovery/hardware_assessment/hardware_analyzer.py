#!/usr/bin/env python3
"""
Hardware Assessment Script for Infrastructure Automation Framework

This script connects to discovered devices and assesses their hardware capabilities:
1. CPU information (cores, architecture)
2. Memory capacity and usage
3. Disk storage capacity and usage
4. Virtualization support
5. Operating system details

Results are formatted as structured data for integration with the automation framework.
"""

import os
import sys
import json
import argparse
import datetime
import ipaddress
import subprocess
from pathlib import Path

# Try to import optional dependencies
try:
    import paramiko
    PARAMIKO_AVAILABLE = True
except ImportError:
    PARAMIKO_AVAILABLE = False
    print("Warning: paramiko not installed, SSH-based assessment will not be available")

try:
    import wmi
    import win32com.client
    WMI_AVAILABLE = True
except ImportError:
    WMI_AVAILABLE = False
    print("Warning: wmi/pywin32 not installed, Windows-based assessment will be limited")

# Constants
DEFAULT_OUTPUT_DIR = Path(__file__).parent.parent / "device_inventory"
DEFAULT_INVENTORY_FILE = None  # Will look for the latest file if None
SSH_PORT = 22
WINRM_PORT = 5985
SSH_USERNAME = "admin"  # Default username for SSH
SSH_PASSWORD = None  # Should be provided via argument or environment variable

class HardwareAssessment:
    """Hardware assessment class for evaluating device capabilities."""
    
    def __init__(self, inventory_file=DEFAULT_INVENTORY_FILE, output_dir=DEFAULT_OUTPUT_DIR, 
                 ssh_username=SSH_USERNAME, ssh_password=SSH_PASSWORD, ssh_key_file=None):
        """
        Initialize the HardwareAssessment class.
        
        Args:
            inventory_file (str): Path to the inventory file with discovered devices
            output_dir (Path): Directory to save assessment results
            ssh_username (str): Username for SSH connections
            ssh_password (str): Password for SSH connections
            ssh_key_file (str): Path to SSH private key file
        """
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        self.ssh_username = ssh_username
        self.ssh_password = ssh_password
        self.ssh_key_file = ssh_key_file
        
        self.inventory_file = self._find_inventory_file(inventory_file)
        self.devices = self._load_inventory()
        self.assessed_devices = []
    
    def _find_inventory_file(self, inventory_file):
        """Find the latest inventory file if none is specified."""
        if inventory_file:
            return inventory_file
        
        # Look for the latest network_discovery JSON file in the device_inventory directory
        network_scan_dir = self.output_dir
        if network_scan_dir.exists():
            json_files = list(network_scan_dir.glob("network_discovery_*.json"))
            if json_files:
                latest_file = max(json_files, key=lambda f: f.stat().st_mtime)
                print(f"Using latest inventory file: {latest_file}")
                return latest_file
        
        return None
    
    def _load_inventory(self):
        """Load the inventory file with discovered devices."""
        if not self.inventory_file or not os.path.exists(self.inventory_file):
            print(f"Inventory file not found: {self.inventory_file}")
            return []
        
        try:
            with open(self.inventory_file, 'r') as f:
                devices = json.load(f)
            print(f"Loaded {len(devices)} devices from inventory")
            return devices
        except Exception as e:
            print(f"Error loading inventory file: {e}")
            return []
    
    def assess_all_devices(self):
        """Assess all devices in the inventory."""
        for device in self.devices:
            try:
                ip_address = device.get('ip_address')
                if not ip_address:
                    print(f"Skipping device without IP address: {device}")
                    continue
                
                print(f"Assessing device: {ip_address}")
                assessment = self.assess_device(ip_address)
                if assessment:
                    # Merge the original device info with the assessment
                    device_info = {**device, **assessment}
                    self.assessed_devices.append(device_info)
            except Exception as e:
                print(f"Error assessing device {device.get('ip_address')}: {e}")
        
        return self.assessed_devices
    
    def assess_device(self, ip_address):
        """
        Assess a single device by trying different assessment methods.
        
        Args:
            ip_address (str): IP address of the device to assess
            
        Returns:
            dict: Assessment results or None if assessment failed
        """
        # Try different assessment methods in order of preference
        assessment = None
        
        # Try SSH first (Linux/macOS)
        if PARAMIKO_AVAILABLE and self._check_port_open(ip_address, SSH_PORT):
            assessment = self._assess_via_ssh(ip_address)
        
        # Try WinRM if SSH failed (Windows)
        if not assessment and WMI_AVAILABLE and self._check_port_open(ip_address, WINRM_PORT):
            assessment = self._assess_via_winrm(ip_address)
        
        # If all else fails, try ICMP and port scanning for basic info
        if not assessment:
            assessment = self._assess_via_basic_scan(ip_address)
        
        if assessment:
            assessment['assessment_timestamp'] = datetime.datetime.now().isoformat()
            
        return assessment
    
    def _check_port_open(self, ip_address, port):
        """Check if a port is open on the target device."""
        try:
            import socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1)
            result = sock.connect_ex((ip_address, port))
            sock.close()
            return result == 0
        except Exception:
            return False
    
    def _assess_via_ssh(self, ip_address):
        """
        Assess a device using SSH (for Linux/macOS).
        
        Args:
            ip_address (str): IP address of the device
            
        Returns:
            dict: Assessment results or None if assessment failed
        """
        if not PARAMIKO_AVAILABLE:
            return None
        
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        try:
            # Try to connect with provided credentials
            if self.ssh_key_file:
                ssh.connect(ip_address, port=SSH_PORT, username=self.ssh_username, 
                            key_filename=self.ssh_key_file, timeout=10)
            else:
                ssh.connect(ip_address, port=SSH_PORT, username=self.ssh_username, 
                            password=self.ssh_password, timeout=10)
            
            print(f"SSH connection established to {ip_address}")
            
            # Get CPU info
            cpu_info = self._ssh_exec(ssh, "lscpu || cat /proc/cpuinfo")
            
            # Get memory info
            memory_info = self._ssh_exec(ssh, "free -m")
            
            # Get disk info
            disk_info = self._ssh_exec(ssh, "df -h")
            
            # Get OS info
            os_info = self._ssh_exec(ssh, "cat /etc/os-release || uname -a")
            
            # Check virtualization support
            virt_check = self._ssh_exec(ssh, "grep -E 'svm|vmx' /proc/cpuinfo")
            virt_support = bool(virt_check)
            
            # Get Docker installation status
            docker_info = self._ssh_exec(ssh, "docker --version || which docker")
            
            # Parse CPU details
            cpu_cores = None
            cpu_arch = None
            
            for line in cpu_info.splitlines():
                if "CPU(s):" in line:
                    cpu_cores = line.split(":")[1].strip()
                elif "Architecture:" in line:
                    cpu_arch = line.split(":")[1].strip()
                    
            # Parse memory details
            total_memory = None
            for line in memory_info.splitlines():
                if line.startswith("Mem:"):
                    parts = line.split()
                    if len(parts) >= 2:
                        total_memory = parts[1]
                    break
            
            # Parse disk space
            disks = []
            for line in disk_info.splitlines()[1:]:  # Skip header
                parts = line.split()
                if len(parts) >= 6:
                    disk = {
                        'filesystem': parts[0],
                        'size': parts[1],
                        'used': parts[2],
                        'available': parts[3],
                        'usage_percent': parts[4],
                        'mount_point': parts[5]
                    }
                    disks.append(disk)
            
            # Parse OS details
            os_name = None
            os_version = None
            
            for line in os_info.splitlines():
                if "PRETTY_NAME" in line:
                    os_name = line.split("=")[1].strip().strip('"')
                elif "VERSION_ID" in line:
                    os_version = line.split("=")[1].strip().strip('"')
            
            # Compile assessment results
            assessment = {
                'assessment_method': 'ssh',
                'operating_system': {
                    'name': os_name,
                    'version': os_version,
                    'type': 'linux'
                },
                'hardware': {
                    'cpu': {
                        'cores': cpu_cores,
                        'architecture': cpu_arch
                    },
                    'memory': {
                        'total_mb': total_memory
                    },
                    'storage': disks,
                    'virtualization_support': virt_support
                },
                'software': {
                    'docker_installed': bool(docker_info)
                }
            }
            
            ssh.close()
            return assessment
            
        except Exception as e:
            print(f"Error assessing device via SSH: {e}")
            ssh.close()
            return None
    
    def _ssh_exec(self, ssh_client, command):
        """Execute a command via SSH and return the output."""
        stdin, stdout, stderr = ssh_client.exec_command(command)
        output = stdout.read().decode('utf-8')
        error = stderr.read().decode('utf-8')
        return output if output else error
    
    def _assess_via_winrm(self, ip_address):
        """
        Assess a device using WinRM (for Windows).
        
        Args:
            ip_address (str): IP address of the device
            
        Returns:
            dict: Assessment results or None if assessment failed
        """
        if not WMI_AVAILABLE:
            return None
        
        try:
            # Connect to the remote computer using WMI
            wmi_connection = wmi.WMI(ip_address, user=self.ssh_username, password=self.ssh_password)
            
            # Get OS info
            os_info = wmi_connection.Win32_OperatingSystem()[0]
            
            # Get CPU info
            cpu_info = wmi_connection.Win32_Processor()
            
            # Get memory info
            memory_info = wmi_connection.Win32_PhysicalMemory()
            
            # Get disk info
            disk_info = wmi_connection.Win32_LogicalDisk(DriveType=3)  # Fixed disks only
            
            # Check virtualization support
            virt_support = any(cpu.VirtualizationFirmwareEnabled for cpu in cpu_info 
                               if hasattr(cpu, 'VirtualizationFirmwareEnabled'))
            
            # Get Docker installation status
            try:
                docker_check = wmi_connection.Win32_Process(Name="docker.exe")
                docker_installed = bool(docker_check)
            except:
                docker_installed = False
            
            # Compile CPU details
            cpu_details = {
                'cores': sum(cpu.NumberOfCores for cpu in cpu_info if hasattr(cpu, 'NumberOfCores')),
                'logical_processors': sum(cpu.NumberOfLogicalProcessors for cpu in cpu_info 
                                          if hasattr(cpu, 'NumberOfLogicalProcessors')),
                'architecture': cpu_info[0].AddressWidth if cpu_info else None,
                'model': cpu_info[0].Name.strip() if cpu_info else None
            }
            
            # Compile memory details
            total_memory = sum(int(mem.Capacity) for mem in memory_info if hasattr(mem, 'Capacity'))
            memory_details = {
                'total_mb': total_memory // (1024*1024) if total_memory else None
            }
            
            # Compile disk details
            disks = []
            for disk in disk_info:
                if hasattr(disk, 'Size') and hasattr(disk, 'FreeSpace'):
                    disk_detail = {
                        'drive': disk.DeviceID,
                        'size': disk.Size,
                        'free_space': disk.FreeSpace,
                        'used': str(int(disk.Size) - int(disk.FreeSpace)),
                        'usage_percent': f"{(1 - (int(disk.FreeSpace) / int(disk.Size))) * 100:.1f}%"
                    }
                    disks.append(disk_detail)
            
            # Compile OS details
            os_details = {
                'name': os_info.Caption.strip() if hasattr(os_info, 'Caption') else None,
                'version': os_info.Version if hasattr(os_info, 'Version') else None,
                'type': 'windows'
            }
            
            # Compile assessment results
            assessment = {
                'assessment_method': 'winrm',
                'operating_system': os_details,
                'hardware': {
                    'cpu': cpu_details,
                    'memory': memory_details,
                    'storage': disks,
                    'virtualization_support': virt_support
                },
                'software': {
                    'docker_installed': docker_installed
                }
            }
            
            return assessment
            
        except Exception as e:
            print(f"Error assessing device via WinRM: {e}")
            return None
    
    def _assess_via_basic_scan(self, ip_address):
        """
        Perform basic assessment of a device using ICMP and port scanning.
        
        Args:
            ip_address (str): IP address of the device
            
        Returns:
            dict: Assessment results or None if assessment failed
        """
        try:
            # Ping the device to check if it's alive
            ping_cmd = "ping" if sys.platform.startswith('win') else "ping -c 4"
            ping_result = subprocess.run(f"{ping_cmd} {ip_address}", shell=True, 
                                          capture_output=True, text=True)
            is_alive = ping_result.returncode == 0
            
            if not is_alive:
                print(f"Device {ip_address} is not responding to ping")
                return None
            
            # Perform basic port scanning to guess OS type
            open_ports = []
            common_ports = [22, 23, 80, 443, 445, 3389, 5985]
            
            for port in common_ports:
                if self._check_port_open(ip_address, port):
                    open_ports.append(port)
            
            # Guess OS type from open ports
            os_type = "unknown"
            if 3389 in open_ports or 5985 in open_ports:
                os_type = "windows"
            elif 22 in open_ports and 445 not in open_ports:
                os_type = "linux"
            
            assessment = {
                'assessment_method': 'basic_scan',
                'operating_system': {
                    'type': os_type
                },
                'network': {
                    'open_ports': open_ports
                }
            }
            
            return assessment
            
        except Exception as e:
            print(f"Error performing basic scan: {e}")
            return None
    
    def save_results(self, filename=None):
        """
        Save assessment results to a JSON file.
        
        Args:
            filename (str): Name of the file to save results to
                If None, a timestamped filename will be used
        
        Returns:
            Path: Path to the saved file
        """
        if not filename:
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"hardware_assessment_{timestamp}.json"
        
        output_path = self.output_dir / filename
        
        with open(output_path, 'w') as f:
            json.dump(self.assessed_devices, f, indent=2)
        
        print(f"Assessment results saved to {output_path}")
        return output_path

def main():
    parser = argparse.ArgumentParser(description="Hardware assessment tool for infrastructure automation")
    parser.add_argument("--inventory-file", "-i", help="Path to inventory file with discovered devices")
    parser.add_argument("--output-dir", "-o", default=str(DEFAULT_OUTPUT_DIR), help="Directory to save results")
    parser.add_argument("--ssh-username", default=SSH_USERNAME, help="SSH username")
    parser.add_argument("--ssh-password", help="SSH password")
    parser.add_argument("--ssh-key-file", help="Path to SSH private key file")
    
    args = parser.parse_args()
    
    # If password not provided via argument, try environment variable
    ssh_password = args.ssh_password
    if not ssh_password:
        ssh_password = os.environ.get("SSH_PASSWORD")
    
    # Create assessment object
    assessment = HardwareAssessment(
        inventory_file=args.inventory_file,
        output_dir=args.output_dir,
        ssh_username=args.ssh_username,
        ssh_password=ssh_password,
        ssh_key_file=args.ssh_key_file
    )
    
    # Run assessment
    assessment.assess_all_devices()
    
    # Save results
    if assessment.assessed_devices:
        assessment.save_results()
    else:
        print("No devices were successfully assessed")

if __name__ == "__main__":
    main() 