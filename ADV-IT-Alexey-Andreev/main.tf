provider "archive" {}
data "aws_caller_identity" "current" {}

resource "local_file" "start_script" {
    content         = templatefile("./start_function.py.tpl", {aws_region  = var.aws_region,tag_name = var.instances_tag_name,tag_value = var.instances_tag_value})
    filename        = "start_function.py"
    # file_permission = "0644"
}

resource "local_file" "stop_script" {
    content         = templatefile("./stop_function.py.tpl", {aws_region  = var.aws_region,tag_name = var.instances_tag_name,tag_value = var.instances_tag_value})
    filename        = "stop_function.py"
    # file_permission = "0644"
}

data "archive_file" "start_func_zip_file" {
	type        = "zip"
	source_file = local_file.start_script.filename # "start_function.py"
	output_path = "start_function.zip"
}

data "archive_file" "stop_func_zip_file" {
	type        = "zip"
	source_file = local_file.stop_script.filename # "stop_function.py"
	output_path = "stop_function.zip"
}

resource "aws_lambda_function" "start_lambda_function" {
	function_name    = "start_function"
	filename         = data.archive_file.start_func_zip_file.output_path
	role             = aws_iam_role.start_stop_lambda_iam.arn
	handler          = "start_function.lambda_handler"
	runtime          = "python3.9"
}

resource "aws_lambda_function" "stop_lambda_function" {
	function_name    = "stop_function"
	filename         = data.archive_file.stop_func_zip_file.output_path
	role             = aws_iam_role.start_stop_lambda_iam.arn
	handler          = "stop_function.lambda_handler"
	runtime          = "python3.9"
}

resource "aws_cloudwatch_event_rule" "start_lambda_event_rule" {
    name = "start-lambda-event-rule"
    description = "Scheduled start instances"
    schedule_expression = "${var.start_cron_val}"
}

resource "aws_cloudwatch_event_rule" "stop_lambda_event_rule" {
    name = "stop-lambda-event-rule"
    description = "Scheduled stop instances"
    schedule_expression = "${var.stop_cron_val}"
}

resource "aws_cloudwatch_event_target" "add_start_event" {
    rule = aws_cloudwatch_event_rule.start_lambda_event_rule.name
    target_id = "start-event-send"
    arn  = aws_lambda_function.start_lambda_function.arn
}

resource "aws_cloudwatch_event_target" "add_stop_event" {
    rule = aws_cloudwatch_event_rule.stop_lambda_event_rule.name
    target_id = "stop-event-send"
    arn  = aws_lambda_function.stop_lambda_function.arn
}

resource "aws_lambda_permission" "allow_start_eventbridge" {
    statement_id  = "AllowExecutionFromEventBridge"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.start_lambda_function.function_name
    principal     = "events.amazonaws.com"
    source_arn    = aws_cloudwatch_event_rule.start_lambda_event_rule.arn
}

resource "aws_lambda_permission" "allow_stop_eventbridge" {
    statement_id  = "AllowExecutionFromEventBridge"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.stop_lambda_function.function_name
    principal     = "events.amazonaws.com"
    source_arn    = aws_cloudwatch_event_rule.stop_lambda_event_rule.arn
}
