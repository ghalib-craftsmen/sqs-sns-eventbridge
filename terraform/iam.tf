# ---------- Step Functions execution role ----------
data "aws_iam_policy_document" "sfn_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sfn" {
  name               = "${var.project_name}-sfn-role"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume.json
}

data "aws_iam_policy_document" "sfn_policy" {
  # Write good messages directly via the SDK integration.
  statement {
    sid       = "WriteGoodMessages"
    actions   = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.messages.arn]
  }

  # Publish bad messages to the alerts topic.
  statement {
    sid       = "PublishBadMessages"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts.arn]
  }

  # Express workflows write to CloudWatch Logs.
  statement {
    sid = "ExpressLogging"
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "sfn" {
  role   = aws_iam_role.sfn.id
  policy = data.aws_iam_policy_document.sfn_policy.json
}

# ---------- EventBridge Pipe role ----------
data "aws_iam_policy_document" "pipe_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["pipes.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "pipe" {
  name               = "${var.project_name}-pipe-role"
  assume_role_policy = data.aws_iam_policy_document.pipe_assume.json
}

data "aws_iam_policy_document" "pipe_policy" {
  statement {
    sid = "ReadFromSQS"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [aws_sqs_queue.primary.arn]
  }

  # Express workflows require StartSyncExecution.
  statement {
    sid       = "StartStateMachine"
    actions   = ["states:StartSyncExecution"]
    resources = [aws_sfn_state_machine.processor.arn]
  }
}

resource "aws_iam_role_policy" "pipe" {
  role   = aws_iam_role.pipe.id
  policy = data.aws_iam_policy_document.pipe_policy.json
}
