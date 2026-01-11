#!/bin/sh
set -eu

# Determine project directory
if [ -z "${PROJECT_DIR+x}" ] || [ -z "$PROJECT_DIR" ]; then
    printf '%s\n' "Error: PROJECT_DIR is required"
    exit 1
fi
ENV_LOADER="$PROJECT_DIR/.devcontainer/scripts/env-loader.sh"

if [ ! -f "$ENV_LOADER" ]; then
    printf '%s\n' "Error: env-loader.sh not found at $ENV_LOADER"
    exit 1
fi

# Load variables: project root .env is authoritative, .devcontainer/config/.env supplies defaults
# shellcheck disable=SC1090
. "$ENV_LOADER"
load_project_env "$PROJECT_DIR"

require_var() {
    var_name="$1"
    eval "value=\${$var_name-}"
    if [ -z "$value" ]; then
        printf '%s\n' "Error: $var_name is required"
        exit 1
    fi
}

require_var "CONTAINER_MEMORY"
require_var "CONTAINER_CPUS"
require_var "CONTAINER_SHM_SIZE"
require_var "CONTAINER_HOSTNAME"
require_var "PYTHON_VERSION"
require_var "ANSIBLE_CORE_VERSION"
require_var "ANSIBLE_LINT_VERSION"
require_var "YAMLLINT_VERSION"

printf '%s\n' "Container configuration:"
printf '%s\n' "  Memory: $CONTAINER_MEMORY"
printf '%s\n' "  CPUs: $CONTAINER_CPUS"
printf '%s\n' "  Shared Memory: $CONTAINER_SHM_SIZE"
printf '%s\n' "  Hostname: $CONTAINER_HOSTNAME"
printf '%s\n' "  Python: $PYTHON_VERSION"
printf '%s\n' "  Ansible Core: $ANSIBLE_CORE_VERSION"
printf '%s\n' "  Ansible Lint: $ANSIBLE_LINT_VERSION"
printf '%s\n' "  Yamllint: $YAMLLINT_VERSION"
