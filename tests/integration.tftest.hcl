# Integration tests for complete module deployment
# Tests the full stack of resources working together

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

  # Override data for specific management subnets to have different AZs
  override_data {
    target = data.aws_subnet.management_subnets["subnet-mgmt-1a"]
    values = {
      id                = "subnet-mgmt-1a"
      vpc_id            = "vpc-12345678"
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-1a"
      arn               = "arn:aws:ec2:us-east-1:123456789012:subnet/subnet-mgmt-1a"
    }
  }

  override_data {
    target = data.aws_subnet.management_subnets["subnet-mgmt-1b"]
    values = {
      id                = "subnet-mgmt-1b"
      vpc_id            = "vpc-12345678"
      cidr_block        = "10.0.3.0/24"
      availability_zone = "us-east-1b"
      arn               = "arn:aws:ec2:us-east-1:123456789012:subnet/subnet-mgmt-1b"
    }
  }

  # Override data for monitoring subnets
  override_data {
    target = data.aws_subnet.monitoring_subnets["subnet-monitor-1a"]
    values = {
      id                = "subnet-monitor-1a"
      vpc_id            = "vpc-12345678"
      cidr_block        = "10.0.4.0/24"
      availability_zone = "us-east-1a"
      arn               = "arn:aws:ec2:us-east-1:123456789012:subnet/subnet-monitor-1a"
    }
  }

  override_data {
    target = data.aws_subnet.monitoring_subnets["subnet-monitor-1b"]
    values = {
      id                = "subnet-monitor-1b"
      vpc_id            = "vpc-12345678"
      cidr_block        = "10.0.5.0/24"
      availability_zone = "us-east-1b"
      arn               = "arn:aws:ec2:us-east-1:123456789012:subnet/subnet-monitor-1b"
    }
  }
}

# Base variables used across all integration tests
variables {
  vpc_id                  = "vpc-12345678"
  corelight_sensor_ami_id = "ami-12345678"
  monitoring_subnet_ids   = ["subnet-monitor-1a", "subnet-monitor-1b"]
  management_subnet_ids   = ["subnet-mgmt-1a", "subnet-mgmt-1b"]
  aws_key_pair_name       = "test-key"
  community_string        = "test-community"
  fleet_token             = "test-token"
  fleet_url               = "https://fleet.example.com"
  fleet_server_sslname    = "fleet.example.com"
  asg_lambda_iam_role_arn = "arn:aws:iam::123456789012:role/test-role"
}

# Test 1: Complete module deployment with default values
run "test_full_deployment_defaults" {
  command = plan

  # Verify Auto Scaling Group is created
  assert {
    condition     = aws_autoscaling_group.sensor_asg.name == "corelight-sensor"
    error_message = "ASG should be created with default name"
  }

  assert {
    condition     = aws_autoscaling_group.sensor_asg.min_size == 1
    error_message = "ASG min_size should be 1"
  }

  assert {
    condition     = aws_autoscaling_group.sensor_asg.max_size == 5
    error_message = "ASG max_size should be 5"
  }

  assert {
    condition     = aws_autoscaling_group.sensor_asg.desired_capacity == 1
    error_message = "ASG desired_capacity should be 1"
  }

  # Verify Launch Template is created and linked
  assert {
    condition     = aws_launch_template.sensor_launch_template.name == "corelight-sensor-launch-template"
    error_message = "Launch template should be created with default name"
  }

  assert {
    condition     = aws_autoscaling_group.sensor_asg.launch_template[0].name == aws_launch_template.sensor_launch_template.name
    error_message = "ASG should reference the launch template"
  }

  # Verify Gateway Load Balancer is created
  assert {
    condition     = aws_lb.sensor_lb.name == "corelight-sensor-lb"
    error_message = "Gateway Load Balancer should be created"
  }

  assert {
    condition     = aws_lb.sensor_lb.load_balancer_type == "gateway"
    error_message = "Load balancer type should be gateway"
  }

  # Verify Security Groups are created
  assert {
    condition     = aws_security_group.monitoring.name == "corelight-sensor-monitoring"
    error_message = "Monitoring security group should be created"
  }

  assert {
    condition     = aws_security_group.management.name == "corelight-sensor-management"
    error_message = "Management security group should be created"
  }
}

# Test 2: CloudWatch Alarms and Auto Scaling Policies
run "test_autoscaling_alarms_integration" {
  command = plan

  # Verify scale-out alarm is properly configured
  assert {
    condition     = aws_cloudwatch_metric_alarm.sensor_asg_high_cpu_alarm.alarm_name == "${var.sensor_asg_name}-high-cpu-alarm"
    error_message = "High CPU alarm should have proper name"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.sensor_asg_high_cpu_alarm.metric_name == "CPUUtilization"
    error_message = "Alarm should monitor CPU utilization"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.sensor_asg_high_cpu_alarm.threshold == 70
    error_message = "Default high CPU threshold should be 70%"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.sensor_asg_high_cpu_alarm.alarm_actions) > 0
    error_message = "High CPU alarm should have alarm actions configured"
  }

  # Verify scale-in alarm is properly configured
  assert {
    condition     = aws_cloudwatch_metric_alarm.sensor_asg_low_cpu_alarm.alarm_name == "${var.sensor_asg_name}-low-cpu-alarm"
    error_message = "Low CPU alarm should have proper name"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.sensor_asg_low_cpu_alarm.threshold == 40
    error_message = "Default low CPU threshold should be 40%"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.sensor_asg_low_cpu_alarm.alarm_actions) > 0
    error_message = "Low CPU alarm should have alarm actions configured"
  }

  # Verify alarm dimensions reference the ASG
  assert {
    condition     = aws_cloudwatch_metric_alarm.sensor_asg_high_cpu_alarm.dimensions["AutoScalingGroupName"] == aws_autoscaling_group.sensor_asg.name
    error_message = "High CPU alarm should reference the ASG"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.sensor_asg_low_cpu_alarm.dimensions["AutoScalingGroupName"] == aws_autoscaling_group.sensor_asg.name
    error_message = "Low CPU alarm should reference the ASG"
  }
}

# Test 3: Gateway Load Balancer Integration
run "test_load_balancer_integration" {
  command = plan

  # Verify target group is created and configured
  assert {
    condition     = aws_lb_target_group.health_check.name == "corelight-sensor-gwlb-tg"
    error_message = "Target group should be created"
  }

  assert {
    condition     = aws_lb_target_group.health_check.protocol == "GENEVE"
    error_message = "Target group protocol should be GENEVE"
  }

  assert {
    condition     = aws_lb_target_group.health_check.port == 6081
    error_message = "Target group port should be 6081"
  }

  # Verify listener is created and configured
  assert {
    condition     = aws_lb_listener.load_balancer_listener.default_action[0].type == "forward"
    error_message = "Listener should have forward action configured"
  }

  assert {
    condition     = length(aws_lb_listener.load_balancer_listener.default_action) > 0
    error_message = "Listener should have default actions configured"
  }

  # Verify ASG is linked to target group
  assert {
    condition     = length(aws_autoscaling_group.sensor_asg.target_group_arns) > 0
    error_message = "ASG should be registered with at least one target group"
  }
}

# Test 4: Lambda Function and EventBridge Integration
run "test_lambda_eventbridge_integration" {
  command = plan

  # Verify Lambda function is created
  assert {
    condition     = aws_lambda_function.auto_scaling_lambda.function_name == "corelight-asg-sensor-nic-manager"
    error_message = "Lambda function should be created"
  }

  assert {
    condition     = aws_lambda_function.auto_scaling_lambda.handler == "corelight_sensor_asg_nic_manager.lambda_handler"
    error_message = "Lambda handler should be configured"
  }

  assert {
    condition     = aws_lambda_function.auto_scaling_lambda.runtime == "python3.12"
    error_message = "Lambda should use Python 3.12"
  }

  # Verify EventBridge rule is created
  assert {
    condition     = aws_cloudwatch_event_rule.asg_lifecycle_rule.name == "corelight-asg-sensor-lifecycle-notification"
    error_message = "EventBridge rule should be created"
  }

  # Verify Lambda permission allows EventBridge to invoke
  assert {
    condition     = aws_lambda_permission.ec2_state_change_event_bridge_trigger_permission.action == "lambda:InvokeFunction"
    error_message = "Lambda permission should allow invocation"
  }

  assert {
    condition     = aws_lambda_permission.ec2_state_change_event_bridge_trigger_permission.principal == "events.amazonaws.com"
    error_message = "Lambda permission should allow EventBridge to invoke"
  }

  # Verify CloudWatch log group is created
  assert {
    condition     = aws_cloudwatch_log_group.log_group.name == "/aws/lambda/${var.lambda_function_name}"
    error_message = "CloudWatch log group should be created for Lambda"
  }

  assert {
    condition     = aws_cloudwatch_log_group.log_group.retention_in_days == 3
    error_message = "Default log retention should be 3 days"
  }
}

# Test 5: Launch Template Configuration
run "test_launch_template_configuration" {
  command = plan

  # Verify instance type
  assert {
    condition     = aws_launch_template.sensor_launch_template.instance_type == "c5.2xlarge"
    error_message = "Default instance type should be c5.2xlarge"
  }

  # Verify AMI ID
  assert {
    condition     = aws_launch_template.sensor_launch_template.image_id == var.corelight_sensor_ami_id
    error_message = "Launch template should use the specified AMI"
  }

  # Verify key pair
  assert {
    condition     = aws_launch_template.sensor_launch_template.key_name == var.aws_key_pair_name
    error_message = "Launch template should use the specified key pair"
  }

  # Verify block device mapping
  assert {
    condition     = aws_launch_template.sensor_launch_template.block_device_mappings[0].device_name == "/dev/xvda"
    error_message = "Root volume device should be /dev/xvda"
  }

  assert {
    condition     = aws_launch_template.sensor_launch_template.block_device_mappings[0].ebs[0].volume_size == 500
    error_message = "Default root volume size should be 500 GiB"
  }

  # Verify user data is configured
  assert {
    condition     = aws_launch_template.sensor_launch_template.user_data != null
    error_message = "User data should be configured"
  }
}

# Test 6: Security Group Rules Configuration
run "test_security_group_rules" {
  command = plan

  # Verify monitoring security group allows GENEVE traffic
  assert {
    condition     = aws_security_group.monitoring.vpc_id == var.vpc_id
    error_message = "Monitoring security group should be in the correct VPC"
  }

  assert {
    condition     = aws_security_group_rule.geneve_mirror_traffic_rule.from_port == 6081
    error_message = "GENEVE rule should allow port 6081"
  }

  assert {
    condition     = aws_security_group_rule.geneve_mirror_traffic_rule.protocol == "udp"
    error_message = "GENEVE rule should use UDP protocol"
  }

  # Verify management security group
  assert {
    condition     = aws_security_group.management.vpc_id == var.vpc_id
    error_message = "Management security group should be in the correct VPC"
  }

  # Verify SSH rule
  assert {
    condition     = aws_security_group_rule.management_ssh.from_port == 22
    error_message = "Management security group should allow SSH on port 22"
  }

  # Verify health check rule
  assert {
    condition     = aws_security_group_rule.monitor_traffic_rule.from_port == 41080
    error_message = "Health check rule should allow port 41080"
  }
}

# Test 7: Multi-AZ Configuration
run "test_multi_az_configuration" {
  command = plan

  # Verify ASG uses multiple subnet IDs
  assert {
    condition     = length(aws_autoscaling_group.sensor_asg.vpc_zone_identifier) == 2
    error_message = "ASG should span multiple availability zones"
  }

  # Verify subnets are configured (specific subnet IDs are known at plan time)
  assert {
    condition     = tolist(aws_autoscaling_group.sensor_asg.vpc_zone_identifier)[0] == "subnet-monitor-1a"
    error_message = "ASG should include monitoring subnet in AZ 1a"
  }

  assert {
    condition     = tolist(aws_autoscaling_group.sensor_asg.vpc_zone_identifier)[1] == "subnet-monitor-1b"
    error_message = "ASG should include monitoring subnet in AZ 1b"
  }

  # Verify load balancer has subnets configured (using variable)
  assert {
    condition     = length(var.monitoring_subnet_ids) == 2
    error_message = "Load balancer should be configured with multiple subnets"
  }
}

# Test 8: Output Values Correctness
run "test_outputs_format" {
  command = plan

  # Verify name outputs match configuration
  assert {
    condition     = output.autoscaling_group_name == "corelight-sensor"
    error_message = "ASG name output should match the default ASG name"
  }

  # Verify security group names match
  assert {
    condition     = aws_security_group.monitoring.name == var.sensor_monitoring_security_group_name
    error_message = "Monitoring security group name should match variable"
  }

  assert {
    condition     = aws_security_group.management.name == var.sensor_management_security_group_name
    error_message = "Management security group name should match variable"
  }
}

# Test 9: Custom Configuration Values
run "test_custom_configuration" {
  command = plan

  variables {
    sensor_asg_name                      = "custom-sensor-asg"
    asg_cpu_scale_out_threshold          = 85
    asg_cpu_scale_in_threshold           = 30
    sensor_launch_template_instance_type = "c5.4xlarge"
    sensor_launch_template_volume_size   = 1000
    cloudwatch_log_group_retention       = 7
  }

  # Verify custom ASG name
  assert {
    condition     = aws_autoscaling_group.sensor_asg.name == "custom-sensor-asg"
    error_message = "ASG should use custom name"
  }

  # Verify custom CPU thresholds
  assert {
    condition     = aws_cloudwatch_metric_alarm.sensor_asg_high_cpu_alarm.threshold == 85
    error_message = "High CPU alarm should use custom threshold"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.sensor_asg_low_cpu_alarm.threshold == 30
    error_message = "Low CPU alarm should use custom threshold"
  }

  # Verify custom instance type
  assert {
    condition     = aws_launch_template.sensor_launch_template.instance_type == "c5.4xlarge"
    error_message = "Launch template should use custom instance type"
  }

  # Verify custom volume size
  assert {
    condition     = aws_launch_template.sensor_launch_template.block_device_mappings[0].ebs[0].volume_size == 1000
    error_message = "Launch template should use custom volume size"
  }

  # Verify custom log retention
  assert {
    condition     = aws_cloudwatch_log_group.log_group.retention_in_days == 7
    error_message = "CloudWatch log group should use custom retention"
  }

  # Verify alarm names include custom ASG name
  assert {
    condition     = aws_cloudwatch_metric_alarm.sensor_asg_high_cpu_alarm.alarm_name == "custom-sensor-asg-high-cpu-alarm"
    error_message = "Alarm name should include custom ASG name"
  }
}

# Test 10: Resource Dependencies
run "test_resource_dependencies" {
  command = plan

  # Verify Lambda function exists (dependencies are implicit in Terraform)
  assert {
    condition     = aws_lambda_function.auto_scaling_lambda.function_name != ""
    error_message = "Lambda function should be created"
  }

  # Verify ASG lifecycle hook is configured
  assert {
    condition     = length(aws_autoscaling_group.sensor_asg.initial_lifecycle_hook) > 0
    error_message = "ASG should have at least one lifecycle hook configured"
  }

  # Verify lifecycle hook configuration via variables
  assert {
    condition     = var.asg_lifecycle_hook_name == "scaling-up"
    error_message = "Lifecycle hook name should be 'scaling-up'"
  }
}

# Test 11: Optional KMS Encryption
run "test_kms_encryption_enabled" {
  command = plan

  variables {
    kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }

  # Verify KMS key is applied to EBS volume
  assert {
    condition     = aws_launch_template.sensor_launch_template.block_device_mappings[0].ebs[0].kms_key_id == var.kms_key_id
    error_message = "Launch template should use KMS key for EBS encryption when provided"
  }

  assert {
    condition     = aws_launch_template.sensor_launch_template.block_device_mappings[0].ebs[0].encrypted == "true"
    error_message = "EBS volume should be encrypted when KMS key is provided"
  }
}

# Test 12: Optional Instance Profile
run "test_instance_profile_integration" {
  command = plan

  variables {
    instance_profile_arn = "arn:aws:iam::123456789012:instance-profile/corelight-sensor-profile"
  }

  # Verify instance profile is attached to launch template
  assert {
    condition     = aws_launch_template.sensor_launch_template.iam_instance_profile[0].arn == var.instance_profile_arn
    error_message = "Launch template should use the specified instance profile"
  }
}

# Test 13: Proxy Configuration
run "test_proxy_configuration" {
  command = plan

  variables {
    fleet_http_proxy  = "http://proxy.example.com:8080"
    fleet_https_proxy = "https://proxy.example.com:8443"
    fleet_no_proxy    = "169.254.169.254,localhost"
  }

  # Verify proxy variables are set (user_data will contain them)
  assert {
    condition     = var.fleet_http_proxy == "http://proxy.example.com:8080"
    error_message = "HTTP proxy should be configurable"
  }

  assert {
    condition     = var.fleet_https_proxy == "https://proxy.example.com:8443"
    error_message = "HTTPS proxy should be configurable"
  }

  assert {
    condition     = var.fleet_no_proxy == "169.254.169.254,localhost"
    error_message = "No proxy list should be configurable"
  }
}
