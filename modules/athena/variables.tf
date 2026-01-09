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

variable "glue_database_name" {
  description = "Glue database name"
  type        = string
}

variable "glue_table_name" {
  description = "Glue table name"
  type        = string
}

variable "query_results_retention_days" {
  description = "Number of days to retain query results in S3"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
