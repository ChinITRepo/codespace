#!/usr/bin/env python3
"""
Network Discovery Script for Infrastructure Automation Framework

This script performs network discovery operations using various methods:
1. Nmap scanning for device identification
2. ARP table analysis
3. DHCP lease querying

Results are formatted as structured data for integration with the automation framework.
"""

import os
import sys
import json
import argparse
import ipaddress
import subprocess
import socket
import datetime
from pathlib import Path

# Try to import optional dependencies
try:
    import nmap
    NMAP_AVAILABLE = True
except ImportError:
    NMAP_AVAILABLE = False
    print("Warning: python-nmap not installed, some scanning functionality will be limited")

try:
    import scapy.all as scapy
    SCAPY_AVAILABLE = True
except ImportError:
    SCAPY_AVAILABLE = False
    print("Warning: scapy not installed, ARP scanning will not be available")

# Constants
DEFAULT_OUTPUT_DIR = Path(__file__).parent.parent / "device_inventory"
DEFAULT_SUBNET = "192.168.1.0/24"  # Default subnet to scan
COMMON_PORTS = [22, 80, 443, 3389, 5985, 5986, 8080]  # Common service ports

class NetworkDiscovery:
    """Network discovery class that provides methods for identifying devices on a network."""
    
    def __init__(self, subnet=DEFAULT_SUBNET, output_dir=DEFAULT_OUTPUT_DIR):
        """
        Initialize the NetworkDiscovery class.
        
        Args:
            subnet (str): The subnet to scan in CIDR notation (e.g., "192.168.1.0/24")
            output_dir (Path): Directory to save discovery results
        """
        self.subnet = subnet
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.discovered_devices = []
    
    def scan_with_nmap(self, ports=None):
        """
        Scan the network using Nmap.
        
        Args:
            ports (list): List of ports to scan. Defaults to COMMON_PORTS.
        
        Returns:
            list: List of discovered devices with their details
        """
        if not NMAP_AVAILABLE:
            print("Error: Nmap scanning requires python-nmap package")
            return []
        
        ports_to_scan = ports if ports else COMMON_PORTS
        ports_str = ",".join(map(str, ports_to_scan))
        
        try:
            print(f"Starting Nmap scan on subnet {self.subnet} for ports {ports_str}")
            scanner = nmap.PortScanner()
            scanner.scan(hosts=self.subnet, arguments=f'-sS -p {ports_str} -O --osscan-guess')
            
            for host in scanner.all_hosts():
                device_info = {
                    'ip_address': host,
                    'hostname': scanner[host].hostname() if scanner[host].hostname() else "Unknown",
                    'mac_address': scanner[host]['addresses'].get('mac', "Unknown"),
                    'os': self._get_os_details(scanner, host),
                    'open_ports': self._get_open_ports(scanner, host),
                    'discovery_method': 'nmap',
                    'timestamp': datetime.datetime.now().isoformat()
                }
                self.discovered_devices.append(device_info)
                
            return self.discovered_devices
        
        except Exception as e:
            print(f"Error during Nmap scan: {e}")
            return []
    
    def scan_with_arp(self):
        """
        Perform an ARP scan on the network.
        
        Returns:
            list: List of discovered devices
        """
        if not SCAPY_AVAILABLE:
            print("Error: ARP scanning requires scapy package")
            return []
        
        try:
            print(f"Starting ARP scan on subnet {self.subnet}")
            network = ipaddress.IPv4Network(self.subnet)
            
            for ip in network.hosts():
                ip_str = str(ip)
                
                # Skip network and broadcast addresses
                if ip == network.network_address or ip == network.broadcast_address:
                    continue
                
                arp_request = scapy.ARP(pdst=ip_str)
                broadcast = scapy.Ether(dst="ff:ff:ff:ff:ff:ff")
                packet = broadcast/arp_request
                
                result = scapy.srp(packet, timeout=1, verbose=0)[0]
                
                for sent, received in result:
                    mac_address = received.hwsrc
                    try:
                        hostname = socket.gethostbyaddr(ip_str)[0]
                    except socket.herror:
                        hostname = "Unknown"
                    
                    device_info = {
                        'ip_address': ip_str,
                        'hostname': hostname,
                        'mac_address': mac_address,
                        'discovery_method': 'arp',
                        'timestamp': datetime.datetime.now().isoformat()
                    }
                    self.discovered_devices.append(device_info)
            
            return self.discovered_devices
        
        except Exception as e:
            print(f"Error during ARP scan: {e}")
            return []
    
    def get_dhcp_leases(self, dhcp_lease_file=None):
        """
        Get DHCP leases from a DHCP server.
        
        Args:
            dhcp_lease_file (str): Path to the DHCP leases file.
                For Windows, this will use netsh.
                For Linux, this defaults to /var/lib/dhcp/dhcpd.leases
        
        Returns:
            list: List of devices with DHCP leases
        """
        if sys.platform.startswith('win'):
            return self._get_windows_dhcp_leases()
        else:
            return self._get_linux_dhcp_leases(dhcp_lease_file)
    
    def save_results(self, filename=None):
        """
        Save discovery results to a JSON file.
        
        Args:
            filename (str): Name of the file to save results to
                If None, a timestamped filename will be used
        
        Returns:
            Path: Path to the saved file
        """
        if not filename:
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"network_discovery_{timestamp}.json"
        
        output_path = self.output_dir / filename
        
        with open(output_path, 'w') as f:
            json.dump(self.discovered_devices, f, indent=2)
        
        print(f"Discovery results saved to {output_path}")
        return output_path
    
    def _get_os_details(self, scanner, host):
        """Extract OS details from Nmap scan results."""
        try:
            if 'osmatch' in scanner[host]:
                matches = scanner[host]['osmatch']
                if matches:
                    return {
                        'name': matches[0]['name'],
                        'accuracy': matches[0]['accuracy'],
                        'matches': [m['name'] for m in matches[:3]]
                    }
            return {"name": "Unknown", "accuracy": "0", "matches": []}
        except (KeyError, IndexError):
            return {"name": "Unknown", "accuracy": "0", "matches": []}
    
    def _get_open_ports(self, scanner, host):
        """Extract open ports and services from Nmap scan results."""
        open_ports = []
        try:
            for proto in scanner[host].all_protocols():
                ports = scanner[host][proto].keys()
                for port in ports:
                    if scanner[host][proto][port]['state'] == 'open':
                        open_ports.append({
                            'port': port,
                            'protocol': proto,
                            'service': scanner[host][proto][port]['name'],
                            'product': scanner[host][proto][port].get('product', '')
                        })
            return open_ports
        except (KeyError, IndexError):
            return []
    
    def _get_windows_dhcp_leases(self):
        """Get DHCP leases on Windows using netsh."""
        try:
            result = subprocess.run(
                ["netsh", "dhcp", "server", "\\\\localhost", "scope", "all", "show", "clients"], 
                capture_output=True, 
                text=True
            )
            
            if result.returncode != 0:
                print(f"Error getting DHCP leases: {result.stderr}")
                return []
            
            # Parse netsh output
            lines = result.stdout.splitlines()
            devices = []
            
            for line in lines:
                if line.strip() and not line.startswith('-') and 'Client IP Address' not in line:
                    parts = line.split()
                    if len(parts) >= 3:
                        device_info = {
                            'ip_address': parts[0],
                            'mac_address': parts[1],
                            'hostname': parts[2] if len(parts) > 2 else "Unknown",
                            'discovery_method': 'dhcp',
                            'timestamp': datetime.datetime.now().isoformat()
                        }
                        devices.append(device_info)
            
            self.discovered_devices.extend(devices)
            return devices
            
        except Exception as e:
            print(f"Error getting Windows DHCP leases: {e}")
            return []
    
    def _get_linux_dhcp_leases(self, lease_file=None):
        """Get DHCP leases on Linux from the lease file."""
        if not lease_file:
            # Common locations of DHCP lease files
            possible_paths = [
                "/var/lib/dhcp/dhcpd.leases",
                "/var/lib/dhcpd/dhcpd.leases",
                "/var/lib/misc/dhcpd.leases"
            ]
            
            for path in possible_paths:
                if os.path.exists(path):
                    lease_file = path
                    break
        
        if not lease_file or not os.path.exists(lease_file):
            print(f"DHCP lease file not found")
            return []
        
        try:
            # This is a simplified parser and might need adjustment based on the lease file format
            with open(lease_file, 'r') as f:
                content = f.read()
            
            # Simple parsing of the lease file
            leases = content.split("lease ")
            devices = []
            
            for lease in leases[1:]:  # Skip the first element which is empty
                lines = lease.split("\n")
                ip = lines[0].split(" ")[0] if lines and " " in lines[0] else None
                
                mac = None
                hostname = None
                
                for line in lines:
                    line = line.strip()
                    if "hardware ethernet" in line:
                        mac = line.split(" ")[-1].rstrip(";")
                    elif "client-hostname" in line:
                        hostname = line.split(" ")[-1].strip('";')
                
                if ip and mac:
                    device_info = {
                        'ip_address': ip,
                        'mac_address': mac,
                        'hostname': hostname if hostname else "Unknown",
                        'discovery_method': 'dhcp',
                        'timestamp': datetime.datetime.now().isoformat()
                    }
                    devices.append(device_info)
            
            self.discovered_devices.extend(devices)
            return devices
                
        except Exception as e:
            print(f"Error parsing DHCP lease file: {e}")
            return []

def main():
    parser = argparse.ArgumentParser(description="Network discovery tool for infrastructure automation")
    parser.add_argument("--subnet", "-s", default=DEFAULT_SUBNET, help="Subnet to scan in CIDR notation")
    parser.add_argument("--output-dir", "-o", default=str(DEFAULT_OUTPUT_DIR), help="Directory to save results")
    parser.add_argument("--nmap", action="store_true", help="Perform Nmap scan")
    parser.add_argument("--arp", action="store_true", help="Perform ARP scan")
    parser.add_argument("--dhcp", action="store_true", help="Get DHCP leases")
    parser.add_argument("--dhcp-file", help="Path to DHCP lease file (Linux only)")
    parser.add_argument("--all", "-a", action="store_true", help="Perform all discovery methods")
    parser.add_argument("--ports", help="Comma-separated list of ports to scan with Nmap")
    
    args = parser.parse_args()
    
    # Create discovery object
    discovery = NetworkDiscovery(subnet=args.subnet, output_dir=args.output_dir)
    
    # Determine which scans to run
    run_nmap = args.nmap or args.all
    run_arp = args.arp or args.all
    run_dhcp = args.dhcp or args.all
    
    # Parse ports if specified
    ports = None
    if args.ports:
        try:
            ports = [int(p) for p in args.ports.split(',')]
        except ValueError:
            print("Error: Ports must be comma-separated integers")
            sys.exit(1)
    
    # Run selected discovery methods
    if run_nmap:
        discovery.scan_with_nmap(ports=ports)
    
    if run_arp:
        discovery.scan_with_arp()
    
    if run_dhcp:
        discovery.get_dhcp_leases(args.dhcp_file)
    
    # If no methods were specified, show help
    if not any([run_nmap, run_arp, run_dhcp]):
        parser.print_help()
        return
    
    # Save results
    if discovery.discovered_devices:
        discovery.save_results()
    else:
        print("No devices discovered")

if __name__ == "__main__":
    main() 