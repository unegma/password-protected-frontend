#resource "aws_acm_certificate" "cert" {
#  domain_name       =  var.WEBSITE_URL
#  validation_method = "DNS"
##  status = "ISSUED"
##  provider = aws.virginia
#
#  tags = {
#    Environment = "production"
#  }
#
#  lifecycle {
#    create_before_destroy = true
#  }
#}
