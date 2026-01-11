# How to Use This Project

This repo deploys Traefik to Raspberry Pi hosts that already have the base OS/infra configured. Keep the base provisioning repo for OS setup and use this repo for app-specific roles and playbooks.

## 0. Configure the Devcontainer Environment

1. Copy the root `.env.example` to `.env`:

   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and set your host username/UID/GID plus the Ansible-related paths:

   - `ANSIBLE_CONFIG=/workspace/src/ansible.cfg`
   - `ANSIBLE_INVENTORY=/workspace/src/inventory/hosts.ini`
   - `ANSIBLE_COLLECTIONS_PATH=/workspace/src/collections:/home/<your-username>/.ansible/collections`
   - `ANSIBLE_ROLES_PATH=/workspace/src/roles`
   - `ANSIBLE_USER`, `ANSIBLE_SSH_PRIVATE_KEY_FILE`

   The devcontainer loads these variables from `.env`, so keeping them here makes
   the configuration obvious and versioned via `.env.example`.

3. Install required Ansible collections:

   ```bash
   cd src
   ansible-galaxy collection install -r requirements.yml
   ```

## 1. Prerequisites

- Launch options:
  - `./editor-launch.sh` for VS Code/Cursor/Antigravity.
  - `./devcontainer-launch.sh` for a CLI shell.
  - `./claude-launch.sh` to start Claude Code inside the container.
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

3. Set `traefik_cert_hosts` in `src/inventory/group_vars/all.yml` to the SANs you want on
   the wildcard certificate, for example:

   ```yaml
   traefik_cert_hosts:
     - "*.rpi-box-01.hhlab.home.arpa"
     - "*.rpi-box-02.hhlab.home.arpa"
   ```

4. Run the playbook. It will generate the cert/key locally (if missing) and copy
   them to `TRAEFIK_CERT_FILE` and `TRAEFIK_KEY_FILE` on the target.

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

## 2. Configure Inventory Host Vars

1. Copy the example host vars file and keep the real one out of git:

   ```bash
   cp src/inventory/host_vars/rpi_box.example.yml src/inventory/host_vars/rpi_box_01.yml
   ```

2. Edit `src/inventory/host_vars/rpi_box_01.yml` with the correct `ansible_host`, `ansible_port`, and hostnames (`whoami_host`, `ca_share_host`, optional `traefik_dashboard_host`).

## 3. Verify Ansible Connectivity

```bash
cd src
ansible rpi_box_01 -i inventory/hosts.ini -m ping
```

## 4. Deploy Apps

```bash
cd src
ansible-playbook playbooks/pi-apps.yml -l rpi_box_01
```

Traefik should be available at `http://<pi-ip>:<TRAEFIK_WEB_PORT>/dashboard/`.
