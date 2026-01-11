# ADR-0017: Support multiple Traefik TLS modes via `.env` switch

## Status

Accepted

## Context

This repository currently targets Raspberry Pi boxes on a LAN and uses a private
CA (mkcert) for HTTPS. Over time, we also want to deploy the same “apps behind
Traefik” pattern to public VPS environments where public TLS via ACME (for
example Let’s Encrypt) is the standard approach.

We want to keep the app deployment pattern stable while allowing the TLS
implementation details to vary by environment.

## Decision

Introduce a TLS strategy switch for Traefik configured via `.env`:

- `TRAEFIK_TLS_MODE=mkcert|acme_http|acme_dns`

Guidance:

- `mkcert`: private CA TLS for LAN and bootstrap environments (works with `/etc/hosts`).
- `acme_http`: public ACME with HTTP-01 challenge (requires inbound port 80 from the internet and public DNS).
- `acme_dns`: public ACME with DNS-01 challenge (requires DNS provider API access and public DNS).

TLS mode is separate from name resolution:

- Name resolution is controlled by `NAME_RESOLUTION_MODE=hosts|dns` (see `documentation/adr/ADR-0013-support-hosts-and-dns-name-resolution-modes.md`).
- TLS strategy is controlled by `TRAEFIK_TLS_MODE=...`.

“DNS exists” definition:

- In `NAME_RESOLUTION_MODE=dns`: required FQDNs must resolve (fail fast if not).
- In `TRAEFIK_TLS_MODE=acme_http|acme_dns`: FQDNs must be in public DNS and satisfy the chosen ACME challenge requirements.

Secrets and provider credentials:

- DNS provider API credentials (for `acme_dns`) are secrets and must not be committed to the repo.
- They must be injected via a secrets mechanism appropriate for the environment (vault/secret manager/host-only env).

## Consequences

- The same roles/patterns for “apps behind Traefik” can be reused across LAN and VPS deployments.
- The project remains explicit and fail-fast: the selected TLS mode determines which prerequisites must be satisfied.
- Additional implementation work is required in the Traefik role to support ACME modes safely and securely.

## Alternatives Considered

- Separate repositories for LAN (mkcert) and VPS (ACME) (rejected: duplicates patterns and increases drift).
- Always use mkcert everywhere (rejected: poor fit for public services).
- Always use ACME everywhere (rejected: blocks offline/LAN bootstrap use cases).
