provider "aws" {
  region = var.aws_region 
}

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.52" # Or specify your desired version
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.main.id
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_traffic.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              sudo docker run -d -p 80:80 nginx:latest
              EOF

  tags = {
    Name = "web-server"
  }
}

# Get Cloudflare Zone ID
# data "cloudflare_zone" "domain" {
#   name   = var.domain_name
# }
# data "cloudflare_zones" "domain" {
#   filter {
#     name   = var.domain_name
#     status = "active" # Optional: Filters only active zones
#   }
# }

data "cloudflare_zones" "domain" {
  filter {
    name   = var.domain_name
  }
}


# Create an A record in Cloudflare
resource "cloudflare_record" "web_server" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = "gemini-proxy"  # Or any subdomain
  value   = aws_instance.web_server.public_ip
  type    = "A"
  proxied = true # Enable Cloudflare proxy (CDN, security)
  depends_on = [aws_instance.web_server]
}

#VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"  # Replace with your AZ
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "allow_traffic" {
  name        = "allow_http_https"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
