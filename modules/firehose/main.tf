resource "aws_kinesis_firehose_delivery_stream" "this" {
  name        = "aws-waf-logs-${var.project_name}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = var.iam_role_arn
    bucket_arn          = var.s3_bucket_arn
    prefix              = var.s3_prefix
    error_output_prefix = var.s3_error_prefix
    buffering_size      = var.buffering_size
    buffering_interval  = var.buffering_interval
    compression_format  = "UNCOMPRESSED"
    custom_time_zone    = var.custom_time_zone

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = var.log_group_name
      log_stream_name = var.log_stream_name
    }

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        role_arn      = var.iam_role_arn
        database_name = var.glue_database_name
        table_name    = var.glue_table_name
        region        = var.region
        version_id    = "LATEST"
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-firehose"
    }
  )
}
