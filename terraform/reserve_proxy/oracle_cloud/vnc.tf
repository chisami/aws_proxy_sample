# Use local values for nat gateway route rules as in the example
locals {
  nat_gateway_route_rules = [] # Initialize the list

  # Convert the list of subnets into a map keyed by subnet_name
  subnets_map = { for subnet in var.subnets : subnet.subnet_name => subnet }
}

module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.6.0"  # Specify the desired version

# General OCI parameters
  compartment_id = var.compartment_id
  label_prefix = var.label_prefix
  freeform_tags = var.freeform_tags
  defined_tags = var.defined_tags

  # VCN parameters
  create_internet_gateway = var.create_internet_gateway
  lockdown_default_seclist = var.lockdown_default_seclist
  create_nat_gateway = var.create_nat_gateway
  create_service_gateway = var.create_service_gateway
  enable_ipv6 = var.enable_ipv6
  vcn_cidrs = var.vcn_cidrs
  vcn_dns_label = var.vcn_dns_label
  vcn_name = var.vcn_name

  # Gateways parameters
  internet_gateway_display_name = var.internet_gateway_display_name
  nat_gateway_display_name = var.nat_gateway_display_name
  service_gateway_display_name = var.service_gateway_display_name
  attached_drg_id = var.attached_drg_id

  # Routing rules
  internet_gateway_route_rules = var.internet_gateway_route_rules
  nat_gateway_route_rules = local.nat_gateway_route_rules

  subnets = local.subnets_map

}


resource "oci_core_security_list" "private-security-list" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
  display_name   = "security-list-for-private-subnet"
}
