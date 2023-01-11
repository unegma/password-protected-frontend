provider "aws" {
  profile = var.profile
  region = var.region
  max_retries = 1
}
