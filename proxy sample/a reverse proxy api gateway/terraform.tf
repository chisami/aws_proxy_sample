# API Gateway
resource "aws_api_gateway_rest_api" "gemini_proxy_api" {
  name = "GeminiProxyAPI"
}

resource "aws_api_gateway_resource" "proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.gemini_proxy_api.id
  parent_id   = aws_api_gateway_rest_api.gemini_proxy_api.root_resource_id
  path_part   = "{proxy+}"  # Catch-all proxy path
}

resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.gemini_proxy_api.id
  resource_id   = aws_api_gateway_resource.proxy_resource.id
  http_method   = "ANY"  # Allow all HTTP methods
  authorization = "NONE"  # Adjust based on your auth needs
  request_parameters = {
    "method.request.path.proxy" = true  # Pass the path
  }
}

resource "aws_api_gateway_integration" "proxy_integration" {
  rest_api_id             = aws_api_gateway_rest_api.gemini_proxy_api.id
  resource_id             = aws_api_gateway_resource.proxy_resource.id
  http_method             = aws_api_gateway_method.proxy_method.http_method
  integration_http_method = "POST" #Gemini may use post specifically
  type                    = "HTTP_PROXY" #Crucial for proxying
  uri                     = "https://generativelanguage.googleapis.com/{stageVariables.proxy}" #Target Gemini endpoint

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy" #pass path to gemini
    "integration.request.header.X-Original-Host" = "context.identity.sourceIp" #original ip info
  }
  passthrough_behavior = "WHEN_NO_MATCH" #pass unmodeled content to backend
}

resource "aws_api_gateway_method_response" "proxy_method_response" {
  rest_api_id = aws_api_gateway_rest_api.gemini_proxy_api.id
  resource_id = aws_api_gateway_resource.proxy_resource.id
  http_method = aws_api_gateway_method.proxy_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "proxy_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.gemini_proxy_api.id
  resource_id = aws_api_gateway_resource.proxy_resource.id
  http_method = aws_api_gateway_method.proxy_method.http_method
  status_code = aws_api_gateway_method_response.proxy_method_response.status_code
}


resource "aws_api_gateway_deployment" "gemini_deployment" {
  rest_api_id = aws_api_gateway_rest_api.gemini_proxy_api.id
  stage_name  = "prod"

  stage_variables = {
     proxy = "v1beta/models/gemini-1.5-pro:generateContent" #Specific endpoint of Gemini, you need to fill it
  }

  depends_on = [
    aws_api_gateway_integration.proxy_integration,
  ]
}

#CloudFront
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_api_gateway_rest_api.gemini_proxy_api.execution_arn}.execute-api.${data.aws_region.current.name}.amazonaws.com"
    origin_id   = "api-gateway"

    custom_origin_config {
      http_port               = 80
      https_port              = 443
      origin_protocol_policy  = "https-only"
      origin_ssl_protocols = ["TLSv1.2"] #Gemini only supports TLS1.2 and above
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  aliases             = ["gateway.mydomain.com"]
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"] #Include all methods Gemini needs
    cached_methods = ["GET", "HEAD"]

    target_origin_id = "api-gateway"

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0

    forwarded_values {
      query_string = true #pass query
      cookies {
        forward = "all" #forward cookies

      }

      headers = ["Authorization","Content-Type"] #important: pass Authorization if using API keys
      query_string = true
      query_string_cache_keys = ["query1","query2"]

    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true #replace with your ACM cert if available
  }
}

data "aws_region" "current" {}
