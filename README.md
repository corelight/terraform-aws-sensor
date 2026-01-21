# terraform-aws-sensor

Terraform for Corelight's AWS Cloud Sensor Deployment.

<img src="docs/overview.png" alt="overview">

## Overview

This module deploys Corelight sensors in an AWS Auto Scaling Group with Lambda-managed network interface attachment.

### Architecture

The deployment requires **two separate modules** working together:

1. **IAM Lambda Module** (`modules/iam/lambda`) - Creates the IAM role and policy
2. **Sensor Module** (root module) - Creates the Lambda function, ASG, and all sensor infrastructure

> **Why separate modules?** The sensor module creates the Lambda **function** but requires you to provide the IAM **role** ARN. This separation allows for flexible IAM configurations and follows AWS best practices for least privilege access.

### Required Resources
These resources are essential for a working sensor deployment:
- **IAM Lambda Role** (`module.asg_lambda_role`) - IAM role for the ENI management Lambda function (created by `modules/iam/lambda`)
- **Sensor Auto Scaling Group** (`module.sensor`) - The core sensor infrastructure including Lambda function (created by root module)
- **Management Subnets** - At least one subnet per availability zone for sensor management
- **Monitoring Subnets** - At least one subnet per availability zone for traffic monitoring

### Optional Resources
These resources enhance sensor functionality but are not required:
- **Enrichment IAM Role** (`module.enrichment_sensor_role`) - Enables S3 bucket access for data enrichment
- **Bastion Hosts** - For secure SSH access to sensors (not shown in basic example)
- **Custom KMS Keys** - For EBS volume encryption beyond AWS-managed keys

## Usage

### Single Region Deployment

```terraform
data "aws_subnet" "management" {
  for_each = toset(["<management subnet id 1>", "<management subnet id 2>"])
  id       = each.value
}

# REQUIRED: IAM role for Lambda function
# This creates the IAM role/policy that the Lambda function will assume
module "asg_lambda_role" {
  source = "github.com/corelight/terraform-aws-sensor//modules/iam/lambda"

  lambda_cloudwatch_log_group_arn = module.sensor.cloudwatch_log_group_arn
  sensor_autoscaling_group_arn    = module.sensor.autoscaling_group_arn
  security_group_arn              = module.sensor.management_security_group_arn
  subnet_arns                     = [for subnet in data.aws_subnet.management : subnet.arn]
}

# REQUIRED: Main sensor deployment
# This creates the Lambda function, ASG, and all infrastructure
# It requires the IAM role ARN created above
module "sensor" {
  source = "github.com/corelight/terraform-aws-sensor"

  # Multi-AZ support: provide one subnet per availability zone
  # The ASG will automatically distribute instances across AZs
  availability_zones = ["us-east-1a", "us-east-1b"]
  aws_key_pair_name = "<key pair name>"

  # Request access to Corelight sensor AMI from your Account Executive
  corelight_sensor_ami_id = "<sensor AMI ID>"
  license_key = "<your Corelight sensor license key>"

  # Provide one management subnet per AZ (must match availability_zones order)
  management_subnet_ids = ["<management subnet in us-east-1a>", "<management subnet in us-east-1b>"]

  # Provide one monitoring subnet per AZ (must match availability_zones order)
  monitoring_subnet_ids = ["<monitoring subnet in us-east-1a>", "<monitoring subnet in us-east-1b>"]

  community_string = "<password for the sensor api>"
  vpc_id = "<vpc where the sensor autoscaling group is deployed>"
  asg_lambda_iam_role_arn = module.asg_lambda_role.role_arn

  fleet_token = "<the pairing token from the Fleet UI>"
  fleet_url   = "<the URL of the fleet instance from the Fleet UI>"
  fleet_server_sslname = "<the ssl name provided by Fleet>"

  # OPTIONAL: KMS key for EBS volume encryption
  kms_key_id  = "<the ID of the KMS key used to encrypt the EBS volumes>"
}

# OPTIONAL: Resources for S3 enrichment
module "enrichment_sensor_role" {
  source = "github.com/corelight/terraform-aws-enrichment//modules/iam/sensor"
  enrichment_bucket_arn = data.aws_s3_bucket.enrichment_bucket.arn
}

resource "aws_iam_instance_profile" "corelight_sensor" {
  name = "<name of the instance profile>"
  role = module.enrichment_sensor_role.sensor_role_name
}
```

### Multi-Region Deployment

When deploying sensors across multiple regions, you need to understand which resources are region-specific:

**Region-Specific Resources** (deploy once per region):
- Sensor Auto Scaling Group and all its components
- Lambda function and CloudWatch Log Groups
- IAM Lambda Role (references regional resources like log groups and subnets)
- VPCs, Subnets, and Security Groups

**Global Resources** (deploy once, shared across regions):
- IAM roles that don't reference regional ARNs (rare in this setup)
- Fleet configuration (same fleet instance can manage sensors in multiple regions)

#### Multi-Region Example

```terraform
# ============================================================================
# Region 1: US-EAST-1
# ============================================================================
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_subnet" "management_east" {
  provider = aws.us_east_1
  for_each = toset(var.management_subnet_ids_east)
  id       = each.value
}

# IAM role for Lambda (region-specific due to log group and subnet ARNs)
module "asg_lambda_role_east" {
  source = "github.com/corelight/terraform-aws-sensor//modules/iam/lambda"
  providers = {
    aws = aws.us_east_1
  }

  lambda_cloudwatch_log_group_arn = module.sensor_east.cloudwatch_log_group_arn
  sensor_autoscaling_group_arn    = module.sensor_east.autoscaling_group_arn
  security_group_arn              = module.sensor_east.management_security_group_arn
  subnet_arns                     = [for subnet in data.aws_subnet.management_east : subnet.arn]

  # Use unique names per region to avoid conflicts
  lambda_role_name   = "corelight-asg-sensor-nic-manager-lambda-role-us-east-1"
  lambda_policy_name = "corelight-asg-sensor-nic-manager-lambda-policy-us-east-1"

  tags = var.tags
}

# Sensor deployment for US-EAST-1
module "sensor_east" {
  source = "github.com/corelight/terraform-aws-sensor"
  providers = {
    aws = aws.us_east_1
  }

  availability_zones    = ["us-east-1a", "us-east-1b"]
  aws_key_pair_name     = var.aws_key_pair_name_east
  corelight_sensor_ami_id = var.corelight_sensor_ami_id_east
  management_subnet_ids = var.management_subnet_ids_east
  monitoring_subnet_ids = var.monitoring_subnet_ids_east
  vpc_id                = var.vpc_id_east

  # Same Fleet instance can manage sensors in multiple regions
  fleet_token          = var.fleet_token
  fleet_url            = var.fleet_url
  fleet_server_sslname = var.fleet_server_sslname
  community_string     = var.community_string

  asg_lambda_iam_role_arn = module.asg_lambda_role_east.role_arn

  # Use unique names per region
  sensor_asg_name = "corelight-sensor-us-east-1"

  tags = var.tags
}

# ============================================================================
# Region 2: US-WEST-2
# ============================================================================
provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"
}

data "aws_subnet" "management_west" {
  provider = aws.us_west_2
  for_each = toset(var.management_subnet_ids_west)
  id       = each.value
}

# IAM role for Lambda (region-specific due to log group and subnet ARNs)
module "asg_lambda_role_west" {
  source = "github.com/corelight/terraform-aws-sensor//modules/iam/lambda"
  providers = {
    aws = aws.us_west_2
  }

  lambda_cloudwatch_log_group_arn = module.sensor_west.cloudwatch_log_group_arn
  sensor_autoscaling_group_arn    = module.sensor_west.autoscaling_group_arn
  security_group_arn              = module.sensor_west.management_security_group_arn
  subnet_arns                     = [for subnet in data.aws_subnet.management_west : subnet.arn]

  # Use unique names per region to avoid conflicts
  lambda_role_name   = "corelight-asg-sensor-nic-manager-lambda-role-us-west-2"
  lambda_policy_name = "corelight-asg-sensor-nic-manager-lambda-policy-us-west-2"

  tags = var.tags
}

# Sensor deployment for US-WEST-2
module "sensor_west" {
  source = "github.com/corelight/terraform-aws-sensor"
  providers = {
    aws = aws.us_west_2
  }

  availability_zones    = ["us-west-2a", "us-west-2b"]
  aws_key_pair_name     = var.aws_key_pair_name_west
  corelight_sensor_ami_id = var.corelight_sensor_ami_id_west
  management_subnet_ids = var.management_subnet_ids_west
  monitoring_subnet_ids = var.monitoring_subnet_ids_west
  vpc_id                = var.vpc_id_west

  # Same Fleet instance can manage sensors in multiple regions
  fleet_token          = var.fleet_token
  fleet_url            = var.fleet_url
  fleet_server_sslname = var.fleet_server_sslname
  community_string     = var.community_string

  asg_lambda_iam_role_arn = module.asg_lambda_role_west.role_arn

  # Use unique names per region
  sensor_asg_name = "corelight-sensor-us-west-2"

  tags = var.tags
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

