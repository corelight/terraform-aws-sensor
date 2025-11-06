# Unit tests for variable validations

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

run "test_valid_vpc_id" {
  command = plan

  variables {
    vpc_id                  = "vpc-12345678"
    corelight_sensor_ami_id = "ami-12345678"
    monitoring_subnet_ids   = ["subnet-12345678"]
    management_subnet_ids   = ["subnet-87654321"]
    aws_key_pair_name       = "test-key"
    community_string        = "test-community"
    fleet_token             = "test-token"
    fleet_url               = "https://fleet.example.com"
    fleet_server_sslname    = "fleet.example.com"
    asg_lambda_iam_role_arn = "arn:aws:iam::123456789012:role/test-role"
  }

  # Should succeed with valid VPC ID format
  assert {
    condition     = var.vpc_id == "vpc-12345678"
    error_message = "VPC ID validation should accept valid format"
  }
}

run "test_invalid_vpc_id" {
  command = plan

  variables {
    vpc_id                  = "invalid-vpc"
    corelight_sensor_ami_id = "ami-12345678"
    monitoring_subnet_ids   = ["subnet-12345678"]
    management_subnet_ids   = ["subnet-87654321"]
    aws_key_pair_name       = "test-key"
    community_string        = "test-community"
    fleet_token             = "test-token"
    fleet_url               = "https://fleet.example.com"
    fleet_server_sslname    = "fleet.example.com"
    asg_lambda_iam_role_arn = "arn:aws:iam::123456789012:role/test-role"
  }

  # Should fail with invalid VPC ID format
  expect_failures = [
    var.vpc_id,
  ]
}

run "test_valid_ami_id" {
  command = plan

  variables {
    vpc_id                  = "vpc-12345678"
    corelight_sensor_ami_id = "ami-abcdef123456"
    monitoring_subnet_ids   = ["subnet-12345678"]
    management_subnet_ids   = ["subnet-87654321"]
    aws_key_pair_name       = "test-key"
    community_string        = "test-community"
    fleet_token             = "test-token"
    fleet_url               = "https://fleet.example.com"
    fleet_server_sslname    = "fleet.example.com"
    asg_lambda_iam_role_arn = "arn:aws:iam::123456789012:role/test-role"
  }

  # Should succeed with valid AMI ID format
  assert {
    condition     = var.corelight_sensor_ami_id == "ami-abcdef123456"
    error_message = "AMI ID validation should accept valid format"
  }
}

run "test_invalid_ami_id" {
  command = plan

  variables {
    vpc_id                  = "vpc-12345678"
    corelight_sensor_ami_id = "invalid-ami"
    monitoring_subnet_ids   = ["subnet-12345678"]
    management_subnet_ids   = ["subnet-87654321"]
    aws_key_pair_name       = "test-key"
    community_string        = "test-community"
    fleet_token             = "test-token"
    fleet_url               = "https://fleet.example.com"
    fleet_server_sslname    = "fleet.example.com"
    asg_lambda_iam_role_arn = "arn:aws:iam::123456789012:role/test-role"
  }

  # Should fail with invalid AMI ID format
  expect_failures = [
    var.corelight_sensor_ami_id,
  ]
}

run "test_valid_fleet_url" {
  command = plan

  variables {
    vpc_id                  = "vpc-12345678"
    corelight_sensor_ami_id = "ami-12345678"
    monitoring_subnet_ids   = ["subnet-12345678"]
    management_subnet_ids   = ["subnet-87654321"]
    aws_key_pair_name       = "test-key"
    community_string        = "test-community"
    fleet_token             = "test-token"
    fleet_url               = "https://fleet.corelight.com"
    fleet_server_sslname    = "fleet.corelight.com"
    asg_lambda_iam_role_arn = "arn:aws:iam::123456789012:role/test-role"
  }

  # Should succeed with valid HTTPS URL
  assert {
    condition     = can(regex("^https://", var.fleet_url))
    error_message = "Fleet URL validation should accept HTTPS URLs"
  }
}

run "test_invalid_fleet_url" {
  command = plan

  variables {
    vpc_id                  = "vpc-12345678"
    corelight_sensor_ami_id = "ami-12345678"
    monitoring_subnet_ids   = ["subnet-12345678"]
    management_subnet_ids   = ["subnet-87654321"]
    aws_key_pair_name       = "test-key"
    community_string        = "test-community"
    fleet_token             = "test-token"
    fleet_url               = "not-a-url"
    fleet_server_sslname    = "fleet.example.com"
    asg_lambda_iam_role_arn = "arn:aws:iam::123456789012:role/test-role"
  }

  # Should fail with invalid URL format
  expect_failures = [
    var.fleet_url,
  ]
}

run "test_cpu_threshold_validation_valid" {
  command = plan

  variables {
    vpc_id                      = "vpc-12345678"
    corelight_sensor_ami_id     = "ami-12345678"
    monitoring_subnet_ids       = ["subnet-12345678"]
    management_subnet_ids       = ["subnet-87654321"]
    aws_key_pair_name           = "test-key"
    community_string            = "test-community"
    fleet_token                 = "test-token"
    fleet_url                   = "https://fleet.example.com"
    fleet_server_sslname        = "fleet.example.com"
    asg_lambda_iam_role_arn     = "arn:aws:iam::123456789012:role/test-role"
    asg_cpu_scale_out_threshold = 80
    asg_cpu_scale_in_threshold  = 30
  }

  # Should succeed when scale-in < scale-out
  assert {
    condition     = var.asg_cpu_scale_in_threshold < var.asg_cpu_scale_out_threshold
    error_message = "Scale-in threshold should be less than scale-out threshold"
  }
}

run "test_cpu_threshold_validation_invalid" {
  command = plan

  variables {
    vpc_id                      = "vpc-12345678"
    corelight_sensor_ami_id     = "ami-12345678"
    monitoring_subnet_ids       = ["subnet-12345678"]
    management_subnet_ids       = ["subnet-87654321"]
    aws_key_pair_name           = "test-key"
    community_string            = "test-community"
    fleet_token                 = "test-token"
    fleet_url                   = "https://fleet.example.com"
    fleet_server_sslname        = "fleet.example.com"
    asg_lambda_iam_role_arn     = "arn:aws:iam::123456789012:role/test-role"
    asg_cpu_scale_out_threshold = 50
    asg_cpu_scale_in_threshold  = 60
  }

  # Should fail when scale-in >= scale-out
  expect_failures = [
    var.asg_cpu_scale_in_threshold,
  ]
}

run "test_cpu_threshold_out_of_range" {
  command = plan

  variables {
    vpc_id                      = "vpc-12345678"
    corelight_sensor_ami_id     = "ami-12345678"
    monitoring_subnet_ids       = ["subnet-12345678"]
    management_subnet_ids       = ["subnet-87654321"]
    aws_key_pair_name           = "test-key"
    community_string            = "test-community"
    fleet_token                 = "test-token"
    fleet_url                   = "https://fleet.example.com"
    fleet_server_sslname        = "fleet.example.com"
    asg_lambda_iam_role_arn     = "arn:aws:iam::123456789012:role/test-role"
    asg_cpu_scale_out_threshold = 150
  }

  # Should fail with out of range value
  expect_failures = [
    var.asg_cpu_scale_out_threshold,
  ]
}

run "test_license_key_or_fleet_url_required" {
  command = plan

  variables {
    vpc_id                  = "vpc-12345678"
    corelight_sensor_ami_id = "ami-12345678"
    monitoring_subnet_ids   = ["subnet-12345678"]
    management_subnet_ids   = ["subnet-87654321"]
    aws_key_pair_name       = "test-key"
    community_string        = "test-community"
    fleet_token             = "test-token"
    fleet_url               = "https://fleet.example.com"
    fleet_server_sslname    = "fleet.example.com"
    asg_lambda_iam_role_arn = "arn:aws:iam::123456789012:role/test-role"
    license_key             = ""
  }

  # Should succeed when fleet_url is provided
  assert {
    condition     = var.fleet_url != ""
    error_message = "Either license_key or fleet_url must be provided"
  }
}
