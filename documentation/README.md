# Documentation Index

## Getting Started

- Quick command reference: [fast start](fast%20start.md)
- Project overview and workflow: [how to use this project](how%20to%20use%20this%20project.md)
- Environment variables (`.env`): [working with environment variables](working%20with%20environment%20variables.md)
- Bootstrap and migration: [bootstrap and migration](bootstrap%20and%20migration.md)
- Devcontainer CLI workflow: [how to use devcontainer cli](how%20to%20use%20devcontainer%20cli.md)

## How-To Guides

- Testing and smoke checks: [how to test](how%20to%20test.md)
- Adding an app behind Traefik: [add app via Traefik](add-app-via-traefik.md)
- Lint-only helper: `scripts/ansible-lint.sh` (documented in [how to test](how%20to%20test.md))
- tmux quick reference: [tmux quick reference](tmux_quick_reference.md)
- tmux workspace launcher: [tmux workspace](tmux_workspace.md)
- Troubleshooting: [troubleshooting](troubleshooting.md)
- Cleaning devcontainer images: [how to clean devcontainer images](how%20to%20clean%20devcontainer%20images.md)
- Git sync helper: [how to use sync-git](how%20to%20use%20sync-git.md)
- Claude Code usage: [how to use claude](how%20to%20use%20claude.md)
- File sync and ownership: [file sync and ownership](file%20sync%20and%20ownership.md)
- External integration example (Pi-hole): [pihole + traefik](pihole-traefik-instructions.md)

## Architecture Decision Records (ADRs)

- ADR directory: [documentation/adr](adr)
- Record decisions: [ADR-0001](adr/ADR-0001-record-architecture-decisions.md)
- Fail-fast configuration: [ADR-0002](adr/ADR-0002-require-environment-variables-and-fail-fast.md)
- Daily diary policy: [ADR-0003](adr/ADR-0003-maintain-diary-daily-project-journal.md)
- Toolchain version pinning: [ADR-0006](adr/ADR-0006-pin-ansible-toolchain-versions-in-devcontainer-build.md)
- Monitoring stack (proposed): [ADR-0011](adr/ADR-0011-monitoring-prometheus-node-exporter-grafana.md)
- Standardize service FQDNs: [ADR-0012](adr/ADR-0012-standardize-service-box-domain-fqdns.md)
- Support hosts and DNS modes: [ADR-0013](adr/ADR-0013-support-hosts-and-dns-name-resolution-modes.md)
- Keep DNS management out-of-repo: [ADR-0014](adr/ADR-0014-keep-dns-server-management-out-of-this-repo.md)
- Fail fast on name resolution: [ADR-0015](adr/ADR-0015-fail-fast-name-resolution-preconditions.md)
- Traefik ingress decision matrix: [ADR-0016](adr/ADR-0016-make-traefik-ingress-opt-in.md)
- Traefik TLS modes: [ADR-0017](adr/ADR-0017-support-multiple-traefik-tls-modes.md)

## Project Diary

- Diary root: [documentation/diary](diary)
- Current state: [documentation/diary/state](diary/state)
- Plans: [documentation/diary/plans](diary/plans)
- Recaps: [documentation/diary/recaps](diary/recaps)
