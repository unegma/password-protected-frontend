
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

  publish = true # publish new version for every change: https://advancedweb.hu/how-to-use-lambda-edge-with-terraform/

  environment {
    variables = {
      "BUCKET_NAME" = aws_s3_bucket_website_configuration.password-protected-lambda.id
      "AUTH_USER"    = var.AUTH_USER
      "AUTH_PASS"    = var.AUTH_PASS
    }
  }
}
