#!/bin/sh

set -eu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

error() {
  printf '%b\n' "${RED}ERROR: $1${NC}" >&2
}

success() {
  printf '%b\n' "${GREEN}$1${NC}"
}

info() {
  printf '%b\n' "${YELLOW}$1${NC}"
}

PROJECT_DIR="$(CDPATH= cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  error "Cannot find .env at $ENV_FILE"
  exit 1
fi

# Load environment variables from the project root .env
set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

if ! command -v docker >/dev/null 2>&1; then
  error "Docker is not installed!"
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  error "Docker does not appear to be running. Start the Docker daemon and try again."
  exit 1
fi

if [ -z "${DEVCONTAINER_IMAGE_RETENTION_DAYS:-}" ]; then
  error "DEVCONTAINER_IMAGE_RETENTION_DAYS must be set in .env."
  exit 1
fi

RETENTION_DAYS="${DEVCONTAINER_IMAGE_RETENTION_DAYS}"
case "$RETENTION_DAYS" in
  ''|*[!0-9]*)
    error "DEVCONTAINER_IMAGE_RETENTION_DAYS must be a positive integer (days)."
    exit 1
    ;;
esac
if [ "$RETENTION_DAYS" -le 0 ]; then
  error "DEVCONTAINER_IMAGE_RETENTION_DAYS must be greater than zero."
  exit 1
fi

RETENTION_HOURS=$((RETENTION_DAYS * 24))

info "Pruning dangling images older than ${RETENTION_DAYS} days..."
docker image prune -f --filter "until=${RETENTION_HOURS}h"

info "Pruning unused devcontainer images older than ${RETENTION_DAYS} days..."
docker image prune -a -f --filter "label=devcontainer.metadata" --filter "until=${RETENTION_HOURS}h"

success "Devcontainer image cleanup complete."
