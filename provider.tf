terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.61.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.8.0"

  backend "s3" {
    bucket = "amazonq-integration"
    key    = "lca-wellington"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}
