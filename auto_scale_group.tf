resource "aws_autoscaling_group" "sensor_asg" {
  name             = var.sensor_asg_name
  min_size         = 1
  max_size         = 5
  desired_capacity = 1

  launch_template {
    name    = aws_launch_template.sensor_launch_template.name
    version = aws_launch_template.sensor_launch_template.latest_version
  }

  availability_zones        = var.auto_scaling_availability_zones
  target_group_arns         = [awscc_elasticloadbalancingv2_target_group.health_check.target_group_arn]
  health_check_type         = "EC2"
  health_check_grace_period = 300
  termination_policies = [
    "OldestInstance"
  ]
  protect_from_scale_in = false
}

