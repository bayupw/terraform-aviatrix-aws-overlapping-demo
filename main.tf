data "aws_region" "current" {}

# Create 3 digit random string
resource "random_string" "this" {
  length  = 3
  number  = true
  special = false
  upper   = false
}

# Create VPCs, subnets, route tables
module "vpcs" {
  for_each = var.vpcs

  source               = "terraform-aws-modules/vpc/aws"
  version              = "~> 3.0"
  name                 = "${each.value.name}-${random_string.this.id}"
  cidr                 = each.value.cidr
  azs                  = each.value.azs
  public_subnets       = each.value.public_subnets
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "AviatrixDemo"
  }
}

# Create IAM role and IAM instance profile for SSM
module "ssm_instance_profile" {
  source  = "bayupw/ssm-instance-profile/aws"
  version = "1.0.0"
}

# VPC-A Web Server EC2 instance in VPC-A
module "web_server" {
  source  = "bayupw/amazon-linux-2/aws"
  version = "1.0.0"

  random_suffix                  = false
  instance_hostname              = local.webserver_hostname
  vpc_id                         = module.vpcs["vpc_a"].vpc_id
  subnet_id                      = module.vpcs["vpc_a"].public_subnets[0]
  private_ip                     = cidrhost(module.vpcs["vpc_a"].public_subnets_cidr_blocks[0], 11)
  iam_instance_profile           = module.ssm_instance_profile.aws_iam_instance_profile
  associate_public_ip_address    = true
  enable_password_authentication = true
  random_password                = false
  instance_username              = var.username
  instance_password              = var.password
  key_name                       = var.key_name
  custom_ingress_cidrs           = ["100.65.0.0/24"]

  depends_on = [module.vpcs, module.ssm_instance_profile]
}


# VPC-B Client EC2 instance in VPC-B
module "client" {
  source  = "bayupw/amazon-linux-2/aws"
  version = "1.0.0"

  random_suffix                  = false
  instance_hostname              = local.client_hostname
  vpc_id                         = module.vpcs["vpc_b"].vpc_id
  subnet_id                      = module.vpcs["vpc_b"].public_subnets[0]
  private_ip                     = cidrhost(module.vpcs["vpc_b"].public_subnets_cidr_blocks[0], 11)
  iam_instance_profile           = module.ssm_instance_profile.aws_iam_instance_profile
  associate_public_ip_address    = true
  enable_password_authentication = true
  random_password                = false
  instance_username              = var.username
  instance_password              = var.password
  key_name                       = var.key_name
  custom_ingress_cidrs           = ["100.64.0.0/24"]

  depends_on = [module.vpcs, module.ssm_instance_profile]
}

# VPC-B VGW
resource "aws_vpn_gateway" "consumer_vgw" {
  vpc_id = module.vpcs["vpc_b"].vpc_id

  tags = {
    Name = "vgw-vpc-b"
  }

  depends_on = [module.vpcs]
}

# VPC-B VGW
resource "aws_vpn_gateway_attachment" "vgw_attachment" {
  vpc_id         = module.vpcs["vpc_b"].vpc_id
  vpn_gateway_id = aws_vpn_gateway.consumer_vgw.id

  depends_on = [aws_vpn_gateway.consumer_vgw]
}

# VPC-B CGW for Aviatrix Gateway
resource "aws_customer_gateway" "aviatrix_gw" {
  bgp_asn    = 65000 #placeholder asn
  ip_address = aviatrix_spoke_gateway.provider_gw.eip
  type       = "ipsec.1"

  tags = {
    Name = "cgw-${aviatrix_spoke_gateway.provider_gw.gw_name}"
  }

  depends_on = [aviatrix_spoke_gateway.provider_gw]
}

# VPC-B CGW for Aviatrix HA Gateway
resource "aws_customer_gateway" "aviatrix_ha_gw" {
  count = var.ha_gw == true ? 1 : 0

  bgp_asn    = 65000 #placeholder asn
  ip_address = aviatrix_spoke_gateway.provider_gw.ha_eip
  type       = "ipsec.1"

  tags = {
    Name = "cgw-${aviatrix_spoke_gateway.provider_gw.ha_gw_name}"
  }

  depends_on = [aviatrix_spoke_gateway.provider_gw]
}

# Create S2S VPN to Aviatrix Gateway
resource "aws_vpn_connection" "aviatrix_gw_connection" {
  vpn_gateway_id      = aws_vpn_gateway.consumer_vgw.id
  customer_gateway_id = aws_customer_gateway.aviatrix_gw.id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name = "aviatrix-gw-connection"
  }

  depends_on = [aws_vpn_gateway_attachment.vgw_attachment, aws_customer_gateway.aviatrix_gw]
}

# Create S2S VPN to Aviatrix HA Gateway
resource "aws_vpn_connection" "aviatrix_hagw_connection" {
  count = var.ha_gw == true ? 1 : 0

  vpn_gateway_id      = aws_vpn_gateway.consumer_vgw.id
  customer_gateway_id = aws_customer_gateway.aviatrix_ha_gw[0].id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name = "aviatrix-hagw-connection"
  }

  depends_on = [aws_vpn_gateway_attachment.vgw_attachment, aws_customer_gateway.aviatrix_gw]
}

# VGW Route Aviatrix Gateway
resource "aws_vpn_connection_route" "route_aviatrix_gw" {
  destination_cidr_block = "100.64.0.0/24"
  vpn_connection_id      = aws_vpn_connection.aviatrix_gw_connection.id
}

# VGW Route Aviatrix HA Gateway
resource "aws_vpn_connection_route" "route_aviatrix_hagw" {
  count = var.ha_gw == true ? 1 : 0

  destination_cidr_block = "100.64.0.0/24"
  vpn_connection_id      = aws_vpn_connection.aviatrix_hagw_connection[0].id
}

# Enable route propagation from VGW
resource "aws_vpn_gateway_route_propagation" "vgw_propagation" {
  vpn_gateway_id = aws_vpn_gateway.consumer_vgw.id
  route_table_id = module.vpcs["vpc_b"].public_route_table_ids[0]
}

# Create Private Zone aviatrix.demo
resource "aws_route53_zone" "aviatrixdemo" {
  name = "aviatrix.demo"

  vpc {
    vpc_id = module.vpcs["vpc_a"].vpc_id
  }

  vpc {
    vpc_id = module.vpcs["vpc_b"].vpc_id
  }
}

resource "aws_route53_record" "web" {
  zone_id = aws_route53_zone.aviatrixdemo.zone_id
  name    = "web.${aws_route53_zone.aviatrixdemo.name}"
  type    = "A"
  ttl     = "300"
  records = ["100.64.0.11"]
}

resource "aws_route53_record" "client" {
  zone_id = aws_route53_zone.aviatrixdemo.zone_id
  name    = "client.${aws_route53_zone.aviatrixdemo.name}"
  type    = "A"
  ttl     = "300"
  records = ["100.65.0.11"]
}