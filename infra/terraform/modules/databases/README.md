# Terraform Module: Provision MongoDB, Redis, and MySQL Instances with Security Groups

This Terraform module deploys and secures three separate AWS EC2 instances—one for MongoDB (NoSQL), one for Redis (in-memory), and one for MySQL (relational database). Each instance has its own dedicated Security Group allowing SSH access and the required database port, restricted to a specified IP address.

## Overview

1. *Security Groups*  
   - *MongoDB Security Group (aws_security_group.mongodb_sg):*  
     Allows inbound SSH (port 22) and MongoDB traffic (port 27017) exclusively from your public IP.  
   - *Redis Security Group (aws_security_group.redis_sg):*  
     Allows inbound SSH (port 22) and Redis traffic (port 6379) exclusively from your public IP.  
   - *MySQL Security Group (aws_security_group.mysql_sg):*  
     Allows inbound SSH (port 22) and MySQL traffic (port 3306) exclusively from your public IP.  
   - All security groups allow outbound traffic to any destination.  

2. *EC2 Instances*  
   - *MongoDB Instance (aws_instance.mongodb):*  
     Uses the MongoDB security group.  
   - *Redis Instance (aws_instance.redis):*  
     Uses the Redis security group.  
   - *MySQL Instance (aws_instance.mysql):*  
     Uses the MySQL security group.  
   - Each instance is launched in a specified subnet, with a common AMI and instance type.  
   - A key pair is used for SSH access.  

3. *Local File for Ansible (local_file.databases):*  
   - Generates an *Ansible inventory file* that includes the public IP of each instance (MongoDB, Redis, MySQL).  
   - Specifies the SSH user, private key file location, and disables strict host key checking for convenience.

## Tasks Addressed

Based on the provided task list, this module mainly satisfies the following:

- *(6) CLOUD: Provision of virtual machines with predefined types and images*  
  All three instances (MongoDB, Redis, MySQL) use a specified AMI and instance type.

- *(10) CLOUD: Provision a NoSQL instance*  
  MongoDB is a NoSQL database.

- *(11) CLOUD: Provision of an in-memory service*  
  Redis is an in-memory data store and cache.

- *(12) CLOUD: Provision of Relational DB*  
  MySQL is a relational database.