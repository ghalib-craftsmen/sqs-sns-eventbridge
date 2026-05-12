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
