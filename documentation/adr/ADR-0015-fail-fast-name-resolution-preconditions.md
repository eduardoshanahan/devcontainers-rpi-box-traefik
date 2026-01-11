# ADR-0015: Fail fast on name-resolution and FQDN preconditions

## Status

Accepted

## Context

This repo already requires required configuration to be explicit and fail fast
(see `documentation/adr/ADR-0002-require-environment-variables-and-fail-fast.md`).

For Traefik-routed admin UIs, a missing or incorrect FQDN (or missing DNS
resolution when DNS is expected) results in confusing failures that are easy to
misdiagnose (certificate mismatch, router not matching, browser errors).

## Decision

Ansible roles that expose services behind Traefik must:

- Assert required FQDN inputs are provided (per host/service).
- In `NAME_RESOLUTION_MODE=dns`, assert required FQDNs resolve before deploying or validating UIs.
- Fail with explicit messages when these preconditions are not met.

Resolution check scope may be configured via `.env`:

- `DNS_PREFLIGHT_CHECK=target|controller|both` (default: `target`)

## Consequences

- Misconfiguration is caught early, before services are deployed in a partial state.
- The behavior is predictable and consistent across services.

## Alternatives Considered

- Proceed without checks and rely on manual debugging (rejected: slower and inconsistent).
- Add implicit defaults for missing FQDNs (rejected: violates the no-magic-defaults policy).
