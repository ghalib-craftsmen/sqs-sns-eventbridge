resource "aws_cloudwatch_log_group" "sfn" {
  name              = "/aws/vendedlogs/states/${var.project_name}-processor"
  retention_in_days = 7
}

# EXPRESS workflow → cheap per-execution + can be invoked synchronously
# by the EventBridge Pipe (StartSyncExecution).
resource "aws_sfn_state_machine" "processor" {
  name     = "${var.project_name}-processor"
  role_arn = aws_iam_role.sfn.arn
  type     = "EXPRESS"

  definition = templatefile("${path.module}/state_machine.asl.json", {
    table_name = aws_dynamodb_table.messages.name
    topic_arn  = aws_sns_topic.alerts.arn
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn.arn}:*"
    include_execution_data = true
    level                  = "ERROR"
  }
}
