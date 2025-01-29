# Terraform Module: AWS VPC with Public and Private Subnets

This Terraform module creates a basic AWS VPC with one public and one private subnet, an internet gateway, and a route table with a public route. It associates the public subnet with the route table, allowing resources in that subnet to access the internet.

## Overview

1. *VPC (aws_vpc.main):*  
   - Defines the main network container for your AWS resources using a specified CIDR block.

2. *Subnets:*  
   - *Public Subnet (aws_subnet.public)*:  
     - Uses map_public_ip_on_launch = true to ensure resources can receive a public IP address.  
   - *Private Subnet (aws_subnet.private)*:  
     - Uses map_public_ip_on_launch = false to keep resources private.

3. *Internet Gateway (aws_internet_gateway.gw):*  
   - Enables internet connectivity for the VPC and is mandatory for public subnets.

4. *Route Table (aws_route_table.public)*:  
   - Specifies routes for sending traffic to the internet gateway.
   - Dynamically creates routes based on a list of CIDR blocks (var.route_table_ips).

5. *Route Table Association (aws_route_table_association.public_assoc)*:  
   - Associates the public route table with the public subnet, enabling internet access for that subnet.

## Tasks Addressed

This module primarily addresses the following task from the provided list:

- *(15) CLOUD: Provision of a Cloud Virtual Network*  
  By creating a VPC, subnets, route table, and internet gateway, the module lays the groundwork for a cloud network infrastructure.
