output "lambda_arn" {
  value = module.lambda.lambda_arn
}

output "tag_key" {
  value = module.lambda.tag_key
}

output "tag_value" {
  value = module.lambda.tag_value
}

output "start_time" {
  value = module.event-bridge.start_time
}

output "stop_time" {
  value = module.event-bridge.stop_time
}
