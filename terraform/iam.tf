
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
        "Service": ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
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

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket-1.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.example.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.bucket-1.id
  policy = data.aws_iam_policy_document.s3_policy.json
}
