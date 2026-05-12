#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../terraform"

if [[ -z "${TF_VAR_admin_email:-}" ]]; then
  read -rp "Admin email for alerts: " admin_email
  export TF_VAR_admin_email="$admin_email"
fi

terraform init -upgrade
terraform apply -auto-approve

echo
echo "==> Done. Confirm the SNS subscription email AWS just sent you."
echo "==> Then run: ./scripts/send-test-messages.sh"
