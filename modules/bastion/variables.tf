variable "vpc_id" {
  description = "The VPC the sensor ASG is deployed in"
  type        = string
}

variable "public_subnet_id" {
  description = "A subnet which can be publicly accessible via SSH"
  type        = string
}

variable "management_security_group_id" {
  description = "ID of the management security group"
  type        = string
}

variable "bastion_key_pair_name" {
  description = "The AWS key pair which should be used to access the bastion host"
  type        = string
}

# Variables with Defaults
variable "os_disk_size" {
  description = "The size of the bastion host primary disk"
  type        = string
  default     = 60
}

variable "bastion_instance_name" {
  description = "The name of the bastion ec2 instance"
  type        = string
  default     = "corelight-bastion"
}

variable "instance_type" {
  description = "The bastion host EC2 instance type"
  type        = string
  default     = "t4g.nano"
}

variable "ami_id" {
  description = "The AMI ID used for the bastion host. Default is AL2023"
  type        = string
  default     = "ami-08a04a1d153bf02a7"
}

variable "bastion_security_group_name" {
  description = "The name of the bastion security group used to allow SSH access from the public"
  type        = string
  default     = "corelight-bastion-allow-ssh"
}

variable "bastion_security_group_description" {
  description = "The description of the bastion security group used to allow SSH access"
  type        = string
  default     = "security group for bastion that allows ssh and all egress traffic"
}

variable "tags" {
  description = "(optional) Any tags that should be applied to resources deployed by the module"
  type        = object({})
  default     = {}
}

