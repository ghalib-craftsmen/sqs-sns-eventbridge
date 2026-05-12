#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../terraform"
QUEUE_URL="$(terraform output -raw primary_queue_url)"
TABLE="$(terraform output -raw dynamodb_table_name)"

echo "Queue: $QUEUE_URL"
echo

echo "--- Sending 6 GOOD messages ---"
for i in 1 2 3 4 5 6; do
  body=$(printf '{"id":"good-%s","name":"User %s","value":%s}' "$i" "$i" "$i")
  aws sqs send-message --queue-url "$QUEUE_URL" --message-body "$body" >/dev/null
  echo "  sent good-$i"
done

echo
echo "--- Sending 6 BAD messages (valid JSON, missing fields) ---"
for i in 1 2 3 4 5 6; do
  body=$(printf '{"oops":"no id or name here, message %s"}' "$i")
  aws sqs send-message --queue-url "$QUEUE_URL" --message-body "$body" >/dev/null
  echo "  sent bad-$i"
done

echo
echo "==> 12 messages in flight. Wait ~30s, then:"
echo "    aws dynamodb scan --table-name $TABLE --select COUNT"
echo "    (should report Count: 6)"
echo "    Check your email inbox for 6 'Bad SQS message detected' alerts."
