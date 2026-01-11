#!/bin/sh
set -eu

# This repo expects the devcontainer to be started via the launchers.
# When started correctly, required env vars (including WORKSPACE_FOLDER) are already set.
if [ -z "${WORKSPACE_FOLDER:-}" ]; then
    printf '%s\n' "Error: WORKSPACE_FOLDER is not set." >&2
    printf '%s\n' "This devcontainer is supported only when started via ./devcontainer-launch.sh or ./editor-launch.sh." >&2
    exit 1
fi

workspace_dir="$WORKSPACE_FOLDER"

# Prefer workspace colors, then HOME; fallback to minimal colors
if [ -f "${workspace_dir}/.devcontainer/scripts/colors.sh" ]; then
    # shellcheck disable=SC1090
    . "${workspace_dir}/.devcontainer/scripts/colors.sh"
elif [ -f "$HOME/.devcontainer/scripts/colors.sh" ]; then
    # shellcheck disable=SC1090
    . "$HOME/.devcontainer/scripts/colors.sh"
else
    COLOR_RESET='\033[0m'
    COLOR_BOLD='\033[1m'
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
fi

# Validate environment early (fail fast).
VALIDATOR="${workspace_dir}/.devcontainer/scripts/validate-env.sh"
if [ -f "$VALIDATOR" ]; then
    if ! sh "$VALIDATOR"; then
        printf '%b\n' "${RED}Error:${COLOR_RESET} environment validation failed." >&2
        printf '%b\n' "${YELLOW}Hint:${COLOR_RESET} start the devcontainer via ./devcontainer-launch.sh or ./editor-launch.sh." >&2
        exit 1
    fi
fi

# Configure Git if variables are set
if [ -n "${GIT_USER_NAME:-}" ] && [ -n "${GIT_USER_EMAIL:-}" ]; then
    REPO_DIR="$workspace_dir"
    if [ -d "$REPO_DIR/.git" ]; then
        printf '%b\n' "${GREEN}Configuring Git (repo-local) with:${COLOR_RESET}"
        printf '%b\n' "  ${COLOR_BOLD}Name:${COLOR_RESET}  $GIT_USER_NAME"
        printf '%b\n' "  ${COLOR_BOLD}Email:${COLOR_RESET} $GIT_USER_EMAIL"
        git -C "$REPO_DIR" config user.name "$GIT_USER_NAME"
        git -C "$REPO_DIR" config user.email "$GIT_USER_EMAIL"
    else
        printf '%b\n' "${YELLOW}Warning:${COLOR_RESET} No git repository found in $REPO_DIR. Skipping git identity setup."
    fi
fi

# Make scripts executable (existing entries)
chmod +x "${workspace_dir}/.devcontainer/scripts/bash-prompt.sh" 2>/dev/null || true
chmod +x "${workspace_dir}/.devcontainer/scripts/ssh-agent-setup.sh" 2>/dev/null || true

# Ensure helper scripts are executable
chmod +x "${workspace_dir}/.devcontainer/scripts/verify-git-ssh.sh" 2>/dev/null || true
chmod +x "${workspace_dir}/.devcontainer/scripts/env-loader.sh" 2>/dev/null || true
chmod +x "${workspace_dir}/.devcontainer/scripts/fix-permissions.sh" 2>/dev/null || true

# Ensure bashrc sources helper scripts (avoid duplicates)
if ! grep -qF "${workspace_dir}/.devcontainer/scripts/bash-prompt.sh" "$HOME/.bashrc" 2>/dev/null; then
    printf '%s\n' ". ${workspace_dir}/.devcontainer/scripts/bash-prompt.sh" >> "$HOME/.bashrc"
fi

if ! grep -qF "${workspace_dir}/.devcontainer/scripts/ssh-agent-setup.sh" "$HOME/.bashrc" 2>/dev/null; then
    printf '%s\n' ". ${workspace_dir}/.devcontainer/scripts/ssh-agent-setup.sh" >> "$HOME/.bashrc"
fi

printf '%b\n' "${GREEN}Initialization complete.${COLOR_RESET}"
