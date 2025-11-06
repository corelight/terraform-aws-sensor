output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group managing the Corelight sensor instances"
  value       = aws_autoscaling_group.sensor_asg.arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group managing the Corelight sensor instances"
  value       = aws_autoscaling_group.sensor_asg.name
}

output "auto_scale_policy_id" {
  description = "ID of the Auto Scaling policy for scaling out (adding instances) when CPU utilization is high"
  value       = aws_autoscaling_policy.sensor_autoscale_policy.id
}

output "auto_scale_group_cloudwatch_alarm_id" {
  description = "ID of the CloudWatch alarm that triggers scale-out when CPU utilization exceeds the threshold"
  value       = aws_cloudwatch_metric_alarm.sensor_asg_high_cpu_alarm.id
}

output "auto_scale_policy_scale_in_id" {
  description = "ID of the Auto Scaling policy for scaling in (removing instances) when CPU utilization is low"
  value       = aws_autoscaling_policy.sensor_scale_in_policy.id
}

output "auto_scale_group_cloudwatch_low_cpu_alarm_id" {
  description = "ID of the CloudWatch alarm that triggers scale-in when CPU utilization falls below the threshold"
  value       = aws_cloudwatch_metric_alarm.sensor_asg_low_cpu_alarm.id
}

output "launch_template_id" {
  description = "ID of the launch template used to configure new sensor instances in the Auto Scaling Group"
  value       = aws_launch_template.sensor_launch_template.id
}

output "load_balancer_id" {
  description = "ID of the Gateway Load Balancer that distributes GENEVE encapsulated traffic to sensor instances"
  value       = aws_lb.sensor_lb.id
}

output "load_balancer_listener_id" {
  description = "ID of the Gateway Load Balancer listener that forwards traffic to the target group"
  value       = aws_lb_listener.load_balancer_listener.id
}

output "load_balancer_health_check_target_group" {
  description = "ID of the target group used by the Gateway Load Balancer to perform health checks on sensor instances"
  value       = aws_lb_target_group.health_check.id
}

output "monitoring_security_group_id" {
  description = "ID of the security group attached to the monitoring network interface that allows health check and GENEVE traffic"
  value       = aws_security_group.monitoring.id
}

output "monitoring_security_group_arn" {
  description = "ARN of the security group attached to the monitoring network interface. Required for IAM role configuration in the Lambda module"
  value       = aws_security_group.monitoring.arn
}

output "management_security_group_id" {
  description = "ID of the security group attached to the management network interface that allows SSH and administrative access"
  value       = aws_security_group.management.id
}

output "management_security_group_arn" {
  description = "ARN of the security group attached to the management network interface. Required for IAM role configuration in the Lambda module"
  value       = aws_security_group.management.arn
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for Lambda function logs. Required for IAM role configuration in the Lambda module"
  value       = aws_cloudwatch_log_group.log_group.arn
}
