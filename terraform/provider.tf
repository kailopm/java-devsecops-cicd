terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket       = "java-devsecops-tf-state"
    key          = "terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
    encrypt      = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-southeast-1"
}