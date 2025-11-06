# Mock providers for testing without AWS credentials

terraform {
  required_version = ">=1.3.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5"
    }
  }
}

# Mock providers - these will use override files in actual tests
provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  # Mock endpoints for testing
  endpoints {
    ec2                  = "http://localhost:4566"
    iam                  = "http://localhost:4566"
    lambda               = "http://localhost:4566"
    cloudwatch           = "http://localhost:4566"
    autoscaling          = "http://localhost:4566"
    elasticloadbalancing = "http://localhost:4566"
    events               = "http://localhost:4566"
    logs                 = "http://localhost:4566"
  }
}
