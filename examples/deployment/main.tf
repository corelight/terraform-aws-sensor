locals {
  vpc_id                   = "<vpc where resources are deployed>"
  monitoring_subnet        = "<monitoring subnet id>"
  management_subnet        = "<management subnet id>"
  sensor_ssh_key_pair_name = "<name of the ssh key in AWS used to access the sensor EC2 instances>"
  sensor_ami_id            = "<sensor ami id from Corelight>"
  license                  = "<your corelight sensor license key>"
  tags = {
    terraform : true,
    purpose : "Corelight"
  }
  fleet_token = "b1cd099ff22ed8a41abc63929d1db126"
  fleet_url   = "https://fleet.example.com:1443/fleet/v1/internal/softsensor/websocket"
}

data "aws_subnet" "management" {
  id = local.management_subnet
}

module "asg_lambda_role" {
  source = "github.com/corelight/terraform-aws-sensor//modules/iam/lambda"

  lambda_cloudwatch_log_group_arn = module.sensor.cloudwatch_log_group_arn
  security_group_arn              = module.sensor.management_security_group_arn
  sensor_autoscaling_group_name   = module.sensor.autoscaling_group_name
  subnet_arn                      = data.aws_subnet.management.arn

  tags = local.tags
}

module "sensor" {
  source = "github.com/corelight/terraform-aws-sensor"

  auto_scaling_availability_zones = ["us-east-1a"]
  aws_key_pair_name               = local.sensor_ssh_key_pair_name
  corelight_sensor_ami_id         = local.sensor_ami_id
  license_key                     = local.license
  management_subnet_id            = local.management_subnet
  monitoring_subnet_id            = local.monitoring_subnet
  community_string                = "<password for the sensor api>"
  vpc_id                          = local.vpc_id
  asg_lambda_iam_role_arn         = module.asg_lambda_role.role_arn
  fleet_token                     = local.fleet_token
  fleet_url                       = local.fleet_url

  tags = local.tags
}

module "bastion" {
  source = "github.com/corelight/terraform-aws-sensor//modules/bastion"

  bastion_key_pair_name        = "<AWS ssh key pair name for the bastion host>"
  subnet_id                    = data.aws_subnet.management.id
  management_security_group_id = module.sensor.management_security_group_id
  vpc_id                       = local.vpc_id
  public_ssh_allow_cidr_blocks = ["0.0.0.0/0"]

  tags = local.tags
}
