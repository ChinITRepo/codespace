/**
 * Tier 1: Core Infrastructure Variables
 * 
 * Variables specific to the core infrastructure module.
 */

# General Variables
variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
}

variable "company_name" {
  description = "Company name for resource naming"
  type        = string
  default     = "company"
}

variable "project_name" {
  description = "Project name for tagging resources"
  type        = string
  default     = "infrastructure-automation"
}

variable "owner" {
  description = "Owner of the resources for tagging"
  type        = string
  default     = "infrastructure-team"
}

# Network Variables
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "database_subnet_cidrs" {
  description = "List of database subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.151.0/24", "10.0.152.0/24", "10.0.153.0/24"]
}

variable "enable_nat_gateway" {
  description = "Should NAT Gateways be created for private subnet outbound traffic"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Should only a single NAT Gateway be created for all private subnets"
  type        = bool
  default     = false
}

variable "enable_vpn_gateway" {
  description = "Should a VPN Gateway be created for VPN connections"
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Should VPC Flow Logs be enabled for network monitoring"
  type        = bool
  default     = true
}

# DNS Variables
variable "dns_zone" {
  description = "Private DNS zone name (e.g., example.internal)"
  type        = string
  default     = "example.internal"
}

variable "create_private_dns_zone" {
  description = "Should a private DNS zone be created"
  type        = bool
  default     = true
}

# Security Variables
variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed for administrative access"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair for EC2 instances"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 90
}

variable "enable_cloudtrail" {
  description = "Should CloudTrail be enabled for API activity tracking"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Should GuardDuty be enabled for threat detection"
  type        = bool
  default     = true
}

# Bastion Variables
variable "enable_bastion" {
  description = "Should a bastion host be deployed for secure SSH access"
  type        = bool
  default     = true
}

variable "bastion_instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "bastion_ami_id" {
  description = "AMI ID for the bastion host (leave empty for latest Amazon Linux)"
  type        = string
  default     = ""
} 