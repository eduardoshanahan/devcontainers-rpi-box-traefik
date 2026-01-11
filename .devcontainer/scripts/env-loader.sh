#!/bin/sh
# Shared env loader: load project-root .env (authoritative)
# Usage:
#   # from inside container: . /workspace/.devcontainer/scripts/env-loader.sh && load_project_env /workspace [debug]
#   # from host script: . "$PROJECT_DIR/.devcontainer/scripts/env-loader.sh" && load_project_env "$PROJECT_DIR" [debug]
#
# Debug mode:
#   - Set ENV_LOADER_DEBUG=true (exported) or pass second param as true to load_project_env to print newly loaded var names.
#   - Set ENV_LOADER_DEBUG_VALUES=true (exported) or pass third param as true to print var values too (may expose secrets).

load_project_env() {
    workspace_dir="${1:-${WORKSPACE_FOLDER:-}}"
    debug="${2:-${ENV_LOADER_DEBUG:-false}}"
    debug_values="${3:-${ENV_LOADER_DEBUG_VALUES:-false}}"

    if [ -z "$workspace_dir" ]; then
        printf 'env-loader: workspace directory not provided; pass as arg or set WORKSPACE_FOLDER\n' >&2
        return 1
    fi

    project_env="$workspace_dir/.env"
    if [ ! -f "$project_env" ]; then
        printf 'env-loader: required .env not found at %s\n' "$project_env" >&2
        return 1
    fi

    # Preserve a valid SSH_AUTH_SOCK from the caller (e.g., /ssh-agent in container).
    original_ssh_auth_sock="${SSH_AUTH_SOCK:-}"
    original_ssh_auth_sock_valid=false
    if [ -n "$original_ssh_auth_sock" ] && [ -S "$original_ssh_auth_sock" ]; then
        original_ssh_auth_sock_valid=true
    fi

    make_temp_file() {
        tmp_dir="${TMPDIR:-/tmp}"
        umask 077
        i=0
        while :; do
            i=$((i + 1))
            path="${tmp_dir}/env-loader.$$.$i"
            if (set -C; : > "$path") 2>/dev/null; then
                printf '%s' "$path"
                return 0
            fi
            [ "$i" -ge 100 ] && return 1
        done
    }

    # Capture current variable names (not values) to avoid marking updates as "new".
    before_file="$(make_temp_file)"
    if [ -z "$before_file" ]; then
        printf 'env-loader: failed to create temp file for env snapshot\n' >&2
        return 1
    fi
    env | cut -d= -f1 | sort > "$before_file"

    # Load project root .env first (authoritative); preserve quoting
    set -a
    # shellcheck disable=SC1090
    . "$project_env"
    set +a

    # Avoid overwriting a valid forwarded SSH agent socket with a host path from `.env`.
    if [ "$original_ssh_auth_sock_valid" = true ]; then
        export SSH_AUTH_SOCK="$original_ssh_auth_sock"
    fi

    # Capture after state and compute newly added variables
    after_file="$(make_temp_file)"
    if [ -z "$after_file" ]; then
        rm -f "$before_file" 2>/dev/null || true
        printf 'env-loader: failed to create temp file for env snapshot\n' >&2
        return 1
    fi
    env | cut -d= -f1 | sort > "$after_file"

    case "$debug" in
        true|false) ;;
        *)
            printf 'env-loader: ENV_LOADER_DEBUG must be true or false (got: %s)\n' "$debug" >&2
            rm -f "$before_file" "$after_file" 2>/dev/null || true
            return 1
            ;;
    esac
    case "$debug_values" in
        true|false) ;;
        *)
            printf 'env-loader: ENV_LOADER_DEBUG_VALUES must be true or false (got: %s)\n' "$debug_values" >&2
            rm -f "$before_file" "$after_file" 2>/dev/null || true
            return 1
            ;;
    esac

    if $debug; then
        printf 'env-loader: debug enabled - listing variables added by load_project_env (workspace: %s)\n' "$workspace_dir"
        if command -v comm >/dev/null 2>&1; then
            comm -13 "$before_file" "$after_file" | while IFS= read -r var; do
                [ -z "$var" ] && continue
                if $debug_values; then
                    eval "var_value=\${$var-}"
                    printf '%s=%s\n' "$var" "$var_value"
                else
                    printf '%s\n' "$var"
                fi
            done
        else
            printf 'env-loader: comm not available; showing all variables (best-effort)\n' >&2
            cat "$after_file"
        fi
    fi

    # Clean up
    rm -f "$before_file" "$after_file" 2>/dev/null || true
}
