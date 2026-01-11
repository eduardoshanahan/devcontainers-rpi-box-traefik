# Bootstrap and Migration (hosts → DNS, mkcert → ACME)

This document describes the intended evolution path for environments that start
without DNS and/or without public TLS, and later converge on “standard”
FQDN-based access behind Traefik.

Authoritative decisions live in ADRs:

- FQDN scheme: `service.box.domain` (ADR-0012)
- Name resolution modes: `NAME_RESOLUTION_MODE=hosts|dns` (ADR-0013)
- DNS server management out of scope (ADR-0014)
- Traefik ingress opt-in (ADR-0016)
- TLS modes: `TRAEFIK_TLS_MODE=mkcert|acme_http|acme_dns` (ADR-0017)

## Phase A: Bootstrap with `/etc/hosts` (no DNS server yet)

Goal: keep URLs stable while clients resolve names via `/etc/hosts`.

- Set `NAME_RESOLUTION_MODE=hosts`.
- Use `SITE_DOMAIN` consistently (example: `hhlab.home.arpa`).
- Generate a deterministic `/etc/hosts` snippet for clients and install it on
  developer/admin machines.
- Expose admin UIs only through Traefik using `Host(service.box.domain)`.

## Phase B: Switch to DNS (DNS server becomes available)

Goal: keep the same URLs, move resolution responsibility to DNS.

- Ensure the DNS server has A/AAAA records for the required FQDNs.
- Switch to `NAME_RESOLUTION_MODE=dns`.
- Deployments must fail fast if required names do not resolve.

## Phase C: TLS strategy

### LAN / internal environments

- Use `TRAEFIK_TLS_MODE=mkcert` (private CA).
- Install the CA on client devices once.

### Public VPS environments

- Use `TRAEFIK_TLS_MODE=acme_http` (HTTP-01) or `TRAEFIK_TLS_MODE=acme_dns` (DNS-01).
- Provide provider credentials via a secrets mechanism (not committed to git).

## Rule of thumb

- URLs should not change across phases.
- Only the resolution mechanism (hosts vs DNS) and TLS strategy (mkcert vs ACME)
  should change.
