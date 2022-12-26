variable "region" {
  default = "us-east-1"
}

variable "tag_key" {
  description = "Tag key on EC2 instance for lambda to look for"
  default     = "stopstart"
}

variable "tag_value" {
  description = "Tag value on EC2 instance for lambda to look for"
  default     = "enabled"
}

variable "start_time" {
  description = "Start EC Mon - Fri at 8 am"
  default     = "cron(0 8 ? * 2-6 *)"
}

variable "stop_time" {
  description = "Stop EC Mon - Fri at 17 pm"
  default     = "cron(0 17 ? * 2-6 *)"
}
