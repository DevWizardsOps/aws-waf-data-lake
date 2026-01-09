output "workgroup_name" {
  description = "Athena workgroup name"
  value       = aws_athena_workgroup.main.name
}

output "workgroup_id" {
  description = "Athena workgroup ID"
  value       = aws_athena_workgroup.main.id
}

output "query_results_bucket" {
  description = "S3 bucket for Athena query results"
  value       = aws_s3_bucket.query_results.bucket
}

output "query_results_bucket_arn" {
  description = "S3 bucket ARN for Athena query results"
  value       = aws_s3_bucket.query_results.arn
}

output "named_queries" {
  description = "Map of created named queries (views)"
  value = {
    daily_summary         = aws_athena_named_query.daily_summary.id
    top_blocked_ips       = aws_athena_named_query.top_blocked_ips.id
    requests_by_country   = aws_athena_named_query.requests_by_country.id
    rule_performance      = aws_athena_named_query.rule_performance.id
    http_method_analysis  = aws_athena_named_query.http_method_analysis.id
    response_codes        = aws_athena_named_query.response_codes.id
    top_blocked_rules     = aws_athena_named_query.top_blocked_rules.id
    blocks_by_rule_type   = aws_athena_named_query.blocks_by_rule_type.id
    blocks_timeline       = aws_athena_named_query.blocks_timeline.id
    block_investigation   = aws_athena_named_query.block_investigation.id
  }
}
