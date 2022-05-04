terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.4.0"
    }
    aviatrix = {
      source  = "aviatrixsystems/aviatrix"
      version = "~> 2.21.2"
    }
  }
}