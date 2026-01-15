# How to use this project

## Overview

This repo deploys Traefik to Raspberry Pi hosts that already have the base OS/infra configured. Keep the base provisioning repo for OS setup and use this repo for app-specific roles and playbooks.

## Quick start

1. Copy `.env.example` to `.env`:

   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and set the required values (host user/UID/GID, locale, Git identity, editor choice, resource limits, Ansible pins, and `ANSIBLE_USER` / `ANSIBLE_SSH_PRIVATE_KEY_FILE`).

3. Run `./editor-launch.sh` and in your editor choose "Reopen in Container".

## Launchers

- `./editor-launch.sh` for VS Code/Cursor/Antigravity.
- `./devcontainer-launch.sh` for a CLI shell.
- `./claude-launch.sh` to start Claude Code inside the container.
- `./workspace.sh` to open a tmux workspace on the host (optional).

## SSH agent forwarding

The devcontainer bind-mounts `SSH_AUTH_SOCK`, so the host must have a running
SSH agent before the container starts. Keys stay on the host; only the agent
socket is forwarded.

## Common scripts

- Validate config: `./scripts/validate-env.sh [editor|devcontainer|claude]`
- Clean old devcontainer images: `./scripts/clean-devcontainer-images.sh`
- Sync git remotes (required for this layer): `./scripts/sync-git.sh`

## Project-specific workflow

### Install Ansible collections

From inside the devcontainer:

```bash
cd src
ansible-galaxy collection install -r requirements.yml
```

### Prerequisites

- Start the environment via one of the repo launchers (see "Launchers" above).
- The Pi is already provisioned with the base OS/infra playbook (Docker Engine + Compose v2 installed, daemon running).
- `/srv/apps` exists on the target (created by the base repo).
- SSH access is working from your devcontainer (SSH agent forwarding is used; keys do not need to be copied into the repo).
- Ports 80/443 must be free on the target (existing apps like Pi-hole may bind these; reconfigure them or Traefik won't start).
- HTTP is redirected to HTTPS for all Traefik-managed apps.
- Traefik deployment can be toggled via `.env` using `TRAEFIK_ENABLED=true|false`.

### Base Provisioning Responsibilities

These items belong in the base provisioning project (shared across all app
stacks):

- Install Docker Engine and create `/srv/apps`.

### Auto-start (Optional)

Set `TRAEFIK_SYSTEMD_AUTOSTART=true` to install a systemd unit that runs
`docker compose up -d` on boot. This recreates the container if it was removed,
while keeping data in `/srv/apps/traefik`.

### TLS Certificates (mkcert)

This repo can generate the Traefik TLS certificate on the controller (your
devcontainer) using mkcert and copy it to the Pi during deployment.

1. Ensure mkcert is installed in the devcontainer (rebuild if needed). The playbook
   will run `mkcert -install` automatically if the local CA is missing.

2. Ensure `TRAEFIK_LOCAL_CERT_DIR` in `.env` points to the repo-local directory
   (default: `/workspace/certs`).

3. Certificates are generated per box (recommended):
   - Default SANs: `*.${box_name}.${SITE_DOMAIN}` and `${box_name}.${SITE_DOMAIN}`.
   - You can override `traefik_cert_hosts` in `host_vars` for edge cases, but you no longer need a shared list in `group_vars`.

4. Run the playbook. It will generate the cert/key locally (if missing) and copy
   them to `TRAEFIK_CERT_FILE` and `TRAEFIK_KEY_FILE` on the target.

   Optional: generate all box certificates on the controller in advance:

   ```bash
   cd src
   ansible-playbook playbooks/controller-certs.yml
   ```

5. Trust the mkcert CA on client devices so browsers accept the HTTPS certs.
   For Ubuntu, `sudo ./scripts/install-ubuntu-ca.sh` uses `scripts/ca-hosts.txt`
   to pull CA files from your boxes.

6. If the local mkcert CA changes, the playbook will automatically regenerate
   the Traefik cert and restart Traefik so it starts serving the new chain.
   Client devices must install the updated CA.
   The playbook also detects target certs signed by an old CA and reissues them.

### CA Share Endpoint (Optional)

You can expose the mkcert root CA over HTTPS so clients can download and install
it easily. See `ca-share-instructions.md` for enabling the endpoint and Ubuntu/
Windows install steps.

### Configure inventory host vars

1. Copy the example host vars file and keep the real one out of git:

   ```bash
   cp src/inventory/host_vars/rpi_box.example.yml src/inventory/host_vars/rpi_box_01.yml
   ```

2. Edit `src/inventory/host_vars/rpi_box_01.yml` with the correct `ansible_host`, `ansible_port`, and hostnames (`whoami_host`, `ca_share_host`, optional `traefik_dashboard_host`).
   By default, service hostnames are derived as `service.<box_name>.<SITE_DOMAIN>` (for example `whoami.rpi-box-01.hhlab.home.arpa`).
   If your inventory hostname contains underscores (for example `rpi_box_01`), set `box_name: "rpi-box-01"` in host_vars to produce DNS-safe FQDNs.

3. If bootstrapping without DNS (`NAME_RESOLUTION_MODE=hosts`), generate a client `/etc/hosts` snippet from inventory:
   - This snippet is printed automatically during playbook runs (dns_preflight).
   - `HOSTS_SNIPPET_OUTPUT_FILE` writes a hosts-compatible snippet file (default: `hosts-snippet.txt` in the repo root).
   - Apply it on your client machine with `sudo tee -a /etc/hosts < hosts-snippet.txt`.
   - Or generate it explicitly:

   ```bash
   ./scripts/generate-hosts-snippet.sh
   ```

4. When you switch to real DNS (`NAME_RESOLUTION_MODE=dns`), remove any `/etc/hosts` entries you previously added for the `*.hhlab.home.arpa` service names (they override DNS).

### Verify Ansible connectivity

```bash
cd src
ansible rpi_box_01 -i inventory/hosts.ini -m ping
```

### Deploy apps

```bash
cd src
ansible-playbook playbooks/pi-full.yml -l rpi_box_01
```

Traefik dashboard is available only when explicitly enabled and protected:

- Set `TRAEFIK_DASHBOARD_ENABLED=true` and configure access control (basic auth and/or IP allowlist) in `.env`.
- Access it via the FQDN: `https://traefik.<box_name>.<SITE_DOMAIN>/dashboard/` (not by IP).
