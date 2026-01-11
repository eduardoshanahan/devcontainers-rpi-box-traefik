#!/bin/sh

set -eu

if [ -z "${WORKSPACE_FOLDER:-}" ]; then
    printf '%s\n' "Error: WORKSPACE_FOLDER is not set." >&2
    printf '%s\n' "This devcontainer is supported only when started via ./devcontainer-launch.sh or ./editor-launch.sh." >&2
    exit 1
fi

workspace_dir="$WORKSPACE_FOLDER"

# Validate environment (including SSH agent forwarding).
VALIDATOR="${workspace_dir}/.devcontainer/scripts/validate-env.sh"
if [ -f "$VALIDATOR" ]; then
    printf '%s\n' "Validating environment variables..."
    if ! sh "$VALIDATOR"; then
        printf '%s\n' "Error: Environment validation failed." >&2
        printf '%s\n' "Hint: start the devcontainer via ./devcontainer-launch.sh or ./editor-launch.sh." >&2
        exit 1
    fi
else
    printf '%s\n' "Error: validate-env.sh not found at $VALIDATOR" >&2
    exit 1
fi

# Ensure VS Code shell integration variables are set early to avoid nounset errors.
ensure_bashrc_guard() {
    bashrc_file="${HOME}/.bashrc"
    guard_start="# >>> devcontainer guard >>>"

    if [ ! -f "$bashrc_file" ]; then
        : > "$bashrc_file"
    fi

    if grep -qF "$guard_start" "$bashrc_file"; then
        return 0
    fi

    make_temp_file() {
        tmp_dir="${TMPDIR:-/tmp}"
        umask 077
        i=0
        while :; do
            i=$((i + 1))
            path="${tmp_dir}/post-create.$$.$i"
            if (set -C; : > "$path") 2>/dev/null; then
                printf '%s' "$path"
                return 0
            fi
            [ "$i" -ge 100 ] && return 1
        done
    }

    tmp_file="$(make_temp_file)"
    if [ -z "$tmp_file" ]; then
        printf '%s\n' "Warning: failed to create temp file for .bashrc guard; skipping" >&2
        return 0
    fi

    {
        cat <<'EOF'
# >>> devcontainer guard >>>
# Avoid nounset errors from VS Code shell integration.
export VSCODE_SHELL_LOGIN="${VSCODE_SHELL_LOGIN:-}"
# <<< devcontainer guard <<<
EOF
        cat "$bashrc_file"
    } > "$tmp_file"

    mv "$tmp_file" "$bashrc_file"
}

ensure_bashrc_guard

# Configure Git if variables are set
if [ -n "${GIT_USER_NAME-}" ] && [ -n "${GIT_USER_EMAIL-}" ]; then
    REPO_DIR="$workspace_dir"
    if [ -d "$REPO_DIR/.git" ]; then
        printf '%s\n' "Configuring repo-local Git identity:"
        printf '%s\n' "  Name:  $GIT_USER_NAME"
        printf '%s\n' "  Email: $GIT_USER_EMAIL"
        git -C "$REPO_DIR" config user.name "$GIT_USER_NAME"
        git -C "$REPO_DIR" config user.email "$GIT_USER_EMAIL"
    else
        printf '%s\n' "Warning: No git repository found in $REPO_DIR. Skipping git identity setup."
    fi
else
    printf '%s\n' "Warning: GIT_USER_NAME or GIT_USER_EMAIL not set. Git identity not configured."
fi

# Add workspace to Git safe directories
printf '%s\n' "Configuring Git safe directories..."
git config --global --add safe.directory "$workspace_dir"
if [ -n "${USERNAME:-}" ]; then
    git config --global --add safe.directory "/home/${USERNAME}/.devcontainer"
fi

# Make scripts executable
chmod +x "${workspace_dir}/.devcontainer/scripts/bash-prompt.sh"
chmod +x "${workspace_dir}/.devcontainer/scripts/ssh-agent-setup.sh"

# Bootstrap Ansible workspace (collections/roles + Galaxy requirements)
ANSIBLE_ROOT="${workspace_dir}/src"
ANSIBLE_REQUIREMENTS_FILE="${ANSIBLE_ROOT}/requirements.yml"

retry_galaxy_install() {
    retry_desc="$1"
    shift
    max_attempts=3
    attempt=1
    while ! "$@"; do
        if [ "$attempt" -ge "$max_attempts" ]; then
            printf '%s\n' "Warning: ${retry_desc} failed after ${max_attempts} attempts." >&2
            return 1
        fi
        printf '%s\n' "Retrying ${retry_desc} (attempt $((attempt + 1))/${max_attempts})..."
        attempt=$((attempt + 1))
        sleep 2
    done
}

if [ -d "$ANSIBLE_ROOT" ]; then
    mkdir -p "${ANSIBLE_ROOT}/collections" "${ANSIBLE_ROOT}/roles"
    if command -v ansible-galaxy >/dev/null 2>&1 && [ -f "$ANSIBLE_REQUIREMENTS_FILE" ]; then
        printf '%s\n' "Installing Ansible dependencies from ${ANSIBLE_REQUIREMENTS_FILE}..."
        retry_galaxy_install "ansible-galaxy collection install" ansible-galaxy collection install -r "$ANSIBLE_REQUIREMENTS_FILE" --force || true
        retry_galaxy_install "ansible-galaxy role install" ansible-galaxy role install -r "$ANSIBLE_REQUIREMENTS_FILE" --force || true
    else
        printf '%s\n' "No Ansible requirements file found at ${ANSIBLE_REQUIREMENTS_FILE}; skipping Galaxy install."
    fi
else
    printf '%s\n' "Ansible src directory (${ANSIBLE_ROOT}) missing; skipping Ansible bootstrap."
fi

# Ensure helper fixer is executable and run it to set permissions for helper scripts
if [ -f "${workspace_dir}/.devcontainer/scripts/fix-permissions.sh" ]; then
    chmod +x "${workspace_dir}/.devcontainer/scripts/fix-permissions.sh" 2>/dev/null || true
    # Run fixer (non-fatal)
    "${workspace_dir}/.devcontainer/scripts/fix-permissions.sh" "${workspace_dir}/.devcontainer/scripts" || true
fi

# Source scripts in bashrc if not already present
if ! grep -qF "${workspace_dir}/.devcontainer/scripts/bash-prompt.sh" "$HOME/.bashrc"; then
    printf '%s\n' ". ${workspace_dir}/.devcontainer/scripts/bash-prompt.sh" >> "$HOME/.bashrc"
fi

if ! grep -qF "${workspace_dir}/.devcontainer/scripts/ssh-agent-setup.sh" "$HOME/.bashrc"; then
    printf '%s\n' ". ${workspace_dir}/.devcontainer/scripts/ssh-agent-setup.sh" >> "$HOME/.bashrc"
fi

# Ensure login shells also inherit the alias setup by sourcing .bashrc
ensure_profile_sources_bashrc() {
    profile_file="$1"
    [ -f "$profile_file" ] || touch "$profile_file"
    if ! grep -qE "(^|[[:space:]])(\.|source)[[:space:]]+~/.bashrc" "$profile_file"; then
        cat <<'EOF' >> "$profile_file"
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
EOF
    fi
}

ensure_profile_sources_bashrc "$HOME/.bash_profile"
ensure_profile_sources_bashrc "$HOME/.profile"
