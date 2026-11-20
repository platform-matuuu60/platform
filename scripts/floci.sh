#!/usr/bin/env bash
# Manage the local Floci AWS emulator on the host (see docs/adr/0001).
# Floci is published on loopback only and must never be exposed to the internet.
set -euo pipefail

IMAGE="${FLOCI_IMAGE:-floci/floci:2.5.0}"
NAME="floci"
NETWORK="floci"
VOLUME="floci-data"

up() {
  docker network inspect "$NETWORK" >/dev/null 2>&1 || docker network create "$NETWORK" >/dev/null
  docker volume create "$VOLUME" >/dev/null
  if docker container inspect "$NAME" >/dev/null 2>&1; then
    docker start "$NAME" >/dev/null
  else
    # The Docker socket lets Floci run Lambda, RDS, ElastiCache and EKS as real containers.
    docker run -d \
      --name "$NAME" \
      --restart unless-stopped \
      --network "$NETWORK" \
      -p 127.0.0.1:4566:4566 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v "$VOLUME":/app/data \
      -e FLOCI_HOSTNAME="$NAME" \
      -e FLOCI_SERVICES_DOCKER_NETWORK="$NETWORK" \
      -e FLOCI_STORAGE_MODE=persistent \
      -e FLOCI_STORAGE_PERSISTENT_PATH=/app/data \
      -e FLOCI_SERVICES_IAM_ENFORCEMENT_ENABLED=true \
      -e FLOCI_SERVICES_EKS_MAX_MEMORY_MIB=4096 \
      -e FLOCI_SERVICES_EKS_MAX_VCPUS=2 \
      "$IMAGE" >/dev/null
  fi
  echo "Floci running on http://127.0.0.1:4566 ($IMAGE)"
}

down() {
  docker stop "$NAME" >/dev/null 2>&1 || true
  echo "Floci stopped (data kept in volume $VOLUME)"
}

status() {
  docker ps --filter "name=^${NAME}$" --format '{{.Names}} {{.Image}} {{.Status}} {{.Ports}}'
}

case "${1:-}" in
  up) up ;;
  down) down ;;
  status) status ;;
  *) echo "usage: $0 {up|down|status}" >&2; exit 2 ;;
esac
