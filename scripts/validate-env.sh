#!/bin/sh
set -eu

error() {
  printf '%s\n' "ERROR: $*" >&2
}

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

ENV_LOADER="${REPO_ROOT}/.devcontainer/scripts/env-loader.sh"
VALIDATOR="${REPO_ROOT}/.devcontainer/scripts/validate-env.sh"

if [ ! -f "$ENV_LOADER" ]; then
  error "Cannot find env-loader at $ENV_LOADER"
  exit 1
fi

if [ ! -f "$VALIDATOR" ]; then
  error "Cannot find validator at $VALIDATOR"
  exit 1
fi

# shellcheck disable=SC1090
. "$ENV_LOADER"
load_project_env "$REPO_ROOT"

context="${1:-editor}"
case "$context" in
  editor|devcontainer|cli|claude) ;;
  *)
    error "Usage: ./scripts/validate-env.sh [editor|devcontainer|claude]"
    exit 2
    ;;
esac

export INSTALL_CLAUDE="${INSTALL_CLAUDE:-false}"
export KEEP_CONTAINER_DEVCONTAINER="${KEEP_CONTAINER_DEVCONTAINER:-false}"
export KEEP_CONTAINER_CLAUDE="${KEEP_CONTAINER_CLAUDE:-false}"
export KEEP_CONTAINER_EDITOR="${KEEP_CONTAINER_EDITOR:-false}"

export CONTAINER_HOSTNAME_EDITOR="${CONTAINER_HOSTNAME_EDITOR:-${PROJECT_NAME}-editor}"
export CONTAINER_HOSTNAME_DEVCONTAINER="${CONTAINER_HOSTNAME_DEVCONTAINER:-${PROJECT_NAME}-devcontainer}"
export CONTAINER_HOSTNAME_CLAUDE="${CONTAINER_HOSTNAME_CLAUDE:-${PROJECT_NAME}-claude}"

case "$context" in
  editor)
    export DEVCONTAINER_CONTEXT="${DEVCONTAINER_CONTEXT:-editor}"
    export DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-${PROJECT_NAME}-editor}"
    export CONTAINER_HOSTNAME="${CONTAINER_HOSTNAME:-${CONTAINER_HOSTNAME_EDITOR}}"
    ;;
  devcontainer|cli)
    export DEVCONTAINER_CONTEXT="${DEVCONTAINER_CONTEXT:-devcontainer}"
    export DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-${PROJECT_NAME}-devcontainer}"
    export CONTAINER_HOSTNAME="${CONTAINER_HOSTNAME:-${CONTAINER_HOSTNAME_DEVCONTAINER}}"
    ;;
  claude)
    export DEVCONTAINER_CONTEXT="${DEVCONTAINER_CONTEXT:-claude}"
    export DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-${PROJECT_NAME}-claude}"
    export CONTAINER_HOSTNAME="${CONTAINER_HOSTNAME:-${CONTAINER_HOSTNAME_CLAUDE}}"
    ;;
esac

if ! sh "$VALIDATOR"; then
  error "Environment validation failed. Fix your .env values, or validate a specific launcher context with: ./scripts/validate-env.sh [editor|devcontainer|claude]"
  exit 1
fi

printf '%s\n' "Environment validation passed."
