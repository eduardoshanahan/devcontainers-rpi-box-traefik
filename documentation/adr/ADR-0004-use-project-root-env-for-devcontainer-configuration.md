# ADR-0004: Use project-root `.env` for devcontainer configuration

## Status

Accepted

## Context

Devcontainer behavior depends on host-specific values (usernames/UIDs, workspace paths, resource limits, tool versions).
Implicit defaults or scattered configuration sources lead to inconsistent environments and hard-to-debug failures.

## Decision

Use the project-root `.env` as the single source of truth for devcontainer configuration:

- Host launchers and devcontainer scripts load `.env` via `.devcontainer/scripts/env-loader.sh`.
- Required variables are validated up front via `./scripts/validate-env.sh [editor|devcontainer|claude]` (which calls `.devcontainer/scripts/validate-env.sh`).
- Missing or invalid configuration fails fast with actionable errors.

## Consequences

- Deterministic devcontainer builds and runs across machines
- Earlier, clearer failures when configuration is missing or malformed
- Requires contributors to maintain a correct local `.env`

## Alternatives Considered

- Rely on ambient shell environment (rejected: error-prone, inconsistent)
- Provide hidden defaults (rejected: violates fail-fast and masks misconfiguration)
