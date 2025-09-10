data "aws_vpc" "provided" {
  id = var.vpc_id
}

data "aws_subnet" "monitoring_subnet" {
  id = var.monitoring_subnet_id
}