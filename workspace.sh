#!/bin/sh

set -eu

error() {
  printf '%s\n' "ERROR: $*" >&2
}

info() {
  printf '%s\n' "INFO: $*"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    error "Missing required command: $1"
    return 1
  fi
}

is_container() {
  if [ -f /.dockerenv ]; then
    return 0
  fi
  if [ -r /proc/1/cgroup ] && grep -Eq '(docker|containerd|kubepods)' /proc/1/cgroup; then
    return 0
  fi
  return 1
}

PROJECT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

# This workspace is intended to be launched from the host machine (outside the devcontainer).
allow_in_container="${WORKSPACE_ALLOW_IN_CONTAINER:-false}"
case "$allow_in_container" in
  true|false) ;;
  *)
    error "WORKSPACE_ALLOW_IN_CONTAINER must be true or false (got: ${allow_in_container})"
    exit 1
    ;;
esac
if is_container && ! $allow_in_container; then
  error "This tmux workspace is intended to run on the host machine, not inside a container."
  error "If you really want to run it in-container, set WORKSPACE_ALLOW_IN_CONTAINER=true and retry."
  exit 1
fi

# Load and validate project environment (required by repo policy).
ENV_LOADER="$PROJECT_DIR/.devcontainer/scripts/env-loader.sh"
if [ ! -f "$ENV_LOADER" ]; then
  error "Cannot find env-loader at $ENV_LOADER"
  exit 1
fi

# shellcheck disable=SC1090
. "$ENV_LOADER"
load_project_env "$PROJECT_DIR"

info "Validating environment variables..."
DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-${PROJECT_NAME}-editor}"
CONTAINER_HOSTNAME_EDITOR="${CONTAINER_HOSTNAME_EDITOR:-${DOCKER_IMAGE_NAME}}"
CONTAINER_HOSTNAME_DEVCONTAINER="${CONTAINER_HOSTNAME_DEVCONTAINER:-${PROJECT_NAME}-devcontainer}"
CONTAINER_HOSTNAME_CLAUDE="${CONTAINER_HOSTNAME_CLAUDE:-${PROJECT_NAME}-claude}"
CONTAINER_HOSTNAME="${CONTAINER_HOSTNAME_EDITOR}"
INSTALL_CLAUDE="${INSTALL_CLAUDE:-false}"
KEEP_CONTAINER_DEVCONTAINER="${KEEP_CONTAINER_DEVCONTAINER:-false}"
KEEP_CONTAINER_CLAUDE="${KEEP_CONTAINER_CLAUDE:-false}"
KEEP_CONTAINER_EDITOR="${KEEP_CONTAINER_EDITOR:-false}"
DEVCONTAINER_CONTEXT="${DEVCONTAINER_CONTEXT:-editor}"
export DOCKER_IMAGE_NAME CONTAINER_HOSTNAME CONTAINER_HOSTNAME_EDITOR CONTAINER_HOSTNAME_DEVCONTAINER CONTAINER_HOSTNAME_CLAUDE INSTALL_CLAUDE KEEP_CONTAINER_DEVCONTAINER KEEP_CONTAINER_CLAUDE KEEP_CONTAINER_EDITOR DEVCONTAINER_CONTEXT

VALIDATOR="$PROJECT_DIR/.devcontainer/scripts/validate-env.sh"
if [ -f "$VALIDATOR" ] && ! sh "$VALIDATOR" >/dev/null; then
  error "Environment validation failed. Please fix your .env values."
  exit 1
fi

SESSION="${WORKSPACE_TMUX_SESSION:-$PROJECT_NAME}"
if [ -z "$SESSION" ]; then
  error "WORKSPACE_TMUX_SESSION is not set and PROJECT_NAME is empty"
  exit 1
fi

require_cmd tmux

cd "$PROJECT_DIR"

tmux_has_session() {
  tmux has-session -t "$SESSION" 2>/dev/null
}

tmux_has_window() {
  window_name="$1"
  tmux list-windows -t "$SESSION" -F '#{window_name}' 2>/dev/null | grep -Fx "$window_name" >/dev/null 2>&1
}

ensure_window() {
  window_name="$1"
  window_dir="$2"
  window_cmd="${3:-}"

  if tmux_has_window "$window_name"; then
    return 0
  fi

  if [ -n "$window_dir" ]; then
    tmux new-window -t "$SESSION" -n "$window_name" -c "$window_dir"
  else
    tmux new-window -t "$SESSION" -n "$window_name"
  fi

  if [ -n "$window_cmd" ]; then
    tmux send-keys -t "$SESSION:$window_name" "$window_cmd" C-m
  fi
}

create_session() {
  tmux new-session -d -s "$SESSION" -c "$PROJECT_DIR" -n shell
}

ensure_workspace_layout() {
  if ! tmux_has_session; then
    create_session
  fi

  ensure_window "shell" "$PROJECT_DIR"
  ensure_window "devcontainer" "$PROJECT_DIR" "./devcontainer-launch.sh"
  ensure_window "editor" "$PROJECT_DIR" "./editor-launch.sh"
  ensure_window "claude" "$PROJECT_DIR" "./claude-launch.sh"

  tmux select-window -t "$SESSION:shell" >/dev/null 2>&1 || true
}

ensure_workspace_layout

if [ -n "${TMUX:-}" ]; then
  exec tmux switch-client -t "$SESSION"
fi

exec tmux attach -t "$SESSION"
