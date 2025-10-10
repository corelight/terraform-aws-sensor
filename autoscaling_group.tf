resource "aws_autoscaling_group" "sensor_asg" {
  name             = var.sensor_asg_name
  min_size         = 1
  max_size         = 5
  desired_capacity = 1

  launch_template {
    name    = aws_launch_template.sensor_launch_template.name
    version = aws_launch_template.sensor_launch_template.latest_version
  }

  vpc_zone_identifier       = var.monitoring_subnet_ids
  target_group_arns         = [aws_lb_target_group.health_check.arn]
  health_check_type         = "EC2"
  health_check_grace_period = 300
  termination_policies      = ["OldestInstance"]
  protect_from_scale_in     = false
  wait_for_capacity_timeout = 0

  initial_lifecycle_hook {
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
    name                 = var.asg_lifecycle_hook_name
    default_result       = "ABANDON"
    heartbeat_timeout    = 300
  }

  depends_on = [
    aws_lambda_function.auto_scaling_lambda,
    aws_cloudwatch_event_rule.asg_lifecycle_rule,
    aws_cloudwatch_log_group.log_group,
  ]
}

resource "aws_autoscaling_policy" "sensor_autoscale_policy" {
  name                   = var.sensor_asg_auto_scale_policy_name
  autoscaling_group_name = aws_autoscaling_group.sensor_asg.name

  policy_type     = "StepScaling"
  adjustment_type = "ChangeInCapacity"
  step_adjustment {
    metric_interval_lower_bound = 0
    scaling_adjustment          = 1
  }
}

resource "awscc_cloudwatch_alarm" "sensor_asg_high_cpu_alarm" {
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Scale out if CPU > 70% for 2 minutes"
  evaluation_periods  = 2
  period              = 60
  comparison_operator = "GreaterThanThreshold"
  namespace           = "AWS/EC2"
  alarm_actions       = [aws_autoscaling_policy.sensor_autoscale_policy.arn]
  dimensions = [
    {
      name  = "AutoScalingGroupName"
      value = "SensorAutoScalingGroup"
    }
  ]
  metric_name = "CPUUtilization"
}