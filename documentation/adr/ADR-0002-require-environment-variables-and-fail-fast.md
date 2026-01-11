# ADR-0002: Require .env variables and fail fast

## Status

Accepted

## Context

Infrastructure deployments using Ansible and Docker were failing silently
when required configuration was missing or defaulted implicitly.

## Decision

All required configuration must be provided via `.env` files.
Playbooks and scripts must fail immediately if required variables are missing.

## Consequences

- More explicit configuration
- Earlier failures during deployment
- Slightly more setup effort

## Alternatives Considered

- Provide defaults (rejected: hides errors)
- Prompt interactively (rejected: breaks automation)
