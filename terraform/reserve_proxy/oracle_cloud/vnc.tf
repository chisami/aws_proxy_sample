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


resource "oci_core_security_list" "security-list" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
  display_name   = var.security_list_display_name

 # Egress rules (allow all outbound traffic)
  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  ingress_security_rules {
    #description = <<Optional value not found in discovery>>
    #icmp_options = <<Optional value not found in discovery>>
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
      #source_port_range = <<Optional value not found in discovery>>
    }
    #udp_options = <<Optional value not found in discovery>>
  }
  ingress_security_rules {
    #description = <<Optional value not found in discovery>>
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    #tcp_options = <<Optional value not found in discovery>>
    #udp_options = <<Optional value not found in discovery>>
  }
  ingress_security_rules {
    #description = <<Optional value not found in discovery>>
    icmp_options {
      code = "-1"
      type = "3"
    }
    protocol    = "1"
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    #tcp_options = <<Optional value not found in discovery>>
    #udp_options = <<Optional value not found in discovery>>
  }

}
