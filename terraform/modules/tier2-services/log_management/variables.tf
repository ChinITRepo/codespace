/**
 * Infrastructure Automation Framework - Tier 2: Log Management Variables
 * 
 * Variables specific to the log management module.
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

# Network variables
variable "vpc_id" {
  description = "ID of the VPC where resources will be deployed"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "ID of the subnet where the syslog server will be deployed"
  type        = string
  default     = ""
}

# Syslog server variables
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

variable "syslog_root_volume_size" {
  description = "Root volume size in GB for the syslog server"
  type        = number
  default     = 20
}

variable "log_volume_size" {
  description = "Size in GB for the dedicated log volume"
  type        = number
  default     = 100
}

variable "syslog_port" {
  description = "Port to use for syslog traffic"
  type        = number
  default     = 514
}

variable "syslog_allowed_cidrs" {
  description = "CIDR blocks allowed to send logs to the syslog server"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed to access administrative interfaces"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production
}

variable "log_retention_days" {
  description = "Number of days to retain logs on the syslog server"
  type        = number
  default     = 30
}

variable "log_mount_point" {
  description = "Mount point for the log volume"
  type        = string
  default     = "/var/log"
}

# AWS specific variables
variable "aws_ami_id" {
  description = "AMI ID for the syslog server"
  type        = string
  default     = ""  # Will default to latest Ubuntu server AMI
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair for instance access"
  type        = string
  default     = ""
}

# Log archive variables
variable "enable_log_archive" {
  description = "Whether to enable log archiving to S3"
  type        = bool
  default     = true
}

variable "log_archive_bucket_name" {
  description = "Name of the S3 bucket for log archive"
  type        = string
  default     = "log-archive"
}

variable "log_archive_retention_days" {
  description = "Number of days to retain logs in the archive"
  type        = number
  default     = 365  # 1 year
}

# CloudWatch logs variables
variable "enable_cloudwatch_logs" {
  description = "Whether to enable CloudWatch Logs integration"
  type        = bool
  default     = true
}

# ELK integration variables
variable "forward_logs_to_elk" {
  description = "Whether to forward logs to an ELK stack"
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