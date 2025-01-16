provider "aws" {
  region = "us-west-1"
}

# Creates a vpc that is the container of subnet, instances, gateway, etc.
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    task = "CLOUD: Provision of a Cloud Virtual Network"
    source = "terraform"
  }
}

# Creates a public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block             = "10.0.0.0/17"
  map_public_ip_on_launch = true # This option set the subnet as public
  tags = {
    task = "CLOUD: Provision of a Cloud Virtual Network"
    source = "terraform"
  }
}

# Creates a private subnet
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block             = "10.0.128.0/17"
  map_public_ip_on_launch = false # This option set the subnet as private
  tags = {
    task = "CLOUD: Provision of a Cloud Virtual Network"
    source = "terraform"
  }
}

# Creates an internet gateway, that alows the communication between vpc and public internet,
# is mandatory if we whant to create a public subnet reachable from internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    task = "CLOUD: Provision of a Cloud Virtual Network"
    source = "terraform"
  }
}

# Create a rout table that specifies how packets are forwarded between the subnets within your VPC,
# the internet, and your VPN connection.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    task = "CLOUD: Provision of a Cloud Virtual Network"
    source = "terraform"
  }
}

# Assosiate a route table to a subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Creates a security group than handles tha ingress and egress trafic of an instance
resource "aws_security_group" "sg" {
  name        = "sg-nebo"
  description = "SG for EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["TU_IP/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    source = "terraform"
    task = "CLOUD: Provision of a Cloud Virtual Network"
  }
}

# Creates an instance
resource "aws_instance" "app" {
  ami           = "ami-12345678"  
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name      = "mykey"  

  tags = {
    source = "terraform"
    task   = "CLOUD: Provision of virtual machines with predefined types and images"
  }
}

# Shows the public IP adress of the instance
output "public_ip" {
  value = aws_instance.app.public_ip
}