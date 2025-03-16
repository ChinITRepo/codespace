/**
 * Infrastructure Automation Framework - Tier 2: Log Management
 * 
 * This module deploys a centralized logging infrastructure including:
 * - Syslog server (rsyslog/syslog-ng)
 * - Log storage and rotation
 * - Log forwarding to monitoring systems
 */

locals {
  syslog_server_name = "${var.environment}-syslog-server"
  log_retention_days = var.log_retention_days > 0 ? var.log_retention_days : 30
}

# Syslog Server Instance
resource "aws_instance" "syslog_server" {
  count = var.cloud_provider == "aws" && var.deploy_syslog_server ? 1 : 0
  
  ami                    = var.aws_ami_id
  instance_type          = var.syslog_instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.syslog[0].id]
  key_name               = var.ssh_key_name
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.syslog_root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  # Additional EBS volume for log storage
  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_type           = "gp3"
    volume_size           = var.log_volume_size
    delete_on_termination = true
    encrypted             = true
  }
  
  user_data = templatefile("${path.module}/templates/syslog_setup.sh.tpl", {
    syslog_port        = var.syslog_port
    log_retention_days = local.log_retention_days
    log_mount_point    = var.log_mount_point
    forward_to_elk     = var.forward_logs_to_elk
    elk_host           = var.elk_host
    elk_port           = var.elk_port
  })
  
  tags = {
    Name        = local.syslog_server_name
    Environment = var.environment
    Tier        = "tier2-services"
    Component   = "log-management"
  }
}

# Security Group for Syslog Server
resource "aws_security_group" "syslog" {
  count = var.cloud_provider == "aws" && var.deploy_syslog_server ? 1 : 0
  
  name        = "${var.environment}-syslog-sg"
  description = "Security group for syslog server"
  vpc_id      = var.vpc_id
  
  # Syslog TCP
  ingress {
    from_port   = var.syslog_port
    to_port     = var.syslog_port
    protocol    = "tcp"
    cidr_blocks = var.syslog_allowed_cidrs
    description = "Syslog TCP"
  }
  
  # Syslog UDP
  ingress {
    from_port   = var.syslog_port
    to_port     = var.syslog_port
    protocol    = "udp"
    cidr_blocks = var.syslog_allowed_cidrs
    description = "Syslog UDP"
  }
  
  # SSH for management
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
    description = "SSH"
  }
  
  # HTTPS for Web UI (if enabled)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.admin_cidr_blocks
    description = "HTTPS for Web UI"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name        = "${var.environment}-syslog-sg"
    Environment = var.environment
    Tier        = "tier2-services"
    Component   = "log-management"
  }
}

# S3 Bucket for Log Archive (optional)
resource "aws_s3_bucket" "log_archive" {
  count = var.cloud_provider == "aws" && var.enable_log_archive ? 1 : 0
  
  bucket = "${var.environment}-${var.log_archive_bucket_name}"
  
  tags = {
    Name        = "${var.environment}-log-archive"
    Environment = var.environment
    Tier        = "tier2-services"
    Component   = "log-management"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "log_archive" {
  count = var.cloud_provider == "aws" && var.enable_log_archive ? 1 : 0
  
  bucket = aws_s3_bucket.log_archive[0].id
  
  rule {
    id      = "log-lifecycle"
    status  = "Enabled"
    
    expiration {
      days = var.log_archive_retention_days
    }
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_archive" {
  count = var.cloud_provider == "aws" && var.enable_log_archive ? 1 : 0
  
  bucket = aws_s3_bucket.log_archive[0].bucket
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudWatch Log Group for centralizing logs (optional)
resource "aws_cloudwatch_log_group" "central_logs" {
  count = var.cloud_provider == "aws" && var.enable_cloudwatch_logs ? 1 : 0
  
  name              = "/infra/${var.environment}/centralized-logs"
  retention_in_days = var.log_retention_days
  
  tags = {
    Name        = "${var.environment}-centralized-logs"
    Environment = var.environment
    Tier        = "tier2-services"
    Component   = "log-management"
  }
}

# Lambda function to forward logs to S3 (optional)
resource "aws_lambda_function" "log_forwarder" {
  count = var.cloud_provider == "aws" && var.enable_log_archive ? 1 : 0
  
  function_name    = "${var.environment}-log-forwarder"
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  role             = aws_iam_role.log_forwarder[0].arn
  timeout          = 300
  memory_size      = 256
  
  filename         = "${path.module}/files/log-forwarder.zip"
  source_code_hash = filebase64sha256("${path.module}/files/log-forwarder.zip")
  
  environment {
    variables = {
      LOG_BUCKET = aws_s3_bucket.log_archive[0].bucket
      PREFIX     = "logs/${var.environment}"
    }
  }
  
  tags = {
    Name        = "${var.environment}-log-forwarder"
    Environment = var.environment
    Tier        = "tier2-services"
    Component   = "log-management"
  }
}

# IAM Role for Lambda Log Forwarder
resource "aws_iam_role" "log_forwarder" {
  count = var.cloud_provider == "aws" && var.enable_log_archive ? 1 : 0
  
  name = "${var.environment}-log-forwarder-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name        = "${var.environment}-log-forwarder-role"
    Environment = var.environment
    Tier        = "tier2-services"
    Component   = "log-management"
  }
}

# IAM Policy for Lambda Log Forwarder
resource "aws_iam_policy" "log_forwarder" {
  count = var.cloud_provider == "aws" && var.enable_log_archive ? 1 : 0
  
  name        = "${var.environment}-log-forwarder-policy"
  description = "Policy for log forwarder Lambda function"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.log_archive[0].arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "log_forwarder" {
  count = var.cloud_provider == "aws" && var.enable_log_archive ? 1 : 0
  
  role       = aws_iam_role.log_forwarder[0].name
  policy_arn = aws_iam_policy.log_forwarder[0].arn
}

# Outputs
output "syslog_server_ip" {
  description = "Private IP address of the syslog server"
  value       = var.cloud_provider == "aws" && var.deploy_syslog_server ? aws_instance.syslog_server[0].private_ip : null
}

output "syslog_server_public_ip" {
  description = "Public IP address of the syslog server (if public IP is enabled)"
  value       = var.cloud_provider == "aws" && var.deploy_syslog_server ? aws_instance.syslog_server[0].public_ip : null
}

output "log_archive_bucket" {
  description = "S3 bucket for log archive"
  value       = var.cloud_provider == "aws" && var.enable_log_archive ? aws_s3_bucket.log_archive[0].bucket : null
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for centralized logs"
  value       = var.cloud_provider == "aws" && var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.central_logs[0].name : null
} 