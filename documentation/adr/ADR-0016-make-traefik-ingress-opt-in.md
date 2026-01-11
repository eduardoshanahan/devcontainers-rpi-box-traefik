# ADR-0016: Make Traefik ingress opt-in using a decision matrix

## Status

Accepted

## Context

This repository enforces that services with web/admin UIs are exposed via Traefik
using FQDNs (see `documentation/adr/ADR-0009-use-traefik-for-all-admin-uis.md`).

However, not every service needs HTTP ingress. Some services are:

- Non-HTTP (TCP/UDP) infrastructure components
- Internal-only workloads
- Headless agents or scheduled jobs

Deploying Traefik for services that do not benefit from ingress increases
operational surface area without adding value.

## Decision

Traefik is treated as an ingress controller, not a dependency. Ingress is opt-in.

A global switch controls whether this repository deploys Traefik:

- `TRAEFIK_ENABLED=true|false` (in `.env`)

A service should be exposed via Traefik only if it passes these gates:

1. Human access: intended to be used via a web browser.
2. Protocol: primarily HTTP/HTTPS (TCP routing is exceptional).
3. Exposure: intended for LAN/shared access (not localhost-only / internal-only).
4. Name resolution: an FQDN exists or is planned (see `documentation/adr/ADR-0013-support-hosts-and-dns-name-resolution-modes.md`).
5. Security value: Traefik adds meaningful policy (TLS termination and/or access controls).
6. Lifecycle: stable user-facing/admin UI (not core infrastructure plumbing).

Rule of thumb:

- Base server roles: do not require Traefik by default.
- Ingress roles: enable Traefik only when at least one service requires ingress.

## Consequences

- Traefik deployment remains intentional and tied to user-facing HTTP/HTTPS services.
- Non-HTTP and internal-only services do not incur ingress complexity.
- Migration from `/etc/hosts` to DNS remains straightforward because URLs stay stable.

## Alternatives Considered

- Run Traefik on every box regardless of service needs (rejected: unnecessary complexity for non-ingress services).
- Always expose UIs directly (rejected: violates the Traefik/FQDN policy).
