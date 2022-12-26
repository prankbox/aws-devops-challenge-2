## Obtain some info ##
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
## Obtain some info end ##

## Fancy VPC by Anton Babenko ##
module "vpc" {
  source              = "terraform-aws-modules/vpc/aws"
  name                = var.environment_name
  cidr                = "${var.half_cidr}.0.0/16"
  azs                 = ["${var.aws_region}a"]
  private_subnets     = ["${var.half_cidr}.10.0/24"]
  enable_ipv6         = false
  enable_nat_gateway  = false
  create_igw          = false
  tags                = merge(var.tags, { Name = "${var.environment_name}-VPC" })
  private_subnet_tags = { tier = "private", Name = "${var.environment_name}-private" }
}
## Fancy VPC end ##

## Instance profile ##
data "aws_iam_policy_document" "server_role" {
  statement {
    sid    = "StsAssumeForServer"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "server" {
  name               = "${var.environment_name}-srv-role"
  assume_role_policy = data.aws_iam_policy_document.server_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "server" {
  name = "${var.environment_name}-server-role"
  role = aws_iam_role.server.name
}
## Instance profile end ##

## EC2 instance ##
data "aws_ami" "amazonlinux_arm" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  filter {
    name   = "hypervisor"
    values = ["xen"]
  }
  owners = ["amazon"]
}

resource "aws_security_group" "server" {
  name        = "${var.environment_name}-jumphost-sg"
  description = "Allow traffic to jump host"
  vpc_id      = module.vpc.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "local_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.server.id
}

resource "aws_security_group_rule" "local_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.server.id
}

resource "aws_instance" "server" {
  count                  = var.instances_number
  ami                    = data.aws_ami.amazonlinux_arm.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.server.id]
  subnet_id              = module.vpc.private_subnets[0]
  iam_instance_profile   = aws_iam_instance_profile.server.id
  tags                   = merge(var.tags, var.tag, { "Name" = "${var.environment_name}-srv-${count.index}" })
  lifecycle {
    ignore_changes = [
      ami,
      tags
    ]
  }
}
## EC2 instance end ##

## Scheduller ##
resource "aws_cloudwatch_event_rule" "action" {
  for_each            = toset(["start", "stop"])
  name                = "${var.environment_name}-${each.value}-time"
  description         = join(" ", ["Start servers by pattern", var.action["${each.value}"]])
  schedule_expression = var.action[each.value]
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "action" {
  for_each  = aws_cloudwatch_event_rule.action
  target_id = "${var.environment_name}-${each.key}-target"
  rule      = aws_cloudwatch_event_rule.action[each.key].name
  arn       = aws_lambda_function.runner.arn
  input     = <<DOC
{
  "action": "${each.key}"
}
DOC
}
## Scheduller end ##

## Lambda ##
# Log #
resource "aws_cloudwatch_log_group" "partitioning_lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.runner.function_name}"
  retention_in_days = 30
}
# Log end #

# IAM #
data "aws_iam_policy_document" "runner_role" {
  statement {
    sid    = "Scheduller"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "runner" {
  name               = "${var.environment_name}-runner-role"
  assume_role_policy = data.aws_iam_policy_document.runner_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "runner" {
  policy_id = "${var.environment_name}-runner"
  statement {
    sid    = "EC2DescribeAccess"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "EC2APIAccess"
    effect = "Allow"
    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances"
    ]
    resources = var.permissive ? ["arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"] : [for inst in aws_instance.server : inst.arn]
  }
}

resource "aws_iam_policy" "runner" {
  name        = "${var.environment_name}-runner-policy"
  description = "Policy manages EC2 API access control"
  path        = "/"
  policy      = data.aws_iam_policy_document.runner.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "runner" {
  role       = aws_iam_role.runner.name
  policy_arn = aws_iam_policy.runner.arn
}

resource "aws_iam_role_policy_attachment" "managed_role_for_lambda_attach" {
  role       = aws_iam_role.runner.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
# IAM end #

# Function #
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "./lambda.py"
  output_path = "./lambda.zip"
}

resource "aws_lambda_function" "runner" {
  filename                       = data.archive_file.lambda_zip.output_path
  function_name                  = "${var.environment_name}-startstop-runner"
  role                           = aws_iam_role.runner.arn
  handler                        = "lambda.handler"
  source_code_hash               = data.archive_file.lambda_zip.output_base64sha256
  runtime                        = "python3.9"
  timeout                        = 30
  reserved_concurrent_executions = 10
  description                    = "Start/Stop runner for EC2 instances inside ${var.environment_name} environment"
  environment {
    variables = {
      TAG = join(",", [for key, value in var.tag : "${key}: ${value}"])
    }
  }
  tags = var.tags
}

resource "aws_lambda_permission" "allow_lambda_call" {
  for_each      = aws_cloudwatch_event_rule.action
  statement_id  = "${var.environment_name}-allow-${each.key}-exec"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.runner.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.action[each.key].arn
}
# Function end #

