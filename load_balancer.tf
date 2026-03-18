resource "aws_lb" "sensor_lb" {
  name                             = var.sensor_asg_load_balancer_name
  load_balancer_type               = "gateway"
  subnets                          = [for subnet in data.aws_subnet.monitoring_subnets : subnet.id]
  enable_cross_zone_load_balancing = true
}

resource "aws_lb_listener" "load_balancer_listener" {
  load_balancer_arn = aws_lb.sensor_lb.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.health_check.arn
  }
}

resource "aws_lb_target_group" "health_check" {
  name        = var.lb_health_check_target_group_name
  vpc_id      = data.aws_vpc.provided.id
  protocol    = "GENEVE"
  port        = 6081
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = var.healthcheck_path
    port                = var.sensor_health_check_http_port
    interval            = 60
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_vpc_endpoint_service" "gwlb_service" {
  acceptance_required        = var.vpc_endpoint_service_acceptance_required
  gateway_load_balancer_arns = [aws_lb.sensor_lb.arn]

  tags = merge(
    var.tags,
    {
      Name = "${var.sensor_asg_load_balancer_name}-service"
    },
  )
}