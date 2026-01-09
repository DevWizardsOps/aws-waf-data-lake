variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "waf-data-lake"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "sa-east-1"
}

variable "aws_profile" {
  description = "AWS CLI Profile"
  type        = string
  default     = "default"
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
  #default     = "<ACCOUNT_ID>"
}

variable "log_retention_days" {
  description = "Number of days to retain logs in S3 before deletion"
  type        = number
  default     = 60
}

variable "glue_database_name" {
  description = "Glue database name"
  type        = string
  default     = "waf_data_lake"
}

variable "glue_table_name" {
  description = "Glue table name for WAF logs schema"
  type        = string
  default     = "logs"
}

variable "glue_schema_location" {
  description = "S3 location for Glue table (not used by Firehose, only for schema reference)"
  type        = string
  default     = ""
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "athena_query_results_retention_days" {
  description = "Athena query results retention in days"
  type        = number
  default     = 7
}

variable "lambda_schedule_expression" {
  description = "EventBridge schedule expression for Lambda (default: daily at 2 AM UTC / 11 PM Brasília)"
  type        = string
  default     = "cron(0 2 * * ? *)"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "production"
    ManagedBy   = "Terraform"
    Project     = "WAF-Data-Lake"
  }
}
