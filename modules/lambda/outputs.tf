output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.update_views.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.update_views.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda.arn
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.daily.name
}

output "schedule_expression" {
  description = "Schedule expression for the EventBridge rule"
  value       = aws_cloudwatch_event_rule.daily.schedule_expression
}

output "log_group_name" {
  description = "CloudWatch log group name for Lambda"
  value       = aws_cloudwatch_log_group.lambda.name
}
