resource "aws_security_group" "monitoring" {
  name   = "corelight_sensor_monitoring"
  vpc_id = data.aws_vpc.provided.id

  ingress {
    protocol    = "udp"
    from_port   = 6081
    to_port     = 6081
    cidr_blocks = [data.aws_vpc.provided.cidr_block]
    description = "Gateway Load Balancer (GENEVE)"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [data.aws_vpc.provided.cidr_block]
    description = "GWLB/NLB Health Check Port"
  }

  tags = var.tags
}

resource "aws_security_group" "management" {
  name   = "corelight_sensor_management"
  vpc_id = data.aws_vpc.provided.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_subnet.management_subnet.cidr_block]
    description = "SSH for Corelight Sensor Admins"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_subnet.fleet_subnet.cidr_block]
    description = "Access for Fleet Manager"
  }

  tags = var.tags
}