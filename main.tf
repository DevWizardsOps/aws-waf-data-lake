# CloudWatch Log Group for Firehose
resource "aws_cloudwatch_log_group" "firehose" {
  name              = "/aws/kinesisfirehose/${var.project_name}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_stream" "firehose" {
  name           = "DestinationDelivery"
  log_group_name = aws_cloudwatch_log_group.firehose.name
}

# Storage Module - S3 Bucket
module "storage" {
  source = "./modules/storage"

  project_name        = var.project_name
  account_id          = var.account_id
  region              = var.aws_region
  log_retention_days  = var.log_retention_days
  tags                = var.tags
}

# Glue Module - Data Catalog
module "glue" {
  source = "./modules/glue"

  project_name    = var.project_name
  database_name   = var.glue_database_name
  table_name      = var.glue_table_name
  schema_location = "s3://${module.storage.bucket_name}/waf/"
  tags            = var.tags

  depends_on = [
    module.storage
  ]
}

# IAM Module - Roles and Policies
module "iam" {
  source = "./modules/iam"

  project_name       = var.project_name
  account_id         = var.account_id
  region             = var.aws_region
  s3_bucket_arn      = module.storage.bucket_arn
  glue_database_name = module.glue.database_name
  glue_table_name    = module.glue.table_name
  log_group_arn      = aws_cloudwatch_log_group.firehose.arn
  tags               = var.tags

  depends_on = [
    module.storage,
    module.glue
  ]
}

# Firehose Module - Delivery Stream
module "firehose" {
  source = "./modules/firehose"

  project_name       = var.project_name
  region             = var.aws_region
  s3_bucket_arn      = module.storage.bucket_arn
  iam_role_arn       = module.iam.firehose_role_arn
  glue_database_name = module.glue.database_name
  glue_table_name    = module.glue.table_name
  log_group_name     = aws_cloudwatch_log_group.firehose.name
  log_stream_name    = aws_cloudwatch_log_stream.firehose.name
  tags               = var.tags

  depends_on = [
    module.iam
  ]
}

# Athena Module - Workgroup and Views
module "athena" {
  source = "./modules/athena"

  project_name                  = var.project_name
  account_id                    = var.account_id
  region                        = var.aws_region
  glue_database_name            = module.glue.database_name
  glue_table_name               = module.glue.table_name
  query_results_retention_days  = var.athena_query_results_retention_days
  tags                          = var.tags

  depends_on = [
    module.glue
  ]
}

# Lambda Module - Daily View Updates
module "lambda" {
  source = "./modules/lambda"

  project_name               = var.project_name
  glue_database_name         = module.glue.database_name
  athena_workgroup           = module.athena.workgroup_name
  athena_output_location     = "s3://${module.athena.query_results_bucket}/lambda-executions/"
  athena_results_bucket_arn  = module.athena.query_results_bucket_arn
  named_query_ids            = module.athena.named_queries
  schedule_expression        = var.lambda_schedule_expression
  tags                       = var.tags

  depends_on = [
    module.athena
  ]
}
