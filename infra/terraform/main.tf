provider "aws" {
  region = var.region
}

# Obtains the metadata of the secret
data "aws_secretsmanager_secret" "ssh_keys" {
  name = "amazon_ssh_keys"
}

# Obtain the secret
data "aws_secretsmanager_secret_version" "ssh_keys_version" {
  secret_id = data.aws_secretsmanager_secret.ssh_keys.id
}

# Retives the secret as a map
locals {
  ssh_keys = jsondecode(data.aws_secretsmanager_secret_version.ssh_keys_version.secret_string)
}

# Creates a vpc that is the container of subnet, instances, gateway, etc.
resource "aws_vpc" "main" {
  cidr_block = var.vpc_ip
  tags = {
    task   = "CLOUD: Provision of a Cloud Virtual Network"
    source = "terraform"
  }
}

# Creates a public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_ip
  map_public_ip_on_launch = true # This option set the subnet as public
  tags = {
    task   = "CLOUD: Provision of a Cloud Virtual Network"
    source = "terraform"
  }
}

# Creates a private subnet
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_ip
  map_public_ip_on_launch = false # This option set the subnet as private
  tags = {
    task   = "CLOUD: Provision of a Cloud Virtual Network"
    source = "terraform"
  }
}

# Creates an internet gateway, that alows the communication between vpc and public internet,
# is mandatory if we whant to create a public subnet reachable from internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    task   = "CLOUD: Provision of a Cloud Virtual Network"
    source = "terraform"
  }
}

# Create a rout table that specifies how packets are forwarded between the subnets within your VPC,
# the internet, and your VPN connection.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.route_table_ips
    content {
      cidr_block = route.value
      gateway_id = aws_internet_gateway.gw.id
    }
  }
  tags = {
    task   = "CLOUD: Provision of a Cloud Virtual Network"
    source = "terraform"
  }
}

# Assosiate a route table to a subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#this block will retrive the ip adress of who is running terraform
data "http" "my_ip" {
  url = "http://ifconfig.me"
}

# Creates a security group than handles tha ingress and egress trafic of an instance
resource "aws_security_group" "sg" {
  name        = var.name
  description = "SG for EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.my_ip.body}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    source = "terraform"
    task   = "CLOUD: Provision of a Cloud Virtual Network"
  }
}

# Creates a key pair to be used to conect whith the instance
resource "aws_key_pair" "nebo" {
  key_name   = var.name
  public_key = local.ssh_keys.public_ssh_key
}

# Creates an instance
resource "aws_instance" "app" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = aws_key_pair.nebo.key_name

  tags = {
    source = "terraform"
    task   = "CLOUD: Provision of virtual machines with predefined types and images"
  }
}

# Creates a new EBS volume
resource "aws_ebs_volume" "var_volume" {
  availability_zone = aws_instance.app.availability_zone
  size              = var.ebs_size # GB
  tags = {
    source = "terraform"
    task   = "Maintenance and support automated configuration of infrastructure environments in project practice"
  }
}

# Attachh the volume to the EC2 instances
resource "aws_volume_attachment" "var_volume_attach" {
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.var_volume.id
  instance_id = aws_instance.app.id
}

# Creates an .ini file to be used by ansible
resource "local_file" "host" {
  content  = <<EOF
  [aws_instance]
  ${aws_instance.app.public_ip} ansible_user=ubuntu ansible_private_key_file=${var.private_ssh_key}
  EOF
  filename = "${path.module}/../ansible/inventory/host.ini"
}

# Shows the public IP adress of the instance
output "public_ip" {
  value = aws_instance.app.public_ip
}