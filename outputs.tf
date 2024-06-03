# output "gwlb_lb_arn" {
#   value = awscc_elasticloadbalancingv2_load_balancer.sensor_lb.load_balancer_arn
# }

output "gwlb_lb_arn" {
  value = aws_lb.sensor_lb.arn
}