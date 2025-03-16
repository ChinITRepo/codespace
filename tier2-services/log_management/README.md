# Log Management Module

This module deploys a centralized logging infrastructure for AWS environments, providing comprehensive log collection, storage, and analysis capabilities.

## Features

- **Centralized Syslog Server**: Collects logs from all infrastructure components
- **Secure Log Storage**: Encrypted storage with configurable retention periods
- **S3 Log Archiving**: Long-term storage with lifecycle management
- **CloudWatch Integration**: Real-time log monitoring and alerting
- **ELK Stack Integration**: Advanced log analysis and visualization
- **Log Rotation**: Automated management of log files
- **Security Hardening**: Secured syslog server with proper network controls

## Architecture

The log management architecture consists of:

1. **Syslog Server**: EC2 instance running rsyslog for centralized log collection
2. **S3 Bucket**: For long-term archival with configurable lifecycle policies
3. **CloudWatch Logs**: For real-time monitoring and alerting
4. **Lambda Function**: Forwards logs between different storage systems
5. **Security Groups**: Control access to the syslog server

## Usage

```hcl
module "log_management" {
  source = "../modules/tier2-services/log_management"

  environment             = "dev"
  vpc_id                  = module.vpc.vpc_id
  subnet_id               = module.vpc.private_subnets[0]
  
  # Syslog server configuration
  deploy_syslog_server    = true
  syslog_instance_type    = "t3.medium"
  log_volume_size         = 100
  log_retention_days      = 30
  syslog_allowed_cidrs    = ["10.0.0.0/16"]
  admin_cidr_blocks       = ["10.0.0.0/24"]
  
  # S3 archive configuration
  enable_log_archive      = true
  log_archive_bucket_name = "my-environment-logs"
  log_archive_retention_days = 365
  
  # CloudWatch integration
  enable_cloudwatch_logs  = true
  
  # Optional ELK stack integration
  forward_logs_to_elk     = false
  elk_host                = ""
  elk_port                = 5044
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (dev, test, prod) | string | n/a | yes |
| vpc_id | VPC ID for the syslog server | string | n/a | yes |
| subnet_id | Subnet ID for the syslog server | string | n/a | yes |
| deploy_syslog_server | Whether to deploy a syslog server | bool | true | no |
| syslog_instance_type | EC2 instance type | string | "t3.medium" | no |
| log_volume_size | Size of the log volume in GB | number | 100 | no |
| log_retention_days | Days to retain logs | number | 30 | no |
| enable_log_archive | Enable S3 log archiving | bool | true | no |
| enable_cloudwatch_logs | Enable CloudWatch logs | bool | true | no |
| forward_logs_to_elk | Forward logs to ELK stack | bool | false | no |

## Outputs

| Name | Description |
|------|-------------|
| syslog_server_ip | Private IP of the syslog server |
| syslog_server_public_ip | Public IP of the syslog server |
| log_archive_bucket | S3 bucket name for log archive |
| cloudwatch_log_group | CloudWatch log group name |

## Security Considerations

- The syslog server only accepts connections from specified CIDR ranges
- All log storage is encrypted at rest
- Access to log management resources is restricted by IAM policies
- Logs are transmitted securely between components

## Monitoring and Alerting

The module includes built-in monitoring:

- Disk space monitoring with email alerts
- CloudWatch dashboards for log metrics
- CloudWatch alarms for log anomalies

## Customization

You can customize the log management module by:

1. Modifying retention periods for different log types
2. Adding additional log forwarders for specific services
3. Implementing log filtering and parsing rules
4. Integrating with additional monitoring services 