#!/bin/sh

set -e

# Load environment variables via shared loader (project root .env is authoritative)
if [ -f "/workspace/.devcontainer/scripts/env-loader.sh" ]; then
    # shellcheck disable=SC1090
    . "/workspace/.devcontainer/scripts/env-loader.sh"
    load_project_env "/workspace"
elif [ -f "$HOME/.devcontainer/scripts/env-loader.sh" ]; then
    # shellcheck disable=SC1090
    . "$HOME/.devcontainer/scripts/env-loader.sh"
    load_project_env "/workspace"
else
    printf '%s\n' "Warning: env-loader.sh not found; skipping environment load"
fi

# Configure Git if variables are set
if [ -n "${GIT_USER_NAME-}" ] && [ -n "${GIT_USER_EMAIL-}" ]; then
    REPO_DIR="/workspace"
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
git config --global --add safe.directory /workspace
git config --global --add safe.directory "/home/${USERNAME:-}/.devcontainer"

# Make scripts executable
chmod +x /workspace/.devcontainer/scripts/bash-prompt.sh
chmod +x /workspace/.devcontainer/scripts/ssh-agent-setup.sh

# Bootstrap Ansible workspace (collections/roles + Galaxy requirements)
ANSIBLE_ROOT="/workspace/src"
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
if [ -f "/workspace/.devcontainer/scripts/fix-permissions.sh" ]; then
    chmod +x "/workspace/.devcontainer/scripts/fix-permissions.sh" 2>/dev/null || true
    # Run fixer (non-fatal)
    "/workspace/.devcontainer/scripts/fix-permissions.sh" "/workspace/.devcontainer/scripts" || true
fi

# Source scripts in bashrc if not already present
if ! grep -qE "(^|[[:space:]])(\.|source)[[:space:]]+/workspace/.devcontainer/scripts/bash-prompt.sh" "$HOME/.bashrc"; then
    printf '%s\n' ". /workspace/.devcontainer/scripts/bash-prompt.sh" >> "$HOME/.bashrc"
fi

if ! grep -qE "(^|[[:space:]])(\.|source)[[:space:]]+/workspace/.devcontainer/scripts/ssh-agent-setup.sh" "$HOME/.bashrc"; then
    printf '%s\n' ". /workspace/.devcontainer/scripts/ssh-agent-setup.sh" >> "$HOME/.bashrc"
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
