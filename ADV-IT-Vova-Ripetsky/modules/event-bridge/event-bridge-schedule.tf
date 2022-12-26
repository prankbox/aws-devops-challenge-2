data "aws_caller_identity" "current" {}

#-----------------------------------------------------------------------------------------------
#EventBridge schedule
#-----------------------------------------------------------------------------------------------

resource "aws_scheduler_schedule" "stop" {
  description   = "Scheduler for ec2 stop"
  name = var.event_stop_name

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.stop_time
  schedule_expression_timezone = var.timezone

  target {
    arn      = var.lambda_arn
    role_arn = aws_iam_role.event_role.arn

    input = jsonencode({
      "action" = "stop"
    })
  }
}

resource "aws_scheduler_schedule" "start" {
  description   = "Scheduler for ec2 start"
  name = var.event_start_name

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = var.start_time # "cron(3 15 ? * 2-6 *)"

  target {
    arn      = var.lambda_arn
    role_arn = aws_iam_role.event_role.arn

    input = jsonencode({
      "action" = "start"
    })
  }
}

#-----------------------------------------------------------------------------------------------
#IAM Role & Policy
#-----------------------------------------------------------------------------------------------

resource "aws_iam_role" "event_role" {
  name = var.event_role_name

  assume_role_policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"Service": "scheduler.amazonaws.com"
			},
			"Action": "sts:AssumeRole",
			"Condition": {
				"StringEquals": {
					"aws:SourceAccount": "${data.aws_caller_identity.current.account_id}",
					"aws:SourceArn": "arn:aws:scheduler:${var.region}:${data.aws_caller_identity.current.account_id}:schedule/default/${var.event_start_name}"
				}
			}
		},
		{
			"Sid": "Statement1",
			"Effect": "Allow",
			"Principal": {
				"Service": "scheduler.amazonaws.com"
			},
			"Action": "sts:AssumeRole",
			"Condition": {
				"StringEquals": {
					"aws:SourceAccount": "${data.aws_caller_identity.current.account_id}",
					"aws:SourceArn": "arn:aws:scheduler:${var.region}:${data.aws_caller_identity.current.account_id}:schedule/default/${var.event_stop_name}"
				}
			}
		}
	]
})

  tags = var.tags
}

resource "aws_iam_policy" "event_policy" {
  name        = var.event_policy_name
  path        = "/"
  description = "Policy for start-stop lambda execution"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": [
                "${var.lambda_arn}:*",
                "${var.lambda_arn}"
            ]
        }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.event_role.name
  policy_arn = aws_iam_policy.event_policy.arn
}
