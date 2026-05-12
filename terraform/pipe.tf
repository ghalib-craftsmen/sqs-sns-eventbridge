resource "aws_pipes_pipe" "sqs_to_sfn" {
  name     = "${var.project_name}-pipe"
  role_arn = aws_iam_role.pipe.arn
  source   = aws_sqs_queue.primary.arn
  target   = aws_sfn_state_machine.processor.arn

  source_parameters {
    sqs_queue_parameters {
      batch_size                         = 5 # <-- required by the spec
      maximum_batching_window_in_seconds = 5
    }
  }

  target_parameters {
    # Express + REQUEST_RESPONSE: pipe waits for the workflow.
    # If the workflow fails, SQS does NOT delete the messages → they retry,
    # eventually landing in the DLQ after maxReceiveCount.
    step_function_state_machine_parameters {
      invocation_type = "REQUEST_RESPONSE"
    }
  }

  depends_on = [
    aws_iam_role_policy.pipe,
    aws_iam_role_policy.sfn,
  ]
}
