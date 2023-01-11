resource "aws_acm_certificate" "cert" {
  provider = aws.us-east-1
  domain_name       =  var.WEBSITE_URL
  validation_method = "DNS"

  tags = {
    Environment = "production"
  }

  lifecycle {
    create_before_destroy = true
  }
}
