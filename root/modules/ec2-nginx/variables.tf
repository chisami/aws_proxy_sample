variable "instance_type" {
  type        = string
  description = "The EC2 instance type"
}

variable "domain_name" {
  type        = string
  description = "The domain name registered in Cloudflare"
}

variable "key_name" {
  type = string
  description = "The key name for SSH access to the EC2 instance"
}

variable "cloudflare_api_token" {
    type = string
    description = "The Cloudflare API token"
    sensitive = true # Mark as sensitive to prevent display in logs
}

variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
}
