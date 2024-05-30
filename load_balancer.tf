resource "aws_subnet" "lb_subnet_one" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.17.0/24"
  availability_zone = "us-east-2a"
}

resource "aws_subnet" "lb_subnet_two" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.16.0/24"
  availability_zone = "us-east-2b"
}

resource "aws_lb" "sensor_asg_load_balancer" {
  name    = var.asg_load_balancer_name
  subnets = [aws_subnet.lb_subnet_one.id, aws_subnet.lb_subnet_two.id]
}

resource "aws_lb_listener" "load_balancer_listener" {
  load_balancer_arn = aws_lb.sensor_asg_load_balancer.arn
  port              = 6081
  protocol          = "HTTPS"
  default_action {
    type             = "forward"
    target_group_arn = awscc_elasticloadbalancingv2_target_group.health_check.target_group_arn
  }
}

resource "awscc_elasticloadbalancingv2_target_group" "health_check" {
  name                          = var.alb_health_check_target_group_name
  vpc_id                        = var.vpc_id
  protocol                      = "GENEVE"
  port                          = 6081
  health_check_enabled          = true
  health_check_protocol         = "HTTPS"
  health_check_path             = "/api/system/healthcheck/"
  health_check_port             = "443"
  health_check_interval_seconds = 30
  healthy_threshold_count       = 3
  unhealthy_threshold_count     = 3
  target_type                   = "instance"
}
