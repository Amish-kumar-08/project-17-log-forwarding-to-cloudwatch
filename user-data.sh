#!/bin/bash
set -e

apt-get update -y
apt-get install -y wget

# Install CloudWatch Agent
wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

dpkg -i -E amazon-cloudwatch-agent.deb

# Create application log
mkdir -p /var/log/project17
touch /var/log/project17/application.log

# Generate sample logs
for i in {1..10}; do
  echo "$(date -u '+%Y-%m-%d %H:%M:%S') INFO Project17 application log $i" >> /var/log/project17/application.log
done

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CONFIG'
{
  "agent": {
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/project17/application.log",
            "log_group_name": "/project17/application-logs",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
CONFIG

# Start agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
-s
