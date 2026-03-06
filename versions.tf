terraform {
  required_version = ">=1.3.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 1"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2"
    }
  }
}