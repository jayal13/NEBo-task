# Terraform Module: AWS ECS Fargate Service with Monitoring and Alerts

This Terraform module provisions an *ECS Fargate* service running an Nginx container, complete with:
- *ECS Cluster* and *Task Definition* for container orchestration
- *Security Group* configured to allow HTTP (80) and HTTPS (443) inbound traffic
- *ECS Service* (Fargate) running the container in the specified subnet
- *CloudWatch Dashboard* that monitors CPU and memory utilization
- *CloudWatch Alarm* for high CPU usage, integrated with an *SNS Topic* to send alerts via email

## Overview of Resources

1. *ECS Cluster (aws_ecs_cluster.nebo):*  
   - Creates a cluster in AWS ECS to host your containerized application.
   - Tagged to indicate monitoring of containerized infrastructure.

2. *ECS Task Definition (aws_ecs_task_definition.nebo):*  
   - Defines an Nginx container (nginx:latest) running on Fargate.
   - Allocates CPU (256) and memory (512) resources.
   - Maps port 80 inside the container to port 80 on the host.

3. *Security Group (aws_security_group.nsg):*  
   - Allows inbound traffic on ports 80 (HTTP) and 443 (HTTPS) from any IP.
   - Allows all outbound traffic.
   - Tagged for container infrastructure monitoring.

4. *ECS Service (aws_ecs_service.nebo):*  
   - Deploys the task definition onto Fargate within the ECS cluster.
   - Configures the network (subnet and security group) and automatically assigns a public IP.
   - Maintains the desired number of tasks (containers).

5. *CloudWatch Dashboard (aws_cloudwatch_dashboard.ecs_dashboard):*  
   - Visualizes ECS metrics (CPU and memory utilization).
   - Uses widgets to track average usage over a 5-minute period.

6. *CloudWatch Metric Alarm (aws_cloudwatch_metric_alarm.cpu_high):*  
   - Triggers when CPU utilization exceeds the specified threshold (70%).
   - Notifies an SNS topic to alert the user.

7. *SNS Topic and Subscription (aws_sns_topic.alerts, aws_sns_topic_subscription.alerts_subscription):*  
   - Creates an SNS topic named ecs-alerts.
   - Subscribes an email address (or other protocol) to receive notifications of high CPU alarms.

## Tasks Addressed

From the provided tasks list, this module most directly addresses:

- *(9) CLOUD: Monitor Containerized Infrastructure*  
  By creating an ECS service, CloudWatch dashboard, and alarms, this module allows for the monitoring and alerting of containerized workloads.