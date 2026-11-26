#!/bin/bash
set -e
set -o errtrace

LOG_FILE="/var/log/radio-infra.log"

log() {
  echo "$(date): $1" >> "$LOG_FILE"
}

trap 'log "Deploy FAILED at line $LINENO"' ERR

cd /home/ubuntu/radio-infra

log "Deploy started"

sudo -H -u ubuntu /home/ubuntu/bin/oci raw-request \
  --auth instance_principal \
  --region eu-milan-1 \
  --http-method GET \
  --target-uri https://eu-milan-1.ocir.io/20180419/docker/token \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["data"]["token"])' |
  docker login eu-milan-1.ocir.io --username BEARER_TOKEN --password-stdin

sudo -H -u ubuntu git pull

sudo -H -u ubuntu ./fetch-secrets.oci.sh

docker compose -f docker-compose.oci.yml pull
docker compose -f docker-compose.oci.yml up -d

log "Deploy COMPLETED successfully"