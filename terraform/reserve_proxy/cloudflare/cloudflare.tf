# Configure the Cloudflare provider
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0" # Or the latest version
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Define variables for Cloudflare API token and Zone ID
variable "cloudflare_api_token" {
  type = string
  description = "The Cloudflare API token"
  sensitive = true # Mark as sensitive to prevent accidental exposure
}

variable "cloudflare_zone_id" {
  type = string
  description = "The Cloudflare Zone ID"
}

variable "cloudfront_domain" {
  type = string
  description = "The CloudFront distribution domain name"
}

# Create a DNS record to point to CloudFront
resource "cloudflare_record" "api_cname" {
  zone_id = var.cloudflare_zone_id
  name    = "api"  # The subdomain (e.g., api.yourdomain.com) - use "@" for the root domain
  type    = "CNAME"
  value   = var.cloudfront_domain # The CloudFront distribution domain
  proxied = true   # Enable Cloudflare proxy (CDN, security)
}
