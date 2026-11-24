# Project 17: Log Forwarding to Amazon CloudWatch

## Overview

Implemented centralized log forwarding from an Ubuntu EC2 instance to Amazon CloudWatch using the AWS CloudWatch Agent.

The project demonstrates how to configure IAM permissions, deploy an EC2 instance, install and configure the CloudWatch Agent automatically using EC2 User Data, forward application logs to CloudWatch Logs, and create a monitoring dashboard.

The entire infrastructure setup and configuration were performed using AWS CLI, with AWS Systems Manager Session Manager used for remote server access.

## Architecture

```text
Ubuntu EC2 Instance
        |
        | Application Log Files
        v
CloudWatch Agent
        |
        | Log Forwarding
        v
Amazon CloudWatch Logs
        |
        | Log Group
        v
Log Stream
        |
        v
CloudWatch Dashboard
        |
        v
Centralized Log Monitoring
```

## AWS Resources Created

| Resource | Name / Configuration |
|---|---|
| EC2 Instance | Project17-Log-Server |
| Operating System | Ubuntu Server 24.04 LTS |
| Instance Type | t3.micro |
| AWS Region | ap-south-1 (Mumbai) |
| IAM Role | Project17-CloudWatch-Role |
| IAM Instance Profile | Project17-CloudWatch-Profile-V2 |
| IAM Policy | CloudWatchAgentServerPolicy |
| IAM Policy | AmazonSSMManagedInstanceCore |
| Security Group | project17-log-sg |
| CloudWatch Log Group | /project17/application-logs |
| Log Stream | EC2 Instance ID |
| CloudWatch Dashboard | Project17-Log-Dashboard |

## Technologies Used

- Amazon EC2
- Amazon CloudWatch
- CloudWatch Agent
- CloudWatch Logs
- CloudWatch Logs Insights
- AWS IAM
- AWS Systems Manager (SSM)
- AWS CLI
- Ubuntu Linux
- Bash Scripting
- JSON Configuration

## Implementation Steps

### 1. Configure IAM Role

Created an IAM role named `Project17-CloudWatch-Role` with EC2 as its trusted entity.

Attached the following AWS-managed policies:

- `CloudWatchAgentServerPolicy`
- `AmazonSSMManagedInstanceCore`

Created an IAM instance profile named `Project17-CloudWatch-Profile-V2` and associated the IAM role with it.

This provides the EC2 instance with permissions to forward logs to CloudWatch and communicate with AWS Systems Manager.

### 2. Configure Security Group

Created a security group named `project17-log-sg`.

Configured SSH access from the administrator's public IP during initial infrastructure setup.

SSM Session Manager was subsequently used for remote access without requiring SSH keys.

### 3. Launch EC2 Instance

Launched an Ubuntu 24.04 EC2 instance using AWS CLI.

Configured:
- Instance Type: t3.micro
- Root Storage: 8 GiB
- IAM Instance Profile: Project17-CloudWatch-Profile-V2
- Security Group: project17-log-sg

Used EC2 User Data to automate the installation and configuration process.

### 4. Install CloudWatch Agent

Downloaded and installed the Amazon CloudWatch Agent package on Ubuntu.

```bash
wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

sudo dpkg -i -E amazon-cloudwatch-agent.deb
```

### 5. Generate Application Logs

Created a custom application log directory:

```bash
sudo mkdir -p /var/log/project17
```

Created the application log file:

```bash
sudo touch /var/log/project17/application.log
```

Generated sample log entries containing application information.

Example:

```text
INFO Project17 application log 1
INFO Project17 application log 2
INFO Project17 application log 3
WARNING High memory usage detected
ERROR Database connection failed
```

### 6. Configure CloudWatch Agent

Created a JSON configuration file to specify the log file location, CloudWatch Log Group, and Log Stream.

Configuration:

```json
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
```

Started the CloudWatch Agent:

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
-s
```

### 7. Access EC2 Using Systems Manager

Used AWS Systems Manager Session Manager to connect to the EC2 instance.

```bash
aws ssm start-session \
  --target YOUR_INSTANCE_ID \
  --region ap-south-1
```

Verified the CloudWatch Agent:

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status
```

Verified that the agent was running successfully.

### 8. Verify CloudWatch Logs

Created and verified the CloudWatch Log Group:

```text
/project17/application-logs
```

Retrieved the Log Stream using AWS CLI:

```bash
aws logs describe-log-streams \
  --log-group-name "/project17/application-logs" \
  --region ap-south-1
```

Retrieved application log events:

```bash
aws logs get-log-events \
  --log-group-name "/project17/application-logs" \
  --log-stream-name YOUR_LOG_STREAM \
  --region ap-south-1 \
  --limit 20
```

Successfully verified that application logs were forwarded from EC2 to CloudWatch.

### 9. Test Continuous Log Forwarding

Used AWS Systems Manager Run Command to generate an additional log entry remotely.

```bash
aws ssm send-command \
  --instance-ids YOUR_INSTANCE_ID \
  --document-name AWS-RunShellScript \
  --parameters '{"commands":["echo \"$(date -u +%Y-%m-%dT%H:%M:%SZ) INFO Live forwarding test successful\" >> /var/log/project17/application.log"]}' \
  --region ap-south-1
```

Verified that the new log entry appeared in the CloudWatch Log Stream.

This confirmed that the CloudWatch Agent continuously monitored the application log file and forwarded new entries.

### 10. Create CloudWatch Dashboard

Created a CloudWatch Dashboard named:

`Project17-Log-Dashboard`

Configured a Logs Insights widget to display the latest application log events.

Query:

```sql
SOURCE '/project17/application-logs'
| fields @timestamp, @message
| sort @timestamp desc
| limit 50
```

Created the dashboard using AWS CLI:

```bash
aws cloudwatch put-dashboard \
  --dashboard-name Project17-Log-Dashboard \
  --dashboard-body file://dashboard.json \
  --region ap-south-1
```

Verified the dashboard configuration using:

```bash
aws cloudwatch get-dashboard \
  --dashboard-name Project17-Log-Dashboard \
  --region ap-south-1
```

## Project Results

Successfully completed the following tasks:

- Created an EC2 instance using AWS CLI.
- Configured IAM roles and instance profiles.
- Installed CloudWatch Agent automatically using EC2 User Data.
- Generated application logs on Ubuntu.
- Configured centralized log forwarding.
- Accessed EC2 through SSM Session Manager.
- Verified CloudWatch Agent service status.
- Successfully forwarded application logs to CloudWatch.
- Verified continuous log forwarding with additional test events.
- Created a CloudWatch Dashboard using AWS CLI.

## Screenshots

Add your project screenshots in the `screenshots/` directory.

| Screenshot | Description |
|---|---|
| ec2-instance.png | EC2 instance running |
| iam-role.png | IAM role and attached policies |
| ssm-session.png | SSM Session Manager connection |
| cloudwatch-agent.png | CloudWatch Agent status |
| log-group.png | CloudWatch Log Group |
| log-events.png | Forwarded application log events |
| cloudwatch-dashboard.png | CloudWatch monitoring dashboard |

## Learning Outcomes

Through this project, I gained practical experience with:

- Centralized log management using Amazon CloudWatch.
- IAM roles and instance profiles.
- EC2 instance provisioning through AWS CLI.
- Automated server configuration using User Data.
- CloudWatch Agent installation and configuration.
- AWS Systems Manager Session Manager.
- CloudWatch Logs and Log Streams.
- CloudWatch Logs Insights queries.
- CloudWatch Dashboard creation.
- Automated log collection and forwarding.

## Cleanup

After completing the demonstration, AWS resources can be deleted to avoid unnecessary charges.

Terminate the EC2 instance and remove the associated CloudWatch Log Group, Dashboard, Security Group, IAM Instance Profile, and IAM Role when no longer required.

## Conclusion

Successfully implemented a centralized log-forwarding workflow using Amazon EC2 and Amazon CloudWatch.

The project demonstrates how application logs generated on a Linux server can be automatically collected, forwarded, stored, and monitored centrally using AWS services and command-line automation.
