variable "aws_region" {
	default = "us-east-1"
}

variable "instances_tag_name" {
	default = "action"
}

variable "instances_tag_value" {
	default = "scheduled"
}

variable "start_cron_val" {
    default = "cron(00 08 ? * MON-FRI *)"
}

variable "stop_cron_val" {
    default = "cron(00 17 ? * MON-FRI *)"
}
