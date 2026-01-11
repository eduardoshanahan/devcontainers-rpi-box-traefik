# Use the official Ubuntu 22.04 image as a base
FROM ubuntu:22.04

ARG LOCALE
ARG INSTALL_CLAUDE
ARG CLAUDE_INSTALL_SHA256

# Install basic dependencies + Ansible toolchain prerequisites
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    ca-certificates \
    curl \
    git \
    git-filter-repo \
    jq \
    libnss3-tools \
    locales \
    mkcert \
    openssh-client \
    python3 \
    python3-pip \
    ripgrep \
    sshpass \
    wget \
    && : "${LOCALE:?LOCALE is required (example: en_IE.UTF-8)}" \
    && grep -Eq "^[# ]*${LOCALE}[[:space:]]+UTF-8" /etc/locale.gen \
    && sed -i "s/^[# ]*${LOCALE}[[:space:]]\\+UTF-8/${LOCALE} UTF-8/" /etc/locale.gen \
    && locale-gen "$LOCALE" \
    && update-locale LANG="$LOCALE" LC_ALL="$LOCALE" \
    && rm -rf /var/lib/apt/lists/*

ENV LANG="${LOCALE}" \
    LANGUAGE="${LOCALE}" \
    LC_ALL="${LOCALE}"

# Install Ansible tooling via pip so the CLI and python packages stay in sync
ARG ANSIBLE_CORE_VERSION
ARG ANSIBLE_LINT_VERSION
ARG YAMLLINT_VERSION
RUN : "${ANSIBLE_CORE_VERSION:?ANSIBLE_CORE_VERSION is required}" \
    && : "${ANSIBLE_LINT_VERSION:?ANSIBLE_LINT_VERSION is required}" \
    && : "${YAMLLINT_VERSION:?YAMLLINT_VERSION is required}" \
    && python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip install --no-cache-dir \
    "ansible-core==${ANSIBLE_CORE_VERSION}" \
    "ansible-lint==${ANSIBLE_LINT_VERSION}" \
    "yamllint==${YAMLLINT_VERSION}"

# Install Starship
RUN curl -sS https://starship.rs/install.sh | sh -s -- --yes

# Install Claude Code CLI (optional; controlled by build arg)
RUN : "${INSTALL_CLAUDE:?INSTALL_CLAUDE build arg is required (true|false)}" \
    && case "$INSTALL_CLAUDE" in true|false) ;; *) echo "INSTALL_CLAUDE must be true or false (current: $INSTALL_CLAUDE)" >&2; exit 1 ;; esac \
    && if [ "$INSTALL_CLAUDE" = "true" ]; then \
      echo "Installing Claude Code CLI..."; \
      install_url="https://claude.ai/install.sh"; \
      install_tmp="/tmp/claude-install.sh"; \
      curl -fsSL "$install_url" -o "$install_tmp"; \
      if [ -n "${CLAUDE_INSTALL_SHA256:-}" ]; then \
        echo "${CLAUDE_INSTALL_SHA256}  ${install_tmp}" | sha256sum -c -; \
      fi; \
      bash "$install_tmp"; \
      if [ -x "/root/.local/bin/claude" ]; then \
        install -m 0755 "/root/.local/bin/claude" /usr/local/bin/claude; \
      else \
        claude_path="$(command -v claude 2>/dev/null || true)"; \
        if [ -n "$claude_path" ] && [ -x "$claude_path" ]; then \
          install -m 0755 "$claude_path" /usr/local/bin/claude; \
        else \
          echo "Warning: Claude installer ran but 'claude' was not found in PATH or /root/.local/bin."; \
        fi; \
      fi; \
      rm -f "$install_tmp"; \
    else \
      echo "Skipping Claude Code CLI install (INSTALL_CLAUDE!=true)."; \
    fi

# Set the working directory
WORKDIR /workspace

ARG USERNAME
ARG USER_UID
ARG USER_GID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Ensure bash is the default shell for the user
RUN chsh -s /bin/bash $USERNAME

# Ensure prompt setup is sourced in interactive shells
RUN printf '\n# Devcontainer prompt\n_dev_ws="${WORKSPACE_FOLDER:-}"\nif [ -z "${_dev_ws}" ]; then\n  echo "Warning: WORKSPACE_FOLDER is not set; prompt setup is disabled (start via ./devcontainer-launch.sh or ./editor-launch.sh)."\nelif [ -f "${_dev_ws}/.devcontainer/scripts/bash-prompt.sh" ]; then\n  . "${_dev_ws}/.devcontainer/scripts/bash-prompt.sh"\nfi\nunset _dev_ws\n' >> /etc/bash.bashrc

# Ensure login shells also source the prompt setup
RUN printf '%s\n' '#!/bin/sh' \
    '_dev_ws="${WORKSPACE_FOLDER:-}"' \
    'if [ -z "${_dev_ws}" ]; then' \
    '  echo "Warning: WORKSPACE_FOLDER is not set; prompt setup is disabled (start via ./devcontainer-launch.sh or ./editor-launch.sh)."' \
    'elif [ -f "${_dev_ws}/.devcontainer/scripts/bash-prompt.sh" ]; then' \
    '  . "${_dev_ws}/.devcontainer/scripts/bash-prompt.sh"' \
    'fi' \
    'unset _dev_ws' \
    > /etc/profile.d/devcontainer-prompt.sh \
    && chmod 0644 /etc/profile.d/devcontainer-prompt.sh

# Entry point to run post-stop logic on container shutdown
COPY scripts/devcontainer-entrypoint.sh /usr/local/bin/devcontainer-entrypoint.sh
RUN chmod 0755 /usr/local/bin/devcontainer-entrypoint.sh

# Set ownership of workspace
RUN chown $USERNAME:$USERNAME /workspace

ENTRYPOINT ["/usr/local/bin/devcontainer-entrypoint.sh"]
