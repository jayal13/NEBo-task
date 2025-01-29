# ECS Cluster
resource "aws_ecs_cluster" "nebo" {
  name = "${var.name}-cluster"
  tags = {
    source = "terraform"
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
  }
}

# Creates a security group than handles tha ingress and egress trafic
resource "aws_security_group" "nsg" {
  name        = "${var.name}-nginx"
  description = "SG for nginx"
  vpc_id      = var.vpc_id

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
    subnets          = [var.public_subnet_id]
    security_groups  = [aws_security_group.nsg.id]
    assign_public_ip = true
  }
  tags = {
    source = "terraform"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "ecs_dashboard" {
  dashboard_name = "ecs_dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 6
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
        type   = "metric"
        x      = 6
        y      = 0
        width  = 6
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
  }
}

# SNS Topic for Notifications
resource "aws_sns_topic" "alerts" {
  name = "ecs-alerts"
  tags = {
    source = "terraform"
  }
}

resource "aws_sns_topic_subscription" "alerts_subscription" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email" # Cambia a 'https' para integraciones como Microsoft Teams o Slack
  endpoint  = var.sns_email
}