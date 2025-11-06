# terraform-aws-sensor

Terraform for Corelight's AWS Cloud Sensor Deployment.

<img src="docs/overview.png" alt="overview">

## Usage
```terraform

data "aws_subnet" "management" {
  for_each = toset(["<management subnet id 1>", "<management subnet id 2>"])
  id       = each.value
}

module "asg_lambda_role" {
  source = "github.com/corelight/terraform-aws-sensor//modules/iam/lambda"

  lambda_cloudwatch_log_group_arn = module.sensor.cloudwatch_log_group_arn
  sensor_autoscaling_group_arn    = module.sensor.autoscaling_group_arn
  security_group_arn              = module.sensor.management_security_group_arn
  subnet_arns                     = [for subnet in data.aws_subnet.management : subnet.arn]
}

module "sensor" {
  source = "github.com/corelight/terraform-aws-sensor"

  # Request access to Corelight sensor AMI from you Account Executive
  corelight_sensor_ami_id = "<sensor AMI ID>"
  license_key = "<your Corelight sensor license key>"
  aws_key_pair_name = "<key pair name>"

  # Multi-AZ support: provide one subnet per availability zone
  # The ASG will automatically distribute instances across AZs based on subnets
  # Provide monitoring subnet per AZ
  monitoring_subnet_ids = ["<monitoring subnet in us-east-1a>", "<monitoring subnet in us-east-1b>"]

  # Provide management subnet per AZ
  management_subnet_ids = ["<management subnet in us-east-1a>", "<management subnet in us-east-1b>"]

  community_string = "<password for the sensor api>"
  vpc_id = "<vpc where the sensor autoscaling group is deployed>"
  asg_lambda_iam_role_arn = module.asg_lambda_role.role_arn

  fleet_token = "<the pairing token from the Fleet UI>"
  fleet_url   = "<the URL of the fleet instance from the Fleet UI>"
  fleet_server_sslname = "<the ssl name provided by Fleet>"

  # optional KMS key, if set will encrpyt the EBS volumes launched by the auto scaler group
  kms_key_id  = "<the ID of the KMS key used to encrypt the EBS volumes>"
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

#### Quick Start with terraform.tfvars

The easiest way to deploy the sensor is using a `terraform.tfvars` file:

1. Copy the example tfvars file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and fill in your values:
   ```hcl
   # Required Variables
   vpc_id                  = "vpc-xxxxxxxxx"
   corelight_sensor_ami_id = "ami-xxxxxxxxx"
   aws_key_pair_name       = "your-key-pair-name"

   # Multi-AZ Network Configuration
   monitoring_subnet_ids = [
     "subnet-xxxxxxxxx",  # Monitoring subnet in AZ 1
     "subnet-xxxxxxxxx",  # Monitoring subnet in AZ 2
   ]

   management_subnet_ids = [
     "subnet-xxxxxxxxx",  # Management subnet in AZ 1
     "subnet-xxxxxxxxx",  # Management subnet in AZ 2
   ]

   # Sensor Configuration
   community_string = "your-secure-api-password"

   # Fleet Configuration
   fleet_token          = "your-fleet-pairing-token"
   fleet_url            = "https://fleet.example.com"
   fleet_server_sslname = "fleet.example.com"

   # IAM Role (from lambda module)
   asg_lambda_iam_role_arn = "arn:aws:iam::123456789012:role/corelight-lambda-role"
   ```

3. Initialize and deploy:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

See `terraform.tfvars.example` for a complete list of available variables including optional configurations for KMS encryption, proxy settings, CPU thresholds, and more.

#### Module Usage

The variables for this module all have default values that can be overwritten
to meet your naming and compliance standards.

Additional deployment examples can be found [here][].

[here]: https://github.com/corelight/corelight-cloud/tree/main/terraform/aws-autoscaling-sensor

## Development

### Testing

This module includes comprehensive unit and integration tests using Terraform's native testing framework.

#### Running Tests

```bash
# Run all tests
task test

# Run tests with verbose output
task test:verbose

# Run specific test suites
task test:validation    # Variable validation tests
task test:resources     # Resource configuration tests
task test:outputs       # Output tests
task test:multi-az      # Multi-AZ functionality tests
task test:defaults      # Default values tests
task test:integration   # Integration tests

# Run all CI checks (format, validate, test, security scan)
task ci
```

#### Test Structure

```
tests/
├── unit_validation.tftest.hcl   # Variable validation tests
├── unit_resources.tftest.hcl    # Resource configuration tests
├── unit_outputs.tftest.hcl      # Output tests
├── unit_multi_az.tftest.hcl     # Multi-AZ functionality tests
├── unit_defaults.tftest.hcl     # Default values tests
└── integration.tftest.hcl       # Full stack integration tests
```

For detailed testing documentation, see [tests/README.md](tests/README.md).

### Code Quality

#### Format Check
```bash
# Check Terraform formatting
task fmt:check

# Auto-format Terraform files
task fmt
```

#### Security Scanning
```bash
# Run Trivy security scan
task trivy:scan
```

### Continuous Integration

The module includes GitHub Actions workflows for:
- **Terraform Validation**: Format checking and validation on PRs
- **Unit Tests**: Comprehensive test suite on PRs and main branch
- **Security Scanning**: Trivy scans on PRs and nightly
- **Lambda Tests**: Python unit tests for Lambda functions
- **Full CI Pipeline**: Combined format, validate, and test checks

## License

The project is licensed under the [MIT][] license.

[MIT]: LICENSE

