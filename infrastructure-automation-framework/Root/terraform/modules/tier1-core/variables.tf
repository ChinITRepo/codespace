/**
 * Infrastructure Automation Framework - Tier 1: Core Infrastructure Variables
 * 
 * Variables specific to the Tier 1 core infrastructure module.
 */

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
}

variable "cloud_provider" {
  description = "Cloud provider to use (aws, azure, gcp, or none for on-prem)"
  type        = string
  default     = "aws"
  
  validation {
    condition     = contains(["aws", "azure", "gcp", "none"], var.cloud_provider)
    error_message = "Valid values for cloud_provider are: aws, azure, gcp, or none."
  }
}

# Networking variables
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to deploy resources"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed to access admin interfaces"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Change this for production
}

# Storage variables
variable "create_object_storage" {
  description = "Whether to create an object storage bucket"
  type        = bool
  default     = true
}

variable "storage_bucket_name" {
  description = "Name of the object storage bucket"
  type        = string
  default     = "infra-automation-storage"
}

# Virtualization variables
variable "deploy_virtualization_hosts" {
  description = "Whether to deploy virtualization hosts"
  type        = bool
  default     = false
}

variable "virtualization_host_count" {
  description = "Number of virtualization hosts to deploy"
  type        = number
  default     = 1
}

variable "aws_ami_id" {
  description = "AMI ID for virtualization hosts (AWS)"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"  # Default Ubuntu AMI, replace with appropriate value
}

variable "virtualization_instance_type" {
  description = "Instance type for virtualization hosts"
  type        = string
  default     = "t3.large"
}

variable "virtualization_root_volume_size" {
  description = "Root volume size for virtualization hosts (in GB)"
  type        = number
  default     = 100
}

variable "virtualization_security_group_id" {
  description = "Security group ID for virtualization hosts"
  type        = string
  default     = ""
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair for instance access"
  type        = string
  default     = ""
}

# On-premises variables
variable "proxmox_node" {
  description = "Proxmox node to deploy VMs"
  type        = string
  default     = "pve"
}

variable "proxmox_storage" {
  description = "Proxmox storage to use for VMs"
  type        = string
  default     = "local-lvm"
}

# Security variables
variable "enable_vpn" {
  description = "Whether to deploy a VPN server"
  type        = bool
  default     = true
}

variable "vpn_protocol" {
  description = "VPN protocol to use (openvpn or wireguard)"
  type        = string
  default     = "openvpn"
  
  validation {
    condition     = contains(["openvpn", "wireguard"], var.vpn_protocol)
    error_message = "Valid values for vpn_protocol are: openvpn or wireguard."
  }
}

# Firewall variables
variable "enable_firewall" {
  description = "Whether to deploy a firewall"
  type        = bool
  default     = true
}

variable "open_ports" {
  description = "Ports to open on the firewall"
  type        = map(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default     = {
    ssh = {
      port        = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH"
    }
  }
} 