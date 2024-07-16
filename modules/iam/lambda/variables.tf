variable "lambda_cloudwatch_log_group_arn" {
  description = "ARN of the log group the Lambda will use to create streams and write logs"
  type        = string
}

variable "sensor_autoscaling_group_name" {
  description = "ARN of the sensor EC2 autoscaling group of Corelight sensors"
  type        = string
}

variable "subnet_arn" {
  description = "ARN of the subnet where new ENIs should be created (management)"
  type        = string
}

variable "security_group_arn" {
  description = "ARN of the security group that should be associated with newly created ENIs"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN of the ENI management lambda role"
  type        = string
  default     = "corelight-asg-sensor-nic-manager-lambda-role"
}

# Variables with defaults
variable "lambda_policy_name" {
  description = "Name of the policy granting permission to the ENI management lambda"
  type        = string
  default     = "corelight-asg-sensor-nic-manager-lambda-policy"
}

variable "tags" {
  description = "(optional) Any tags that should be applied to resources deployed by the module"
  type        = object({})
  default     = {}
}