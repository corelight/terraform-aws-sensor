data "aws_vpc" "provided" {
  id = var.vpc_id
}

data "aws_subnet" "monitoring_subnet" {
  id = var.monitoring_subnet_id
}

data "aws_subnet" "management_subnet" {
  id = var.management_subnet_id
}