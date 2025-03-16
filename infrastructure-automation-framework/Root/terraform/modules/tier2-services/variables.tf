/**
 * Infrastructure Automation Framework - Tier 2: Essential Services Variables
 * 
 * Variables specific to the Tier 2 essential services module.
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

# Network variables - passed from Tier 1
variable "vpc_id" {
  description = "ID of the VPC where resources will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where services will be deployed"
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where public-facing services will be deployed"
  type        = list(string)
  default     = []
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed to access administrative interfaces"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production
}

# AWS specific variables
variable "aws_ami_id" {
  description = "AMI ID for service instances (if not specified, latest Ubuntu LTS will be used)"
  type        = string
  default     = ""
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair for instance access"
  type        = string
  default     = ""
}

# Log Management variables
variable "deploy_syslog_server" {
  description = "Whether to deploy a dedicated syslog server"
  type        = bool
  default     = true
}

variable "syslog_instance_type" {
  description = "Instance type for the syslog server"
  type        = string
  default     = "t3.medium"
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "enable_log_archive" {
  description = "Whether to enable log archiving to S3"
  type        = bool
  default     = true
}

variable "log_archive_bucket_name" {
  description = "Base name of the S3 bucket for log archive"
  type        = string
  default     = "log-archive"
}

variable "log_archive_retention_days" {
  description = "Number of days to retain logs in the archive"
  type        = number
  default     = 365  # 1 year
}

variable "enable_cloudwatch_logs" {
  description = "Whether to enable CloudWatch Logs integration"
  type        = bool
  default     = true
}

# ELK Stack variables
variable "enable_elk_stack" {
  description = "Whether to enable an ELK stack for log aggregation"
  type        = bool
  default     = false
}

variable "elk_host" {
  description = "Hostname or IP address of the ELK stack"
  type        = string
  default     = ""
}

variable "elk_port" {
  description = "Port of the ELK stack"
  type        = number
  default     = 5044
}

# Monitoring variables
variable "deploy_monitoring" {
  description = "Whether to deploy monitoring services (Prometheus, Grafana)"
  type        = bool
  default     = true
}

variable "monitoring_instance_type" {
  description = "Instance type for monitoring services"
  type        = string
  default     = "t3.medium"
}

variable "alert_email" {
  description = "Email address to send monitoring alerts to"
  type        = string
  default     = ""
}

# Identity Management variables
variable "deploy_identity_management" {
  description = "Whether to deploy identity management services"
  type        = bool
  default     = false
}

variable "identity_provider" {
  description = "Identity provider to use (keycloak, openldap)"
  type        = string
  default     = "keycloak"
  
  validation {
    condition     = contains(["keycloak", "openldap", "none"], var.identity_provider)
    error_message = "Valid values for identity_provider are: keycloak, openldap, or none."
  }
}

# Secret Management variables
variable "deploy_vault" {
  description = "Whether to deploy HashiCorp Vault for secret management"
  type        = bool
  default     = false
}

variable "vault_instance_type" {
  description = "Instance type for Vault server"
  type        = string
  default     = "t3.small"
}

variable "vault_storage_backend" {
  description = "Storage backend for Vault (file, consul, dynamodb)"
  type        = string
  default     = "file"
  
  validation {
    condition     = contains(["file", "consul", "dynamodb", "s3"], var.vault_storage_backend)
    error_message = "Valid values for vault_storage_backend are: file, consul, dynamodb, or s3."
  }
} 