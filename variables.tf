variable "vpcs" {
  description = "Maps of VPC attributes"
  type        = map(any)
  default = {
    vpc_a = {
      name           = "Aviatrix-Provider-VPC-A"
      cidr           = "10.0.0.0/16"
      azs            = ["ap-southeast-2a", "ap-southeast-2b"]
      public_subnets = ["10.0.0.0/24", "10.0.1.0/24"]
    }
    vpc_b = {
      name           = "Aviatrix-Consumer-VPC-B"
      cidr           = "10.0.0.0/16"
      azs            = ["ap-southeast-2a"]
      public_subnets = ["10.0.0.0/24"]
    }
  }
}

variable "aws_account" {
  description = "AWS Account name"
  type        = string
  default     = "aws-account"
}

variable "ha_gw" {
  description = "Set to true to enable HA"
  type        = bool
  default     = false
}

variable "username" {
  description = "EC2 instance username"
  type        = string
  default     = "ec2-user"
}

variable "password" {
  description = "EC2 instance password"
  type        = string
  default     = "Aviatrix123#"
}

variable "key_name" {
  description = "Existing EC2 Key Pair"
  type        = string
  default     = "ec2_keypair"
}

locals {
  client_hostname    = "aviatrixdemo-client-${random_string.this.id}"
  webserver_hostname = "aviatrixdemo-webserver-${random_string.this.id}"
}