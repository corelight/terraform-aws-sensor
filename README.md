# terraform-aws-sensor

Terraform for Corelight's AWS Cloud Sensor Deployment.

<img src="docs/overview.png" alt="overview">

## Usage
```terraform

module "sensor" {
  source = "github.com/corelight/terraform-aws-sensor"

  auto_scaling_availability_zones = ["<first az>", "<second az>"]
  aws_key_pair_name = "<key pair name>"
  
  # Request access to Corelight sensor AMI from you Account Executive
  corelight_sensor_ami_id = "<sensor AMI ID>"
  license_key = "<your Corelight sensor license key>"
  management_subnet_id = "<management subnet>"
  monitoring_subnet_id = "<monitoring subnet>"
  community_string = "<password for the sensor api>"
  vpc_id = "<vpc where the sensor auto scale group is deployed>"
  
  # (Optional) Enrichment Bucket - ASG should have an instance 
  # profile when using cloud enrichment
  enrichment_bucket_name = "<cloud enrichment s3 bucket name>"
  enrichment_bucket_region = "<cloud enrichment s3 bucket region>"
}
```

### Deployment

The variables for this module all have default values that can be overwritten
to meet your naming and compliance standards.

Deployment examples can be found [here](examples).

## License

The project is licensed under the [MIT][] license.

[MIT]: LICENSE