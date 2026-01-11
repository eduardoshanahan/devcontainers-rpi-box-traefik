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
if is_container && [ "${WORKSPACE_ALLOW_IN_CONTAINER:-0}" != "1" ] && [ "${WORKSPACE_ALLOW_IN_CONTAINER:-}" != "true" ]; then
  error "This tmux workspace is intended to run on the host machine, not inside a container."
  error "If you really want to run it in-container, set WORKSPACE_ALLOW_IN_CONTAINER=1 and retry."
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

VALIDATOR="$PROJECT_DIR/.devcontainer/scripts/validate-env.sh"
if [ -f "$VALIDATOR" ]; then
  info "Validating environment variables..."
  if ! sh "$VALIDATOR"; then
    error "Environment validation failed. Please fix your .env values."
    exit 1
  fi
fi

SESSION="${WORKSPACE_TMUX_SESSION:-${PROJECT_NAME:-}}"
if [ -z "$SESSION" ]; then
  error "WORKSPACE_TMUX_SESSION is not set and PROJECT_NAME is empty"
  exit 1
fi

REMOTE_HOST="${WORKSPACE_REMOTE_HOST:-}"

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

  if [ -n "$REMOTE_HOST" ]; then
    ensure_window "ssh-box" "" "ssh \"$REMOTE_HOST\" -t 'tmux attach -t infra || tmux new -s infra'"
  else
    ensure_window "ssh-box" "" "printf '%s\\n' \"Set WORKSPACE_REMOTE_HOST in .env to enable ssh-box.\"; exec sh"
  fi

  tmux select-window -t "$SESSION:shell" >/dev/null 2>&1 || true
}

ensure_workspace_layout

if [ -n "${TMUX:-}" ]; then
  exec tmux switch-client -t "$SESSION"
fi

exec tmux attach -t "$SESSION"
