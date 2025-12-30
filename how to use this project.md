# How to Use This Project

This repo deploys Traefik to Raspberry Pi hosts that already have the base OS/infra configured. Keep the base repo for provisioning and use this repo for app-specific roles and playbooks.

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

- The Pi is already provisioned with the base OS/infra playbook (Docker Engine installed).
- `/srv/apps` exists on the target (created by the base repo).
- SSH access is working from your devcontainer.

### Base Provisioning Responsibilities

These items belong in the base provisioning project (shared across all app
stacks):

- Install Docker Engine and create `/srv/apps`.

### Auto-start (Optional)

Set `TRAEFIK_SYSTEMD_AUTOSTART=true` to install a systemd unit that runs
`docker compose up -d` on boot. This recreates the container if it was removed,
while keeping data in `/srv/apps/traefik`.

## 2. Configure Inventory Host Vars

1. Copy the example host vars file and keep the real one out of git:

   ```bash
   cp src/inventory/host_vars/rpi_box.example.yml src/inventory/host_vars/rpi_box_01.yml
   ```

2. Edit `src/inventory/host_vars/rpi_box_01.yml` with the correct `ansible_host` and `ansible_port`.
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

Traefik should be available at `http://<pi-ip>:<TRAEFIK_WEB_PORT>/admin/`.
