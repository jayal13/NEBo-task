# Auto Scaling: Launch Configuration
resource "aws_launch_template" "lt" {
  name_prefix   = "${var.name}-lt"
  image_id      = var.ami
  instance_type = var.instance_type
  key_name      = var.key_pair

  network_interfaces {
    security_groups = [var.sg_id]
    subnet_id       = var.public_subnet_id
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      source = "terraform"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    source = "terraform"
  }
}

# Auto Scaling: Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  name                = "${var.name}-asg"
  max_size            = 3
  min_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [var.public_subnet_id]

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
  alarm_name          = "HighCPUAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  tags = {
    source = "terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "LowCPUAlarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 20
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  tags = {
    source = "terraform"
  }
}