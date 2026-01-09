variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for Firehose destination"
  type        = string
}

variable "iam_role_arn" {
  description = "IAM role ARN for Firehose"
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

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "log_stream_name" {
  description = "CloudWatch log stream name"
  type        = string
}

variable "s3_prefix" {
  description = "S3 prefix for log files"
  type        = string
  default     = "waf/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
}

variable "s3_error_prefix" {
  description = "S3 prefix for error files"
  type        = string
  default     = "errors/"
}

variable "buffering_size" {
  description = "Buffer size in MB"
  type        = number
  default     = 128
}

variable "buffering_interval" {
  description = "Buffer interval in seconds"
  type        = number
  default     = 300
}

variable "custom_time_zone" {
  description = "Custom timezone for timestamps"
  type        = string
  default     = "America/Sao_Paulo"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
