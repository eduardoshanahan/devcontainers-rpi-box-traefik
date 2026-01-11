# ADR-0011: Monitoring stack (Prometheus + node exporter + Grafana)

## Status

Proposed

## Context

This project already installs `prometheus-node-exporter` on managed hosts to
expose machine metrics (CPU, memory, disk, network) for monitoring.

Prometheus and Grafana are not yet deployed as part of this repository, but are
expected to be introduced later.

Key constraints and risks:

- Prometheus has no built-in auth; exposure must be controlled (network and/or proxy).
- node exporter metrics can leak host details; default exposure should be minimal.
- This repo’s policy for web UIs is to expose them via Traefik using FQDNs
  (see `documentation/adr/ADR-0009-use-traefik-for-all-admin-uis.md`).

## Decision (proposed)

Adopt a standard monitoring architecture for Raspberry Pi boxes:

- **Metrics source**: `prometheus-node-exporter` runs on each managed host.
- **Metrics store/scraper**: Prometheus periodically scrapes exporters.
- **Dashboards**: Grafana visualizes Prometheus data.

Security defaults:

- node exporter binds to `127.0.0.1:9100` by default until a Prometheus server
  exists and an allowlisted access path is defined.
- When Prometheus runs on a different host, node exporter may bind to the LAN
  interface, but access to `9100/tcp` must be restricted to the Prometheus host
  (firewall allowlist).

Web UI exposure:

- Grafana and Prometheus web UIs (if exposed) must be published through Traefik
  with FQDNs, not by direct IP access.

## Open questions

- Where will Prometheus run?
  - On one of the Pi boxes
  - On a separate server/NAS
  - In Docker on a designated host
- How will exporters be reached?
  - LAN bind + firewall allowlist
  - localhost-only + Prometheus co-located
  - localhost-only + tunnel/proxy pattern
- Will we run Alertmanager, and how will notifications be handled?
- Will we add remote_write (long-term storage) later?

## Consequences

- Establishes a consistent and secure default for node exporter.
- Requires explicit decisions for network access before enabling remote scraping.
- Aligns future admin UIs with the Traefik/FQDN policy.

## Alternatives considered

- Expose node exporter on `0.0.0.0:9100` everywhere (rejected: unnecessary exposure).
- Run Prometheus on every host (rejected: heavier and duplicates data).
- Skip node exporter and rely on ad-hoc health checks (rejected: limited visibility).

