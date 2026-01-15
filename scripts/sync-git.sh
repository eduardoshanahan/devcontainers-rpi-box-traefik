#!/bin/sh

# Enable strict mode
set -eu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print functions
info() { printf '%b\n' "${YELLOW}  $1${NC}"; }
success() { printf '%b\n' "${GREEN} $1${NC}"; }
error() { printf '%b\n' "${RED} $1${NC}" >&2; }

# Get the actual project directory (parent of scripts directory)
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment variables using the shared loader (project root .env is authoritative)
ENV_LOADER="$PROJECT_DIR/.devcontainer/scripts/env-loader.sh"
if [ ! -f "$ENV_LOADER" ]; then
    error "env-loader.sh not found at $ENV_LOADER"
    exit 1
fi
# shellcheck disable=SC1090
. "$ENV_LOADER"
load_project_env "$PROJECT_DIR"

BRANCH="${BRANCH:-}"
FORCE_PULL="${FORCE_PULL:-false}"
GIT_REMOTE_URL="${GIT_REMOTE_URL:-}"
GIT_SYNC_REMOTES="${GIT_SYNC_REMOTES:-}"
GIT_SYNC_PUSH_REMOTES="${GIT_SYNC_PUSH_REMOTES:-}"

case "$FORCE_PULL" in
    true|false) ;;
    *)
        error "FORCE_PULL must be true or false (got: ${FORCE_PULL})"
        exit 1
        ;;
esac

normalize_list() {
    # Normalize a comma/space-separated list to unique tokens, one per line.
    # Empty input => empty output.
    raw="$1"
    if [ -z "$raw" ]; then
        return 0
    fi
    printf '%s\n' "$raw" | tr ',' ' ' | tr -s ' ' '\n' | awk 'NF && !seen[$0]++'
}

remote_list="$(normalize_list "$GIT_SYNC_REMOTES" || true)"
if [ -z "$remote_list" ]; then
    error "GIT_SYNC_REMOTES is required. Set it in .env (space or comma separated)."
    exit 1
fi
set -- $remote_list
primary_remote="$1"

push_targets="$(normalize_list "$GIT_SYNC_PUSH_REMOTES" || true)"

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
    remote_url=""
    eval "remote_url=\${$remote_url_var:-}"

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
    mode="${3:-normal}"

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

    for remote in $remote_list; do
        ensure_remote "$remote"
    done

    current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || printf '')"
    if [ "$current_branch" = "HEAD" ] || [ -z "$current_branch" ]; then
        current_branch="main"
    fi
    target_branch="${BRANCH:-$current_branch}"

    if [ "$FORCE_PULL" != "true" ] && [ -n "$(git status --porcelain)" ]; then
        error "Local changes detected. Commit/stash them or run FORCE_PULL=true ./scripts/sync-git.sh"
        exit 1
    fi

    ensure_branch_checked_out "$target_branch"
    info "Syncing branch $target_branch"

    for remote in $remote_list; do
        if [ "$remote" = "$primary_remote" ] && [ "$FORCE_PULL" = "true" ]; then
            sync_remote "$remote" "$target_branch" "force"
        else
            sync_remote "$remote" "$target_branch" "normal"
        fi
    done

    ensure_upstream_tracking "$primary_remote" "$target_branch"

    if [ -n "$push_targets" ]; then
        for remote in $push_targets; do
            ensure_remote "$remote"
            info "Pushing $target_branch to $remote"
            if remote_has_branch "$remote" "$target_branch"; then
                git push "$remote" "$target_branch"
            else
                git push -u "$remote" "$target_branch"
            fi
        done
    fi

    success "Git sync complete!"
}

main "$@"

