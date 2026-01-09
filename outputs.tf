# S3 Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket for WAF logs"
  value       = module.storage.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for WAF logs"
  value       = module.storage.bucket_arn
}

# Glue Outputs
output "glue_database_name" {
  description = "Name of the Glue database"
  value       = module.glue.database_name
}

output "glue_table_name" {
  description = "Name of the Glue table"
  value       = module.glue.table_name
}

# IAM Outputs
output "iam_firehose_role_arn" {
  description = "ARN of the IAM role for Firehose"
  value       = module.iam.firehose_role_arn
}

# Firehose Outputs
output "firehose_stream_name" {
  description = "Name of the Kinesis Firehose delivery stream"
  value       = module.firehose.delivery_stream_name
}

output "firehose_stream_arn" {
  description = "ARN of the Kinesis Firehose delivery stream"
  value       = module.firehose.delivery_stream_arn
}

# CloudWatch Outputs
output "cloudwatch_log_group" {
  description = "CloudWatch log group for Firehose"
  value       = aws_cloudwatch_log_group.firehose.name
}

# Athena Outputs
output "athena_workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = module.athena.workgroup_name
}

output "athena_query_results_bucket" {
  description = "S3 bucket for Athena query results"
  value       = module.athena.query_results_bucket
}

output "athena_views" {
  description = "List of created Athena views"
  value = [
    "vw_daily_summary",
    "vw_top_blocked_ips",
    "vw_requests_by_country",
    "vw_rule_performance",
    "vw_http_method_analysis",
    "vw_response_codes"
  ]
}

# Lambda Outputs
output "lambda_function_name" {
  description = "Name of the Lambda function for updating views"
  value       = module.lambda.lambda_function_name
}

output "lambda_schedule" {
  description = "Schedule for Lambda execution"
  value       = module.lambda.schedule_expression
}

# Summary Output
output "data_lake_summary" {
  description = "Summary of WAF Data Lake resources"
  value = {
    project_name                = var.project_name
    region                      = var.aws_region
    s3_bucket                   = module.storage.bucket_name
    glue_database               = module.glue.database_name
    glue_table                  = module.glue.table_name
    firehose_stream             = module.firehose.delivery_stream_name
    athena_workgroup            = module.athena.workgroup_name
    athena_query_results_bucket = module.athena.query_results_bucket
    lambda_function             = module.lambda.lambda_function_name
    lambda_schedule             = module.lambda.schedule_expression
    log_retention_days          = var.log_retention_days
  }
}
output "grafana_user_name" {
  description = "IAM user name for Grafana"
  value       = aws_iam_user.grafana.name
}

output "grafana_user_arn" {
  description = "IAM user ARN for Grafana"
  value       = aws_iam_user.grafana.arn
}

output "grafana_access_key_id" {
  description = "Access Key ID for Grafana user (SENSITIVE - store securely)"
  value       = aws_iam_access_key.grafana.id
  sensitive   = false
}

output "grafana_secret_access_key" {
  description = "Secret Access Key for Grafana user (SENSITIVE - store securely)"
  value       = aws_iam_access_key.grafana.secret
  sensitive   = true
}

output "grafana_configuration" {
  description = "Grafana Athena datasource configuration details"
  value = {
    aws_region      = var.aws_region
    database        = module.glue.database_name
    workgroup       = module.athena.workgroup_name
    output_location = "s3://${module.athena.query_results_bucket}/"
  }
}