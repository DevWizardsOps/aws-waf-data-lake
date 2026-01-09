variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for Firehose"
  type        = string
}

variable "glue_database_name" {
  description = "Glue database name"
  type        = string
}

variable "glue_table_name" {
  description = "Glue table name"
  type        = string
}

variable "log_group_arn" {
  description = "CloudWatch log group ARN"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
