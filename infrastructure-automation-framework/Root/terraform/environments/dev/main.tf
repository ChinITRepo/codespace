/**
 * Infrastructure Automation Framework - Dev Environment
 * 
 * This is the main configuration for the dev environment.
 */

# Use the root module configuration
module "root" {
  source = "../../"
  
  # Environment-specific variables
  environment = "dev"
  
  # Cloud provider settings
  cloud_provider = "aws"  # or "azure", "gcp", "none"
  aws_region     = "us-west-2"
  
  # Network settings
  vpc_cidr = "10.0.0.0/16"
  
  # Compute settings
  instance_types = {
    small  = "t3.small"
    medium = "t3.medium"
    large  = "t3.large"
    xlarge = "t3.xlarge"
  }
  
  # Storage settings
  storage_sizes = {
    small  = 20
    medium = 50
    large  = 100
    xlarge = 200
  }
  
  # Security settings
  allowed_ips = ["0.0.0.0/0"]  # Restrict this in production!
  
  # Domain settings
  domain_name = "dev.example.com"
  
  # Feature flags
  enable_monitoring = true
  enable_logging    = true
  enable_ha         = false
  multi_az          = false
} 