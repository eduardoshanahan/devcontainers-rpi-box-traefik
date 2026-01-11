# ADR-0008: Tag devcontainer images via launch scripts

## Status

Accepted

## Context

This repo needs deterministic, host-specific devcontainer builds (UID/GID matching, resource limits, host-mounted paths).
Relying on implicit Dev Containers behavior makes it harder to:

- Ensure images are tagged consistently (`DOCKER_IMAGE_NAME`/`DOCKER_IMAGE_TAG`)
- Keep configuration sourced from the project-root `.env`
- Avoid Docker `--env-file` limitations (no shell expansion) when we depend on `localEnv` expansion in launch scripts

## Decision

Use the host launch scripts to manage build tagging:

- `devcontainer build --image-name "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"`
- Avoid using `devcontainer.json` `image` and avoid `runArgs` `--env-file=...` for configuration

Devcontainer configuration remains sourced from the project-root `.env` via `localEnv` and `.devcontainer/scripts/env-loader.sh`.

## Consequences

- Builds are repeatable and images are easy to identify/clean up
- Launch scripts remain the canonical entrypoint for non-editor sessions (CLI, Claude)
- Requires `.env` to define image naming variables

## Alternatives Considered

- Let Dev Containers pick image names (rejected: harder to manage/clean; less deterministic)
- Use Docker `--env-file` (rejected: breaks shell expansion and conflicts with `localEnv`-driven configuration)
