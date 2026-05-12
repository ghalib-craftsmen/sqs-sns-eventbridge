# Single SNS topic for *all* admin alerts:
#   • bad messages (published by Step Functions)
#   • DLQ alarm transitions (published by CloudWatch)
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "admin_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.admin_email
  # After apply, the admin must click the AWS confirmation link in their inbox.
}
