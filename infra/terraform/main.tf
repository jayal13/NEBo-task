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

# Retrieves the secret as a map
locals {
  ssh_keys = jsondecode(data.aws_secretsmanager_secret_version.ssh_keys_version.secret_string)
}

# Creates a VPC that is the container of subnet, instances, gateway, etc.
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

# Associate a route table to a subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Retrieves the IP address of who is running Terraform
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

# Create AMI from Instance
resource "aws_ami_from_instance" "custom_ami" {
  name               = "${var.name}-custom-ami"
  source_instance_id = aws_instance.app.id
  tags = {
    task = "CLOUD: Provision of virtual machines with predefined types and images"
    source = "terraform"
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
  filename = "${path.module}/../ansible/lvm/inventory/host.ini"
}

# Shows the public IP address of the instance
output "public_ip" {
  value = aws_instance.app.public_ip
}

# Auto Scaling: Launch Configuration
resource "aws_launch_template" "lt" {
  name_prefix   = "${var.name}-lt"
  image_id      = aws_instance.app.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.nebo.key_name

  network_interfaces {
    security_groups = [aws_security_group.sg.id]
    subnet_id       = aws_subnet.public.id
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      task   = "CLOUD: Provision of virtual machines with predefined types and images"
      source = "terraform"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    task   = "CLOUD: Control scaling parameters for virtual machines"
    source = "terraform"
  }
}

# Auto Scaling: Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  name                = "${var.name}-asg"
  max_size            = 3
  min_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [aws_subnet.public.id]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  tag {
    key                 = "source"
    value               = "terraform"
    propagate_at_launch = true
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300
}

# Auto Scaling: Policies
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.asg.id
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.asg.id
}

# Auto Scaling: CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name                = "HighCPUAlarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 80
  alarm_actions             = [aws_autoscaling_policy.scale_out.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  tags = {
    task   = "CLOUD: Control scaling parameters for virtual machines"
    source = "terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name                = "LowCPUAlarm"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 20
  alarm_actions             = [aws_autoscaling_policy.scale_in.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  tags = {
    task   = "CLOUD: Control scaling parameters for virtual machines"
    source = "terraform"
  }
}

# Security group for MongoDB
resource "aws_security_group" "mongodb_sg" {
  name        = "${var.name}-mongodb-sg"
  description = "SG for MongoDB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.my_ip.body}/32"]
  }

  ingress {
    description = "MongoDB Access"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["${data.http.my_ip.body}/32"] # Allow only your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    source = "terraform"
    task   = "CLOUD: Provision of virtual machines with predefined types and images"
  }
}

# Security group for Redis
resource "aws_security_group" "redis_sg" {
  name        = "${var.name}-redis-sg"
  description = "SG for Redis"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.my_ip.body}/32"]
  }
  
  ingress {
    description = "Redis Access"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["${data.http.my_ip.body}/32"] # Allow only your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    source = "terraform"
    task   = "CLOUD: Provision of virtual machines with predefined types and images"
  }
}

# Security group for MySQL
resource "aws_security_group" "mysql_sg" {
  name        = "${var.name}-mysql-sg"
  description = "SG for MySQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.my_ip.body}/32"]
  }

  ingress {
    description = "MySQL Access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${data.http.my_ip.body}/32"] # Allow only your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    source = "terraform"
    task   = "CLOUD: Provision of virtual machines with predefined types and images"
  }
}

# Creates an instance for MongoDB
resource "aws_instance" "mongodb" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  key_name               = aws_key_pair.nebo.key_name

  tags = {
    source = "terraform"
    task   = "CLOUD: Provision of virtual machines with predefined types and images"
  }
}

# Creates an instance for Redis
resource "aws_instance" "redis" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.redis_sg.id]
  key_name               = aws_key_pair.nebo.key_name

  tags = {
    source = "terraform"
    task   = "CLOUD: Provision of virtual machines with predefined types and images"
  }
}

# Creates an instance for MySQL
resource "aws_instance" "mysql" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  key_name               = aws_key_pair.nebo.key_name

  tags = {
    source = "terraform"
    task   = "CLOUD: Provision of virtual machines with predefined types and images"
  }
}

# Creates an .ini file for Ansible
resource "local_file" "databases" {
  content = <<EOF
[mongodb]
${aws_instance.mongodb.public_ip} ansible_user=ubuntu ansible_private_key_file=${var.private_ssh_key} ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[redis]
${aws_instance.redis.public_ip} ansible_user=ubuntu ansible_private_key_file=${var.private_ssh_key} ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[mysql]
${aws_instance.mysql.public_ip} ansible_user=ubuntu ansible_private_key_file=${var.private_ssh_key} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
  filename = "${path.module}/../ansible/databases/inventory/host.ini"

  depends_on = [aws_route_table_association.public_assoc]
}


# Output the private IPs of the instances
output "mongodb_public_ip" {
  value = aws_instance.mongodb.public_ip
}

output "redis_public_ip" {
  value = aws_instance.redis.public_ip
}

output "mysql_public_ip" {
  value = aws_instance.mysql.public_ip
}