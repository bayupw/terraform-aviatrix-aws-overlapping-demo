terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.63"
    }
    aviatrix = {
      source  = "aviatrixsystems/aviatrix"
      version = "~> 2.21.2"
    }
  }
}