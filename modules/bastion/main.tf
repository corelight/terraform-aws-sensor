resource "aws_instance" "bastion" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.bastion_key_pair_name

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.bastion_nic.id
  }

  root_block_device {
    volume_size = var.os_disk_size
  }

  tags = merge(var.tags, { Name : var.bastion_instance_name })
}

resource "aws_security_group" "allow_ssh" {
  vpc_id      = var.vpc_id
  name        = "allow-ssh"
  description = "security group for bastion that allows ssh and all egress traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "allow-ssh" })
}

resource "aws_network_interface" "bastion_nic" {
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.allow_ssh.id]

  tags = var.tags
}

resource "aws_eip" "bastion_public_ip" {
  network_interface = aws_network_interface.bastion_nic.id

  tags = var.tags
}
