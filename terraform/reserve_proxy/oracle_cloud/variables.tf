variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
# variable "availability_domain" {}
variable "compartment_id" {}
# variable "subnet_id" {}
variable "ssh_public_key_path" {}
variable "tailscale_auth_key" {}

# Define the subnets
variable "subnets" {
  type = list(object({
    subnet_name                = string
    cidr_block                 = string
    prohibit_public_ip_on_vnic = bool
    dns_label                  = string
  }))
  default = [
    {
      subnet_name                = "private_subnet1"
      cidr_block                 = "10.0.1.0/24"
      prohibit_public_ip_on_vnic = true
      dns_label                  = "privatesubnet1"
    },
    {
      subnet_name                = "private_subnet2"
      cidr_block                 = "10.0.2.0/24"
      prohibit_public_ip_on_vnic = true
      dns_label                  = "privatesubnet2"
    }
  ]
}

# Adapt VCN parameters as variables
variable "label_prefix" {
  default = "terraform-oci"
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}

variable "create_internet_gateway" {
  default = true
}

variable "lockdown_default_seclist" {
  default = false
}

variable "create_nat_gateway" {
  default = false
}

variable "create_service_gateway" {
  default = false
}

variable "enable_ipv6" {
  default = false
}

variable "vcn_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "vcn_dns_label" {
  default = "myvcn"
}

variable "vcn_name" {
  default = "MyVCN"
}

variable "internet_gateway_display_name" {
  default = "InternetGateway"
}

variable "nat_gateway_display_name" {
  default = "NATGateway"
}

variable "service_gateway_display_name" {
  default = "ServiceGateway"
}

variable "attached_drg_id" {
  default = null
  type    = string
}

variable "internet_gateway_route_rules" {
  type = list(object({
    destination       = string
    destination_type  = string
  }))
  default = []
}