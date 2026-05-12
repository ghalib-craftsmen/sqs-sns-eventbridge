# Dead Letter Queue — receives messages whose StartExecution failed
# `maxReceiveCount` times against the primary queue.
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project_name}-dlq"
  message_retention_seconds = 1209600 # 14 days
}

# Primary queue — source for the EventBridge Pipe.
# Visibility timeout must be ≥ longest possible state-machine run.
resource "aws_sqs_queue" "primary" {
  name                       = "${var.project_name}-primary"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600 # 4 days

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

# Alert the admin when *anything* lands in the DLQ.
resource "aws_cloudwatch_metric_alarm" "dlq_has_messages" {
  alarm_name          = "${var.project_name}-dlq-not-empty"
  alarm_description   = "Messages have been redriven to the DLQ"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}
