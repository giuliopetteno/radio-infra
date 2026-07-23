#!/bin/bash
set -e

echo "CONTAINER_REGISTRY_REPO=643297135589.dkr.ecr.eu-south-1.amazonaws.com" > .env

fetch_param() {
  local param_name=$1
  local var_name=$2
  value=$(aws ssm get-parameter --name "$param_name" --with-decryption --query "Parameter.Value" --output text --region eu-south-1)
  echo "${var_name}=${value}" >> .env
}

fetch_param "/radio/prod/shared/DB_URL" "DB_URL"
fetch_param "/radio/prod/shared/DB_USERNAME" "DB_USERNAME"
fetch_param "/radio/prod/shared/DB_PASSWORD" "DB_PASSWORD"
fetch_param "/radio/prod/registry/SSL_KEYSTORE_PASSWORD" "SSL_KEYSTORE_PASSWORD"

chmod 600 .env
echo "Secrets fetched successfully."
