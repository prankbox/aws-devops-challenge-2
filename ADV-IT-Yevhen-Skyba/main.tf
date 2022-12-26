# Author: Yevhen Skyba
# E-mail: eugene.skiba@gmail.com
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      version = "~> 4.48"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = var.common_tags
  }
}

data "archive_file" "lambda_source" {
  type        = "zip"
  source_file = "${path.module}/main.py"
  output_path = "${path.module}/.terraform/lambda_source/source.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_name}Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
    Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_policy" "lambda_custom_policy" {
  name        = "${var.lambda_name}CustomPolicy"
  path        = "/"
  description = "${var.lambda_name}CustomPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/${var.lambda_name}:*"
      },
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Effect   = "Allow"
        Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_custom_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_custom_policy.arn
}

resource "aws_lambda_function" "lambda" {
  function_name    = var.lambda_name
  handler          = "main.lambda_handler"
  runtime          = "python3.9"
  timeout          = "60"
  role             = aws_iam_role.lambda_role.arn
  filename         = data.archive_file.lambda_source.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_source.output_path)
  environment {
    variables = {
      TAG_FILTER = var.tag_filter
    }
  }
}

resource "aws_cloudwatch_event_rule" "lambda_cwe_rules" {
  for_each            = var.schedule
  name                = "${var.lambda_name}${title(each.key)}CweRule"
  schedule_expression = each.value
}

resource "aws_cloudwatch_event_target" "lambda_cwe_targets" {
  for_each = aws_cloudwatch_event_rule.lambda_cwe_rules
  rule     = each.value.name
  arn      = aws_lambda_function.lambda.arn
  input_transformer {
    input_template = <<EOF
      {"action": "${each.key}"}
    EOF
  }
}

resource "aws_lambda_permission" "allow_permissions_to_run_lambda" {
  for_each      = aws_cloudwatch_event_rule.lambda_cwe_rules
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  function_name = aws_lambda_function.lambda.function_name
  source_arn    = each.value.arn
}
# vim:filetype=terraform ts=2 sw=2 et: