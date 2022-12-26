variable "aws_region" {
  description = "AWS region to deploy to"
  default     = "us-east-1"
  type        = string
}

variable "profile" {
  description = "Local AWS profile to use"
  default     = "default"
  type        = string
}

variable "environment_name" {
  description = "Unique name of environment to be deployed"
  default     = "farm"
  type        = string
}

variable "half_cidr" {
  description = "First part of VPC CIDR address"
  default     = "10.11"
  type        = string
}

variable "instances_number" {
  description = "How many EC2 instances will be created"
  default     = 3
  type        = number
}

variable "permissive" {
  description = "Gives more trust to Lambda. If set to false Lambda policy will be restricted only to instances created by this configuration. If true Lambda can operate all instances in current account"
  default     = true
  type        = bool
}

variable "instance_type" {
  description = "EC2 instance type. Should be Graviton based"
  default     = "t4g.small"
  type        = string
}

variable "action" {
  description = "Cron expression for start/stop time"
  default = {
    start = "cron(0 8 ? * MON-FRI *)"
    stop  = "cron(0 17 ? * MON-FRI *)"
  }
  type = map(string)
}

variable "tag" {
  description = "Start/Stop tag"
  default = {
    startstop = "true"
  }
  type = map(string)
}

variable "tags" {
  description = "Tags to be applied to all resources"
  default = {
    tag    = "hola Denis"
    tool   = "terraform"
    task   = "adv-it-challenge-2"
    author = "Boris Gorbuntsov"
  }
  type = map(string)
}

