#!/bin/bash
set -e
set -o errtrace

echo "CONTAINER_REGISTRY_REPO=643297135589.dkr.ecr.eu-south-1.amazonaws.com" > .env
LOG_FILE="/var/log/radio-infra.log"

log() {
  echo "$(date): $1" >> "$LOG_FILE"
}

trap 'log "Fetching secrets FAILED at line $LINENO: $BASH_COMMAND"' ERR

fetch_param() {
  local param_name=$1
  local var_name=$2
  local error_output

  if ! value=$(aws ssm get-parameter --name "$param_name" --with-decryption --query "Parameter.Value" --output text --region eu-south-1 2>&1); then
    log "FAILED to fetch $param_name: $value"
    exit 1
  fi

  echo "${var_name}=${value}" >> .env
}

fetch_param "/radio/prod/shared/DB_URL" "DB_URL"
fetch_param "/radio/prod/shared/DB_USERNAME" "DB_USERNAME"
fetch_param "/radio/prod/shared/DB_PASSWORD" "DB_PASSWORD"
fetch_param "/radio/prod/shared/GRAFANA_ADMIN_PASSWORD" "GRAFANA_ADMIN_PASSWORD"
fetch_param "/radio/prod/registry/SSL_KEYSTORE_PASSWORD" "SSL_KEYSTORE_PASSWORD"
fetch_param "/radio/prod/registry/JWT_SECRET" "JWT_SECRET"

chmod 600 .env
log "Secrets FETCHED successfully"
