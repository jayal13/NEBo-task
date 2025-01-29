# Terraform Main Configuration

This is the main Terraform configuration file that orchestrates multiple modules, bringing together a comprehensive AWS infrastructure setup. Here’s an overview of how each part of the code works and which tasks it addresses.

---

## Overview

1. *AWS Provider Configuration*  
   - Specifies the AWS region (var.region) where resources will be created.

2. *Secret Retrieval from AWS Secrets Manager*  
   - *data "aws_secretsmanager_secret" "ssh_keys"* and *data "aws_secretsmanager_secret_version" "ssh_keys_version"*  
     - Fetches SSH key pairs (public/private) stored securely in AWS Secrets Manager.  
     - *Local variable ssh_keys* uses jsondecode to convert the secret string into a map, so the module can consume the keys.

3. *Public IP Retrieval*  
   - *data "http" "my_ip"*  
     - Retrieves the external IP address of the user running Terraform. This IP can be used to whitelist SSH access in various security groups.

4. *Modules*  
   - Each module encapsulates a logical subset of the infrastructure:

   ### a. Network (module "network")
   - *Path*: ./modules/network  
   - *Purpose*: Creates a primary VPC, public and private subnets, and an internet gateway. Also sets up route tables and associations.  
   - *Key Variables*: vpc_ip, public_subnet_ip, private_subnet_ip, route_table_ips, my_ip  
   - *Primary Tasks Addressed*:  
     - (15) *CLOUD: Provision of a Cloud Virtual Network*  

   ### b. Compute (module "compute")
   - *Path*: ./modules/compute  
   - *Purpose*: Creates basic compute resources (EC2 instances, key pair, security groups, EBS volumes, etc.).  
   - *Key Variables*: vpc_id, public_subnet_id, my_ip, public_ssh_key, ami, instance_type, ebs_size, private_ssh_key  
   - *Primary Tasks Addressed*:  
     - (1) Possibly part of *Maintenance and support* (if you track changes in a version control system and automate environment management)  
     - (6) *CLOUD: Provision of virtual machines with predefined types and images*  

   ### c. Autoscaling (module "autoscaling")
   - *Path*: ./modules/autoscaling  
   - *Purpose*: Creates an Auto Scaling Group (ASG), Launch Template, scaling policies, and CloudWatch alarms to automatically scale EC2 instances.  
   - *Key Variables*: key_pair, public_subnet_id, sg_id, ami, instance_type, name  
   - *Primary Tasks Addressed*:  
     - (7) *CLOUD: Control scaling parameters for virtual machines*  

   ### d. Databases (module "databases")
   - *Path*: ./modules/databases  
   - *Purpose*: Provisions database instances (MongoDB, Redis, MySQL) on separate EC2 instances, each with its own security group and basic firewall rules. Also generates an Ansible inventory.  
   - *Key Variables*: key_pair, vpc_id, public_subnet_id, public_route_table, my_ip, public_ssh_key, ami, instance_type, private_ssh_key  
   - *Primary Tasks Addressed*:  
     - (10) *CLOUD: Provision a NoSQL instance* (MongoDB)  
     - (11) *CLOUD: Provision of an in-memory service* (Redis)  
     - (12) *CLOUD: Provision of Relational DB* (MySQL)  
     - (6) *CLOUD: Provision of virtual machines with predefined types and images* (under each database instance)

   ### e. ECS (module "ecs")
   - *Path*: ./modules/ecs  
   - *Purpose*: Creates an ECS Cluster and Fargate Service running an Nginx container, with a CloudWatch dashboard and alarm for CPU utilization. It also sets up an SNS topic for alerts.  
   - *Key Variables*: vpc_id, public_subnet_id, region, name, sns_email  
   - *Primary Tasks Addressed*:  
     - (9) *CLOUD: Monitor Containerized Infrastructure*  

   ### f. Private Network & Peering (module "private_network")
   - *Path*: ./modules/private_network  
   - *Purpose*: Creates a second VPC (fully private), a private subnet, and a VPC peering connection between it and the main VPC. Also launches a private EC2 instance accessible via peering.  
   - *Key Variables*: vpc_ip, instance_type, ami, vpc_id, vpc_route_table_id, public_route_table, key_pair, private_vpc_cidr, private_subnet_cidr, name  
   - *Primary Tasks Addressed*:  
     - (15) *CLOUD: Provision of a Cloud Virtual Network* (private VPC)  
     - (16) *CLOUD: Ensure connection between private and public clouds without exposing your traffic to the public internet* (VPC peering)  
     - (6) *CLOUD: Provision of virtual machines* for a private environment  

   ### g. Static Website, Versioning & Backup (module "s3_cloudfront")
   - *Path*: ./modules/s3_cloudfront (example path; adjust as needed)  
   - *Purpose*: Creates an S3 bucket for static website hosting, configures public read access, attaches a CloudFront distribution for CDN, enables versioning and a lifecycle policy to transition objects to Glacier, and sets up AWS Backup.  
   - *Key Variables*: Typically includes a name (for bucket naming), plus any region or certificate settings if used.  
   - *Primary Tasks Addressed*:  
     - (13) *CLOUD: Archive and back up storage services* (lifecycle policy to Glacier + AWS Backup)  
     - (18) *CLOUD: Provision fast delivery of Internet content* (CloudFront distribution over S3)

---

## Tasks Addressed

Overall, this main Terraform configuration addresses several tasks from the list:

- *(2) Use secret management tool*:  
  By retrieving SSH keys from AWS Secrets Manager, this setup integrates secure secret management into an automated infrastructure workflow.
- *(6) Provision of virtual machines* (with various modules).
- *(7) Control scaling parameters* (Auto Scaling module).
- *(9) Monitor containerized infrastructure* (ECS module with CloudWatch).
- *(10) Provision a NoSQL instance (MongoDB)* (Databases module).
- *(11) Provision an in-memory service (Redis)* (Databases module).
- *(12) Provision a relational DB (MySQL)* (Databases module).
- *(13) Archive and back up storage services* (S3 lifecycle + AWS Backup in the new S3/CloudFront module).
- *(15) Provision a Cloud Virtual Network* (Network module & Private Network module).
- *(16) Connection between private and public clouds* via VPC peering (Private Network module).
- *(18) Provision fast delivery of Internet content* (CloudFront as CDN for the static website).

---

## Usage

1. *Clone or copy* this repository/configuration.
2. *Customize* the variables in your terraform.tfvars or equivalent:
   - region, vpc_ip, public_subnet_ip, private_subnet_ip, etc.
   - ami and instance_type for your EC2 instances.
   - private_ssh_key location, sns_email address, bucket name, and any other required variables.
3. *Initialize, Plan, and Apply*:
   ```bash
   terraform init
   terraform plan
   terraform apply