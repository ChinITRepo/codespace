/**
 * Infrastructure Automation Framework - Tier 1: Core Infrastructure
 * 
 * This module deploys the core infrastructure components including:
 * - Networking (VPN, VLANs, Firewalls)
 * - Storage (NAS, SAN, Object Storage)
 * - Virtualization (Proxmox, VMware, Hyper-V)
 * - Security (RADIUS, LDAP, Certificates)
 */

# Networking components
resource "aws_vpc" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name        = "${var.environment}-vpc"
    Tier        = "tier1-core"
    Component   = "networking"
  }
}

resource "aws_subnet" "public" {
  count = var.cloud_provider == "aws" ? length(var.public_subnet_cidrs) : 0
  
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "${var.environment}-public-subnet-${count.index + 1}"
    Tier        = "tier1-core"
    Component   = "networking"
    Subnet      = "public"
  }
}

resource "aws_subnet" "private" {
  count = var.cloud_provider == "aws" ? length(var.private_subnet_cidrs) : 0
  
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false
  
  tags = {
    Name        = "${var.environment}-private-subnet-${count.index + 1}"
    Tier        = "tier1-core"
    Component   = "networking"
    Subnet      = "private"
  }
}

# Security components
resource "aws_security_group" "vpn" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  name        = "${var.environment}-vpn-sg"
  description = "Security group for VPN server"
  vpc_id      = aws_vpc.main[0].id
  
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "OpenVPN"
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
    description = "SSH"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name        = "${var.environment}-vpn-sg"
    Tier        = "tier1-core"
    Component   = "security"
  }
}

# Storage components
resource "aws_s3_bucket" "object_storage" {
  count = var.cloud_provider == "aws" && var.create_object_storage ? 1 : 0
  
  bucket = "${var.environment}-${var.storage_bucket_name}"
  
  tags = {
    Name        = "${var.environment}-object-storage"
    Tier        = "tier1-core"
    Component   = "storage"
  }
}

resource "aws_s3_bucket_versioning" "object_storage" {
  count = var.cloud_provider == "aws" && var.create_object_storage ? 1 : 0
  
  bucket = aws_s3_bucket.object_storage[0].bucket
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "object_storage" {
  count = var.cloud_provider == "aws" && var.create_object_storage ? 1 : 0
  
  bucket = aws_s3_bucket.object_storage[0].bucket
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Virtualization components
# For on-premises deployments, Proxmox nodes would be defined here
# Below is a placeholder for a Proxmox VM template

# For cloud providers, this might be instance templates
resource "aws_instance" "virtualization_host" {
  count = var.cloud_provider == "aws" && var.deploy_virtualization_hosts ? var.virtualization_host_count : 0
  
  ami                    = var.aws_ami_id
  instance_type          = var.virtualization_instance_type
  subnet_id              = aws_subnet.private[count.index % length(aws_subnet.private)].id
  vpc_security_group_ids = [var.virtualization_security_group_id]
  key_name               = var.ssh_key_name
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.virtualization_root_volume_size
    delete_on_termination = true
    encrypted             = true
  }
  
  tags = {
    Name        = "${var.environment}-virtualization-host-${count.index + 1}"
    Tier        = "tier1-core"
    Component   = "virtualization"
  }
}

# Outputs to be used in other tiers
output "vpc_id" {
  description = "ID of the created VPC"
  value       = var.cloud_provider == "aws" ? aws_vpc.main[0].id : null
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = var.cloud_provider == "aws" ? aws_subnet.public[*].id : null
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = var.cloud_provider == "aws" ? aws_subnet.private[*].id : null
}

output "object_storage_bucket" {
  description = "Name of the object storage bucket"
  value       = var.cloud_provider == "aws" && var.create_object_storage ? aws_s3_bucket.object_storage[0].bucket : null
} 