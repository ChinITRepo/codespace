/**
 * Infrastructure Automation Framework - Tier 2: Essential Services
 * 
 * This module deploys essential services including:
 * - Log Management (Syslog, Log Archives)
 * - Monitoring (Prometheus, Grafana)
 * - Identity Management
 * - Secret Management (Vault)
 */

# Get the first private subnet ID from Tier 1
locals {
  subnet_id = length(var.private_subnet_ids) > 0 ? var.private_subnet_ids[0] : ""
}

# Log Management Submodule
module "log_management" {
  source = "./log_management"
  
  # Pass through variables
  environment         = var.environment
  cloud_provider      = var.cloud_provider
  vpc_id              = var.vpc_id
  subnet_id           = local.subnet_id
  admin_cidr_blocks   = var.admin_cidr_blocks
  
  # Log management specific variables
  deploy_syslog_server        = var.deploy_syslog_server
  syslog_instance_type        = var.syslog_instance_type
  log_retention_days          = var.log_retention_days
  enable_log_archive          = var.enable_log_archive
  log_archive_bucket_name     = "${var.environment}-${var.log_archive_bucket_name}"
  log_archive_retention_days  = var.log_archive_retention_days
  enable_cloudwatch_logs      = var.enable_cloudwatch_logs
  
  # Conditional variables
  aws_ami_id          = var.cloud_provider == "aws" ? var.aws_ami_id : ""
  ssh_key_name        = var.cloud_provider == "aws" ? var.ssh_key_name : ""
  
  # ELK integration
  forward_logs_to_elk = var.enable_elk_stack
  elk_host            = var.elk_host
  elk_port            = var.elk_port
}

# Monitoring submodule will be added here
# module "monitoring" {
#   source = "./monitoring"
#   ...
# }

# Identity Management submodule will be added here
# module "identity" {
#   source = "./identity"
#   ...
# }

# Secret Management submodule will be added here
# module "secrets" {
#   source = "./secrets"
#   ...
# }

# Outputs
output "syslog_server_ip" {
  description = "Private IP address of the syslog server"
  value       = module.log_management.syslog_server_ip
}

output "log_archive_bucket" {
  description = "S3 bucket for log archive"
  value       = module.log_management.log_archive_bucket
} 