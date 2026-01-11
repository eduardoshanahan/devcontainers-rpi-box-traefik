# ADR-0012: Standardize admin UI FQDNs as `service.box.domain`

## Status

Accepted

## Context

This repository enforces the policy that all web/admin UIs are exposed via Traefik
using FQDNs (see `documentation/adr/ADR-0009-use-traefik-for-all-admin-uis.md`).

To scale to multiple Raspberry Pi boxes and multiple services per box, we need a
single naming convention that:

- Produces predictable URLs across all services and boxes
- Works equally well when name resolution is provided via `/etc/hosts` or DNS
- Avoids IP-based access as a primary workflow

## Decision

Adopt a standardized FQDN scheme for Traefik-routed services:

`service.box.domain`

Examples:

- `traefik.rpi-box-01.hhlab.home.arpa`
- `pihole.rpi-box-01.hhlab.home.arpa`
- `whoami.rpi-box-01.hhlab.home.arpa`

The domain suffix is configured via `.env`:

- `SITE_DOMAIN=hhlab.home.arpa`

## Consequences

- Traefik router rules and documentation become consistent across services.
- Certificates can be generated consistently (SANs can cover `*.rpi-box-XX.<domain>` patterns).
- Switching from `/etc/hosts` to DNS does not require changing URLs.

## Alternatives Considered

- `box.domain` with path-based routing (rejected: weaker separation, harder per-app auth/middleware).
- `service.domain` without the box component (rejected: conflicts across multiple boxes).
- IP-based access as a standard workflow (rejected: conflicts with the Traefik/FQDN policy).
