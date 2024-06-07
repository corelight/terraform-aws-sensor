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

  tags = local.tags
}

module "bastion" {
  source = "github.com/corelight/terraform-aws-sensor//modules/bastion"

  bastion_key_pair_name = "<AWS ssh key pair name for the bastion host>"
  subnet_id             = "<subnet with public ssh access>"
  vpc_id                = local.vpc_id

  tags = local.tags
}