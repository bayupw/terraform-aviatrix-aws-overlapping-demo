# Create Aviatrix Spoke Gateway with HA in Production VPC
resource "aviatrix_spoke_gateway" "provider_gw" {
  cloud_type   = 1 # AWS Cloud Type
  account_name = var.aws_account
  gw_name      = "provider-gw"
  vpc_reg      = "ap-southeast-2"
  vpc_id       = module.vpcs["vpc_a"].vpc_id
  gw_size      = "t2.micro"
  subnet       = module.vpcs["vpc_a"].public_subnets_cidr_blocks[0]
  ha_gw_size   = var.ha_gw == true ? "t2.micro" : null
  ha_subnet    = var.ha_gw == true ? module.vpcs["vpc_a"].public_subnets_cidr_blocks[1] : null

  single_ip_snat                    = false
  manage_transit_gateway_attachment = false
}

# Create Site2Cloud
resource "aviatrix_site2cloud" "vgw_s2c" {
  vpc_id                     = module.vpcs["vpc_a"].vpc_id
  connection_name            = "vgw_s2c"
  connection_type            = "mapped"
  remote_gateway_type        = "aws"
  tunnel_type                = "route"
  primary_cloud_gateway_name = aviatrix_spoke_gateway.provider_gw.gw_name
  remote_gateway_ip          = aws_vpn_connection.aviatrix_gw_connection.tunnel1_address
  pre_shared_key             = aws_vpn_connection.aviatrix_gw_connection.tunnel1_preshared_key

  ha_enabled               = var.ha_gw == true ? true : false
  enable_single_ip_ha      = var.ha_gw == true ? true : null
  backup_gateway_name      = var.ha_gw == true ? aviatrix_spoke_gateway.provider_gw.ha_gw_name : null
  backup_remote_gateway_ip = var.ha_gw == true ? aws_vpn_connection.aviatrix_hagw_connection[0].tunnel2_address : null
  backup_pre_shared_key    = var.ha_gw == true ? aws_vpn_connection.aviatrix_hagw_connection[0].tunnel2_preshared_key : null

  custom_mapped         = false
  remote_subnet_cidr    = "10.0.0.0/24"
  remote_subnet_virtual = "100.65.0.0/24"
  local_subnet_cidr     = "10.0.0.0/24"
  local_subnet_virtual  = "100.64.0.0/24"

  depends_on = [aviatrix_spoke_gateway.provider_gw, aws_vpn_connection.aviatrix_gw_connection]
}