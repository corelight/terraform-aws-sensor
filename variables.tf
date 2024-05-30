variable "vpc_id" {
  description = ""
  type        = string
}

variable "corelight_sensor_ami_id" {
  description = ""
  type        = string
}

variable "management_subnet_id" {
  description = ""
  type        = string
}

variable "fleet_subnet_id" {
  description = ""
  type        = string
}

variable "aws_key_pair_name" {
  description = ""
  type        = string
}

variable "auto_scaling_availability_zones" {
  description = ""
  type        = list(string)
}

variable "sensor_api_password" {
  description = "The password that should be used for the Corelight sensor API"
  sensitive   = true
  type        = string
}

variable "license_key" {
  description = "Your Corelight sensor license key"
  type        = string
}

variable "asg_subnet_cidr" {
  description = ""
  type        = string
}

# Variables with Defaults
variable "asg_load_balancer_name" {
  description = ""
  type        = string
  default     = "corelight-sensor-lb"
}
variable "sensor_asg_name" {
  description = ""
  type        = string
  default     = "corelight-sensor"
}

variable "sensor_asg_subnet_name" {
  description = ""
  type        = string
  default     = "corelight-sensor-asg-subnet"
}

variable "monitoring_nic_name" {
  description = ""
  type        = string
  default     = "corelight-mon-nic"
}

variable "management_nic_name" {
  description = ""
  type        = string
  default     = "corelight-mgmt-nic"
}


variable "sensor_launch_template_name" {
  description = ""
  type        = string
  default     = "corelight-sensor-launch-template"
}

variable "sensor_launch_template_instance_type" {
  description = ""
  type        = string
  default     = "c5.2xlarge"
}

variable "alb_health_check_target_group_name" {
  description = ""
  type        = string
  default     = "corelight-sensor-gwlb-tg"
}

variable "enrichment_bucket_name" {
  description = ""
  type        = string
  default     = ""
}

variable "enrichment_bucket_region" {
  description = ""
  type        = string
  default     = ""
}

variable "tags" {
  description = "Any tags that should be applied to resources deployed by the module"
  type        = object({})
  default     = {}
}