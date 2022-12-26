/**
* author: Yessimova Indira
* e-mail: indira1111011@gmail.com
*/
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
}

variable "instance_tag_name" {
  type    = string
  default = "startstop"
}

variable "start_time" {
  type    = string
  default = "0 8" // 0 minutes, 8 - hours
}

variable "stop_time" {
  type    = string
  default = "0 17"
}

resource "aws_iam_policy" "ssm_ec2_policy" {
  name        = "ssm_ec2_policy"
  description = "A test policy"

  policy =  file("${path.module}/ssm_for_ec2_policy.json")
}


resource "aws_iam_role" "ssm_ec2_role" {
  name        = "ssm_ec2_role"
  description = "Role for ssm service to allow ec2 start stop describe"

  assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "",
              "Effect": "Allow",
              "Principal": {
                  "Service": [
                      "ssm.amazonaws.com"
                  ]
              },
              "Action": "sts:AssumeRole"
          }
      ]
  }
EOF
}

resource "aws_iam_role_policy_attachment" "ssm_role_attach" {
  role       = aws_iam_role.ssm_ec2_role.name
  policy_arn = aws_iam_policy.ssm_ec2_policy.arn
}

resource "aws_ssm_document" "ssm_doc" {
  name            = "ssm_doc"
  document_format = "YAML"
  document_type   = "Automation"
  content         = file("${path.module}/change_instance_state.yaml")
}

resource "aws_ssm_maintenance_window" "stop_scheduled" {
  name     = "stop_scheduled"
  schedule = "cron(${var.stop_time} ? * MON,FRI *)"
  duration = 1
  cutoff   = 0
}

resource "aws_ssm_maintenance_window" "start_scheduled" {
  name     = "start_scheduled"
  schedule = "cron(${var.start_time} ? * MON,FRI *)"
  duration = 1
  cutoff   = 0
}

resource "aws_ssm_maintenance_window_task" "start_scheduled_task" {
  priority        = 1
  task_arn        = "ssm_doc"
  task_type       = "AUTOMATION"
  window_id       = aws_ssm_maintenance_window.start_scheduled.id

  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "AutomationAssumeRole"
        values = [aws_iam_role.ssm_ec2_role.arn]
      }

      parameter {
        name   = "TagName"
        values = [var.instance_tag_name]
      }

      parameter {
        name   = "Action"
        values = [1]
      }
    }
  }
}

resource "aws_ssm_maintenance_window_task" "stop_scheduled_task" {
  priority        = 1
  task_arn        = "ssm_doc"
  task_type       = "AUTOMATION"
  window_id       = aws_ssm_maintenance_window.stop_scheduled.id

  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "AutomationAssumeRole"
        values = [aws_iam_role.ssm_ec2_role.arn]
      }

      parameter {
        name   = "TagName"
        values = [var.instance_tag_name]
      }

      parameter {
        name   = "Action"
        values = [0]
      }
    }
  }
}
