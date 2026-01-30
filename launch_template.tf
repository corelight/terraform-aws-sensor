resource "aws_launch_template" "sensor_launch_template" {
  name = var.sensor_launch_template_name

  instance_type = var.sensor_launch_template_instance_type
  image_id      = var.corelight_sensor_ami_id
  key_name      = var.aws_key_pair_name
  ebs_optimized = false

  dynamic "iam_instance_profile" {
    for_each = var.instance_profile_arn == "" ? toset([]) : toset([1])

    content {
      arn = var.instance_profile_arn
    }
  }

  # CKV_AWS_79: Enforce IMDSv2 (Instance Metadata Service Version 2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  block_device_mappings {
    device_name = var.sensor_launch_template_volume_name

    ebs {
      volume_size           = var.sensor_launch_template_volume_size
      volume_type           = "gp3"
      iops                  = var.ebs_iops
      encrypted             = var.kms_key_id == "" ? false : true
      kms_key_id            = var.kms_key_id == "" ? null : var.kms_key_id
      delete_on_termination = true
    }
  }

  network_interfaces {
    device_index          = 0
    security_groups       = [aws_security_group.monitoring.id]
    delete_on_termination = true
  }

  user_data = module.sensor_config.cloudinit_config.rendered

  tags = var.tags

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }
}
