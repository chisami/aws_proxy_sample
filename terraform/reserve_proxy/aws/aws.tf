terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.87"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Replace with your desired AWS region
}

locals {
  aliases = ["proxyai.zibolaon.cc"]
}

# --- Lambda Function ---
resource "aws_iam_role" "lambda_role" {
  name = "lambda_reverse_proxy_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_reverse_proxy_policy"
  description = "IAM policy for Lambda reverse proxy function"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunctionConfiguration"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

#Zip the lambda function to upload to AWS
data "archive_file" "lambda_function_zip" {
  type        = "zip"
  output_path = "lambda_function_payload.zip"
  source_dir  = "lambda_function" # Assuming your index.js is in a folder called lambda_function
}

resource "aws_lambda_function" "reverse_proxy" {
  function_name = "reverse-proxy-function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler" # Make sure this matches your handler
  runtime       = "nodejs20.x" # or another supported Node.js runtime
  filename      = data.archive_file.lambda_function_zip.output_path # Use the zip file
  source_code_hash = data.archive_file.lambda_function_zip.output_base64sha256
  timeout       = 5
  memory_size   = 128 # Adjust as needed
  publish       = true                              # Must be true to create a published version

  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment
  ]
}

# Lambda Function URL to access it
resource "aws_lambda_function_url" "reverse_proxy_url" {
  function_name      = aws_lambda_function.reverse_proxy.function_name
  authorization_type = "NONE"
  cors {
    allow_origins = ["*"] # Adjust as needed
    allow_methods = ["*"]  # Adjust as needed
    allow_headers = ["*"]  # Adjust as needed
    expose_headers = ["*"] # Adjust as needed
    max_age = 300
    allow_credentials = false
  }
}

# # --- CloudFront Distribution ---
resource "aws_cloudfront_distribution" "s3_distribution" {

  aliases = local.aliases  
  comment = "to cloudflare"

  origin {
    # domain_name = aws_lambda_function_url.reverse_proxy_url.function_url # Lambda Function URL
    # domain_name = replace(aws_lambda_function_url.reverse_proxy_url.function_url, "https://", "") # Lambda Function URL
    domain_name = trim(replace(aws_lambda_function_url.reverse_proxy_url.function_url, "https://", ""), "/") # Lambda Function URL
    origin_id   = "lambdaOrigin"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy = "https-only"  #IMPORTANT force HTTPS
      origin_ssl_protocols     = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"] # Adjust as needed
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "lambdaOrigin"

    forwarded_values {
      query_string = true
      cookies {
        forward = "none" # Or "all", "whitelist" as needed
      }

      headers = ["*"] # Forward all headers to the origin
      query_string_cache_keys = ["*"]
    }

    viewer_protocol_policy = "redirect-to-https" # Ensure HTTPS

    # Associate Lambda function here
    lambda_function_association {
      event_type   = "origin-request"                       # Event type (e.g., viewer-request, origin-request, etc.)
      lambda_arn   = aws_lambda_function.reverse_proxy.qualified_arn  # Attach the published Lambda function version
      include_body = false                                  # Optional, only use for events requiring the body
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  price_class = "PriceClass_100" # US, Canada, Europe
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    acm_certificate_arn = data.aws_acm_certificate.proxy_cert.arn
    ssl_support_method  = "sni-only"
  }
}


# CloudFront Monitoring Subscription
resource "aws_cloudfront_monitoring_subscription" "s3_distribution" {
  distribution_id = aws_cloudfront_distribution.s3_distribution.id

  monitoring_subscription {
    realtime_metrics_subscription_config {
      realtime_metrics_subscription_status = "Enabled"  # Enable Real-Time Monitoring
    }
  }
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}