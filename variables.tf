variable "vpc_id" {
  description = "The ID of the VPC where resources will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]{8,}$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC identifier (vpc-xxxxxxxx)."
  }
}

variable "corelight_sensor_ami_id" {
  description = "The AMI ID of the Corelight sensor. Request access to the AMI from your account executive"
  type        = string

  validation {
    condition     = can(regex("^ami-[a-f0-9]{8,}$", var.corelight_sensor_ami_id))
    error_message = "AMI ID must be a valid AWS AMI identifier (ami-xxxxxxxx)."
  }
}

variable "monitoring_subnet_ids" {
  description = "List of subnet IDs where monitor traffic will be available, one per availability zone"
  type        = list(string)
}

variable "management_subnet_ids" {
  description = "List of subnet IDs used to SSH / manage Corelight sensors, one per availability zone"
  type        = list(string)
}

variable "aws_key_pair_name" {
  description = "The name of the AWS key pair that will be used to access the sensor instances in the auto-scale group"
  type        = string
}


variable "community_string" {
  description = "API password for sensor management and authentication. Used by Fleet and other management interfaces to access the sensor API"
  type        = string
  sensitive   = true
}

variable "fleet_token" {
  type        = string
  sensitive   = true
  description = "Pairing token from the Fleet UI. Must be set if 'fleet_url' is provided"
}

variable "fleet_url" {
  type        = string
  description = "URL of the fleet instance from the Fleet UI. Must be set if 'fleet_token' is provided"

  validation {
    condition     = can(regex("^https?://[a-zA-Z0-9.-]+", var.fleet_url))
    error_message = "fleet_url must be a valid HTTP/HTTPS URL."
  }
}

variable "fleet_server_sslname" {
  type        = string
  description = "SSL hostname for the fleet server"
}

variable "kms_key_id" {
  description = "The KMS key ID to be used for EBS volume encryption for the auto-scale group instances"
  type        = string
  default     = null
}

variable "license_key" {
  description = "Your Corelight sensor license key. Optional if fleet_url is configured."
  sensitive   = true
  type        = string
  default     = ""

  validation {
    condition     = var.license_key != "" || var.fleet_url != ""
    error_message = "Either license_key must be provided or fleet_url must be configured."
  }
}

variable "asg_lambda_iam_role_arn" {
  description = "ARN of the ASG lambda role created in the `iam/lambda` sub-module"
  type        = string
}

# Variables with defaults
variable "sensor_asg_auto_scale_policy_name" {
  description = "The name of the auto-scale group policy"
  type        = string
  default     = "corelight-sensor-asg-policy"
}

variable "sensor_asg_load_balancer_name" {
  description = "The name of the load balancer which fronts the auto-scale group"
  type        = string
  default     = "corelight-sensor-lb"
}

variable "sensor_asg_name" {
  description = "The name of the Corelight sensor auto-scale group"
  type        = string
  default     = "corelight-sensor"
}

variable "asg_cpu_scale_out_threshold" {
  description = "CPU utilization percentage threshold to trigger scale-out (add instances)"
  type        = number
  default     = 70

  validation {
    condition     = var.asg_cpu_scale_out_threshold > 0 && var.asg_cpu_scale_out_threshold <= 100
    error_message = "CPU scale-out threshold must be between 1 and 100."
  }
}

variable "asg_cpu_scale_in_threshold" {
  description = "CPU utilization percentage threshold to trigger scale-in (remove instances)"
  type        = number
  default     = 40

  validation {
    condition     = var.asg_cpu_scale_in_threshold > 0 && var.asg_cpu_scale_in_threshold <= 100
    error_message = "CPU scale-in threshold must be between 1 and 100."
  }

  validation {
    condition     = var.asg_cpu_scale_in_threshold < var.asg_cpu_scale_out_threshold
    error_message = "CPU scale-in threshold must be lower than scale-out threshold to prevent scaling thrashing."
  }
}

variable "monitoring_nic_name" {
  description = "The name of the Network Interface used for monitoring GENEVE traffic to the sensor"
  type        = string
  default     = "corelight-mon-nic"
}

variable "management_nic_name" {
  description = "The name of the Network Interface used for management of the sensor - SSH/HTTPS"
  type        = string
  default     = "corelight-mgmt-nic"
}


variable "sensor_launch_template_name" {
  description = "The name of the launch template used by the auto-scale group"
  type        = string
  default     = "corelight-sensor-launch-template"
}

variable "sensor_launch_template_instance_type" {
  description = "The instance type the auto-scale group will use for each instance"
  type        = string
  default     = "c5.2xlarge"
}

variable "sensor_launch_template_volume_name" {
  description = "Device path for the root EBS volume attached to sensor instances"
  type        = string
  default     = "/dev/xvda"
}

variable "sensor_launch_template_volume_size" {
  description = "Size of the root EBS volume for sensor instances in GiB. Minimum recommended size is 500 GiB for optimal performance"
  type        = number
  default     = 500
}

variable "lb_health_check_target_group_name" {
  description = "Name of the Gateway Load Balancer target group used for health checks to verify sensor instances are healthy and ready to receive traffic"
  type        = string
  default     = "corelight-sensor-gwlb-tg"
}

variable "sensor_monitoring_security_group_name" {
  description = "Name of the security group attached to the monitoring network interface to allow health check and GENEVE encapsulated traffic"
  type        = string
  default     = "corelight-sensor-monitoring"
}

variable "sensor_monitoring_security_group_description" {
  description = "Description of the security group attached to the monitoring network interface that allows health check and GENEVE traffic inbound from the Gateway Load Balancer"
  type        = string
  default     = "Security group for the sensor which allows health check and GENEVE traffic inbound"
}

variable "sensor_management_security_group_name" {
  description = "Name of the security group used to allow access to the management NIC for SSH and administrative access"
  type        = string
  default     = "corelight-sensor-management"
}

variable "sensor_management_security_group_description" {
  description = "Description of the security group used to allow SSH and administrative access to the sensor from authorized sources"
  type        = string
  default     = "Security group for the sensor which allows SSH from the DMZ / Bastion"
}

variable "instance_profile_arn" {
  description = "ARN of the IAM instance profile to attach to sensor instances. Required for enrichment features that need AWS API access (e.g., S3, Route53). Leave empty if not using enrichment features"
  type        = string
  default     = ""
}

variable "eventbridge_lifecycle_rule_name" {
  description = "Name of the EventBridge rule that triggers Lambda functions during Auto Scaling Group lifecycle events (instance launch/terminate)"
  type        = string
  default     = "corelight-asg-sensor-lifecycle-notification"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function that manages network interface (ENI) attachments during sensor instance lifecycle events"
  type        = string
  default     = "corelight-asg-sensor-nic-manager"
}

variable "cloudwatch_log_group_prefix" {
  description = "Prefix for the CloudWatch log group name. This is prepended to the Lambda function name to create the log group path"
  type        = string
  default     = "/aws/lambda"
}

variable "cloudwatch_log_group_retention" {
  description = "Number of days to retain Lambda function logs in CloudWatch Logs. After this period, logs are automatically deleted"
  type        = number
  default     = 3
}

variable "asg_lifecycle_hook_name" {
  description = "Name of the lifecycle hook triggered when new instances are launched in the Auto Scaling Group"
  type        = string
  default     = "scaling-up"
}

variable "fleet_http_proxy" {
  type        = string
  default     = ""
  description = "HTTP proxy URL for Fleet communication. Leave empty to connect directly without a proxy"
}

variable "fleet_https_proxy" {
  type        = string
  default     = ""
  description = "HTTPS proxy URL for Fleet communication. Leave empty to connect directly without a proxy"
}

variable "fleet_no_proxy" {
  type        = string
  default     = ""
  description = "Comma-separated list of hosts or domains to bypass proxy settings for Fleet traffic (e.g., '169.254.169.254,localhost,.internal')"
}
