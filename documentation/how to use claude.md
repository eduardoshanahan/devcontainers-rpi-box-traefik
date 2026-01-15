# How to use Claude Code

This project provides a helper that runs Claude Code inside the devcontainer.

## Prerequisites

- Install the devcontainer CLI on the host: `npm install -g @devcontainers/cli`
- Ensure `.env` is valid (run `./scripts/validate-env.sh claude`).
- Ensure Claude Code is installed in the container (build-time opt-in via `INSTALL_CLAUDE=true`; the Claude launcher forces this on).
- Optional hardening: set `CLAUDE_INSTALL_SHA256` (64 hex chars) in `.env` to verify the installer download.

## Run the helper

```sh
./claude-launch.sh
```

## Notes

- The helper starts the devcontainer if needed and launches Claude Code in it.
- If Claude is not found, rebuild the container with `INSTALL_CLAUDE=true` (the launcher exports this for you).
