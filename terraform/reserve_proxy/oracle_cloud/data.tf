# Fetch Availability Domains
data "oci_identity_availability_domains" "ads" {
  # Required
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "oracle_linux" {
  compartment_id            = var.compartment_id
#   compartment_id            = var.tenancy_ocid
  operating_system          = "Oracle Linux"
  operating_system_version  = "8"
#   shape                     = "VM.Standard.E2.1.Micro"
}

# data "oci_core_shapes" "available_shapes" {
#   compartment_id = var.compartment_id
# }

# output "shapes" {
#   value = data.oci_core_shapes.available_shapes.shapes
# }

output "images" {
  value = data.oci_core_images.oracle_linux.images.*.id
}