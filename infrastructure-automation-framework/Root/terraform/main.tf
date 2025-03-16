/**
 * Infrastructure Automation Framework - Main Terraform Configuration
 * 
 * This is the entry point for Terraform-based infrastructure provisioning.
 * It defines provider configurations and includes modules for different tiers.
 */

terraform {
  required_version = ">= 1.0.0"
  
  # Uncomment this block to enable remote state storage
  # backend "s3" {
  #   bucket         = "infra-automation-tf-state"
  #   key            = "terraform.tfstate"
  #   region         = "us-west-2"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
  
  # Alternative Azure backend
  # backend "azurerm" {
  #   resource_group_name  = "infra-automation-rg"
  #   storage_account_name = "infraautomationsa"
  #   container_name       = "tfstate"
  #   key                  = "terraform.tfstate"
  # }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
  
  # Uncomment to use profile
  # profile = var.aws_profile
  
  # Default tags to apply to all AWS resources
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "Infrastructure Automation Framework"
      ManagedBy   = "Terraform"
    }
  }
}

# Azure Provider Configuration
provider "azurerm" {
  features {}
  
  # Uncomment and specify these values in terraform.tfvars or as environment variables
  # subscription_id = var.azure_subscription_id
  # tenant_id       = var.azure_tenant_id
}

# Google Cloud Provider Configuration
provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
  # credentials = file(var.gcp_credentials_file)
}

# Proxmox Provider Configuration - for on-premises virtualization
provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.proxmox_user
  # pm_password     = var.proxmox_password
  # pm_tls_insecure = true
}

# Vault Provider Configuration - for secret management
provider "vault" {
  address = var.vault_addr
  # token   = var.vault_token
}

# Include Tier 1 Core Infrastructure module
module "tier1_core" {
  source = "./modules/tier1-core"
  
  environment = var.environment
  # Additional variables will be passed here
}

# Include Tier 2 Essential Services module
module "tier2_services" {
  source = "./modules/tier2-services"
  
  environment = var.environment
  # Additional variables will be passed here
  
  # Make Tier 2 depend on Tier 1
  depends_on = [module.tier1_core]
}

# Include Tier 3 Application Services module
module "tier3_applications" {
  source = "./modules/tier3-applications"
  
  environment = var.environment
  # Additional variables will be passed here
  
  # Make Tier 3 depend on Tier 2
  depends_on = [module.tier2_services]
}

# Include Tier 4 Specialized Services module
module "tier4_specialized" {
  source = "./modules/tier4-specialized"
  
  environment = var.environment
  # Additional variables will be passed here
  
  # Make Tier 4 depend on Tier 3
  depends_on = [module.tier3_applications]
} 