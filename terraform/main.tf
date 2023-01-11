# Configure the AWS provider

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      #      version = "~> 3.27"
    }
  }

  #  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = var.profile
  region = var.region
  max_retries = 1
}

# Create an S3 bucket for hosting a static website
resource "aws_s3_bucket" "bucket-1" {
  bucket = var.WEBSITE_URL
}

data "aws_s3_bucket" "selected-bucket" {
  bucket = aws_s3_bucket.bucket-1.bucket
}

resource "aws_s3_bucket_website_configuration" "password-protected-lambda" {
  bucket = data.aws_s3_bucket.selected-bucket.bucket
  #acl    = "public-read"

    index_document {
      suffix = "index.html"
    }

    error_document {
      key = "index.html"
    }
}

# Cloudfront

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.b.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "mylogs.s3.amazonaws.com"
    prefix          = "myprefix"
  }

  aliases = ["mysite.example.com", "yoursite.example.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.example.arn
    }
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}



# Create an IAM role for the Lambda@Edge function
resource "aws_iam_role" "lambda_edge_role" {
  name = "lambda_edge_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Create a policy for the Lambda@Edge function to allow it to read from the S3 bucket and write to CloudWatch logs
resource "aws_iam_policy" "lambda_edge_policy" {
  name = "lambda_edge_policy"

#{
#"Version": "2008-10-17",
#"Id": "PolicyForCloudFrontPrivateContent",
#"Statement": [
#{
#"Sid": "1",
#"Effect": "Allow",
#"Principal": {
#"AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E1********"
#},
#"Action": "s3:GetObject",
#"Resource": "arn:aws:s3:::MY.DOMAIN.NAME/*"
#}
#]
#}


policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::${var.WEBSITE_URL}"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Attach the policy to the IAM role
resource "aws_iam_policy_attachment" "lambda_edge_policy_attachment" {
  name       = "lambda_edge_policy_attachment"
  policy_arn = aws_iam_policy.lambda_edge_policy.arn
  roles      = [aws_iam_role.lambda_edge_role.name]
}

data "archive_file" "Lambda_function_archive" {
  type        = "zip"
  source_dir  = "${path.module}/../aws/lambda/dist"
  output_path = "${path.module}/../aws/lambda/dist/function.zip"
}


# Create the Lambda@Edge function
resource "aws_lambda_function" "lambda_edge_function" {
  function_name = "Password_Protected_Lambda"
  filename = data.archive_file.Lambda_function_archive.output_path
  role             = aws_iam_role.lambda_edge_role.arn
  handler          = "index.handler"
  runtime          = "nodejs16.x"
  source_code_hash = data.archive_file.Lambda_function_archive.output_base64sha256

  environment {
    variables = {
      "BUCKET_NAME" = aws_s3_bucket_website_configuration.password-protected-lambda.id
      "AUTH_USER"    = var.AUTH_USER
      "AUTH_PASS"    = var.AUTH_PASS
    }
  }
}

# Create
