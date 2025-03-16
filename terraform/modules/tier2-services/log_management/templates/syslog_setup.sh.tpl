#!/bin/bash
# Infrastructure Automation Framework - Syslog Server Setup Script
# This script sets up a centralized syslog server using rsyslog

# Exit on error
set -e

# Update package lists
apt-get update

# Install required packages
apt-get install -y rsyslog logrotate awscli jq curl chrony

# Stop rsyslog service for configuration
systemctl stop rsyslog

# Format and mount the log volume
mkfs.xfs /dev/nvme1n1
mkdir -p ${log_mount_point}
echo "/dev/nvme1n1 ${log_mount_point} xfs defaults 0 2" >> /etc/fstab
mount -a

# Check if we need to move existing logs
if [ "${log_mount_point}" != "/var/log" ]; then
  cp -a /var/log/* ${log_mount_point}/
  # Create symlink if needed
  ln -sf ${log_mount_point} /var/log
fi

# Configure rsyslog
cat > /etc/rsyslog.conf << EOL
# /etc/rsyslog.conf - rsyslog configuration file
# For more information see /usr/share/doc/rsyslog-doc/html/rsyslog_conf.html

#### MODULES ####
module(load="imuxsock") # provides support for local system logging
module(load="imklog")   # provides kernel logging support
module(load="imtcp")    # provides TCP syslog reception
module(load="imudp")    # provides UDP syslog reception

# TCP and UDP inputs
input(type="imtcp" port="${syslog_port}")
input(type="imudp" port="${syslog_port}")

# Set the default permissions for log files
$FileOwner root
$FileGroup adm
$FileCreateMode 0640
$DirCreateMode 0755
$Umask 0022
$PrivDropToUser syslog
$PrivDropToGroup syslog

#### GLOBAL DIRECTIVES ####
# Use traditional timestamp format
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat

# Include all config files in /etc/rsyslog.d/
$IncludeConfig /etc/rsyslog.d/*.conf

#### RULES ####
# Log all kernel messages to the console
#kern.*                                                 /dev/console

# Log anything (except mail) of level info or higher
*.info;mail.none;authpriv.none;cron.none               ${log_mount_point}/syslog

# The authpriv file has restricted access
authpriv.*                                              ${log_mount_point}/auth.log

# Log all the mail messages in one place
mail.*                                                 ${log_mount_point}/mail.log

# Log cron stuff
cron.*                                                 ${log_mount_point}/cron.log

# Everybody gets emergency messages
*.emerg                                                :omusrmsg:*

# Save boot messages to boot.log
local7.*                                               ${log_mount_point}/boot.log

# Remote host logs (by IP address)
$template RemoteHost,"${log_mount_point}/remote/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteHost

# Remote host logs (by hostname)
$template RemoteHostByName,"${log_mount_point}/remote/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteHostByName
EOL

# Configure log rotation
cat > /etc/logrotate.d/rsyslog << EOL
${log_mount_point}/syslog
${log_mount_point}/mail.log
${log_mount_point}/mail.err
${log_mount_point}/mail.warn
${log_mount_point}/daemon.log
${log_mount_point}/kern.log
${log_mount_point}/auth.log
${log_mount_point}/user.log
${log_mount_point}/lpr.log
${log_mount_point}/cron.log
${log_mount_point}/debug
${log_mount_point}/messages
${log_mount_point}/remote/*/*.log
{
    rotate ${log_retention_days}
    daily
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
EOL

# Create directory for remote host logs
mkdir -p ${log_mount_point}/remote

# Set correct permissions
chown -R syslog:adm ${log_mount_point}

# Start rsyslog service
systemctl enable rsyslog
systemctl start rsyslog

%{ if forward_to_elk }
# ELK Stack integration (Filebeat)
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
apt-get install apt-transport-https -y
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list
apt-get update && apt-get install filebeat -y

# Configure Filebeat
cat > /etc/filebeat/filebeat.yml << EOL
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - ${log_mount_point}/syslog
    - ${log_mount_point}/auth.log
    - ${log_mount_point}/remote/*/*.log

output.logstash:
  hosts: ["${elk_host}:${elk_port}"]
  
setup.kibana:
  host: "${elk_host}:5601"

logging.level: info
logging.to_files: true
logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
  permissions: 0644
EOL

# Start Filebeat service
systemctl enable filebeat
systemctl start filebeat
%{ endif }

# Setup AWS CloudWatch Logs Agent (if in AWS)
EC2_INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "not-in-aws")
if [ "$EC2_INSTANCE_ID" != "not-in-aws" ]; then
  # Install CloudWatch Logs Agent
  wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
  dpkg -i amazon-cloudwatch-agent.deb
  
  # Configure CloudWatch Logs Agent
  cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOL
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "${log_mount_point}/syslog",
            "log_group_name": "/infra/${environment}/syslog",
            "log_stream_name": "{instance_id}",
            "retention_in_days": ${log_retention_days}
          },
          {
            "file_path": "${log_mount_point}/auth.log",
            "log_group_name": "/infra/${environment}/auth",
            "log_stream_name": "{instance_id}",
            "retention_in_days": ${log_retention_days}
          }
        ]
      }
    }
  }
}
EOL

  # Start the CloudWatch Logs Agent
  systemctl enable amazon-cloudwatch-agent
  systemctl start amazon-cloudwatch-agent
fi

# Configure security hardening
# Firewall
apt-get install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow ${syslog_port}/tcp
ufw allow ${syslog_port}/udp
ufw --force enable

# Update system time
timedatectl set-timezone UTC
systemctl enable chrony
systemctl start chrony

# Setup log monitoring
cat > /etc/cron.daily/check-disk-space << EOL
#!/bin/bash
# Check disk space and email admin if it's running low

THRESHOLD=80
MOUNT="${log_mount_point}"

USAGE=$(df -h | grep \$MOUNT | awk '{print \$5}' | sed 's/%//')

if [ \$USAGE -gt \$THRESHOLD ]; then
  echo "ALERT: Disk space on \$MOUNT is at \$USAGE%" | mail -s "Disk Space Alert: Syslog Server" root
fi
EOL

chmod +x /etc/cron.daily/check-disk-space

# Complete setup
echo "Syslog server setup completed successfully!" 