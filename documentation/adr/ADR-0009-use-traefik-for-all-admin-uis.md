# ADR-0009: Use Traefik for all admin UIs

## Status

Accepted

## Context

Some Raspberry Pi boxes expose admin UIs directly by IP.
This causes inconsistency once Pi-hole DNS is enabled.

## Decision

All services with a web UI must be exposed via Traefik
using an FQDN. No direct IP access is supported.

## Consequences

- Name resolution must exist for FQDNs (via `/etc/hosts` or DNS) before relying on Traefik routing.
- Service exposure decisions should follow the ingress decision matrix (see `documentation/adr/ADR-0016-make-traefik-ingress-opt-in.md`).

## Alternatives Considered

- Expose UIs directly by IP (rejected: inconsistent UX)
- Mixed IP/FQDN access (rejected: harder automation)
