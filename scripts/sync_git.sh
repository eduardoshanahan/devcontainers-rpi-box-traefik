#!/bin/sh

set -eu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { printf '%b\n' "${YELLOW}  $1${NC}"; }
success() { printf '%b\n' "${GREEN} $1${NC}"; }
error() { printf '%b\n' "${RED} $1${NC}" >&2; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

ENV_LOADER="$PROJECT_DIR/.devcontainer/scripts/env-loader.sh"
if [ ! -f "$ENV_LOADER" ]; then
    error "env-loader.sh not found at $ENV_LOADER"
    exit 1
fi
# shellcheck disable=SC1090
. "$ENV_LOADER"
load_project_env "$PROJECT_DIR"

require_env_set() {
    var_name="$1"
    eval "value=\${$var_name+x}"
    if [ -z "$value" ]; then
        error "Missing required environment variable: $var_name"
        exit 1
    fi
}

require_env_nonempty() {
    var_name="$1"
    eval "value=\${$var_name-}"
    if [ -z "$value" ]; then
        error "Missing required environment variable: $var_name"
        exit 1
    fi
}

normalize_list() {
    printf '%s\n' "$1" | tr ',' ' ' | tr -s ' ' '\n' | awk 'NF && !seen[$0]++'
}

REMOTE_LIST_FILE="$(mktemp)"
PUSH_TARGETS_FILE="$(mktemp)"

cleanup() {
    rm -f "$REMOTE_LIST_FILE" "$PUSH_TARGETS_FILE" 2>/dev/null || true
}
trap cleanup EXIT HUP INT TERM

require_env_nonempty "BRANCH"
require_env_nonempty "FORCE_PULL"
require_env_nonempty "GIT_REMOTE_URL"
require_env_nonempty "GIT_SYNC_REMOTES"
require_env_set "GIT_SYNC_PUSH_REMOTES"

eval "BRANCH=\${BRANCH}"
eval "FORCE_PULL=\${FORCE_PULL}"
eval "GIT_REMOTE_URL=\${GIT_REMOTE_URL}"
eval "GIT_SYNC_REMOTES=\${GIT_SYNC_REMOTES}"
eval "GIT_SYNC_PUSH_REMOTES=\${GIT_SYNC_PUSH_REMOTES-}"

normalize_list "$GIT_SYNC_REMOTES" > "$REMOTE_LIST_FILE"
if [ ! -s "$REMOTE_LIST_FILE" ]; then
    error "GIT_SYNC_REMOTES is empty after normalization"
    exit 1
fi

primary_remote="$(sed -n '1p' "$REMOTE_LIST_FILE")"
normalize_list "$GIT_SYNC_PUSH_REMOTES" > "$PUSH_TARGETS_FILE" || true

remote_env_key() {
    echo "$1" | tr '[:lower:]' '[:upper:]' | sed 's/[^A-Z0-9]/_/g'
}

remote_has_branch() {
    remote="$1"
    branch="$2"
    git ls-remote --heads "$remote" "$branch" | grep -q "$branch"
}

ensure_remote() {
    remote="$1"
    if git remote get-url "$remote" >/dev/null 2>&1; then
        return
    fi

    env_suffix="$(remote_env_key "$remote")"
    remote_url_var="GIT_REMOTE_URL_${env_suffix}"
    eval "remote_url_value=\${$remote_url_var-}"
    remote_url=""
    if [ -n "$remote_url_value" ]; then
        remote_url="$remote_url_value"
    fi

    if [ -z "$remote_url" ] && [ "$remote" = "$primary_remote" ]; then
        remote_url="$GIT_REMOTE_URL"
    fi

    if [ -z "$remote_url" ]; then
        error "Remote '$remote' is not configured. Set $remote_url_var (or GIT_REMOTE_URL for the primary remote) in .env."
        exit 1
    fi

    git remote add "$remote" "$remote_url"
    info "Added remote '$remote': $remote_url"
}

ensure_branch_checked_out() {
    branch="$1"
    if git rev-parse --verify --quiet "refs/heads/$branch" >/dev/null; then
        git checkout "$branch" >/dev/null 2>&1 || git checkout "$branch"
    else
        info "Creating local branch $branch"
        git checkout -b "$branch"
    fi
}

sync_remote() {
    remote="$1"
    branch="$2"
    mode="$3"

    if [ -z "$mode" ]; then
        error "sync_remote requires a mode (normal or force)"
        exit 1
    fi

    if [ "$mode" = "force" ]; then
        info "Force syncing from $remote/$branch"
        if remote_has_branch "$remote" "$branch"; then
            git fetch "$remote" "$branch"
            git reset --hard "$remote/$branch"
            git clean -fd
        else
            info "Remote $remote does not have $branch. Pushing current branch upstream."
            git push -u "$remote" "$branch"
        fi
    else
        if remote_has_branch "$remote" "$branch"; then
            info "Rebasing onto $remote/$branch"
            git pull --rebase "$remote" "$branch"
        else
            info "Remote $remote does not have $branch. Pushing current branch upstream."
            git push -u "$remote" "$branch"
        fi
    fi
}

ensure_upstream_tracking() {
    remote="$1"
    branch="$2"
    if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
        return
    fi
    if remote_has_branch "$remote" "$branch"; then
        info "Setting upstream of $branch to $remote/$branch"
        git branch --set-upstream-to="$remote/$branch" "$branch" >/dev/null 2>&1 || \
            git branch -u "$remote/$branch" "$branch"
    fi
}

main() {
    cd "$PROJECT_DIR" || { error "Project directory not found!"; exit 1; }
    info "Working in directory: $PROJECT_DIR"

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        error "This directory is not a git repository. Initialize it first."
        exit 1
    fi

    while IFS= read -r remote; do
        [ -z "$remote" ] && continue
        ensure_remote "$remote"
    done < "$REMOTE_LIST_FILE"

    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || printf '')
    if [ "$current_branch" = "HEAD" ] || [ -z "$current_branch" ]; then
        current_branch="main"
    fi
    target_branch="$BRANCH"

    if [ "$FORCE_PULL" != "true" ] && ! git diff --quiet --ignore-submodules HEAD --; then
        error "Local changes detected. Commit/stash them or run FORCE_PULL=true ./scripts/sync_git.sh"
        exit 1
    fi

    ensure_branch_checked_out "$target_branch"
    info "Syncing branch $target_branch"

    while IFS= read -r remote; do
        [ -z "$remote" ] && continue
        if [ "$remote" = "$primary_remote" ] && [ "$FORCE_PULL" = "true" ]; then
            sync_remote "$remote" "$target_branch" "force"
        else
            sync_remote "$remote" "$target_branch" "normal"
        fi
    done < "$REMOTE_LIST_FILE"

    ensure_upstream_tracking "$primary_remote" "$target_branch"

    if [ -s "$PUSH_TARGETS_FILE" ]; then
        while IFS= read -r remote; do
            [ -z "$remote" ] && continue
            ensure_remote "$remote"
            info "Pushing $target_branch to $remote"
            if remote_has_branch "$remote" "$target_branch"; then
                git push "$remote" "$target_branch"
            else
                git push -u "$remote" "$target_branch"
            fi
        done < "$PUSH_TARGETS_FILE"
    fi

    success "Git sync complete!"
}

main "$@"
