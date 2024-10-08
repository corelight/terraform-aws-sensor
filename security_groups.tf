resource "aws_security_group" "monitoring" {
  name        = var.sensor_monitoring_security_group_name
  description = var.sensor_monitoring_security_group_description
  vpc_id      = data.aws_vpc.provided.id

  tags = merge({ Name : var.sensor_monitoring_security_group_name }, var.tags)
}

resource "aws_security_group_rule" "geneve_mirror_traffic_rule" {
  type              = "ingress"
  from_port         = 6081
  to_port           = 6081
  protocol          = "udp"
  security_group_id = aws_security_group.monitoring.id
  description       = "Gateway Load Balancer (GENEVE)"
  cidr_blocks       = [data.aws_vpc.provided.cidr_block]
}

resource "aws_security_group_rule" "monitor_traffic_rule" {
  type              = "ingress"
  from_port         = 41080
  to_port           = 41080
  protocol          = "tcp"
  security_group_id = aws_security_group.monitoring.id
  description       = "GWLB Health Check Port"
  cidr_blocks       = [data.aws_vpc.provided.cidr_block]
}

resource "aws_security_group_rule" "public_network_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.monitoring.id
  description       = "Default egress rule"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "management" {
  name        = var.sensor_management_security_group_name
  description = var.sensor_management_security_group_description
  vpc_id      = data.aws_vpc.provided.id

  tags = merge({ Name : var.sensor_management_security_group_name }, var.tags)
}

resource "aws_security_group_rule" "management_network_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.management.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "management_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.management.id

  cidr_blocks = [data.aws_vpc.provided.cidr_block]
  description = "SSH for Corelight Sensor Admins"
}
