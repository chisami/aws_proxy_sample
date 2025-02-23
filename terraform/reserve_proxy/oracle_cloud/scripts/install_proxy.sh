#!/bin/bash

# Update the package repository
sudo yum update -y

# Install Nginx
sudo yum install -y nginx

# # Configure Nginx as a reverse proxy
# cat <<EOF | sudo tee /etc/nginx/conf.d/reverse-proxy.conf
# server {
#   listen 80;

#   location / {
#     proxy_pass http://backend-server-ip:backend-server-port; # Replace with your backend server IP and port
#     proxy_set_header Host \$host;
#     proxy_set_header X-Real-IP \$remote_addr;
#     proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
#     proxy_set_header X-Forwarded-Proto \$scheme;
#   }
# }
# EOF

# Start Nginx service
sudo systemctl start nginx

# Enable Nginx to start on boot
sudo systemctl enable nginx
