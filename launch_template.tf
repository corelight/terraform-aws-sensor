resource "aws_launch_template" "sensor_launch_template" {
  name = var.sensor_launch_template_name

  instance_type = var.sensor_launch_template_instance_type
  image_id      = var.corelight_sensor_ami_id
  key_name      = var.aws_key_pair_name
  ebs_optimized = false

  network_interfaces {
    device_index         = 0
    network_interface_id = aws_network_interface.monitoring_nic.id
  }

  network_interfaces {
    device_index         = 1
    network_interface_id = aws_network_interface.management_nic.id
  }

  user_data = module.sensor_config.cloudinit_config.rendered

  tags = var.tags
}

resource "aws_network_interface" "monitoring_nic" {
  subnet_id       = data.aws_subnet.monitoring_subnet.id
  security_groups = [aws_security_group.monitoring.id]

  tags = merge(var.tags, { name : var.monitoring_nic_name })
}

resource "aws_network_interface" "management_nic" {
  subnet_id       = data.aws_subnet.management_subnet.id
  security_groups = [aws_security_group.management.id]

  tags = merge(var.tags, { name : var.management_nic_name })
}

