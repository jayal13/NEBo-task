# Terraform Module: Private VPC, Subnet, and VPC Peering with an Existing VPC

This Terraform module creates:
- A *new private VPC* and subnet, without an internet gateway (fully private).
- A *VPC Peering Connection* between the existing (primary) VPC and the new private VPC.
- Appropriate *routes* in both VPCs to allow traffic to flow via the peering connection.
- An *EC2 instance* in the new private VPC, accessible only via the peering connection from the main VPC.

## Overview

1. *Private VPC (aws_vpc.private_vpc)*  
   - Defines a separate VPC using a custom CIDR block (e.g., 10.1.0.0/16).

2. *Private Subnet (aws_subnet.private_side_subnet)*  
   - Creates a subnet in the private VPC without a public IP assignment.

3. *Route Table + Association*  
   - *aws_route_table.private_side_rt*: Route table for the private VPC.  
   - *aws_route_table_association.private_side_assoc*: Associates the private subnet with this route table, which has no internet gateway routes to maintain its privacy.

4. *VPC Peering Connection (aws_vpc_peering_connection.public_private_peering)*  
   - Creates a peering connection between the existing (public/main) VPC and the newly created private VPC.
   - auto_accept = true for simplicity.

5. *Routes*  
   - *aws_route.main_public_to_private*: Adds a route in the public route table so it knows how to reach the private VPC via peering.  
   - *aws_route.main_private_to_private*: (Optional) Adds a route in your main VPC’s default or private route table for reaching the new private VPC.  
   - *aws_route.private_side_to_main*: Adds a route in the private VPC’s route table to reach the main VPC’s CIDR block.

6. *Private Security Group (aws_security_group.private_app_sg)*  
   - Allows SSH only from the main VPC CIDR range (e.g., 10.0.0.0/16).
   - Provides unrestricted outbound traffic.

7. *Private EC2 Instance (aws_instance.private_app)*  
   - Demonstrates a private instance that can be accessed solely via the peering connection from the main VPC.
   - Uses the private subnet and the new security group.

## Tasks Addressed

From the provided list of tasks, this module primarily addresses:
 
- *(19) Secure network infrastructure*  
- *(15) CLOUD: Provision of a Cloud Virtual Network* (the new private VPC and subnet).  
- *(16) CLOUD: Ensure connection between private and public clouds without exposing your traffic to the public internet* (via VPC peering).  
- *(7) CLOUD: Provision of virtual machines with predefined types and images* (the private EC2 instance).  
- *(14) Configure traffic control at the Instance and Subnet Levels* (security group rules and private subnet traffic isolation).
