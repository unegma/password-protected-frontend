# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create an S3 bucket for hosting a static website
resource "aws_s3_bucket" "website" {
  bucket = "password-protected-lambda.mydomain.com"
  acl    = "public-read"
  website {
    index_document = "${path.module}/../aws/s3/dist/index.html"
    error_document = "${path.module}/../aws/s3/dist/index.html"
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
        "${aws_s3_bucket.website.arn}/*"
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
      "BUCKET_NAME" = aws_s3_bucket.website.id
      "AUTH_USER"    = var.AUTH_USER
      "AUTH_PASS"    = var.AUTH_PASS
    }
  }
}

# Create
