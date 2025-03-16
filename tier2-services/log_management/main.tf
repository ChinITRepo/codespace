/**
 * Infrastructure Automation Framework - Tier 2: Log Management
 * 
 * This module deploys a centralized logging infrastructure including:
 * - Syslog server (rsyslog/syslog-ng)
 * - Log storage and rotation
 * - Log forwarding to monitoring systems
 * - CloudWatch dashboards and alerts
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

# CloudWatch Dashboard for log monitoring
resource "aws_cloudwatch_dashboard" "logs_dashboard" {
  count = var.cloud_provider == "aws" && var.enable_cloudwatch_logs && var.create_cloudwatch_dashboard ? 1 : 0
  
  dashboard_name = "${var.environment}-logs-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text",
        x      = 0,
        y      = 0,
        width  = 24,
        height = 1,
        properties = {
          markdown = "# ${upper(var.environment)} Environment - Log Management Dashboard"
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 1,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            [ "AWS/Logs", "IncomingLogEvents", "LogGroupName", "/infra/${var.environment}/centralized-logs" ],
            [ ".", "IncomingBytes", ".", "." ]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = data.aws_region.current.name,
          title   = "Incoming Log Events and Size",
          period  = 300
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 1,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            [ "AWS/EC2", "CPUUtilization", "InstanceId", count.index > 0 ? aws_instance.syslog_server[0].id : "" ],
            [ ".", "DiskReadBytes", ".", "." ],
            [ ".", "DiskWriteBytes", ".", "." ]
          ],
          view    = "timeSeries",
          stacked = false,
          region  = data.aws_region.current.name,
          title   = "Syslog Server Performance",
          period  = 300
        }
      },
      {
        type   = "log",
        x      = 0,
        y      = 7,
        width  = 24,
        height = 6,
        properties = {
          query   = "SOURCE '/infra/${var.environment}/centralized-logs' | fields @timestamp, @message | sort @timestamp desc | limit 100",
          region  = data.aws_region.current.name,
          title   = "Recent Log Entries",
          view    = "table"
        }
      }
    ]
  })
}

# CloudWatch Alarms for log monitoring
resource "aws_cloudwatch_metric_alarm" "syslog_server_high_cpu" {
  count = var.cloud_provider == "aws" && var.deploy_syslog_server && var.create_cloudwatch_alarms ? 1 : 0
  
  alarm_name          = "${var.environment}-syslog-server-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors the syslog server CPU utilization"
  alarm_actions       = var.cloudwatch_alarm_actions
  
  dimensions = {
    InstanceId = aws_instance.syslog_server[0].id
  }
}

resource "aws_cloudwatch_metric_alarm" "log_group_ingestion_drops" {
  count = var.cloud_provider == "aws" && var.enable_cloudwatch_logs && var.create_cloudwatch_alarms ? 1 : 0
  
  alarm_name          = "${var.environment}-log-ingestion-drops"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DeliveryThrottling"
  namespace           = "AWS/Logs"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "This metric monitors if logs are being throttled/dropped"
  alarm_actions       = var.cloudwatch_alarm_actions
  
  dimensions = {
    LogGroupName = aws_cloudwatch_log_group.central_logs[0].name
  }
}

# Data source for current AWS region
data "aws_region" "current" {}

# S3 log analyzer Lambda (new feature)
resource "aws_lambda_function" "log_analyzer" {
  count = var.cloud_provider == "aws" && var.enable_log_archive && var.enable_log_analysis ? 1 : 0
  
  function_name    = "${var.environment}-log-analyzer"
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  role             = aws_iam_role.log_analyzer[0].arn
  timeout          = 300
  memory_size      = 512
  
  filename         = "${path.module}/files/log-analyzer.zip"
  source_code_hash = filebase64sha256("${path.module}/files/log-analyzer.zip")
  
  environment {
    variables = {
      LOG_BUCKET        = aws_s3_bucket.log_archive[0].bucket
      NOTIFICATION_SNS  = var.notification_sns_topic
      ENVIRONMENT       = var.environment
    }
  }
  
  tags = {
    Name        = "${var.environment}-log-analyzer"
    Environment = var.environment
    Tier        = "tier2-services"
    Component   = "log-management"
  }
}

# IAM Role for Log Analyzer Lambda
resource "aws_iam_role" "log_analyzer" {
  count = var.cloud_provider == "aws" && var.enable_log_archive && var.enable_log_analysis ? 1 : 0
  
  name = "${var.environment}-log-analyzer-role"
  
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
    Name        = "${var.environment}-log-analyzer-role"
    Environment = var.environment
    Tier        = "tier2-services"
    Component   = "log-management"
  }
}

# IAM Policy for Log Analyzer
resource "aws_iam_policy" "log_analyzer" {
  count = var.cloud_provider == "aws" && var.enable_log_archive && var.enable_log_analysis ? 1 : 0
  
  name        = "${var.environment}-log-analyzer-policy"
  description = "Policy for log analyzer Lambda function"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Effect = "Allow",
        Resource = [
          aws_s3_bucket.log_archive[0].arn,
          "${aws_s3_bucket.log_archive[0].arn}/*"
        ]
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "sns:Publish"
        ],
        Effect = "Allow",
        Resource = var.notification_sns_topic
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "log_analyzer" {
  count = var.cloud_provider == "aws" && var.enable_log_archive && var.enable_log_analysis ? 1 : 0
  
  role       = aws_iam_role.log_analyzer[0].name
  policy_arn = aws_iam_policy.log_analyzer[0].arn
}

# S3 Event Notification for Log Analysis
resource "aws_s3_bucket_notification" "log_analysis_notification" {
  count = var.cloud_provider == "aws" && var.enable_log_archive && var.enable_log_analysis ? 1 : 0
  
  bucket = aws_s3_bucket.log_archive[0].id
  
  lambda_function {
    lambda_function_arn = aws_lambda_function.log_analyzer[0].arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "logs/${var.environment}/"
  }
}

# Additional output for CloudWatch dashboard
output "logs_dashboard_url" {
  description = "URL of the CloudWatch logs dashboard"
  value       = var.cloud_provider == "aws" && var.enable_cloudwatch_logs && var.create_cloudwatch_dashboard ? "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.logs_dashboard[0].dashboard_name}" : null
}

# Additional output for log analyzer Lambda
output "log_analyzer_function" {
  description = "Name of the log analyzer Lambda function"
  value       = var.cloud_provider == "aws" && var.enable_log_archive && var.enable_log_analysis ? aws_lambda_function.log_analyzer[0].function_name : null
} 