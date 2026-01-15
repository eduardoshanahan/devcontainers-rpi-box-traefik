# ADR-0007: Isolate devcontainer sessions with `--id-label`

## Status

Accepted

## Context

This repo supports multiple workflows (editor, CLI shell, Claude Code).
Sharing a single container across different launchers can cause conflicts:

- Container name collisions
- One workflow stopping/replacing another workflow’s container
- Hard-to-reason-about lifecycle and cleanup

## Decision

Isolate non-editor workflows by labeling their devcontainer resources:

- Each launcher uses a distinct `--id-label` (for example `devcontainer.session=${PROJECT_NAME}-cli`)
- Each launcher uses a dedicated image/container name (`${PROJECT_NAME}-editor`, `${PROJECT_NAME}-devcontainer`, `${PROJECT_NAME}-claude`) to avoid collisions across workflows
- CLI/Claude containers stop automatically at session end unless the launcher-specific keep flag is set (`KEEP_CONTAINER_DEVCONTAINER=true` or `KEEP_CONTAINER_CLAUDE=true`)

## Consequences

- Editor sessions can coexist with CLI and Claude sessions without clobbering each other
- Cleanup and troubleshooting are simpler (label-based identification)
- May run multiple containers for the same repo concurrently

## Alternatives Considered

- Single shared container for all workflows (rejected: conflicts and unpredictable lifecycle)
