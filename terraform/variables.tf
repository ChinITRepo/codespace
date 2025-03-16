/**
 * Infrastructure Automation Framework - Terraform Variables
 * 
 * This file defines all variables used across the Terraform configurations.
 */

# General variables
variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  default     = "dev"
}

# AWS variables
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication"
  type        = string
  default     = "default"
}

# Azure variables
variable "azure_location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "eastus"
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
  default     = ""
  sensitive   = true
}

# Google Cloud variables
variable "gcp_project" {
  description = "Google Cloud project ID"
  type        = string
  default     = ""
}

variable "gcp_region" {
  description = "Google Cloud region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "gcp_credentials_file" {
  description = "Path to Google Cloud credentials file"
  type        = string
  default     = "~/.gcp/credentials.json"
  sensitive   = true
}

# Proxmox variables
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://proxmox.example.com:8006/api2/json"
}

variable "proxmox_user" {
  description = "Proxmox API user"
  type        = string
  default     = "terraform@pve"
}

variable "proxmox_password" {
  description = "Proxmox API password"
  type        = string
  default     = ""
  sensitive   = true
}

# Vault variables
variable "vault_addr" {
  description = "HashiCorp Vault server address"
  type        = string
  default     = "https://vault.example.com:8200"
}

variable "vault_token" {
  description = "HashiCorp Vault authentication token"
  type        = string
  default     = ""
  sensitive   = true
}

# Networking variables
variable "vpc_cidr" {
  description = "CIDR block for the VPC (AWS) or VNet (Azure)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "CIDR blocks for subnets"
  type        = map(string)
  default     = {
    public1  = "10.0.1.0/24"
    public2  = "10.0.2.0/24"
    private1 = "10.0.10.0/24"
    private2 = "10.0.11.0/24"
    data1    = "10.0.20.0/24"
    data2    = "10.0.21.0/24"
  }
}

# Compute variables
variable "instance_types" {
  description = "Instance types for different service tiers"
  type        = map(string)
  default     = {
    small  = "t3.small"   # or equivalent
    medium = "t3.medium"  # or equivalent
    large  = "t3.large"   # or equivalent
    xlarge = "t3.xlarge"  # or equivalent
  }
}

# Storage variables
variable "storage_sizes" {
  description = "Storage sizes in GB for different service tiers"
  type        = map(number)
  default     = {
    small  = 20
    medium = 50
    large  = 100
    xlarge = 200
  }
}

# Security variables
variable "allowed_ips" {
  description = "List of IP addresses or CIDR blocks allowed to access management interfaces"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # WARNING: This allows all IP addresses, change for production
}

# Domain and DNS variables
variable "domain_name" {
  description = "Base domain name for services"
  type        = string
  default     = "example.com"
}

variable "enable_dns" {
  description = "Enable DNS zone management"
  type        = bool
  default     = false
}

# Monitoring variables
variable "enable_monitoring" {
  description = "Enable monitoring stack deployment"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable logging stack deployment"
  type        = bool
  default     = true
}

# High availability variables
variable "enable_ha" {
  description = "Enable high-availability configurations"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Deploy resources across multiple availability zones"
  type        = bool
  default     = false
} 