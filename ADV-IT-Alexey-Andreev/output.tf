output "start_lambda_function" {
	value = aws_lambda_function.start_lambda_function.qualified_arn
}

output "stop_lambda_function" {
	value = aws_lambda_function.stop_lambda_function.qualified_arn
}

