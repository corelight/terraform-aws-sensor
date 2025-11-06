# Unit tests for default values and optional parameters

mock_provider "aws" {
  mock_data "aws_vpc" {
    defaults = {
      id         = "vpc-12345678"
      cidr_block = "10.0.0.0/16"
      arn        = "arn:aws:ec2:us-east-1:123456789012:vpc/vpc-12345678"
    }
  }

  mock_data "aws_subnet" {
    defaults = {
      id                = "subnet-12345678"
      vpc_id            = "vpc-12345678"
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
      arn               = "arn:aws:ec2:us-east-1:123456789012:subnet/subnet-12345678"
    }
  }
}

variables {
  vpc_id                  = "vpc-12345678"
  corelight_sensor_ami_id = "ami-12345678"
  monitoring_subnet_ids   = ["subnet-monitor-1a"]
  management_subnet_ids   = ["subnet-mgmt-1a"]
  aws_key_pair_name       = "test-key"
  community_string        = "test-community"
  fleet_token             = "test-token"
  fleet_url               = "https://fleet.example.com"
  fleet_server_sslname    = "fleet.example.com"
  asg_lambda_iam_role_arn = "arn:aws:iam::123456789012:role/test-role"
}

run "test_default_asg_name" {
  command = plan

  # Verify default ASG name
  assert {
    condition     = var.sensor_asg_name == "corelight-sensor"
    error_message = "Default ASG name should be 'corelight-sensor'"
  }
}

run "test_default_cpu_thresholds" {
  command = plan

  # Verify default CPU threshold values
  assert {
    condition     = var.asg_cpu_scale_out_threshold == 70
    error_message = "Default scale-out threshold should be 70"
  }

  assert {
    condition     = var.asg_cpu_scale_in_threshold == 40
    error_message = "Default scale-in threshold should be 40"
  }
}

run "test_default_instance_type" {
  command = plan

  # Verify default instance type
  assert {
    condition     = var.sensor_launch_template_instance_type == "c5.2xlarge"
    error_message = "Default instance type should be c5.2xlarge"
  }
}

run "test_default_volume_size" {
  command = plan

  # Verify default volume size
  assert {
    condition     = var.sensor_launch_template_volume_size == 500
    error_message = "Default volume size should be 500 GB"
  }
}

run "test_default_cloudwatch_retention" {
  command = plan

  # Verify default CloudWatch log retention
  assert {
    condition     = var.cloudwatch_log_group_retention == 3
    error_message = "Default CloudWatch log retention should be 3 days"
  }
}

run "test_optional_kms_key_null" {
  command = plan

  # Verify KMS key is optional (null by default)
  assert {
    condition     = var.kms_key_id == null
    error_message = "KMS key should be optional and null by default"
  }
}

run "test_custom_cpu_thresholds" {
  command = plan

  variables {
    asg_cpu_scale_out_threshold = 85
    asg_cpu_scale_in_threshold  = 25
  }

  # Verify custom CPU thresholds can be set
  assert {
    condition     = var.asg_cpu_scale_out_threshold == 85
    error_message = "Should be able to set custom scale-out threshold"
  }

  assert {
    condition     = var.asg_cpu_scale_in_threshold == 25
    error_message = "Should be able to set custom scale-in threshold"
  }
}
