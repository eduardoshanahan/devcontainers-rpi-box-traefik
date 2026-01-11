# ADR-0003: Maintain `documentation/diary/` daily project journal

## Status

Accepted

## Context

This repository is being actively developed with AI-assisted workflows.
Important context, intermediate reasoning, and operational details can be lost if they only exist in chat history.

We need a lightweight, repo-local way to:

- Preserve day-to-day context for handoffs
- Record current working state and next steps
- Keep a timeline of what changed and why

## Decision

Maintain `documentation/diary/` as a daily project journal:

- `documentation/diary/state/YYYY-MM-DD.md` records the current project status and next steps.
- `documentation/diary/plans/YYYY-MM-DD.md` records what we plan to accomplish that day.
- `documentation/diary/recaps/YYYY-MM-DD.md` records progress checkpoints and outcomes during the day.

When code or documentation changes, the corresponding `documentation/diary/` files for that day must be updated.

## Consequences

- Better continuity across sessions and contributors
- Clearer reasoning trail for changes made with AI assistance
- Small ongoing overhead to keep the journal current

## Alternatives Considered

- Rely on chat history (rejected: not durable, not searchable in-repo)
- Only update README/docs (rejected: loses daily execution details and intermediate steps)
