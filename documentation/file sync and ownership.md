# File sync and ownership

This project focuses on two related problems when using a host file sync tool
with devcontainers.

## File synchronization

Sync tools like Synology Drive can conflict with file changes produced inside a
container. The helper scripts are designed to keep Git operations safe when a
sync tool is active:

- Prefer running `./scripts/sync-git.sh` for pulls and pushes.
- Keep the working tree clean before syncing (or use `FORCE_PULL=true`).
- Configure remotes in `.env` so the script can add missing remotes reliably.

## File ownership

When a container creates files with a different UID/GID than the host, sync
tools can get confused and cause permission errors. This template aligns the
container user with the host user:

- Set `HOST_USERNAME`, `HOST_UID`, and `HOST_GID` in `.env`.
- The devcontainer uses these values to create the matching user.
- This keeps file ownership consistent across host and container.
