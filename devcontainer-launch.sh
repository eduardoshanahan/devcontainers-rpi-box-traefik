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
info "Validating environment variables..."
if ! sh "$PROJECT_DIR/scripts/validate-env.sh"; then
  error "Environment validation failed. Please fix your .env values."
  exit 1
fi

# Check if devcontainer CLI is installed
if ! command -v devcontainer >/dev/null 2>&1; then
  error "devcontainer CLI is not installed!"
  info "Please install it with: npm install -g @devcontainers/cli"
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

# Devcontainer CLI launcher uses a dedicated image/container name (not tied to EDITOR_CHOICE).
LAUNCHER_TAG="cli"
ID_LABEL="devcontainer.session=${PROJECT_NAME}-${LAUNCHER_TAG}"
export DOCKER_IMAGE_NAME="${PROJECT_NAME}-devcontainer"
export CONTAINER_HOSTNAME="${CONTAINER_HOSTNAME_DEVCONTAINER}"

info "Ensuring devcontainer is running..."
if [ -n "${DOCKER_IMAGE_NAME:-}" ] && [ -n "${DOCKER_IMAGE_TAG:-}" ]; then
  force_rebuild="${FORCE_REBUILD:-false}"
  case "$force_rebuild" in
    true|false) ;;
    *)
      error "FORCE_REBUILD must be true or false (got: ${force_rebuild})"
      exit 1
      ;;
  esac

  if ! $force_rebuild && docker image inspect "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" >/dev/null 2>&1; then
    info "Using cached devcontainer image ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} (set FORCE_REBUILD=true to rebuild)..."
  else
    info "Building devcontainer image ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}..."
    devcontainer build --workspace-folder "$PROJECT_DIR" --image-name "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" >/dev/null
  fi
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
  keep_container="${KEEP_CONTAINER_DEVCONTAINER:-false}"
  case "$keep_container" in
    true|false) ;;
    *)
      error "KEEP_CONTAINER_DEVCONTAINER must be true or false (got: ${keep_container})"
      return 1
      ;;
  esac
  if $keep_container; then
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

info "Opening a shell in the container..."
echo ""
devcontainer exec --workspace-folder "$PROJECT_DIR" --id-label "$ID_LABEL" bash -l
