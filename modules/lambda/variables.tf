variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "glue_database_name" {
  description = "Glue database name"
  type        = string
}

variable "athena_workgroup" {
  description = "Athena workgroup name"
  type        = string
}

variable "athena_output_location" {
  description = "S3 location for Athena query results"
  type        = string
}

variable "athena_results_bucket_arn" {
  description = "ARN of the S3 bucket for Athena query results"
  type        = string
}

variable "named_query_ids" {
  description = "Map of named query IDs to execute"
  type        = map(string)
}

variable "schedule_expression" {
  description = "EventBridge schedule expression (default: daily at 2 AM UTC)"
  type        = string
  default     = "cron(0 2 * * ? *)"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 256
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
