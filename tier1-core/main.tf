/**
 * Tier 1: Core Infrastructure
 * 
 * This module deploys the foundational infrastructure components including
 * networking, security baseline, and essential infrastructure services.
 */

# Provider configuration is inherited from the root module

# Local variables for resource naming and tags
locals {
  name_prefix = "${var.environment}-${var.company_name}"
  
  common_tags = {
    Environment     = var.environment
    Tier            = "tier1-core"
    ManagedBy       = "terraform"
    Project         = var.project_name
    Owner           = var.owner
  }
}

# VPC and Networking
module "vpc" {
  source = "../terraform/modules/vpc"

  name                 = "${local.name_prefix}-vpc"
  cidr                 = var.vpc_cidr
  azs                  = var.availability_zones
  private_subnets      = var.private_subnet_cidrs
  public_subnets       = var.public_subnet_cidrs
  database_subnets     = var.database_subnet_cidrs
  
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_vpn_gateway   = var.enable_vpn_gateway
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  enable_flow_log                  = var.enable_vpc_flow_logs
  flow_log_destination_type        = "s3"
  flow_log_destination_arn         = aws_s3_bucket.logs.arn
  flow_log_traffic_type            = "ALL"
  flow_log_max_aggregation_interval = 60
  
  tags = merge(local.common_tags, {
    Component = "networking"
  })
}

# Central Log Bucket
resource "aws_s3_bucket" "logs" {
  bucket = "${local.name_prefix}-logs"
  
  tags = merge(local.common_tags, {
    Component = "logging"
  })
}

# Bucket policies and settings
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "log-lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = var.log_retention_days
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Security Groups

# Bastion Host Security Group
resource "aws_security_group" "bastion" {
  count = var.enable_bastion ? 1 : 0
  
  name        = "${local.name_prefix}-bastion-sg"
  description = "Security group for bastion hosts"
  vpc_id      = module.vpc.vpc_id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
    description = "SSH from admin IPs"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = merge(local.common_tags, {
    Component = "security"
    Name      = "${local.name_prefix}-bastion-sg"
  })
}

# Internal Access Security Group
resource "aws_security_group" "internal" {
  name        = "${local.name_prefix}-internal-sg"
  description = "Security group for internal resources"
  vpc_id      = module.vpc.vpc_id
  
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow all traffic between resources with this security group"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = merge(local.common_tags, {
    Component = "security"
    Name      = "${local.name_prefix}-internal-sg"
  })
}

# KMS Key for Encryption
resource "aws_kms_key" "main" {
  description             = "${local.name_prefix} main encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  tags = merge(local.common_tags, {
    Component = "security"
    Name      = "${local.name_prefix}-main-kms-key"
  })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${local.name_prefix}-main"
  target_key_id = aws_kms_key.main.key_id
}

# DNS Zone (if requested)
resource "aws_route53_zone" "private" {
  count = var.create_private_dns_zone ? 1 : 0
  
  name = var.dns_zone
  
  vpc {
    vpc_id = module.vpc.vpc_id
  }
  
  tags = merge(local.common_tags, {
    Component = "dns"
    Name      = "${local.name_prefix}-private-zone"
  })
}

# Bastion Host (if enabled)
resource "aws_instance" "bastion" {
  count = var.enable_bastion ? 1 : 0
  
  ami                    = var.bastion_ami_id != "" ? var.bastion_ami_id : data.aws_ami.amazon_linux[0].id
  instance_type          = var.bastion_instance_type
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion[0].id]
  key_name               = var.ssh_key_name
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = aws_kms_key.main.arn
  }
  
  user_data = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname bastion.${var.dns_zone}
    yum update -y
    yum install -y amazon-cloudwatch-agent
    echo "Setting up bastion host..."
  EOF
  
  tags = merge(local.common_tags, {
    Component = "bastion"
    Name      = "${local.name_prefix}-bastion"
  })
}

# Latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  count = var.enable_bastion ? 1 : 0
  
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# CloudTrail for Auditing
resource "aws_cloudtrail" "main" {
  count = var.enable_cloudtrail ? 1 : 0
  
  name                          = "${local.name_prefix}-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.logs.id
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  
  event_selector {
    read_write_type           = "All"
    include_management_events = true
    
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }
  
  tags = merge(local.common_tags, {
    Component = "security"
    Name      = "${local.name_prefix}-cloudtrail"
  })
}

# Central Configuration Storage for Infrastructure
resource "aws_s3_bucket" "config" {
  bucket = "${local.name_prefix}-config"
  
  tags = merge(local.common_tags, {
    Component = "configuration"
  })
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config.bucket
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.main.arn
    }
  }
}

# GuardDuty for Threat Detection (if enabled)
resource "aws_guardduty_detector" "main" {
  count = var.enable_guardduty ? 1 : 0
  
  enable = true
  
  finding_publishing_frequency = "SIX_HOURS"
  
  tags = merge(local.common_tags, {
    Component = "security"
    Name      = "${local.name_prefix}-guardduty"
  })
} 