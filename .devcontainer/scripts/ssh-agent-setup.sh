#!/bin/sh
# --- SSH Agent Setup ---

# Avoid running multiple times in the same shell.
if ${SSH_AGENT_SETUP_DONE:-false}; then
  return 0 2>/dev/null || exit 0
fi
export SSH_AGENT_SETUP_DONE=true

# Function to check file permissions
check_file_permissions() {
  file="$1"
  expected_perms="$2"
  actual_perms="$(stat -c %a "$file")"

  if [ "$actual_perms" != "$expected_perms" ]; then
    echo "Warning: $file has incorrect permissions ($actual_perms). Expected: $expected_perms"
    return 1
  fi
  return 0
}

# Exit on error and undefined vars.
# Preserve shell opts because this script is sourced from interactive shells.
_SSH_AGENT_OLD_OPTS="$(set +o)"
set -eu
IFS='
	'

# Check for an interactive shell.
case $- in
*i*)
  # Create .ssh directory with proper permissions if it doesn't exist
  if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
  else
    check_file_permissions "$HOME/.ssh" "700" || chmod 700 "$HOME/.ssh"
  fi

  # If SSH_AUTH_SOCK points to a forwarded agent, trust it; otherwise try to reuse a saved agent.
  if [ -n "${SSH_AUTH_SOCK:-}" ] && [ -S "${SSH_AUTH_SOCK}" ]; then
    echo "Using forwarded SSH agent at ${SSH_AUTH_SOCK}"
  else
    reused_agent=false
    if [ -f "$HOME/.ssh/agent_env" ]; then
      # shellcheck disable=SC1090
      . "$HOME/.ssh/agent_env"
      if [ -n "${SSH_AUTH_SOCK:-}" ] && [ -S "${SSH_AUTH_SOCK}" ]; then
        if [ -z "${SSH_AGENT_PID:-}" ] || ps -p "${SSH_AGENT_PID}" >/dev/null 2>&1; then
          echo "Reusing existing SSH agent at ${SSH_AUTH_SOCK}"
          reused_agent=true
        else
          unset SSH_AUTH_SOCK SSH_AGENT_PID
        fi
      fi
    fi

    if [ "$reused_agent" = false ]; then
      echo "No forwarded SSH agent detected. Starting a new agent..."
      eval "$(ssh-agent -s)" >/dev/null
      export SSH_AUTH_SOCK SSH_AGENT_PID
    fi
  fi

  # Save the agent variables with proper permissions
  umask 077
  {
    echo "export SSH_AUTH_SOCK=${SSH_AUTH_SOCK}"
    echo "export SSH_AGENT_PID=${SSH_AGENT_PID:-}"
  } >"$HOME/.ssh/agent_env"

  if [ -z "${SSH_AGENT_PID:-}" ]; then
    echo "Warning: SSH_AGENT_PID is not set (using forwarded agent)."
  fi

  # Only add private keys when we're running our own agent to avoid duplicating host-managed keys
  if [ -n "${SSH_AGENT_PID:-}" ]; then
    echo "Looking for SSH keys in $HOME/.ssh/"
    for key in "$HOME/.ssh/"*; do
      if [ -f "$key" ]; then
        case "$key" in
          *.pub|*known_hosts*|*agent_env) continue ;;
        esac
        echo "Attempting to add private key: $key"
        if check_file_permissions "$key" "600"; then
          if ssh-add "$key" 2>/dev/null; then
            echo "Successfully added key: $key"
          else
            echo "Failed to add key: $key"
          fi
        else
          echo "Warning: $key has incorrect permissions. Skipping."
        fi
      fi
    done
  else
    echo "Skipping ssh-add because we are using the forwarded agent."
  fi

  # Show all loaded keys
  echo "Currently loaded keys:"
  ssh-add -l || echo "ssh-add failed (no identities or agent not available)."
  ;;
esac

set +e
# Restore caller shell options (notably disables nounset for the caller).
eval "$_SSH_AGENT_OLD_OPTS"

# --- End SSH Agent Setup ---
