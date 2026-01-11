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
- CLI and Claude launchers use unique container names when needed to avoid collisions with the editor container
- CLI/Claude containers stop automatically at session end unless `KEEP_CONTAINER` is set

## Consequences

- Editor sessions can coexist with CLI and Claude sessions without clobbering each other
- Cleanup and troubleshooting are simpler (label-based identification)
- May run multiple containers for the same repo concurrently

## Alternatives Considered

- Single shared container for all workflows (rejected: conflicts and unpredictable lifecycle)
