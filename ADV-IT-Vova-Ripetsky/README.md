# Scheduled stop/start of EC2 instances

## Author
- [Volodymyr Ripetsky](https://www.linkedin.com/in/volodymyr-ripetskyi-651641168/)
- Email: vova.ripetsky@gmail.com

## Lambda
lambda_function.py
- Getting list of EC2 which have appropriate tags.
- Stoping EC2 if payload contains {"action": "stop"}
- Starting EC2 if payload contains {"action": "start"}

## Terraform resources:
- Lambda Function
- Lambda IAM Role
- Lamdba IAM Policy
- EventBridge Cron Scheduler for Stop
- EventBridge Cron Scheduler for Start
- EventBridge Role
- EventBridge Policy

## Terraform vars:
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


## Diagram
![Alt text](Diagram.PNG?raw=true "diagram")

## Least privileges access

Lamdba IAM Policy using "${var.region}" and "${data.aws_caller_identity.current.account_id}" variables to limit Region and AccountID

Also Lambda IAM Policy having "aws:ResourceTag/${var.tag_key}": "${var.tag_value}" as condition.
Even if modify the function code by adding different InstanceID manually - it will not execute stop/start when condition is not met.

EventBridge schedulers can only invoke current lambda function, they are sharing same IAM Role which is having appropriate trust condition.


## Lambda Environment Variables

To run this project, you will need to add the following environment variables to your lambda env 

`REGION` - region were we are creating/discovering resources, default = "us-east-1"

`TAG_KEY` - Tag key on EC2 which lambda search for, default = "stopstart"

`TAG_VALUE` - Tag value on EC2 which lambda search for, default = "enabled"


