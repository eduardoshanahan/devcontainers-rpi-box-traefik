#!/bin/sh

# Ensure nounset doesn't break VS Code shell integration in interactive shells.
set +u

if [ -z "${WORKSPACE_FOLDER:-}" ]; then
    printf '%s\n' "Warning: WORKSPACE_FOLDER is not set; devcontainer prompt setup is disabled." >&2
    printf '%s\n' "Hint: start the devcontainer via ./devcontainer-launch.sh or ./editor-launch.sh." >&2
    return 0
fi

workspace_dir="$WORKSPACE_FOLDER"

# Enable Starship prompt first
if command -v starship >/dev/null 2>&1; then
    if [ -f "${workspace_dir}/.devcontainer/config/starship.toml" ]; then
        export STARSHIP_CONFIG="${workspace_dir}/.devcontainer/config/starship.toml"
        mkdir -p "$HOME/.config"
        cp "$STARSHIP_CONFIG" "$HOME/.config/starship.toml"
    fi
    eval "$(starship init bash)"
fi

if [ -f /etc/container.env ]; then
    . /etc/container.env
fi

# Validate environment early (don't kill interactive shells).
validator="${workspace_dir}/.devcontainer/scripts/validate-env.sh"
if [ -f "$validator" ]; then
    sh "$validator" >/dev/null 2>&1 || {
        printf '%s\n' "Warning: environment validation failed; see output from: ${validator}" >&2
    }
fi

# Source SSH agent setup
if [ -f "$HOME/.devcontainer/scripts/ssh-agent-setup.sh" ]; then
    . "$HOME/.devcontainer/scripts/ssh-agent-setup.sh"
fi

# Source color definitions
if [ -f "$HOME/.devcontainer/scripts/colors.sh" ]; then
    . "$HOME/.devcontainer/scripts/colors.sh"
else
    printf '%s\n' "Warning: colors.sh not found, using default colors"
fi

# Only set up prompt in interactive shells
case $- in
    *i*) ;;
    *) return ;;
esac

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'

# JSON linting aliases
alias jsonlint='jq "."'
alias jsonformat='jq "."'
alias jsonvalidate='jq empty'
alias jsonpretty='jq "."'

# Export SHELL variable to ensure bash is used
export SHELL=/bin/bash
