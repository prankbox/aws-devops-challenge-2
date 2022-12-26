data "aws_caller_identity" "current" {}

#-----------------------------------------------------------------------------------------------
#Lambda
#-----------------------------------------------------------------------------------------------

resource "aws_lambda_function" "lambda" {
  description   = "Scheduled Lambda for start-stop ec2"
  filename      = var.filename
  function_name = var.function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  environment {
    variables = {
      REGION    = var.region
      TAG_KEY   = var.tag_key
      TAG_VALUE = var.tag_value
    }
  }
}

#-----------------------------------------------------------------------------------------------
#IAM Role & Policy
#-----------------------------------------------------------------------------------------------

resource "aws_iam_role" "lambda_role" {
  name = var.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  tags = var.tags
}

resource "aws_iam_policy" "lambda_policy" {
  name        = var.lambda_policy_name
  path        = "/"
  description = "Policy for getting ec2 information and stop-starting"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Resource": "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/${var.tag_key}": "${var.tag_value}"
                }
            }
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances"
            ],
            "Resource": "*"
            "Condition": {
                "StringEquals": {
                    "ec2:Region": "${var.region}"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.function_name}:*"
            ]
        }
    ]
})
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
