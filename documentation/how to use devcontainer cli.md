# How to use the devcontainer CLI

This project includes a helper that wraps the devcontainer CLI to open a shell
inside the container.

## Prerequisites

- Install the CLI on the host: `npm install -g @devcontainers/cli`
- Ensure `.env` is valid (run `./.devcontainer/scripts/validate-env.sh`).

## Run the helper

```sh
./devcontainer-launch.sh
```

## Notes

- The helper ensures the devcontainer is running before opening a shell.
- It uses a unique container name for CLI sessions to avoid conflicts.
- Set `KEEP_CONTAINER=true` to avoid stopping the container when the session ends.
