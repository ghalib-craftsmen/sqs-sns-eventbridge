# Frontend — SQS Message Sender

A minimal React SPA that sends messages through the pipeline:

```
Browser → CloudFront → API Gateway → SQS → Step Functions → DynamoDB / SNS
```

## Local development

```bash
npm install
npm run dev
```

> `npm run dev` sends requests to `/api/messages` which won't resolve locally.
> To test end-to-end, deploy to S3 and use the CloudFront URL.

## Build

```bash
npm run build   # outputs to dist/
```

## Deploy to AWS

From the project root, use the deploy script (requires bash):

```bash
bash scripts/deploy-frontend.sh
```

Or manually from PowerShell:

```powershell
npm run build

aws s3 sync dist/ s3://<bucket-name>/ --delete `
  --cache-control "public, max-age=31536000, immutable" `
  --exclude "index.html"

aws s3 cp dist/index.html s3://<bucket-name>/index.html `
  --cache-control "no-cache, no-store, must-revalidate"

aws cloudfront create-invalidation `
  --distribution-id <distribution-id> `
  --paths "/*"
```

Get `<bucket-name>` and `<distribution-id>` from Terraform outputs:

```bash
terraform -chdir=../terraform output s3_bucket_name
terraform -chdir=../terraform output cloudfront_distribution_id
```

## Message format

| Type    | Payload                              | Result              |
|---------|--------------------------------------|---------------------|
| Valid   | `{"id":"msg-001","name":"Alice"}`    | Stored in DynamoDB  |
| Invalid | _(missing `id` or `name`)_           | SNS email alert     |

Use the **"Send invalid message"** checkbox in the UI to test the invalid path.
