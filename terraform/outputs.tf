output "primary_queue_url" {
  value       = aws_sqs_queue.primary.url
  description = "Send test messages here"
}

output "dlq_url" {
  value = aws_sqs_queue.dlq.url
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.messages.name
}

output "alerts_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "state_machine_arn" {
  value = aws_sfn_state_machine.processor.arn
}

output "cost_filter_tag" {
  value       = "Project=${var.project_name}"
  description = "Filter by this tag in AWS Cost Explorer to see total spend"
}

output "cloudfront_url" {
  value       = aws_cloudfront_distribution.main.domain_name
  description = "Open in a browser — React app is served from here"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.frontend.id
  description = "Upload the built React app here via scripts/deploy-frontend.sh"
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.main.id
}

output "api_gateway_id" {
  value       = aws_api_gateway_rest_api.main.id
  description = "REST API that receives POST /api/messages from CloudFront"
}
