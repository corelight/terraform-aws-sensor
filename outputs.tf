output "auto_scale_group_id" {
  value = aws_autoscaling_group.sensor_asg.id
}

output "auto_scale_policy_id" {
  value = aws_autoscaling_policy.sensor_autoscale_policy.id
}

output "auto_scale_group_cloudwatch_alarm_id" {
  value = awscc_cloudwatch_alarm.sensor_asg_high_cpu_alarm.id
}

output "launch_template_id" {
  value = aws_launch_template.sensor_launch_template.id
}

output "auto_scale_group_mgmt_nic_id" {
  value = aws_network_interface.management_nic.id
}

output "auto_scale_group_mon_nic_id" {
  value = aws_network_interface.monitoring_nic.id
}

output "load_balancer_id" {
  value = aws_lb.sensor_lb.id
}

output "load_balancer_listener_id" {
  value = aws_lb_listener.load_balancer_listener.id
}

output "load_balancer_health_check_target_group" {
  value = aws_lb_target_group.health_check.id
}

output "monitoring_security_group_id" {
  value = aws_security_group.monitoring.id
}

output "management_security_group_id" {
  value = aws_security_group.management.id
}

