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
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(var.tags, { Name : var.bastion_instance_name })
}

resource "aws_network_interface" "bastion_nic" {
  subnet_id       = var.public_subnet_id
  security_groups = [aws_security_group.bastion_sg.id]

  tags = merge({ Name : "${var.bastion_instance_name}-nic" }, var.tags)
}

resource "aws_eip" "bastion_public_ip" {
  instance          = aws_instance.bastion.id
  network_interface = aws_network_interface.bastion_nic.id

  tags = merge({ Name : "${var.bastion_instance_name}-public-ip" }, var.tags)
}
