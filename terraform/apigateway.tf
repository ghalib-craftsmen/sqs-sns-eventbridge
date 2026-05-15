data "aws_caller_identity" "current" {}

resource "aws_api_gateway_rest_api" "main" {
  name = "${var.project_name}-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# /api
resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "api"
}

# /api/messages
resource "aws_api_gateway_resource" "messages" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "messages"
}

# ── POST /api/messages ────────────────────────────────────────────────────────

resource "aws_api_gateway_method" "post_messages" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.messages.id
  http_method   = "POST"
  authorization = "NONE"
}

# Direct AWS SDK integration: API Gateway → SQS SendMessage (no Lambda needed)
resource "aws_api_gateway_integration" "sqs" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.messages.id
  http_method             = aws_api_gateway_method.post_messages.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  credentials             = aws_iam_role.apigw.arn
  uri                     = "arn:aws:apigateway:${var.aws_region}:sqs:path/${data.aws_caller_identity.current.account_id}/${aws_sqs_queue.primary.name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  # SQS SendMessage expects form-encoded: Action=SendMessage&MessageBody=<body>
  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }
}

resource "aws_api_gateway_method_response" "post_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.messages.id
  http_method = aws_api_gateway_method.post_messages.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "post_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.messages.id
  http_method = aws_api_gateway_method.post_messages.http_method
  status_code = aws_api_gateway_method_response.post_200.status_code

  response_templates = {
    "application/json" = "{\"message\":\"Message queued\"}"
  }

  depends_on = [aws_api_gateway_integration.sqs]
}

# ── OPTIONS /api/messages (CORS preflight) ────────────────────────────────────
# Needed for browsers reaching API GW directly during local dev

resource "aws_api_gateway_method" "options_messages" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.messages.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_messages" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.messages.id
  http_method = aws_api_gateway_method.options_messages.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\":200}"
  }
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.messages.id
  http_method = aws_api_gateway_method.options_messages.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.messages.id
  http_method = aws_api_gateway_method.options_messages.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.options_messages]
}

# ── Deployment & stage ────────────────────────────────────────────────────────

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.messages.id,
      aws_api_gateway_method.post_messages.id,
      aws_api_gateway_integration.sqs.id,
      aws_api_gateway_integration_response.post_200.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration_response.post_200,
    aws_api_gateway_integration_response.options_200,
  ]
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  deployment_id = aws_api_gateway_deployment.main.id
  stage_name    = "prod"
}
