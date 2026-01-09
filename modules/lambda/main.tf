# Create ZIP file for Lambda deployment
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/function/update_views.py"
  output_path = "${path.module}/function/update_views.zip"
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-update-views"
  retention_in_days = 7

  tags = var.tags
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-update-views-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-update-views-lambda-role"
    }
  )
}

# IAM Policy for Lambda
resource "aws_iam_policy" "lambda" {
  name = "${var.project_name}-update-views-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:GetNamedQuery",
          "athena:ListNamedQueries"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetPartitions",
          "glue:CreateTable",
          "glue:UpdateTable"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = [
          var.athena_results_bucket_arn,
          "${var.athena_results_bucket_arn}/*"
        ]
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-update-views-lambda-policy"
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

# Lambda Function
resource "aws_lambda_function" "update_views" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "${var.project_name}-update-views"
  role            = aws_iam_role.lambda.arn
  handler         = "update_views.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime         = "python3.12"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  environment {
    variables = {
      ATHENA_WORKGROUP       = var.athena_workgroup
      GLUE_DATABASE          = var.glue_database_name
      ATHENA_OUTPUT_LOCATION = var.athena_output_location
      NAMED_QUERY_IDS        = jsonencode(var.named_query_ids)
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.lambda
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-update-views"
    }
  )
}

# EventBridge Rule for daily execution
resource "aws_cloudwatch_event_rule" "daily" {
  name                = "${var.project_name}-update-views-daily"
  description         = "Trigger Lambda to update Athena views daily"
  schedule_expression = var.schedule_expression

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-update-views-daily"
    }
  )
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.daily.name
  target_id = "UpdateViewsLambda"
  arn       = aws_lambda_function.update_views.arn
}

# Lambda Permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_views.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily.arn
}
