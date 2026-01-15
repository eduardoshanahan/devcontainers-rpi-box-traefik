# Working with environment variables

## TL;DR

1. **Copy the template:** `cp .env.example .env` (only needs to happen once per project).
2. **Fill in the values:** edit `.env` so that `PROJECT_NAME`, `HOST_USERNAME`, `HOST_UID`, `HOST_GID`, `WORKSPACE_FOLDER`, `LOCALE`, Git identity, `EDITOR_CHOICE`, resource limits, Ansible pins, and (optionally) workflow-specific names like `CONTAINER_HOSTNAME_*` / `DOCKER_IMAGE_NAME` match your machine. This file is the single source of truth.
3. **Single source of truth:** the project-root `.env` is the only supported configuration source for the devcontainer.
4. **Ansible vars from env:** some Ansible `host_vars` read from `.env` via `lookup('env', ...)` (at minimum `ANSIBLE_USER` and `ANSIBLE_SSH_PRIVATE_KEY_FILE`). Role defaults (Traefik/Whoami/CA share/Pi-hole sync) also come from `.env.example` and can be overridden in `host_vars`/`group_vars`.
5. **Validate & launch:** start with `./editor-launch.sh` (GUI), `./devcontainer-launch.sh` (CLI shell), or `./claude-launch.sh` (Claude Code). Each loads `.env`, sets launcher defaults, and runs `./scripts/validate-env.sh [editor|devcontainer|claude]` (which calls the internal validator `.devcontainer/scripts/validate-env.sh`) and exits early if something is wrong.
6. **Inside the container:** helper scripts source `.devcontainer/scripts/env-loader.sh`, so anything defined in `.env` shows up in init/post-create hooks and in your shell.
7. **Adding new variables:** document them in `.env.example`, load them via `env-loader.sh`, and (if they’re required) add a rule to the internal validator `.devcontainer/scripts/validate-env.sh` (the host entrypoint is `./scripts/validate-env.sh [editor|devcontainer|claude]`). For multiple git remotes, set `GIT_SYNC_REMOTES`, `GIT_SYNC_PUSH_REMOTES`, and matching `GIT_REMOTE_URL_<REMOTE>` entries here as well.

## Naming conventions

- Image/container names (defaults): `${PROJECT_NAME}-editor`, `${PROJECT_NAME}-devcontainer`, `${PROJECT_NAME}-claude`
- Devcontainer session labels (CLI workflows): `devcontainer.session=${PROJECT_NAME}-cli` and `devcontainer.session=${PROJECT_NAME}-claude`

## Optional launcher flags (common)

- `KEEP_CONTAINER_EDITOR=true` / `KEEP_CONTAINER_DEVCONTAINER=true` / `KEEP_CONTAINER_CLAUDE=true` to keep the corresponding container after exit.
- `FORCE_REBUILD=true` to force `devcontainer build` even if the tagged image already exists.
- `INSTALL_CLAUDE=true` to install the Claude CLI during devcontainer image build (the Claude launcher forces this on).
- `CLAUDE_INSTALL_SHA256=<sha256>` to verify the Claude installer download.
- `ENV_LOADER_DEBUG=true` to print which variables were added by the env loader.
- `ENV_LOADER_DEBUG_VALUES=true` to print variable values too (may expose secrets).

Keep `.env` out of version control (already covered by `.gitignore`) so each machine can store its own user-specific values without conflicts.
