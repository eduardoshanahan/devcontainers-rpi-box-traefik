# Troubleshooting

## Launch script fails validation

- Run `./.devcontainer/scripts/validate-env.sh` to see the exact error.
- Confirm `.env` matches your host user, UID, and GID.

## Devcontainer fails to start due to SSH_AUTH_SOCK

- Ensure an SSH agent is running on the host.
- Export `SSH_AUTH_SOCK` in your shell before running `./editor-launch.sh`.

## Git identity not set in the container

- Confirm `GIT_USER_NAME` and `GIT_USER_EMAIL` are set in `.env`.
- Rebuild the container if post-create did not run.

## Git sync fails due to dirty working tree

- Commit or stash changes, or rerun with `FORCE_PULL=true`.
- Check the configured remotes in `.env` if it fails to find a remote.
