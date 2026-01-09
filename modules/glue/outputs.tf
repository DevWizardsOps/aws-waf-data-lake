output "database_name" {
  description = "Glue database name"
  value       = aws_glue_catalog_database.this.name
}

output "database_id" {
  description = "Glue database ID"
  value       = aws_glue_catalog_database.this.id
}

output "table_name" {
  description = "Glue table name"
  value       = aws_glue_catalog_table.waf_logs.name
}

output "table_id" {
  description = "Glue table ID"
  value       = aws_glue_catalog_table.waf_logs.id
}
