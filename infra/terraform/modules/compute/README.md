# Terraform Module: AWS Key Pair, Security Group, EC2 Instance, and EBS Volume

This Terraform module creates and configures the following AWS resources:
- *Key Pair* (for SSH access)
- *Security Group* (manages inbound and outbound traffic)
- *EC2 Instance* (with a predefined AMI and instance type)
- *EBS Volume* (attached to the EC2 instance for additional storage)
- *Local File* (generates an Ansible host inventory file)

## Overview

1. *Key Pair (aws_key_pair.nebo):*  
   - Creates an SSH key pair in AWS, using a provided public key.

2. *Security Group (aws_security_group.sg):*  
   - Allows inbound traffic on ports 22 (SSH) and 80 (HTTP).
   - Restricts SSH access to the IP address you specify.
   - Allows all outbound traffic.
   - Tagged with "CLOUD: Provision of a Cloud Virtual Network" to reflect the network-related task.

3. *EC2 Instance (aws_instance.app):*  
   - Launches an EC2 instance using the specified AMI and instance type.
   - Uses the created Security Group and Key Pair.
   - Tagged with "CLOUD: Provision of virtual machines with predefined types and images".

4. *EBS Volume (aws_ebs_volume.var_volume and aws_volume_attachment.var_volume_attach):*  
   - Creates a new EBS volume in the same Availability Zone as the instance.
   - Attaches this volume to the EC2 instance.
   - Tagged to indicate *maintenance and support of automated configuration* tasks.

5. *Local File (local_file.lvm):*  
   - Generates an Ansible inventory file that includes the public IP of the newly created instance and the path to the private SSH key.
   - Useful for further configuration management tasks with Ansible.

## Tasks Addressed

This module satisfies the following tasks from the provided list:

- *(1) Maintenance and support automated configuration of infrastructure environments in project practice*  
  The EBS volume resource is tagged with this requirement, indicating we are automating storage configuration for the project environment.

- *(6) CLOUD: Provision of virtual machines with predefined types and images*  
  The EC2 instance resource is tagged to reflect the provisioning of VMs with a specified AMI and instance type.

- *(8) CLOUD: Custom virtual machine type and image
  An Elastic Block Container was added to the EC2 to create a LVM for the resource


- *(15) CLOUD: Provision of a Cloud Virtual Network*  
  The security group resource is tagged to show the setup of basic network rules for an instance, which is part of network provisioning in the cloud.

- *(17) CLOUD: Manage Public DNS names
  The EC2 instance is reachable by a domain (not set up in terraform to avoid charges)
