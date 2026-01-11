# Raspberry Pi Traefik (Docker + Ansible)

This repo deploys Traefik to Raspberry Pi hosts that have already been
provisioned by the [rpi-box project](https://github.com/eduardoshanahan/devcontainers-rpi-box). It is designed to run inside a similar devcontainer workflow and focus only on the Traefik reverse-proxy stack.

## Quick Start

1. Copy `.env.example` to `.env`, then run `./launch.sh`.
2. Start the devcontainer via `./editor-launch.sh` (GUI) or `./devcontainer-launch.sh` (CLI); the devcontainer build expects environment variables to be exported by the launcher.
3. Reopen in container (VS Code/Cursor/Antigravity) to use the preconfigured Ansible tools.
4. Configure inventory + host vars for your Pi.
5. Run the apps playbook: `ansible-playbook src/playbooks/pi-apps.yml -l rpi_box_01`.

## Key Docs

- Environment variables: [documentation/working with environment variables.md](documentation/working%20with%20environment%20variables.md)
- Usage: [documentation/how to use this project.md](documentation/how%20to%20use%20this%20project.md)
- Testing: [documentation/how to test.md](documentation/how%20to%20test.md)
- CA share endpoint: [documentation/ca-share-instructions.md](documentation/ca-share-instructions.md)
- Add app behind Traefik: [documentation/add-app-via-traefik.md](documentation/add-app-via-traefik.md)

## Helpful Scripts

- Lint + idempotence + checks: `scripts/ansible-smoke.sh`
- Devcontainer launcher (POSIX sh): `launch.sh`
