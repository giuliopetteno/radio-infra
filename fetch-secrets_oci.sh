#!/bin/bash
set -e
set -o errtrace

echo "CONTAINER_REGISTRY_REPO=eu-milan-1.ocir.io/axaxdolyh0iq" > .env
VAULT_ID="ocid1.vault.oc1.eu-milan-1.hjvql4s7aah2s.abwgsljr4qe7pxiybuvfokwrt3jzrxhtwapb6v2e7tclz5kkyfrbd2kocbtq"
LOG_FILE="/var/log/radio-infra.log"

log() {
  echo "$(date): $1" >> "$LOG_FILE"
}

trap 'log "Fetching secrets FAILED at line $LINENO: $BASH_COMMAND"' ERR

fetch_param() {
  local param_name=$1
  local var_name=$2

  if ! value=$("$HOME/bin/oci" secrets secret-bundle get-secret-bundle-by-name \
    --auth instance_principal \
    --region eu-milan-1 \
    --vault-id "$VAULT_ID" \
    --secret-name "$param_name" \
    --query 'data."secret-bundle-content".content' \
    --raw-output 2>&1); then
    log "FAILED to fetch $param_name: $value"
    exit 1
  fi

  value=$(printf '%s' "$value" | base64 --decode)
  echo "${var_name}=${value}" >> .env
}

fetch_param "radio.prod.shared.DB_URL" "DB_URL"
fetch_param "radio.prod.shared.POSTGRES_ADMIN_USER" "POSTGRES_ADMIN_USER"
fetch_param "radio.prod.shared.POSTGRES_ADMIN_PASSWORD" "POSTGRES_ADMIN_PASSWORD"
fetch_param "radio.prod.shared.DB_USERNAME" "DB_USERNAME"
fetch_param "radio.prod.shared.DB_PASSWORD" "DB_PASSWORD"
fetch_param "radio.prod.shared.GRAFANA_ADMIN_PASSWORD" "GRAFANA_ADMIN_PASSWORD"
fetch_param "radio.prod.registry.SSL_KEYSTORE_PASSWORD" "SSL_KEYSTORE_PASSWORD"
fetch_param "radio.prod.registry.JWT_SECRET" "JWT_SECRET"

chmod 600 .env
log "Secrets FETCHED successfully"
