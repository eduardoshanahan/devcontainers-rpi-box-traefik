# How to use Claude Code

This project provides a helper that runs Claude Code inside the devcontainer.

## Prerequisites

- Install the devcontainer CLI on the host: `npm install -g @devcontainers/cli`
- Ensure `.env` is valid (run `./.devcontainer/scripts/validate-env.sh`).
- Ensure Claude Code is installed in the container (post-create installs it by default).

## Run the helper

```sh
./claude-launch.sh
```

## Notes

- The helper starts the devcontainer if needed and launches Claude Code in it.
- If Claude is not found, rebuild the container or re-run the post-create step.
