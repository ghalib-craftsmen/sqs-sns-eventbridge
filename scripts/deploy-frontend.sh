#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRONTEND_DIR="$SCRIPT_DIR/../frontend"
TF_DIR="$SCRIPT_DIR/../terraform"

echo "--- Reading Terraform outputs ---"
BUCKET=$(terraform -chdir="$TF_DIR" output -raw s3_bucket_name)
CF_ID=$(terraform -chdir="$TF_DIR" output -raw cloudfront_distribution_id)
CF_DOMAIN=$(terraform -chdir="$TF_DIR" output -raw cloudfront_url)

echo "--- Building React app ---"
cd "$FRONTEND_DIR"
npm ci --silent
npm run build

echo "--- Uploading to s3://$BUCKET ---"
# Static assets (JS/CSS) are content-hashed by Vite — cache aggressively
aws s3 sync dist/ "s3://$BUCKET/" --delete \
  --cache-control "public, max-age=31536000, immutable" \
  --exclude "index.html"

# index.html must never be cached so deploys take effect immediately
aws s3 cp dist/index.html "s3://$BUCKET/index.html" \
  --cache-control "no-cache, no-store, must-revalidate"

echo "--- Invalidating CloudFront cache ($CF_ID) ---"
aws cloudfront create-invalidation \
  --distribution-id "$CF_ID" \
  --paths "/*" \
  --query 'Invalidation.Id' \
  --output text

echo ""
echo "Done. Open: https://$CF_DOMAIN"
