# ADR-0014: Keep DNS server deployment and management out of this repository

## Status

Accepted

## Context

This repository’s goal is to deploy Traefik as the reverse proxy on Raspberry Pi
boxes already running Docker, and to ensure containerized admin UIs are exposed
only through Traefik.

Running a DNS server (Pi-hole or other) is infrastructure with its own lifecycle,
credentials, and operational concerns. Coupling DNS server deployment into this
repo would blur responsibilities and make it harder to reuse across different
environments.

## Decision

This repository will not:

- Deploy Pi-hole or any other DNS server
- Manage DNS server configuration (create/update DNS records)

This repository may:

- Validate DNS resolution in `NAME_RESOLUTION_MODE=dns`
- Generate `/etc/hosts` snippets for clients in `NAME_RESOLUTION_MODE=hosts`

## Consequences

- Clear separation of concerns: DNS infrastructure is managed elsewhere.
- This repo remains reusable across different DNS providers and environments.
- DNS integrations (if ever needed) can be added as optional, provider-specific tooling without making it a core requirement.

## Alternatives Considered

- Deploy Pi-hole from this repo (rejected: mixes concerns, increases risk and scope).
- Create DNS records via a fixed provider API (rejected: reduces portability).
