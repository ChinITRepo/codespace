#!/usr/bin/env python3
"""
Inventory Generator Script for Infrastructure Automation Framework

This script converts discovered device data into an Ansible inventory format.
It reads hardware assessment data from JSON files and generates a YAML inventory
that can be used for subsequent automation tasks.
"""

import os
import sys
import json
import argparse
import datetime
import glob
from pathlib import Path

try:
    import yaml
    YAML_AVAILABLE = True
except ImportError:
    YAML_AVAILABLE = False
    print("Warning: PyYAML not installed, will output JSON format instead")

# Constants
DEFAULT_INPUT_DIR = Path(__file__).parent.parent / "device_inventory"
DEFAULT_OUTPUT_FILE = None  # Will use a timestamp if not specified

class InventoryGenerator:
    """Generator for Ansible inventory from discovered devices."""
    
    def __init__(self, input_dir=DEFAULT_INPUT_DIR, output_file=DEFAULT_OUTPUT_FILE):
        """
        Initialize the InventoryGenerator class.
        
        Args:
            input_dir (Path): Directory containing device discovery and assessment data
            output_file (Path): Path to write the generated inventory
        """
        self.input_dir = Path(input_dir)
        
        if not output_file:
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            output_file = self.input_dir / f"generated_inventory_{timestamp}.yml"
        
        self.output_file = Path(output_file)
        self.discovered_devices = []
        self.inventory = self._create_base_inventory()
    
    def _create_base_inventory(self):
        """Create the base inventory structure."""
        return {
            'all': {
                'children': {
                    'ungrouped': {
                        'hosts': {}
                    },
                    'tier1_core': {
                        'children': {
                            'network': {'hosts': {}},
                            'storage': {'hosts': {}},
                            'security': {'hosts': {}},
                            'virtualization': {'hosts': {}}
                        }
                    },
                    'tier2_services': {
                        'children': {
                            'automation': {'hosts': {}},
                            'monitoring': {'hosts': {}},
                            'identity': {'hosts': {}},
                            'secrets': {'hosts': {}}
                        }
                    },
                    'tier3_applications': {
                        'children': {
                            'business': {'hosts': {}},
                            'media': {'hosts': {}},
                            'cloud': {'hosts': {}}
                        }
                    },
                    'tier4_specialized': {
                        'children': {
                            'ai': {'hosts': {}},
                            'gaming': {'hosts': {}},
                            'security_specialized': {'hosts': {}}
                        }
                    },
                    # OS-based groups
                    'os_types': {
                        'children': {
                            'linux': {'hosts': {}},
                            'windows': {'hosts': {}},
                            'macos': {'hosts': {}},
                            'network_devices': {'hosts': {}},
                            'other': {'hosts': {}}
                        }
                    }
                },
                'vars': {
                    'ansible_python_interpreter': 'auto',
                    'ansible_ssh_common_args': '-o StrictHostKeyChecking=no'
                }
            }
        }
    
    def load_discovered_devices(self):
        """Load discovered devices from JSON files in the input directory."""
        if not self.input_dir.exists():
            print(f"Input directory not found: {self.input_dir}")
            return False
        
        # Find all hardware assessment files
        assessment_files = list(self.input_dir.glob("hardware_assessment_*.json"))
        if not assessment_files:
            print("No hardware assessment files found")
            
            # Try to use network discovery files instead
            discovery_files = list(self.input_dir.glob("network_discovery_*.json"))
            if not discovery_files:
                print("No network discovery files found either")
                return False
            
            # Use the latest network discovery file
            latest_file = max(discovery_files, key=lambda f: f.stat().st_mtime)
            print(f"Using latest network discovery file: {latest_file}")
            
            try:
                with open(latest_file, 'r') as f:
                    self.discovered_devices = json.load(f)
                print(f"Loaded {len(self.discovered_devices)} devices from network discovery")
                return len(self.discovered_devices) > 0
            except Exception as e:
                print(f"Error loading network discovery file: {e}")
                return False
        
        # Use the latest hardware assessment file
        latest_file = max(assessment_files, key=lambda f: f.stat().st_mtime)
        print(f"Using latest hardware assessment file: {latest_file}")
        
        try:
            with open(latest_file, 'r') as f:
                self.discovered_devices = json.load(f)
            print(f"Loaded {len(self.discovered_devices)} devices from hardware assessment")
            return len(self.discovered_devices) > 0
        except Exception as e:
            print(f"Error loading hardware assessment file: {e}")
            return False
    
    def generate_inventory(self):
        """Generate Ansible inventory from discovered devices."""
        if not self.discovered_devices:
            print("No devices loaded, cannot generate inventory")
            return False
        
        for device in self.discovered_devices:
            try:
                ip_address = device.get('ip_address')
                hostname = device.get('hostname', "unknown")
                
                if not ip_address:
                    print(f"Skipping device without IP address: {device}")
                    continue
                
                # Normalize hostname for Ansible
                safe_hostname = self._safe_hostname(hostname, ip_address)
                
                # Determine OS type
                os_type = self._determine_os_type(device)
                
                # Determine device role based on assessment data
                device_role = self._determine_device_role(device)
                
                # Add to inventory with host vars
                self._add_host_to_inventory(safe_hostname, ip_address, os_type, device_role, device)
                
            except Exception as e:
                print(f"Error processing device {device.get('ip_address')}: {e}")
        
        return True
    
    def _safe_hostname(self, hostname, ip_address):
        """Create a safe hostname for Ansible inventory."""
        if hostname and hostname.lower() != "unknown":
            # Remove domain if present
            hostname = hostname.split('.')[0]
            
            # Replace invalid characters
            safe_name = ''.join(c if c.isalnum() or c in '-_' else '_' for c in hostname)
            
            # Ensure it doesn't start with a number
            if safe_name and safe_name[0].isdigit():
                safe_name = f"host_{safe_name}"
                
            if safe_name:
                return safe_name
        
        # Fallback to IP with prefix
        return f"host_{ip_address.replace('.', '_')}"
    
    def _determine_os_type(self, device):
        """Determine the OS type from device data."""
        # Check if operating_system data is available
        if 'operating_system' in device:
            os_data = device['operating_system']
            if isinstance(os_data, dict) and 'type' in os_data:
                os_type = os_data['type'].lower()
                if os_type in ['linux', 'windows', 'macos']:
                    return os_type
                elif 'network' in os_type:
                    return 'network_devices'
        
        # Try to guess from open ports
        if 'open_ports' in device:
            ports = device['open_ports']
            if isinstance(ports, list):
                # Check for Windows-specific ports
                if any(p.get('port') in [3389, 5985, 5986] for p in ports if isinstance(p, dict)):
                    return 'windows'
                # Check for Linux-specific ports
                if any(p.get('port') == 22 for p in ports if isinstance(p, dict)):
                    return 'linux'
        
        # Default to other
        return 'other'
    
    def _determine_device_role(self, device):
        """
        Determine the device role based on assessment data.
        This is a basic heuristic and can be expanded with more sophisticated logic.
        """
        # Simple heuristics based on hostnames and services
        hostname = device.get('hostname', '').lower()
        
        # Check for networking devices
        if any(term in hostname for term in ['router', 'switch', 'fw', 'firewall', 'gateway']):
            return 'network'
        
        # Check for storage
        if any(term in hostname for term in ['nas', 'san', 'storage', 'backup']):
            return 'storage'
        
        # Check for virtualization hosts
        if 'hardware' in device and 'virtualization_support' in device['hardware']:
            if device['hardware']['virtualization_support']:
                return 'virtualization'
        
        # Check for services based on open ports
        if 'open_ports' in device:
            ports = device['open_ports']
            if isinstance(ports, list):
                # Web servers
                if any(p.get('port') in [80, 443, 8080] for p in ports if isinstance(p, dict)):
                    return 'cloud'
                # Database servers
                if any(p.get('port') in [3306, 5432, 1521, 27017] for p in ports if isinstance(p, dict)):
                    return 'business'
        
        # Default to ungrouped
        return 'ungrouped'
    
    def _add_host_to_inventory(self, hostname, ip_address, os_type, device_role, device_data):
        """Add a host to the inventory with appropriate groups and variables."""
        # Host variables
        host_vars = {
            'ansible_host': ip_address
        }
        
        # Add OS-specific variables
        if os_type == 'windows':
            host_vars['ansible_connection'] = 'winrm'
            host_vars['ansible_winrm_server_cert_validation'] = 'ignore'
        elif os_type in ['linux', 'macos']:
            host_vars['ansible_connection'] = 'ssh'
        
        # Add hardware details if available
        if 'hardware' in device_data:
            hardware = device_data['hardware']
            if isinstance(hardware, dict):
                # CPU information
                if 'cpu' in hardware:
                    host_vars['cpu_cores'] = hardware['cpu'].get('cores')
                    host_vars['cpu_arch'] = hardware['cpu'].get('architecture')
                
                # Memory information
                if 'memory' in hardware:
                    host_vars['memory_mb'] = hardware['memory'].get('total_mb')
                
                # Virtualization support
                if 'virtualization_support' in hardware:
                    host_vars['virtualization_support'] = hardware['virtualization_support']
        
        # Add to OS type group
        self.inventory['all']['children']['os_types']['children'][os_type]['hosts'][hostname] = host_vars
        
        # Add to role-based group
        if device_role != 'ungrouped':
            # Determine the tier group
            if device_role in ['network', 'storage', 'security', 'virtualization']:
                tier_group = 'tier1_core'
            elif device_role in ['automation', 'monitoring', 'identity', 'secrets']:
                tier_group = 'tier2_services'
            elif device_role in ['business', 'media', 'cloud']:
                tier_group = 'tier3_applications'
            elif device_role in ['ai', 'gaming', 'security_specialized']:
                tier_group = 'tier4_specialized'
            else:
                tier_group = None
            
            if tier_group:
                # Add to the appropriate tier and role group
                self.inventory['all']['children'][tier_group]['children'][device_role]['hosts'][hostname] = {}
        else:
            # Add to ungrouped
            self.inventory['all']['children']['ungrouped']['hosts'][hostname] = host_vars
    
    def save_inventory(self):
        """Save the generated inventory to a file."""
        try:
            # Create parent directory if it doesn't exist
            self.output_file.parent.mkdir(parents=True, exist_ok=True)
            
            # Determine output format based on file extension
            if self.output_file.suffix.lower() in ['.yml', '.yaml'] and YAML_AVAILABLE:
                with open(self.output_file, 'w') as f:
                    yaml.dump(self.inventory, f, default_flow_style=False)
            else:
                with open(self.output_file, 'w') as f:
                    json.dump(self.inventory, f, indent=2)
            
            print(f"Inventory saved to {self.output_file}")
            return True
        except Exception as e:
            print(f"Error saving inventory: {e}")
            return False

def main():
    parser = argparse.ArgumentParser(description="Generate Ansible inventory from discovered devices")
    parser.add_argument("--input-dir", "-i", default=str(DEFAULT_INPUT_DIR), 
                        help="Directory containing device discovery and assessment data")
    parser.add_argument("--output-file", "-o", default=None, 
                        help="Output file for the generated inventory (default: timestamped file in input directory)")
    
    args = parser.parse_args()
    
    # Create inventory generator
    generator = InventoryGenerator(input_dir=args.input_dir, output_file=args.output_file)
    
    # Load devices
    if not generator.load_discovered_devices():
        print("Failed to load discovered devices")
        sys.exit(1)
    
    # Generate inventory
    if not generator.generate_inventory():
        print("Failed to generate inventory")
        sys.exit(1)
    
    # Save inventory
    if not generator.save_inventory():
        print("Failed to save inventory")
        sys.exit(1)
    
    print("Inventory generation completed successfully")

if __name__ == "__main__":
    main() 