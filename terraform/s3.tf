
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
