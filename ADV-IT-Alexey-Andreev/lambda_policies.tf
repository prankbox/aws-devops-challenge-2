resource "aws_iam_role" "start_stop_lambda_iam" {
	name               = "start_stop_lambda_iam"
	assume_role_policy = jsonencode(
        {
            Version = "2012-10-17"
            Statement = [
                {
                    Action = "sts:AssumeRole"
                    Effect = "Allow"
                    Sid    = ""
                    Principal = {
                    Service = "lambda.amazonaws.com"
                    }
                }
            ]
        },
    )
}

resource "aws_iam_policy" "start_stop_policy" {
	name               = "start_stop_lambda_policy"
	policy = jsonencode(
        {
            Version = "2012-10-17"
            Statement = [
                {
                    Effect = "Allow",
                    Action = [
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents"
                    ],
                    Resource = "arn:aws:logs:*:*:*"
                },
                {
                    Effect = "Allow",
                    Action = [
                        "ec2:Describe*",
                        "ec2:Start*",
                        "ec2:Stop*"
                    ],
                    Resource = "*"
                }
            ]
        },
    )
}

resource "aws_iam_role_policy_attachment" "start_stop_attach" {
  role       = aws_iam_role.start_stop_lambda_iam.name
  policy_arn = aws_iam_policy.start_stop_policy.arn
}
