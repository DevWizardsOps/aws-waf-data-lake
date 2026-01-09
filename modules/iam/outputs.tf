output "firehose_role_arn" {
  description = "IAM role ARN for Firehose"
  value       = aws_iam_role.firehose.arn
}

output "firehose_role_name" {
  description = "IAM role name for Firehose"
  value       = aws_iam_role.firehose.name
}

output "firehose_policy_arn" {
  description = "IAM policy ARN for Firehose"
  value       = aws_iam_policy.firehose.arn
}
