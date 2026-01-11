# ADR-0013: Support both `/etc/hosts` and DNS name-resolution modes

## Status

Accepted

## Context

Some deployments start without any local DNS server. In those environments, the
only practical way to resolve internal service FQDNs is via client `/etc/hosts`
entries.

Later, a DNS server (Pi-hole or another DNS platform) may become available and
configured. We want a clean migration path that keeps URLs stable and adds
fail-fast validation once DNS exists.

## Decision

Introduce a single configuration switch for name-resolution expectations:

- `NAME_RESOLUTION_MODE=hosts|dns` (in `.env`)

Behavior:

- `hosts` mode:
  - The project provides a deterministic `/etc/hosts` snippet for clients (derived from inventory/host_vars).
  - Ansible does not require DNS resolution to be present.
- `dns` mode:
  - Ansible fails fast if required FQDNs do not resolve.
  - DNS record creation is out of scope for this repository (see ADR-0014).

## Consequences

- The same Traefik/app configuration works in both environments.
- Teams can start with `/etc/hosts` and later switch to DNS by changing a single variable.
- In `dns` mode, failures happen early when DNS is not correctly configured.

## Alternatives Considered

- Always require DNS (rejected: blocks environments without a DNS server).
- Always rely on `/etc/hosts` (rejected: does not scale and prevents DNS validation).
- Auto-detect DNS availability (rejected: implicit behavior and harder to reason about).
