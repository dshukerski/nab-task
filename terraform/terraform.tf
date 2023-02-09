terraform {
  # Terraform Version
  required_version = "~> 1.3.0"

  # Providers
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.52.0"
    }
  }
}