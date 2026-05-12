# SQS Message Processing Pipeline

Serverless pipeline that routes valid JSON messages to DynamoDB and invalid messages to email alerts using SQS, EventBridge Pipes, Step Functions, and SNS.

## Architecture

```
SQS Queue (batch 5) → EventBridge Pipe → Step Functions Express
                                              ├─ Valid → DynamoDB
                                              └─ Invalid → SNS Email
                        ↓ (3 failed attempts)
                      DLQ → CloudWatch Alarm → SNS Email
```

**Zero compute resources:** Step Functions uses AWS SDK integrations (`dynamodb:PutItem`, `sns:Publish`) to call services directly without Lambda/EC2/ECS.

## Prerequisites

- AWS account with configured credentials
- Terraform >= 1.5
- AWS CLI v2

Default configuration:

- Region: `ap-southeast-1`
- Resource prefix: `trainee-2026-abdullah-sqs-homework`

## Getting Started

### 1. Configure AWS

```bash
aws configure
```

### 2. Deploy

```bash
chmod +x scripts/*.sh
./scripts/deploy.sh
```

Enter your email when prompted. Confirm SNS subscription via the email link.

### 3. Test

```bash
./scripts/send-test-messages.sh
```

Wait 30 seconds, then verify:

```bash
aws dynamodb scan --table-name trainee-2026-abdullah-sqs-homework-messages --select COUNT
```

Expected: 6 items in DynamoDB, 6 email alerts received.

### 4. Cleanup

```bash
./scripts/destroy.sh
```

## Message Validation

Valid messages require `id` (string) and `name` (string):

```json
{ "id": "abc123", "name": "Alice", "value": 42 }   // valid
{ "id": "xyz", "value": 7 }                         // invalid - no name
{ "oops": "wrong schema" }                          // invalid
```

Edit validation logic in `terraform/state_machine.asl.json`.

## How It Works

1. **EventBridge Pipe** polls SQS with batch size 5
2. **Step Functions** processes each message:
   - Parse JSON body
   - Validate schema (id + name present)
   - Valid → write to DynamoDB
   - Invalid → publish to SNS
3. **Failures** (invalid JSON) retry 3 times → DLQ → alarm

## Cost Tracking

All resources tagged `Project=trainee-2026-abdullah-sqs-homework`.

To view total cost:

1. AWS Console → Billing → Cost allocation tags
2. Activate `Project` tag
3. Cost Explorer → filter by `Project=trainee-2026-abdullah-sqs-homework`

## Troubleshooting

**No SNS email:** Check spam folder

**DynamoDB Count: 0:** Wait 30 seconds, check CloudWatch logs at `/aws/vendedlogs/states/trainee-2026-abdullah-sqs-homework-processor`

**Step Functions shows "Failed":** Expected for Express workflows. Failed executions are from DLQ testing. DynamoDB table shows successful processing.

## Configuration Override

```bash
TF_VAR_aws_region=us-east-1 TF_VAR_project_name=custom-name ./scripts/deploy.sh
```

## Project Structure

```
terraform/
  providers.tf            AWS provider + tags
  variables.tf            Configuration variables
  sqs.tf                  Queues + DLQ + alarm
  dynamodb.tf             Messages table
  sns.tf                  Alert topic
  stepfunctions.tf        State machine
  state_machine.asl.json  Workflow definition
  pipe.tf                 EventBridge Pipe
  iam.tf                  IAM roles
scripts/
  deploy.sh               Deploy infrastructure
  destroy.sh              Remove resources
  send-test-messages.sh   Test with 12 messages
```
