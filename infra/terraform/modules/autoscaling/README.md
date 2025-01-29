# Terraform Module: AWS Auto Scaling

This Terraform module provisions an AWS Auto Scaling environment, including:
- A Launch Template defining virtual machine configuration
- An Auto Scaling Group (ASG) that manages EC2 instances
- Auto Scaling policies to scale in and out based on load
- CloudWatch alarms that monitor CPU utilization to trigger scaling actions

## Overview

1. *Launch Template (aws_launch_template):*
   - Specifies the AMI, instance type, key pair, and security group.
   - Uses a public subnet for the network interface.
   - Includes tags that describe the provisioning tasks and Terraform as the source.

2. *Auto Scaling Group (aws_autoscaling_group):*
   - Manages the desired, minimum, and maximum number of EC2 instances.
   - Associates with the Launch Template.
   - Includes configuration for health checks and tagging.

3. *Auto Scaling Policies (aws_autoscaling_policy):*
   - Define the actions to scale out (add an instance) and scale in (remove an instance).
   - Tied to the Auto Scaling Group.

4. *CloudWatch Metric Alarms (aws_cloudwatch_metric_alarm):*
   - Monitor CPU usage across the Auto Scaling Group.
   - Trigger scale-out or scale-in policies based on CPU utilization thresholds.

## Tasks Addressed

This module primarily covers the following tasks from the provided list:

- *(6) CLOUD: Provision of virtual machines with predefined types and images*  
  By specifying the AMI and instance type in the Launch Template, this module sets up VM instances with predefined configurations.

- *(7) CLOUD: Control scaling parameters for virtual machines*  
  The Auto Scaling Group and scaling policies control how many VMs run at a time, adjusting capacity automatically based on CPU usage.