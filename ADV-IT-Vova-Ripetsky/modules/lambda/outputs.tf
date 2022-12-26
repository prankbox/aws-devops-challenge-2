output "lambda_arn" {
  value = aws_lambda_function.lambda.arn
}

output "tag_key" {
  value = var.tag_key
}

output "tag_value" {
  value = var.tag_value
}
