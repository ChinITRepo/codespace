# Tier 1: Core Infrastructure

This module is responsible for deploying the fundamental infrastructure components that form the foundation of the environment. It includes core networking, security baseline, and essential infrastructure services.

## Components

### Networking

- **VPC and Subnets**: Multi-AZ VPC architecture with public, private, and data subnets
- **Routing**: Route tables, Internet Gateway, and NAT Gateways for secure outbound connectivity
- **Security Groups**: Base security group templates with least-privilege rules
- **VPN Configuration**: Site-to-site and client VPN options for secure remote access

### Security Baseline

- **IAM Policies**: Least-privilege role configurations for infrastructure components
- **Key Management**: KMS key infrastructure for data encryption
- **Security Monitoring**: Initial CloudTrail and GuardDuty configuration
- **Compliance**: Automated validation of security baselines

### Core Infrastructure Services

- **DNS Infrastructure**: Route 53 configuration for internal and external DNS resolution
- **Shared Storage**: S3 buckets for configuration, backups, and shared data
- **State Management**: Remote state storage for Terraform state files
- **Bastion Hosts**: Jump servers for secure administration

## Usage

```hcl
module "tier1_core" {
  source = "../modules/tier1-core"

  environment             = "dev"
  region                  = "us-east-1"
  vpc_cidr                = "10.0.0.0/16"
  availability_zones      = ["us-east-1a", "us-east-1b", "us-east-1c"]
  enable_vpn              = true
  enable_bastion          = true
  company_name            = "example"
  dns_zone                = "example.internal"
}
```

## Dependencies

The Tier 1 Core Infrastructure requires:

1. AWS account with appropriate permissions
2. Terraform >= 1.0.0
3. AWS provider >= 4.0.0

## Security Considerations

This module establishes the security foundations for your infrastructure:

- All resources are deployed with encryption enabled
- Network segmentation with security groups and NACLs
- VPC Flow Logs and CloudTrail enabled for audit purposes
- Secure by default - least privilege principle applied

## Customization

You can customize this module by:

1. Adjusting the VPC CIDR and subnet allocations
2. Modifying security group rules for your specific requirements
3. Adding additional Route 53 DNS records
4. Configuring IAM roles for specific service needs 