variable "region" { default = "eu-central-1" }
variable "lambda_name" { default = "EC2StartStopLambda" }
variable "tag_filter" { default = "startstop:true" }
variable "schedule" {
  type = map(string)
  default = {
    "start" = "cron(0 8 ? * MON-FRI *)"
    "stop"  = "cron(0 17 ? * MON-FRI *)"
  }
}
variable "common_tags" {
  type = map(string)
  default = {
    Owner   = "Yevhen Skyba"
    Project = "ADV-IT_Challange2"
  }
}
# vim:filetype=terraform ts=2 sw=2 et: