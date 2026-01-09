# IAM User for Grafana Athena Datasource
resource "aws_iam_user" "grafana" {
  name = "${var.project_name}-grafana"
  path = "/"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-grafana"
      Description = "IAM user for Grafana to access Athena data lake"
    }
  )
}

# IAM Policy for Grafana with Athena, Glue, and S3 permissions
resource "aws_iam_policy" "grafana" {
  name        = "${var.project_name}-grafana-policy"
  description = "Policy for Grafana to query WAF data lake via Athena"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:StartQueryExecution",
          "athena:StopQueryExecution",
          "athena:GetWorkGroup",
          "athena:ListWorkGroups",
          "athena:GetDatabase",
          "athena:GetDataCatalog",
          "athena:GetTableMetadata",
          "athena:ListDatabases",
          "athena:ListDataCatalogs",
          "athena:ListTableMetadata",
          "athena:ListQueryExecutions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions"
        ]
        Resource = [
          "arn:aws:glue:${var.aws_region}:${var.account_id}:catalog",
          "arn:aws:glue:${var.aws_region}:${var.account_id}:database/${module.glue.database_name}",
          "arn:aws:glue:${var.aws_region}:${var.account_id}:table/${module.glue.database_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          module.storage.bucket_arn,
          module.athena.query_results_bucket_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${module.storage.bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${module.athena.query_results_bucket_arn}/*"
        ]
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-grafana-policy"
    }
  )
}

# Attach policy to Grafana user
resource "aws_iam_user_policy_attachment" "grafana" {
  user       = aws_iam_user.grafana.name
  policy_arn = aws_iam_policy.grafana.arn
}

# Access Key for Grafana (optional - can be created manually for security)
resource "aws_iam_access_key" "grafana" {
  user = aws_iam_user.grafana.name
}
