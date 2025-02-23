output "vcn_id" {
  value = module.vcn.vcn_id
}

# output "public_subnet_id" {
#   value = module.vcn.public_subnets[0].id
# }

# output "private_subnet_id" {
#   value = module.vcn.private_subnets[0].id
# }


output "subnet_id" {
  value = module.vcn.subnet_id
}