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
HOST_USERNAME|System username|^[a-z_][a-z0-9_-]*$
HOST_UID|User ID|^[0-9]+$
HOST_GID|Group ID|^[0-9]+$
GIT_USER_NAME|Git author name|^[a-zA-Z0-9 ._-]+$
GIT_USER_EMAIL|Git author email|^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
GIT_REMOTE_URL|Git remote URL|^(https://|git@).+
EDITOR_CHOICE|Editor selection|^(code|cursor|antigravity)$
CONTAINER_HOSTNAME|Container hostname|^[a-zA-Z][a-zA-Z0-9-]*$
CONTAINER_MEMORY|Container memory limit|^[0-9]+[gGmM]$
CONTAINER_CPUS|Container CPU count|^[0-9]+(\.[0-9]+)?$
CONTAINER_SHM_SIZE|Container shared memory size|^[0-9]+[gGmM]$
DOCKER_IMAGE_NAME|Docker image name|^[a-z0-9][a-z0-9._-]+$
DOCKER_IMAGE_TAG|Docker image tag|^[a-zA-Z0-9][a-zA-Z0-9._-]+$
ANSIBLE_USER|Ansible SSH user|^[a-z_][a-z0-9_-]*$
ANSIBLE_SSH_PRIVATE_KEY_FILE|Ansible SSH private key file|^.+$
EOF

if [ "$errors" -gt 0 ]; then
    printf '\nFound %s error(s). Please fix them and try again.\n' "$errors"
    exit 1
else
    printf '\nAll environment variables are valid!\n'
fi
