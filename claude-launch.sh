#!/bin/sh

# Set strict shell options
set -eu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print error messages
error() {
  printf '%b\n' "${RED}ERROR: $1${NC}" >&2
}

# Function to print success messages
success() {
  printf '%b\n' "${GREEN}$1${NC}"
}

# Function to print info messages
info() {
  printf '%b\n' "${YELLOW}$1${NC}"
}

# Load project environment
PROJECT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ENV_LOADER="$PROJECT_DIR/.devcontainer/scripts/env-loader.sh"

if [ ! -f "$ENV_LOADER" ]; then
  error "Cannot find env-loader at $ENV_LOADER"
  exit 1
fi

# shellcheck disable=SC1090
. "$ENV_LOADER"
load_project_env "$PROJECT_DIR"

# Validate environment
VALIDATOR="$PROJECT_DIR/.devcontainer/scripts/validate-env.sh"
if [ -f "$VALIDATOR" ]; then
  info "Validating environment variables..."
  if ! sh "$VALIDATOR"; then
    error "Environment validation failed. Please fix your .env values."
    exit 1
  fi
fi

# Check if devcontainer CLI is installed
if ! command -v devcontainer >/dev/null 2>&1; then
  error "devcontainer CLI is not installed!"
  info "Please install it with: npm install -g @devcontainers/cli"
  info "Or use ./editor-launch.sh to work with VS Code/Cursor instead."
  exit 1
fi

# Check if Docker is installed and running
if ! command -v docker >/dev/null 2>&1; then
  error "Docker is not installed!"
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  error "Docker does not appear to be running. Start the Docker daemon and try again."
  exit 1
fi

# Export variables for devcontainer
export HOST_USERNAME
export HOST_UID
export HOST_GID
export GIT_USER_NAME
export GIT_USER_EMAIL
export GIT_REMOTE_URL
export EDITOR_CHOICE
export DOCKER_IMAGE_TAG

# Use a unique container name for Claude sessions to avoid conflicts
LAUNCHER_TAG="claude"
BASE_CONTAINER_NAME="${PROJECT_NAME}-${LAUNCHER_TAG}"
DEFAULT_CONTAINER_NAME="${PROJECT_NAME}-${EDITOR_CHOICE:-code}"
ID_LABEL="devcontainer.session=${PROJECT_NAME}-${LAUNCHER_TAG}"
if [ -z "${DOCKER_IMAGE_NAME:-}" ] || [ "$DOCKER_IMAGE_NAME" = "$DEFAULT_CONTAINER_NAME" ] || [ "$DOCKER_IMAGE_NAME" = "${PROJECT_NAME}-code" ]; then
  UNIQUE_SUFFIX="$(date +%s)-$$"
  export DOCKER_IMAGE_NAME="${BASE_CONTAINER_NAME}-${UNIQUE_SUFFIX}"
  export CONTAINER_HOSTNAME="${DOCKER_IMAGE_NAME}"
fi

info "Ensuring devcontainer is running..."
if [ -n "${DOCKER_IMAGE_NAME:-}" ] && [ -n "${DOCKER_IMAGE_TAG:-}" ]; then
  info "Building devcontainer image ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}..."
  devcontainer build --workspace-folder "$PROJECT_DIR" --image-name "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" >/dev/null
fi
if ! devcontainer exec --workspace-folder "$PROJECT_DIR" --id-label "$ID_LABEL" true >/dev/null 2>&1; then
  if docker ps -a --format '{{.Names}}' | grep -qx "${DOCKER_IMAGE_NAME}"; then
    info "Removing stale container: ${DOCKER_IMAGE_NAME}"
    docker rm -f "${DOCKER_IMAGE_NAME}" >/dev/null 2>&1 || true
  fi
  devcontainer up --workspace-folder "$PROJECT_DIR" --id-label "$ID_LABEL" --remove-existing-container >/dev/null
fi

success "Devcontainer is running"
info "Container will stop when this session ends."
stop_container() {
  if [ "${KEEP_CONTAINER:-}" = "1" ] || [ "${KEEP_CONTAINER:-}" = "true" ]; then
    return 0
  fi
  if devcontainer down --workspace-folder "$PROJECT_DIR" --id-label "$ID_LABEL" >/dev/null 2>&1; then
    return 0
  fi
  if command -v docker >/dev/null 2>&1; then
    docker stop "${DOCKER_IMAGE_NAME}" >/dev/null 2>&1 || true
  fi
}
trap 'stop_container' EXIT

info "Launching Claude Code..."
echo ""

# Launch Claude Code interactively in the container.
# Avoid relying on non-interactive .bashrc behavior; prefer a direct path fallback.
devcontainer exec --workspace-folder "$PROJECT_DIR" --id-label "$ID_LABEL" bash -lc 'if command -v claude >/dev/null 2>&1; then exec claude; elif [ -x "$HOME/.local/bin/claude" ]; then exec "$HOME/.local/bin/claude"; else echo "Claude Code not found in PATH or ~/.local/bin. Rebuild the container or re-run post-create to install it."; exit 127; fi'

echo ""
info "Claude Code session ended."
stop_container
