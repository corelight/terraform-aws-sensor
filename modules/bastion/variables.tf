variable "vpc_id" {
  description = ""
  type        = string
}

variable "subnet_id" {
  description = ""
  type        = string
}

variable "key_pair_name" {
  description = ""
  type        = string
}

# Variables with Defaults
variable "os_disk_size" {
  description = ""
  type        = string
  default     = 60
}
variable "bastion_instance_name" {
  description = ""
  type        = string
  default     = "corelight-bastion"
}
variable "instance_type" {
  description = ""
  type        = string
  default     = "t4g.nano"
}

variable "ami_id" {
  description = ""
  type        = string
  default     = "ami-08a04a1d153bf02a7"
}

variable "tags" {
  description = "Any tags that should be applied to resources deployed by the module"
  type        = object({})
  default     = {}
}

