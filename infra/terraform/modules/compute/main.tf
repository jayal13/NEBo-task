# Creates a key pair to be used to conect whith the instance
resource "aws_key_pair" "nebo" {
  key_name   = var.name
  public_key = var.public_ssh_key
}

# Creates a security group than handles tha ingress and egress trafic of an instance
resource "aws_security_group" "sg" {
  name        = var.name
  description = "SG for EC2"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  ingress {
    description = "HHTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    source = "terraform"
  }
}

# Creates an instance
resource "aws_instance" "app" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = aws_key_pair.nebo.key_name

  tags = {
    Name   = "principal"
    source = "terraform"
  }
}

# # Create AMI from Instance
# resource "aws_ami_from_instance" "custom_ami" {
#   name               = "${var.name}-custom-ami"
#   source_instance_id = aws_instance.app.id
#   tags = {
#     task = "CLOUD: Provision of virtual machines with predefined types and images"
#     source = "terraform"
#   }
# }

# Creates a new EBS volume
resource "aws_ebs_volume" "var_volume" {
  availability_zone = aws_instance.app.availability_zone
  size              = var.ebs_size # GB
  tags = {
    source = "terraform"
  }
}

# Attach the volume to the EC2 instances
resource "aws_volume_attachment" "var_volume_attach" {
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.var_volume.id
  instance_id = aws_instance.app.id
}

# Creates an .ini file for Ansible
resource "local_file" "lvm" {
  content  = <<EOF
  [aws_instance]
  ${aws_instance.app.public_ip} ansible_user=ubuntu ansible_private_key_file=${var.private_ssh_key}
  EOF
  filename = "${path.module}/../../ansible/lvm/inventory/host.ini"
}
