# Working with environment variables (TL;DR)

1. **Copy the template:** `cp .env.example .env` (only needs to happen once per project).
2. **Fill in the values:** edit `.env` so that the required devcontainer values match your machine: `HOST_USERNAME`, `HOST_UID`, `HOST_GID`, Git info (`GIT_REMOTE_URL`, `GIT_USER_NAME`, `GIT_USER_EMAIL`), `EDITOR_CHOICE` (code/cursor/antigravity), plus container/image settings like `CONTAINER_HOSTNAME` and `DOCKER_IMAGE_NAME`. This file is the single source of truth.
3. **Optional defaults:** if you create `.devcontainer/config/.env` (usually by copying `.devcontainer/config/.env.example`), the loader fills any missing variables from it without overwriting `.env`.
4. **Ansible vars from env:** some Ansible `host_vars` read from `.env` via `lookup('env', ...)` (at minimum `ANSIBLE_USER` and `ANSIBLE_SSH_PRIVATE_KEY_FILE`). Role defaults (Traefik/Whoami/CA share/Pi-hole sync) also come from `.env.example` and can be overridden in `host_vars`/`group_vars`.
5. **Validate & launch:** start with `./editor-launch.sh` (GUI), `./devcontainer-launch.sh` (CLI shell), or `./claude-launch.sh` (Claude Code inside the container). Each loads `.env`, runs `.devcontainer/scripts/validate-env.sh`, and exits early if something is wrong.
6. **Inside the container:** helper scripts source `.devcontainer/scripts/env-loader.sh`, so anything defined in `.env` shows up in init/post-create hooks and in your shell.
7. **Adding new variables:** document them in `.env.example`, load them via `env-loader.sh`, and (if they’re required) add a rule to `.devcontainer/scripts/validate-env.sh`. For multiple git remotes, set `GIT_SYNC_REMOTES`, `GIT_SYNC_PUSH_REMOTES`, and matching `GIT_REMOTE_URL_<REMOTE>` entries here as well.

Optional launcher flags:
- `KEEP_CONTAINER=1` to keep the CLI container running after exit.
- `SKIP_CLAUDE_INSTALL=1` to skip Claude Code install in post-create.
- `ENV_LOADER_DEBUG=1` to print which variables were added by the env loader.

Keep `.env` out of version control (already covered by `.gitignore`) so each machine can store its own user-specific values without conflicts.
