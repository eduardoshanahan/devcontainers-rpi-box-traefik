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

if ! sh "$VALIDATOR"; then
  error "Environment validation failed. This project expects you to start the devcontainer via ./devcontainer-launch.sh, ./editor-launch.sh, or ./workspace.sh."
  exit 1
fi

printf '%s\n' "Environment validation passed."
