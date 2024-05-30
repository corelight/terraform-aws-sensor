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

  user_data = var.enrichment_bucket_name == "" ? data.cloudinit_config.config.rendered : data.cloudinit_config.config_with_enrichment.rendered

  tags = var.tags
}

resource "aws_subnet" "sensor_asg_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = var.asg_subnet_cidr

  tags = merge(var.tags,
    { name : var.sensor_asg_subnet_name }
  )
}

resource "aws_network_interface" "monitoring_nic" {
  subnet_id = aws_subnet.sensor_asg_subnet.id
  security_groups = [
    aws_security_group.monitoring.id
  ]

  tags = merge(var.tags,
    { name : var.monitoring_nic_name }
  )
}

resource "aws_network_interface" "management_nic" {
  subnet_id = aws_subnet.sensor_asg_subnet.id
  security_groups = [
    data.aws_subnet.management_subnet.id
  ]

  tags = merge(var.tags,
    { name : var.management_nic_name }
  )
}

