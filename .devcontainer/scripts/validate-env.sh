#!/bin/sh
set -eu

get_env_value() {
    var_name="$1"
    eval "printf '%s' \"\${$var_name-}\""
}

validate_var() {
    var_name="$1"
    var_value="$2"
    pattern="$3"
    description="$4"

    if ! printf '%s' "$var_value" | grep -Eq "$pattern"; then
        printf '%s\n' "Error: $var_name is invalid"
        printf '%s\n' "Description: $description"
        printf '%s\n' "Pattern: $pattern"
        printf '%s\n' "Current value: $var_value"
        return 1
    fi
    return 0
}

errors=0
printf '%s\n' "Validating required variables..."

while IFS='|' read -r var description pattern; do
    [ -z "$var" ] && continue
    value="$(get_env_value "$var")"
    if [ -z "$value" ]; then
        printf '%s\n' "Error: Required variable $var is not set"
        printf '%s\n' "Description: $description"
        errors=$((errors + 1))
        continue
    fi
    if ! validate_var "$var" "$value" "$pattern" "$description"; then
        errors=$((errors + 1))
    fi
done <<'EOF'
PROJECT_NAME|Project name|^[a-z0-9][a-z0-9-]*$
HOST_USERNAME|System username|^[a-z_][a-z0-9_-]*$
HOST_UID|User ID|^[0-9]+$
HOST_GID|Group ID|^[0-9]+$
GIT_USER_NAME|Git author name|^[a-zA-Z0-9 ._-]+$
GIT_USER_EMAIL|Git author email|^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
GIT_REMOTE_URL|Git remote URL|^(https://|git@).+
EDITOR_CHOICE|Editor selection|^(code|cursor|antigravity)$
CONTAINER_HOSTNAME|Container hostname|^[a-zA-Z][a-zA-Z0-9-]*$
CONTAINER_HOSTNAME_EDITOR|Editor container hostname|^[a-zA-Z][a-zA-Z0-9-]*$
CONTAINER_HOSTNAME_DEVCONTAINER|CLI container hostname|^[a-zA-Z][a-zA-Z0-9-]*$
CONTAINER_HOSTNAME_CLAUDE|Claude container hostname|^[a-zA-Z][a-zA-Z0-9-]*$
DEVCONTAINER_CONTEXT|Prompt context label|^[a-zA-Z0-9][a-zA-Z0-9-]*$
CONTAINER_MEMORY|Container memory limit|^[0-9]+[gGmM]$
CONTAINER_CPUS|Container CPU count|^[0-9]+(\.[0-9]+)?$
CONTAINER_SHM_SIZE|Container shared memory size|^[0-9]+[gGmM]$
DOCKER_IMAGE_NAME|Docker image name|^[a-z0-9][a-z0-9._-]+$
DOCKER_IMAGE_TAG|Docker image tag|^[a-zA-Z0-9][a-zA-Z0-9._-]+$
WORKSPACE_FOLDER|Workspace folder inside the container|^/[^[:space:]]*$
LOCALE|System locale for the devcontainer (example: en_IE.UTF-8)|^[A-Za-z]{2}_[A-Za-z]{2}\.UTF-8$
PYTHON_VERSION|Python version pin used by tooling|^[0-9]+(\.[0-9]+)*$
ANSIBLE_CONFIG|Ansible config path|^.+$
ANSIBLE_INVENTORY|Ansible inventory path|^.+$
ANSIBLE_COLLECTIONS_PATH|Ansible collections path|^.+$
ANSIBLE_ROLES_PATH|Ansible roles path|^.+$
ANSIBLE_CORE_VERSION|ansible-core version pin for devcontainer build|^[0-9]+(\.[0-9]+)*(\.\*)?$
ANSIBLE_LINT_VERSION|ansible-lint version pin for devcontainer build|^[0-9]+(\.[0-9]+)*(\.\*)?$
YAMLLINT_VERSION|yamllint version pin for devcontainer build|^[0-9]+(\.[0-9]+)*(\.\*)?$
INSTALL_CLAUDE|Install Claude CLI during devcontainer build|^(true|false)$
KEEP_CONTAINER_DEVCONTAINER|Keep devcontainer CLI container after exit|^(true|false)$
KEEP_CONTAINER_CLAUDE|Keep Claude container after exit|^(true|false)$
KEEP_CONTAINER_EDITOR|Keep editor-started container after exit|^(true|false)$
ANSIBLE_USER|Ansible SSH user|^[a-z_][a-z0-9_-]*$
ANSIBLE_SSH_PRIVATE_KEY_FILE|Ansible SSH private key file|^.+$
EOF

printf '\nValidating optional variables...\n'
while IFS='|' read -r var description pattern; do
    [ -z "$var" ] && continue
    value="$(get_env_value "$var")"
    if [ -n "$value" ]; then
        if ! validate_var "$var" "$value" "$pattern" "$description"; then
            errors=$((errors + 1))
        fi
    fi
done <<'EOF'
CLAUDE_INSTALL_SHA256|Claude Code installer checksum|^[A-Fa-f0-9]{64}$
WORKSPACE_ALLOW_IN_CONTAINER|Allow workspace.sh inside container (not recommended)|^(true|false)$
WORKSPACE_TMUX_SESSION|tmux session name for workspace.sh|^[^[:space:]]+$
WORKSPACE_REMOTE_HOST|Optional SSH host for workspace.sh|^.*$
SMOKE_GROUP|Default Ansible host group for ansible-smoke.sh|^[a-zA-Z0-9_-]+$
DEVCONTAINER_IMAGE_RETENTION_DAYS|Retention days for clean-devcontainer-images.sh|^[0-9]+$
FORCE_REBUILD|Force devcontainer image rebuild in launchers|^(true|false)$
EOF

printf '\nValidating SSH agent forwarding...\n'
if [ -z "${SSH_AUTH_SOCK:-}" ]; then
    printf '%s\n' "Error: SSH_AUTH_SOCK is not set. Start an SSH agent and export SSH_AUTH_SOCK before running the launcher."
    errors=$((errors + 1))
elif [ ! -S "${SSH_AUTH_SOCK}" ]; then
    printf '%s\n' "Error: SSH_AUTH_SOCK is set but is not a valid socket: ${SSH_AUTH_SOCK}"
    errors=$((errors + 1))
fi

if [ "$errors" -gt 0 ]; then
    printf '\nFound %s error(s). Please fix them and try again.\n' "$errors"
    exit 1
else
    printf '\nAll environment variables are valid!\n'
fi
