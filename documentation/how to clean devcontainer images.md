# How to clean devcontainer images

Dev Containers builds a new image whenever the config changes, and it may also
create a `-uid` image variant when UID/GID needs to be adjusted. Over time this
can leave many unused images on disk.

This repo includes a cleanup script that removes older, unused devcontainer
images while keeping recent ones.

## Configure retention

Set how many days of unused images to keep in `.env`:

```text
DEVCONTAINER_IMAGE_RETENTION_DAYS=7
```

The cleanup script requires this value and will fail if it is missing or
invalid.

## Run the cleanup

From the project root:

```text
./scripts/clean-devcontainer-images.sh
```

## What gets removed

- Dangling images older than the retention window.
- Unused images labeled by Dev Containers (`devcontainer.metadata`) older than
  the retention window.

Images in use by running containers are not removed.
