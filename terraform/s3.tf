
# Create an S3 bucket for hosting a static website
resource "aws_s3_bucket" "bucket-1" {
  bucket = var.WEBSITE_URL
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.bucket-1.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_s3_bucket" "selected-bucket" {
  bucket = aws_s3_bucket.bucket-1.bucket
}

resource "aws_s3_bucket_website_configuration" "password-protected-lambda" {
  bucket = data.aws_s3_bucket.selected-bucket.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}
