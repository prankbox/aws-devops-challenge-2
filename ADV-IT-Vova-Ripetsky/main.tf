###########################################
# Aauthor:  Vova Ripetsky                 #
# E-mail:   vova.ripetsky@gmail.com       #
###########################################

locals {
  label = "DevOps-Challenge-2-VovaRipetsky"
}

provider "aws" {
  region = var.region #default is "us-east-1"
}

module "lambda" {
  source = "./modules/lambda"

  filename           = "lambda_function.zip"
  function_name      = "lambda_start_stop_ec2"
  handler            = "lambda_function.lambda_handler"
  runtime            = "python3.9"
  timeout            = "15"
  region             = var.region
  tag_key            = var.tag_key   # default is "stopstart"
  tag_value          = var.tag_value # default is "enabled"
  lambda_role_name   = "lambda_start_stop_role"
  lambda_policy_name = "lambda_start_stop_policy"
  tags = {
    "label" = local.label
  }
}

module "event-bridge" {
  source = "./modules/event-bridge"

  event_stop_name   = "stop_ec2_on_schedule"
  event_start_name  = "start_ec2_on_schedule"
  timezone          = "UTC"
  lambda_arn        = module.lambda.lambda_arn
  region            = var.region
  stop_time         = var.stop_time  # default is"cron(0 8 ? * 2-6 *)"
  start_time        = var.start_time # default is "cron(0 17 ? * 2-6 *)"
  event_role_name   = "event_start_stop_role"
  event_policy_name = "event_start_stop_policy"
  tags = {
    "label" = local.label
  }
  depends_on = [module.lambda]
}
