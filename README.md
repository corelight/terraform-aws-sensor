[#](#) terraform-aws-sensor

Terraform for Corelight's AWS Cloud Sensor Deployment.

<img src="docs/overview.png" alt="overview">

## Usage
```terraform

data "aws_subnet" "management" {
  id = "<management subnet id>"
}

module "asg_lambda_role" {
  source = "github.com/corelight/terraform-aws-sensor//modules/iam/lambda"

  lambda_cloudwatch_log_group_arn = module.sensor.cloudwatch_log_group_arn
  sensor_autoscaling_group_arn    = module.sensor.autoscaling_group_arn
  security_group_arn              = module.sensor.management_security_group_arn
  subnet_arn                      = data.aws_subnet.management.arn
}

module "sensor" {
  source = "github.com/corelight/terraform-aws-sensor"

  # Recommend deploying a sensor per availability zone. Multiple AZs can
  # be set but GWLB cross availability zone support is not recommended.
  auto_scaling_availability_zones = ["<availability zone>"]
  aws_key_pair_name = "<key pair name>"

  # Request access to Corelight sensor AMI from you Account Executive
  corelight_sensor_ami_id = "<sensor AMI ID>"
  license_key = "<your Corelight sensor license key>"
  management_subnet_id = "<management subnet>"
  monitoring_subnet_id = "<monitoring subnet>"
  community_string = "<password for the sensor api>"
  vpc_id = "<vpc where the sensor autoscaling group is deployed>"
  asg_lambda_iam_role_arn = module.asg_lambda_role.role_arn

  # (Optional) ASG should have an instance profile when using
  # the cloud enrichment feature
  enrichment_bucket_name = "<cloud enrichment s3 bucket name>"
  enrichment_bucket_region = "<cloud enrichment s3 bucket region>"
  enrichment_instance_profile_arn = aws_iam_instance_profile.corelight_sensor.arn

  # Optional - Fleet Manager
  fleet_token = "<the pairing token from the Fleet UI>"
  fleet_url   = "<the URL of the fleet instance from the Fleet UI>"
}


### Optional resources for enrichment
module "enrichment_sensor_role" {
  source = "github.com/corelight/terraform-aws-enrichment//modules/iam/sensor"
  enrichment_bucket_arn = data.aws_s3_bucket.enrichment_bucket.arn
}

resource "aws_iam_instance_profile" "corelight_sensor" {
  name = "<name of the instance profile>"
  role = module.enrichment_sensor_role.sensor_role_name
}
```

### Deployment

The variables for this module all have default values that can be overwritten
to meet your naming and compliance standards.

Deployment examples can be found [here][].

[here]: https://github.com/corelight/corelight-cloud/tree/main/terraform/aws-autoscaling-sensor

## License

The project is licensed under the [MIT][] license.

[MIT]: LICENSE

