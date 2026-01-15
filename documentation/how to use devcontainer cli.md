# How to use the devcontainer CLI

This project includes a helper that wraps the devcontainer CLI to open a shell
inside the container.

## Prerequisites

- Install the CLI on the host: `npm install -g @devcontainers/cli`
- Ensure `.env` is valid (run `./scripts/validate-env.sh devcontainer`).

## Run the helper

```sh
./devcontainer-launch.sh
```

## Notes

- The helper ensures the devcontainer is running before opening a shell.
- It uses a dedicated image/container name (`${PROJECT_NAME}-devcontainer`) to avoid conflicts with editor/Claude sessions.
- Set `KEEP_CONTAINER_DEVCONTAINER=true` to avoid stopping the container when the session ends.
- About builds: `./devcontainer-launch.sh` skips `devcontainer build` when the tagged image already exists (unless `FORCE_REBUILD=true`), but `devcontainer up` may still run a cached "features" build (`Dockerfile-with-features` → `vsc-...` image). This is normal and provides the Dev Containers glue layer; it usually stays fast because it’s cached.
