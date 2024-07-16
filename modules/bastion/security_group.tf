resource "aws_security_group" "bastion_sg" {
  vpc_id      = var.vpc_id
  name        = var.bastion_security_group_name
  description = var.bastion_security_group_description

  tags = merge(var.tags, { Name = var.bastion_security_group_name })
}

resource "aws_security_group_rule" "public_network_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.bastion_sg.id
  description       = "Public SSH to bastion host"
  cidr_blocks       = var.public_ssh_allow_cidr_blocks
}

resource "aws_security_group_rule" "public_network_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.bastion_sg.id
  description       = "Default egress rule"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "management_subnet_ssh_access" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = var.management_security_group_id
  description              = "SSH Access from Bastion"
  source_security_group_id = aws_security_group.bastion_sg.id
}