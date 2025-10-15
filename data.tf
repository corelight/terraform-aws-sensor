data "aws_vpc" "provided" {
  id = var.vpc_id
}

data "aws_subnet" "monitoring_subnets" {
  for_each = toset(var.monitoring_subnet_ids)
  id       = each.value
}

data "aws_subnet" "management_subnets" {
  for_each = toset(var.management_subnet_ids)
  id       = each.value
}