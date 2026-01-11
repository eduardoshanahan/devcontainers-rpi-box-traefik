# ADR-0010: Provide Claude Code workflow in devcontainer

## Status

Accepted

## Context

This repository is developed with AI-assisted workflows and benefits from having an agent available inside the devcontainer with the same toolchain and filesystem view as Ansible/Docker operations.

We want a workflow that is:

- Easy to start (one launcher)
- Optional (not every contributor wants the tool)
- Safer (avoid silently running arbitrary installers)
- Consistent across editors and CLI sessions

## Decision

Provide an optional Claude Code workflow in the devcontainer:

- Include a host launcher (`./claude-launch.sh`) that starts the devcontainer and runs `claude` inside it.
- Install the Claude CLI during devcontainer image build when `INSTALL_CLAUDE=true` (the Claude launcher forces this on).
- Allow optional checksum verification of the installer script via `CLAUDE_INSTALL_SHA256` when set and validated.
- Add the VS Code extension `anthropic.claude-code` in `.devcontainer/devcontainer.json` (without removing other extensions).

## Consequences

- Contributors can use Claude Code with the same environment as Ansible runs.
- Install behavior is explicit and can be opted out of.
- Checksum verification is available but requires maintainers to keep `CLAUDE_INSTALL_SHA256` current when they choose to pin it.

## Alternatives Considered

- Install Claude Code only on the host (rejected: loses devcontainer parity and complicates setup).
- Always skip installation and require manual install steps (rejected: too much friction).
- Always install without verification (rejected: less safe and harder to audit).
