# Working with environment variables (TL;DR)

1. **Copy the template:** `cp .env.example .env` (only needs to happen once per project).
2. **Fill in the values:** edit `.env` so that `PROJECT_NAME`, `HOST_USERNAME`, `HOST_UID`, `HOST_GID`, Git info, `EDITOR_CHOICE`, `CONTAINER_HOSTNAME=${PROJECT_NAME}-${EDITOR_CHOICE}`, `DOCKER_IMAGE_NAME=${PROJECT_NAME}-${EDITOR_CHOICE}`, etc. match your machine. This file is the single source of truth.
3. **Host vars from env:** Ansible host vars read from `.env` via `lookup('env', ...)`. Populate `ANSIBLE_USER`, `ANSIBLE_SSH_PRIVATE_KEY_FILE`
4. **Optional defaults:** if you create `.devcontainer/config/.env` (usually by copying `.devcontainer/config/.env.example`), the loader fills any missing variables from it without overwriting `.env`.
5. **Validate & launch:** always start your session with `./launch.sh`. It loads `.env`, runs `.devcontainer/scripts/validate-env.sh`, and only opens VS Code/Cursor/Antigravity after the check passes. If something is wrong, the script exits with the list of fixes so you don’t waste time booting the devcontainer.
6. **Inside the container:** every helper script sources `.devcontainer/scripts/env-loader.sh`, so anything defined in `.env` automatically shows up in init/post-create hooks and in your shell.
7. **Adding new variables:** document them in `.env.example`, consume them via `env-loader.sh`, and (if they’re required) add a rule to `.devcontainer/scripts/validate-env.sh`. No other script needs to change. For multiple git remotes, set `GIT_SYNC_REMOTES`, `GIT_SYNC_PUSH_REMOTES`, and matching `GIT_REMOTE_URL_<REMOTE>` entries here as well.

Keep `.env` out of version control (already covered by `.gitignore`) so each machine can store its own user-specific values without conflicts.
