variable "vpc_id" {
  description = "The ID of the VPC where resources will be deployed"
  type        = string
}

variable "corelight_sensor_ami_id" {
  description = "The AMI ID of the Corelight sensor. Request access to the AMI from your account executive"
  type        = string
}

variable "monitoring_subnet_id" {
  description = "The ID of the subnet where monitor traffic will be available"
  type        = string
}

variable "management_subnet_id" {
  description = "The ID of the subnet used to SSH / manage Corelight sensors"
  type        = string
}

variable "aws_key_pair_name" {
  description = "The name of the AWS key pair that will be used to access the sensor instances in the auto-scale group"
  type        = string
}

variable "availability_zones" {
  description = "The availability zone the auto scale group and load balancer will use"
  type        = list(string)
}

variable "community_string" {
  description = "the community string (api string) often times referenced by Fleet"
  type        = string
  sensitive   = true
}

variable "license_key" {
  description = "Your Corelight sensor license key"
  sensitive   = true
  type        = string
}

# Variables with Defaults
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

variable "lb_health_check_target_group_name" {
  description = "The name of the health check target group which determines if the sensor in the ASG comes up and is ready to accept traffic"
  type        = string
  default     = "corelight-sensor-gwlb-tg"
}

variable "sensor_monitoring_security_group_name" {
  description = "Name of the security group used to allow health check and GENEVE traffic to the sensor"
  type        = string
  default     = "corelight-sensor-monitoring"
}

variable "sensor_monitoring_security_group_description" {
  description = "Description of the security group used to allow access to the monitoring NIC"
  type        = string
  default     = "Security group for the sensor which allows health check and GENEVE traffic inbound"
}

variable "sensor_management_security_group_name" {
  description = "Name of the security group used to allow access to the monitoring NIC"
  type        = string
  default     = "corelight-sensor-management"
}

variable "sensor_management_security_group_description" {
  description = "Name of the security group used to allow SSH access to the sensor"
  type        = string
  default     = "Security group for the sensor which allows ssh from the DMZ / Bastion"
}

variable "enrichment_bucket_name" {
  description = "(optional) The name of the s3 bucket where cloud enrichment data is being stored"
  type        = string
  default     = ""
}

variable "enrichment_bucket_region" {
  description = "(optional) The region of the cloud enrichment s3 bucket"
  type        = string
  default     = ""
}

variable "enrichment_iam_role_arn" {
  description = "(optional) When configuring enrichment, an instance profile must be added granting the ASG EC2 nodes access to read from the bucket"
  type        = string
  default     = ""
}

variable "eventbridge_lifecycle_rule_name" {
  description = "Auto Scale Group EventBridge rule name"
  type        = string
  default     = "corelight-asg-sensor-lifecycle-notification"
}

variable "lambda_function_name" {
  description = "Name of the Multi-ENI lambda function"
  type        = string
  default     = "corelight-asg-sensor-nic-manager"
}

variable "iam_lambda_role_name" {
  description = "The name of the Multi-ENI lambda role"
  type        = string
  default     = "corelight-asg-sensor-nic-manager-lambda-role"
}

variable "cloudwatch_log_group_prefix" {
  description = "The cloudwatch string prepended to the cloud watch log group name"
  type        = string
  default     = "/aws/lambda"
}

variable "cloudwatch_log_group_retention" {
  description = "The Lambda log group retention in days"
  type        = number
  default     = 3
}

variable "asg_lifecycle_hook_name" {
  description = "name of the lifecycle hook triggered when new instances are launched"
  type        = string
  default     = "scaling-up"
}

variable "tags" {
  description = "(optional) Any tags that should be applied to resources deployed by the module"
  type        = object({})
  default     = {}
}