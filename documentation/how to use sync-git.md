# How to use sync-git.sh

This helper keeps a local repo in sync with one or more remotes while avoiding
conflicts from external file sync tools.

## Configure in .env

Required:

- `GIT_SYNC_REMOTES` list (space or comma separated).

Optional:

- `GIT_SYNC_PUSH_REMOTES` list (space or comma separated).
- `GIT_REMOTE_URL` for the primary remote.
- `GIT_REMOTE_URL_<REMOTE>` for additional remotes.
- `BRANCH` to force a specific branch name (otherwise uses current branch).
- `FORCE_PULL=true` to allow overwriting local changes (primary remote only).

Example:

```env
GIT_SYNC_REMOTES="origin lan"
GIT_SYNC_PUSH_REMOTES="origin lan"
GIT_REMOTE_URL="git@github.com:username/repo.git"
GIT_REMOTE_URL_LAN="ssh://git@192.168.1.10:/volume1/git/${PROJECT_NAME}.git"
```

## Run the script

Standard sync (requires clean working tree):

```sh
./scripts/sync-git.sh
```

Sync a specific branch:

```sh
BRANCH=main ./scripts/sync-git.sh
```

Force sync (overwrites local changes):

```sh
FORCE_PULL=true ./scripts/sync-git.sh
```

## Behavior notes

- The first remote in `GIT_SYNC_REMOTES` is the primary upstream.
- Additional remotes are rebased in sequence to keep them aligned.
- If a remote is missing, the script adds it using the configured URL.
- If the current branch does not exist on a remote, it pushes it upstream.
