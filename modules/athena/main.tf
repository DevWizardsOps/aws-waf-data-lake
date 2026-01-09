# S3 Bucket for Athena Query Results
resource "aws_s3_bucket" "query_results" {
  bucket = "${var.project_name}-athena-results-${var.account_id}-${var.region}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-athena-results"
    }
  )
}

resource "aws_s3_bucket_lifecycle_configuration" "query_results" {
  bucket = aws_s3_bucket.query_results.id

  rule {
    id     = "delete-old-query-results"
    status = "Enabled"

    filter {}

    expiration {
      days = var.query_results_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}

resource "aws_s3_bucket_public_access_block" "query_results" {
  bucket = aws_s3_bucket.query_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Athena Workgroup
resource "aws_athena_workgroup" "main" {
  name = var.project_name

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.query_results.bucket}/results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    engine_version {
      selected_engine_version = "AUTO"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-workgroup"
    }
  )
}

# Named Query: Daily Summary View
resource "aws_athena_named_query" "daily_summary" {
  name      = "${var.project_name}_daily_summary"
  workgroup = aws_athena_workgroup.main.id
  database  = var.glue_database_name
  query     = <<-SQL
    CREATE OR REPLACE VIEW ${var.glue_database_name}.vw_daily_summary AS
    SELECT 
      DATE(FROM_UNIXTIME("timestamp"/1000)) as log_date,
      httprequest.host as host,
      COUNT(*) as total_requests,
      SUM(CASE WHEN action = 'ALLOW' THEN 1 ELSE 0 END) as allowed_requests,
      SUM(CASE WHEN action = 'BLOCK' THEN 1 ELSE 0 END) as blocked_requests,
      SUM(CASE WHEN action = 'COUNT' THEN 1 ELSE 0 END) as counted_requests,
      COUNT(DISTINCT httprequest.clientip) as unique_ips,
      COUNT(DISTINCT httprequest.country) as unique_countries
    FROM ${var.glue_database_name}.${var.glue_table_name}
    GROUP BY DATE(FROM_UNIXTIME("timestamp"/1000)), httprequest.host
    ORDER BY log_date DESC, total_requests DESC
  SQL

  description = "Daily summary of WAF logs with request counts by action"
}

# Named Query: Top Blocked IPs
resource "aws_athena_named_query" "top_blocked_ips" {
  name      = "${var.project_name}_top_blocked_ips"
  workgroup = aws_athena_workgroup.main.id
  database  = var.glue_database_name
  query     = <<-SQL
    CREATE OR REPLACE VIEW ${var.glue_database_name}.vw_top_blocked_ips AS
    SELECT 
      httprequest.clientip as client_ip,
      httprequest.country as country,
      COUNT(*) as total_blocks,
      ARRAY_AGG(DISTINCT terminatingruleid) as triggered_rules,
      MAX(timestamp) as last_seen_timestamp,
      FROM_UNIXTIME(MAX(timestamp)/1000) as last_seen_date
    FROM ${var.glue_database_name}.${var.glue_table_name}
    WHERE action = 'BLOCK'
    GROUP BY httprequest.clientip, httprequest.country
    ORDER BY total_blocks DESC
  SQL

  description = "Top blocked IP addresses with country and triggered rules"
}

# Named Query: Requests by Country
resource "aws_athena_named_query" "requests_by_country" {
  name      = "${var.project_name}_requests_by_country"
  workgroup = aws_athena_workgroup.main.id
  database  = var.glue_database_name
  query     = <<-SQL
    CREATE OR REPLACE VIEW ${var.glue_database_name}.vw_requests_by_country AS
    SELECT 
      httprequest.country as country,
      COUNT(*) as total_requests,
      SUM(CASE WHEN action = 'ALLOW' THEN 1 ELSE 0 END) as allowed,
      SUM(CASE WHEN action = 'BLOCK' THEN 1 ELSE 0 END) as blocked,
      ROUND(100.0 * SUM(CASE WHEN action = 'BLOCK' THEN 1 ELSE 0 END) / COUNT(*), 2) as block_rate_percentage
    FROM ${var.glue_database_name}.${var.glue_table_name}
    GROUP BY httprequest.country
    ORDER BY total_requests DESC
  SQL

  description = "Request statistics grouped by country with block rates"
}

# Named Query: Rule Performance
resource "aws_athena_named_query" "rule_performance" {
  name      = "${var.project_name}_rule_performance"
  workgroup = aws_athena_workgroup.main.id
  database  = var.glue_database_name
  query     = <<-SQL
    CREATE OR REPLACE VIEW ${var.glue_database_name}.vw_rule_performance AS
    SELECT 
      terminatingruleid as rule_id,
      terminatingruletype as rule_type,
      action,
      COUNT(*) as total_triggers,
      COUNT(DISTINCT httprequest.clientip) as unique_ips,
      COUNT(DISTINCT httprequest.country) as unique_countries,
      ARRAY_AGG(DISTINCT httprequest.country) as countries
    FROM ${var.glue_database_name}.${var.glue_table_name}
    WHERE terminatingruleid IS NOT NULL
    GROUP BY terminatingruleid, terminatingruletype, action
    ORDER BY total_triggers DESC
  SQL

  description = "WAF rule performance metrics with trigger counts"
}

# Named Query: HTTP Method Analysis
resource "aws_athena_named_query" "http_method_analysis" {
  name      = "${var.project_name}_http_method_analysis"
  workgroup = aws_athena_workgroup.main.id
  database  = var.glue_database_name
  query     = <<-SQL
    CREATE OR REPLACE VIEW ${var.glue_database_name}.vw_http_method_analysis AS
    SELECT 
      httprequest.httpmethod as http_method,
      action,
      COUNT(*) as total_requests,
      COUNT(DISTINCT httprequest.clientip) as unique_ips
    FROM ${var.glue_database_name}.${var.glue_table_name}
    GROUP BY httprequest.httpmethod, action
    ORDER BY total_requests DESC
  SQL

  description = "Analysis of requests by HTTP method and action"
}

# Named Query: Response Code Distribution
resource "aws_athena_named_query" "response_codes" {
  name      = "${var.project_name}_response_codes"
  workgroup = aws_athena_workgroup.main.id
  database  = var.glue_database_name
  query     = <<-SQL
    CREATE OR REPLACE VIEW ${var.glue_database_name}.vw_response_codes AS
    SELECT 
      responsecodesent as response_code,
      action,
      COUNT(*) as total_responses,
      ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) as percentage
    FROM ${var.glue_database_name}.${var.glue_table_name}
    WHERE responsecodesent IS NOT NULL
    GROUP BY responsecodesent, action
    ORDER BY total_responses DESC
  SQL

  description = "Distribution of HTTP response codes with percentages"
}

# Named Query: Top Blocked Rules (Specific Rule Names)
resource "aws_athena_named_query" "top_blocked_rules" {
  name      = "${var.project_name}_top_blocked_rules"
  workgroup = aws_athena_workgroup.main.id
  database  = var.glue_database_name
  query     = <<-SQL
    CREATE OR REPLACE VIEW ${var.glue_database_name}.vw_top_blocked_rules AS
    SELECT 
      CASE 
        WHEN terminatingruleid IS NULL THEN 'No Rule'
        WHEN terminatingruleid LIKE '%/%' THEN element_at(split(terminatingruleid, '/'), -1)
        ELSE terminatingruleid
      END as rule_name,
      terminatingruleid as full_rule_id,
      terminatingruletype as rule_type,
      COUNT(*) as blocks,
      COUNT(DISTINCT httprequest.clientip) as unique_ips,
      COUNT(DISTINCT httprequest.country) as unique_countries
    FROM ${var.glue_database_name}.${var.glue_table_name}
    WHERE action = 'BLOCK'
    GROUP BY terminatingruleid, terminatingruletype
    ORDER BY blocks DESC
  SQL

  description = "Top blocked rules with specific rule names (SQLi, XSS, etc.)"
}

# Named Query: Blocks by Rule Type
resource "aws_athena_named_query" "blocks_by_rule_type" {
  name      = "${var.project_name}_blocks_by_rule_type"
  workgroup = aws_athena_workgroup.main.id
  database  = var.glue_database_name
  query     = <<-SQL
    CREATE OR REPLACE VIEW ${var.glue_database_name}.vw_blocks_by_rule_type AS
    SELECT 
      terminatingruletype as rule_type,
      COUNT(*) as total_blocks,
      COUNT(DISTINCT httprequest.clientip) as unique_ips,
      COUNT(DISTINCT httprequest.country) as unique_countries,
      ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) as percentage
    FROM ${var.glue_database_name}.${var.glue_table_name}
    WHERE action = 'BLOCK'
      AND terminatingruletype IS NOT NULL
    GROUP BY terminatingruletype
    ORDER BY total_blocks DESC
  SQL

  description = "Distribution of blocks by rule type (REGULAR, MANAGED_RULE_GROUP, etc.)"
}

# Named Query: Blocks Timeline (Time Series)
resource "aws_athena_named_query" "blocks_timeline" {
  name      = "${var.project_name}_blocks_timeline"
  workgroup = aws_athena_workgroup.main.id
  database  = var.glue_database_name
  query     = <<-SQL
    CREATE OR REPLACE VIEW ${var.glue_database_name}.vw_blocks_timeline AS
    SELECT 
      date_trunc('minute', from_unixtime("timestamp"/1000)) as time_minute,
      CASE 
        WHEN terminatingruleid LIKE '%/%' THEN element_at(split(terminatingruleid, '/'), -1)
        ELSE COALESCE(terminatingruleid, 'No Rule')
      END as rule_name,
      terminatingruletype as rule_type,
      COUNT(*) as blocks
    FROM ${var.glue_database_name}.${var.glue_table_name}
    WHERE action = 'BLOCK'
      AND from_unixtime("timestamp"/1000) >= current_timestamp - interval '7' day
    GROUP BY date_trunc('minute', from_unixtime("timestamp"/1000)), terminatingruleid, terminatingruletype
  SQL

  description = "Time series of blocks per minute by rule"
}

# Named Query: Block Investigation Details
resource "aws_athena_named_query" "block_investigation" {
  name      = "${var.project_name}_block_investigation"
  workgroup = aws_athena_workgroup.main.id
  database  = var.glue_database_name
  query     = <<-SQL
    CREATE OR REPLACE VIEW ${var.glue_database_name}.vw_block_investigation AS
    SELECT 
      from_unixtime("timestamp"/1000) as event_time,
      httprequest.clientip as client_ip,
      COALESCE(httprequest.country, 'Unknown') as country,
      COALESCE(httprequest.host, 'Unknown') as origin,
      httprequest.httpmethod as method,
      httprequest.uri as uri,
      CASE 
        WHEN terminatingruleid LIKE '%/%' THEN element_at(split(terminatingruleid, '/'), -1)
        ELSE COALESCE(terminatingruleid, 'No Rule')
      END as rule_name,
      terminatingruleid as full_rule_id,
      terminatingruletype as rule_type,
      httprequest.requestid as request_id,
      responsecodesent as response_code
    FROM ${var.glue_database_name}.${var.glue_table_name}
    WHERE action = 'BLOCK'
      AND from_unixtime("timestamp"/1000) >= current_timestamp - interval '7' day
  SQL

  description = "Detailed block investigation view for forensic analysis"
}
