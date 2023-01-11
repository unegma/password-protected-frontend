
# Cloudfront

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_origin_access_identity" "example" {
  comment = "Some comment"
}

data "aws_cloudfront_cache_policy" "cloudfront_cache_policy" {
  name        = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.bucket-1.bucket_regional_domain_name
    #origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.example.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

#  logging_config {
#    include_cookies = false
#    bucket          = "mylogs.s3.amazonaws.com"
#    prefix          = "myprefix"
#  }

  aliases = [var.WEBSITE_URL]

  default_cache_behavior {
    cache_policy_id = data.aws_cloudfront_cache_policy.cloudfront_cache_policy.id
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn = aws_lambda_function.lambda_edge_function.qualified_arn # The lambda_arn must include the version, that’s why the qualified_arn has to be used here. https://advancedweb.hu/how-to-use-lambda-edge-with-terraform/
    }
  }
#
#  # Cache behavior with precedence 0
#  ordered_cache_behavior {
#    path_pattern     = "/content/immutable/*"
#    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#    cached_methods   = ["GET", "HEAD", "OPTIONS"]
#    target_origin_id = local.s3_origin_id
#
#    forwarded_values {
#      query_string = false
#      headers      = ["Origin"]
#
#      cookies {
#        forward = "none"
#      }
#    }
#
#    min_ttl                = 0
#    default_ttl            = 86400
#    max_ttl                = 31536000
#    compress               = true
#    viewer_protocol_policy = "redirect-to-https"
#  }
#
#  # Cache behavior with precedence 1
#  ordered_cache_behavior {
#    path_pattern     = "/content/*"
#    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#    cached_methods   = ["GET", "HEAD"]
#    target_origin_id = local.s3_origin_id
#
#    forwarded_values {
#      query_string = false
#
#      cookies {
#        forward = "none"
#      }
#    }
#
#    min_ttl                = 0
#    default_ttl            = 3600
#    max_ttl                = 86400
#    compress               = true
#    viewer_protocol_policy = "redirect-to-https"
#  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
#    acm_certificate_arn = data.aws_acm_certificate.issued.id
    acm_certificate_arn = var.certificate_arn
#    acm_certificate_arn = aws_acm_certificate.cert.id
    cloudfront_default_certificate = false # todo is this needed?
    # todo which of these?
    ssl_support_method = "sni-only"
#    ssl_support_method = "vip"
    minimum_protocol_version = "TLSv1.2_2019"
  }
}
