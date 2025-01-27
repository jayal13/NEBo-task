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
resource "local_file" "host" {
  content  = <<EOF
  [aws_instance]
  ${aws_instance.app.public_ip} ansible_user=ubuntu ansible_private_key_file=${var.private_ssh_key}
  EOF
  filename = "${path.module}/../ansible/inventory/host.ini"
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

# ECS Cluster
resource "aws_ecs_cluster" "nebo" {
  name = "${var.name}-cluster"
  tags = {
    source = "terraform"
    task   = "CLOUD: Monitor Containerized Infrastructure"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "nebo" {
  family                   = "${var.name}-task"
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name      = "${var.name}-container"
      image     = "nginx:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
  tags = {
    source = "terraform"
    task   = "CLOUD: Monitor Containerized Infrastructure"
  }
}

# Creates a security group than handles tha ingress and egress trafic
resource "aws_security_group" "nsg" {
  name        = "${var.name}-nginx"
  description = "SG for nginx"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "nginx"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS trafic"
    from_port   = 443
    to_port     = 443
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
    task   = "CLOUD: Monitor Containerized Infrastructure"
  }
}

# ECS Service
resource "aws_ecs_service" "nebo" {
  name            = "${var.name}-service"
  cluster         = aws_ecs_cluster.nebo.id
  task_definition = aws_ecs_task_definition.nebo.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.nsg.id]
    assign_public_ip = true
  }
  tags = {
    source = "terraform"
    task   = "CLOUD: Monitor Containerized Infrastructure"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "ecs_dashboard" {
  dashboard_name = "ecs_dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x = 0
        y = 0
        width = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.nebo.name, "ServiceName", aws_ecs_service.nebo.name]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "CPU Utilization"
        }
      },
      {
        type = "metric"
        x = 6
        y = 0
        width = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.nebo.name, "ServiceName", aws_ecs_service.nebo.name]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "Memory Utilization"
        }
      }
    ]
  })
}

# CloudWatch Alarms for CPU
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "high_cpu_utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.nebo.name
    ServiceName = aws_ecs_service.nebo.name
  }
  tags = {
    source = "terraform"
    task   = "CLOUD: Monitor Containerized Infrastructure"
  }
}

# SNS Topic for Notifications
resource "aws_sns_topic" "alerts" {
  name = "ecs-alerts"
  tags = {
    source = "terraform"
    task   = "CLOUD: Monitor Containerized Infrastructure"
  }
}

resource "aws_sns_topic_subscription" "alerts_subscription" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email" # Cambia a 'https' para integraciones como Microsoft Teams o Slack
  endpoint  = var.sns_email
}