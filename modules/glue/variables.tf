variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "database_name" {
  description = "Glue database name"
  type        = string
}

variable "table_name" {
  description = "Glue table name"
  type        = string
}

variable "schema_location" {
  description = "S3 location for Glue table data"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
