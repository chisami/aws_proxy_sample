# Shared provider inputs
inputs = {
  aws_region  = "us-west-2"      # Default AWS region
  cloudflare_api_token  = get_env("CLOUDFLARE_API_TOKEN") # Cloudflare API key (replace with a secret)
  common_tag  = "shared-tag"
}