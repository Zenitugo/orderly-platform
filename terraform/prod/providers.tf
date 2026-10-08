terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.14"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"
}