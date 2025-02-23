

# # Define Local for Availability Domain
# locals {
#   availability_domain = length(data.oci_identity_availability_domains.ads.availability_domains) > 0 ? 
#                        data.oci_identity_availability_domains.ads.availability_domains[0].name : 
#                        ""
#   # availability_domain =  ""                      
# }

resource "oci_core_instance" "nginx_proxy" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[2].name
  compartment_id      = var.compartment_id
  display_name        = "nginx-reverse-proxy"
  shape               = "VM.Standard.E2.1.Micro"

  create_vnic_details {
    subnet_id         = module.vcn.subnet_id["private_subnet1"] # Use the first created private subnet
    assign_public_ip  = false # We will use NAT gateway for outbound traffic
  }
  
  source_details {
    source_type = "image"
    # source_id   = data.oci_core_images.oracle_linux.images[0].id # Fetch the first matching image
    source_id   = "ocid1.image.oc1.iad.aaaaaaaapu34hvrujrklcjgki5zhfkiztf2li7hrvacwgpob6m2ct7aslvoq" # Fetch the first matching image
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data           = filebase64("scripts/install_proxy.sh") 
  }
  # create_vnic_details {
  #   subnet_id         = module.vcn.public_subnets[0].id
  #   assign_public_ip  = true
  # }

  # metadata = {
  #   ssh_authorized_keys = file(var.ssh_public_key_path)
  #   user_data = <<-EOF
  #     #!/bin/bash
  #     sudo yum install -y nginx
  #     sudo systemctl start nginx
  #     sudo systemctl enable nginx
  #     echo 'server {
  #       listen 80;
  #       location / {
  #         proxy_pass http://backend-server-ip:backend-port;
  #         proxy_set_header Host $host;
  #         proxy_set_header X-Real-IP $remote_addr;
  #         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  #       }
  #     }' | sudo tee /etc/nginx/conf.d/reverse_proxy.conf
  #     sudo systemctl restart nginx
  #   EOF
  # }
}

# resource "oci_core_instance" "tailscale_node" {
#   availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
#   compartment_id      = var.compartment_id
#   display_name        = "tailscale-node"
#   shape               = "VM.Standard.E2.1.Micro"

#   create_vnic_details {
#     subnet_id         = module.vcn.public_subnets[0].id
#     assign_public_ip  = true
#   }
#   image_id = data.oci_core_images.oracle_linux.images[0].id # Use the first available image
#   metadata = {
#     ssh_authorized_keys = file(var.ssh_public_key_path)
#     user_data = <<-EOF
#       #!/bin/bash
#       curl -fsSL https://tailscale.com/install.sh | sh
#       tailscale up --authkey=${var.tailscale_auth_key}
#     EOF
#   }
# }
