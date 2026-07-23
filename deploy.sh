#!/bin/bash
set -e

LOG_FILE="/var/log/radio-infra.log"

log() {
  echo "$(date): $1" >> "$LOG_FILE"
}

trap 'log "Deploy FAILED at line $LINENO"' ERR

cd /home/ssm-user/radio-infra

log "Deploy started"

aws ecr get-login-password --region eu-south-1 | docker login --username AWS --password-stdin 643297135589.dkr.ecr.eu-south-1.amazonaws.com

sudo -u ssm-user git pull

sudo -u ssm-user ./fetch-secrets.sh

docker compose -f docker-compose.aws.yml pull
docker compose -f docker-compose.aws.yml up -d

log "Deploy COMPLETED successfully"
