variable "cloudflare_api_token" {
  type = string
  description = "The Cloudflare API token"
  sensitive = true
}

variable "cloudflare_zone_id" {
  type = string
  description = "The Cloudflare Zone ID"
}

# No cloudfront_domain defined here, as it's an output from the aws.tf

