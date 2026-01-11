# tmux workspace (Makefile + workspace.sh)

This repo includes a repeatable tmux workspace launcher so you can replace
multiple manually opened terminal tabs with one command.

## Start the workspace

From a terminal on the host machine (outside the devcontainer), in the repo root:

```bash
make workspace
```

Behavior:

- Creates (or reuses) a tmux session named by `WORKSPACE_TMUX_SESSION` (defaults to `PROJECT_NAME` from `.env`).
- Creates tmux windows (if missing): `shell`, `devcontainer`, `editor`, `claude`, `ssh-box`.
- Re-running `make workspace` attaches (or switches the client) without recreating existing windows.

## Configuration

Set these in `.env` if you want to override defaults:

- `WORKSPACE_TMUX_SESSION`: tmux session name (default: `PROJECT_NAME`)
- `WORKSPACE_REMOTE_HOST`: host to use for the `ssh-box` window
- `WORKSPACE_ALLOW_IN_CONTAINER`: set `1`/`true` to bypass the host-only guard (not recommended)

If `WORKSPACE_REMOTE_HOST` is not set, the `ssh-box` window prints a reminder instead of attempting SSH.

## What runs in each window

- `shell`: interactive shell in the repo root
- `devcontainer`: `./devcontainer-launch.sh`
- `editor`: `./editor-launch.sh`
- `claude`: `./claude-launch.sh`
- `ssh-box`: `ssh "$WORKSPACE_REMOTE_HOST" -t 'tmux attach -t infra || tmux new -s infra'`
