# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create an S3 bucket for hosting a static website
resource "aws_s3_bucket" "website" {
  bucket = "my-website"
  acl    = "public-read"
  website {
    index_document = "index.html"
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

# Create the Lambda@Edge function
resource "aws_lambda_function" "lambda_edge_function" {
  filename         = "lambda_edge_function.zip"
  function_name    = "lambda_edge_function"
  role             = aws_iam_role.lambda_edge_role.arn
  handler          = "index.handler"
  runtime          = "nodejs16.x"
  source_code_hash = filebase64sha256("lambda_edge_function.zip")

  environment {
    variables = {
      "BUCKET_NAME" = aws_s3_bucket.website.id
      "PASSWORD"    = "secret"
    }
  }
}

# Create
