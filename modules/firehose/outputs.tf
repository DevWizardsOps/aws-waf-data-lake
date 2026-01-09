output "delivery_stream_name" {
  description = "Kinesis Firehose delivery stream name"
  value       = aws_kinesis_firehose_delivery_stream.this.name
}

output "delivery_stream_arn" {
  description = "Kinesis Firehose delivery stream ARN"
  value       = aws_kinesis_firehose_delivery_stream.this.arn
}

output "delivery_stream_id" {
  description = "Kinesis Firehose delivery stream ID"
  value       = aws_kinesis_firehose_delivery_stream.this.id
}
