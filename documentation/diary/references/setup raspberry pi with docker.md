# Setup Raspberry Pi With Docker

## Repository Snapshot

- Devcontainer already bakes in Ansible tooling (`.devcontainer/Dockerfile`, `.devcontainer/devcontainer.json`) and exports `ANSIBLE_CONFIG`/`ANSIBLE_INVENTORY` so anything under `src/` is immediately usable once the container boots.
- Helper workflow is `.env` ➝ `./editor-launch.sh` ➝ “Reopen in Container”; Ansible lint + smoke testing live in `scripts/ansible-smoke.sh`.
- Current inventory (`src/inventory/hosts.ini`) only declares the `local` group with `localhost ansible_connection=local`; there are no Raspberry Pi hosts or groups yet.
- `src/playbooks/sample.yml` is a placeholder sanity check; no real playbooks exist for imaging or configuring a Pi.
- `group_vars/all.yml` only pins `ansible_python_interpreter`; there are no variables for Pi credentials, package mirrors, Docker settings, etc.
- `requirements.yml` already installs `ansible.posix` and `community.general`, so we have the modules needed for apt repositories, user/group tweaks, and service management when we start adding Pi roles.

## Raspberry Pi Targets – Missing Pieces

- **Inventory layout:** need to model at least one `raspberry_pi_boxes` (or `pi_k3s`, `pi_media`, etc.) group with connection vars: SSH host/IP, `ansible_user`, `ansible_port`, preferred Python path (Ubuntu on ARM usually `/usr/bin/python3`), and privilege escalation preferences.
- **Credential handoff:** decide how we’ll store initial passwords or SSH keys (probably via `host_vars/<pi-name>.yml` kept out of git if secrets). Might lean on `ansible-vault` or expect manual key provisioning.
- **Playbooks:** propose `playbooks/pi-base.yml` for first-boot hardening (apt upgrade, timezone, hostname), and `playbooks/pi-docker.yml` (or a role) for container runtime setup.
- **Roles:** at minimum a `roles/pi_base` and `roles/docker_engine` pair so we can reuse them per host group. `docker_engine` can wrap enabling cgroup features (if necessary), installing Docker CE repos, and configuring the Docker service (daemon options, log rotation).
- **Ubuntu Server image prep:** scope whether we automate SD/SSD flashing (might live outside Ansible) or assume Ubuntu Server 24.04 LTS is already running with SSH reachable.
- **Docker install path:** confirm whether we stick to Canonical’s `docker.io` packages or install upstream `docker-ce`. For compose, Ubuntu 24.04 ships `docker-compose-plugin`; we can ensure it’s present plus symlink `/usr/libexec/docker/cli-plugins/docker-compose`.
- **User membership:** add the admin user (likely `ubuntu` initially, later custom) into the `docker` group, and optionally create an application-specific user for compose stacks.
- **Storage + data dirs:** define variables for `/srv/docker` or similar root where compose projects will live; ensure permissions and maybe mount points for external SSDs.
- **Validation tasks:** after Docker install, run `docker run hello-world` (with `changed_when: false`) and `docker compose version` to assert the runtime works before proceeding.

## Questions / Decisions to Capture

- Which Ubuntu version + kernel do we target? (22.04 server vs 24.04 vs Raspberry Pi OS). This affects `ansible_distribution` checks and package names.
- Are we managing only the Docker host, or also flashing the OS image / configuring boot firmware?
- Should Docker be managed through upstream apt repo or Canonical packages? Need to confirm networking implications (iptables legacy vs nft).
- Do we expect Wi‑Fi setup, static IP, or VLAN tagging? Might belong in `pi_network` role before Docker.
- What compose workloads are first on the list (Portainer, Home Assistant, custom app)? That influences how we structure data directories and secrets handling.

## Confirmed Direction (Session ✅)

- **OS + media**: Ubuntu Server **22.04 LTS (64-bit)** will be flashed onto an SD card. Raspberry Pi Imager is the preferred workflow, but any flashing tool is acceptable as long as it yields the two partitions (`system-boot`, `writable`).
- **Imaging artifacts**: The canonical cloud-init seed lives in `non_comitted_files/system-boot/`. Copy those `meta-data`, `network-config`, `user-data`, and the empty `ssh` flag straight into the freshly-flashed `system-boot` partition before first boot so SSH comes up immediately.
- **Networking**: Only wired Ethernet (`eth0`) is in scope; Wi-Fi is explicitly out. Static IP `192.168.1.58/24`, gateway `192.168.1.1`, DNS `[192.168.1.1, 1.1.1.1]` per `network-config`.
- **Access policy**: SSH public key auth only (`ssh_pwauth: false`, `disable_root: true`, user `eduardo` with passwordless sudo). `non_comitted_files/system-boot/user-data` is the single source of truth for the cloud-init stanza.
- **First boot checklist**:
  1. Flash Ubuntu 22.04 server image to SD.
  2. Mount the `system-boot` partition and overwrite it with the four files from `non_comitted_files/system-boot`, then `sync`.
  3. Insert SD into the Pi, connect Ethernet, power on, and wait ~60s for cloud-init.
  4. SSH in with `ssh -i ~/.ssh/eduardo-hhlab eduardo@192.168.1.58`.
  5. Run `sudo cloud-init status --wait` to confirm initial provisioning completed.
- **Post-image automation**: Once the Pi is reachable, everything else (OS updates, hardening, Docker install) must be handled through Ansible roles/playbooks in this repo so downstream projects inherit a reliable base.

## Automating SD Flashing With Ansible

- Added `src/playbooks/flash_sd_card.yml` to take over what Raspberry Pi Imager did manually. It runs on `localhost` (the devcontainer host) and requires the SD card to be attached and visible under `/dev/…`.
- The playbook workflow:
  1. Prompts for confirmation after showing `lsblk` details for the target block device so we don’t clobber the wrong disk.
  2. Downloads `ubuntu-22.04.5-preinstalled-server-arm64+raspi.img.xz` into `~/.cache/rpi-box/` (override via `work_dir` if needed). Pass `-e ubuntu_image_sha256=<sha256>` to enforce checksum validation once we pull it from Canonical’s release page.
  3. Decompresses the image (requires `xz-utils` on the host) and uses `dd bs=4M conv=fsync status=progress` to flash it to `sd_card_device`.
  4. Re-reads the partition table, mounts the first partition (`system-boot`), and copies `non_comitted_files/system-boot/{meta-data,network-config,user-data,ssh}` so SSH and the static IP come online immediately.
  5. Unmounts `system-boot`, runs `sync`, and prints a success message so the card can be ejected/inserted into the Pi.
- Usage example (run from repo root so the relative `seed_source_dir` resolves):

```bash
ansible-playbook src/playbooks/flash_sd_card.yml \
  -e sd_card_device=/dev/sdX \
  -e ubuntu_image_sha256=<sha256-from-canonical>
```

Replace `/dev/sdX` with the removable device reported by `lsblk` (e.g., `/dev/sdb` or `/dev/mmcblk0`). The playbook already handles `/dev/mmcblk0p1` style suffixes, and it unmounts any auto-mounted partitions before flashing.

## Docker Host Baseline – Implementation Notes

- **Docker channel**: Use the official Docker CE apt repository (Arm64 supported) to ensure the most recent stable `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, and `docker-compose-plugin`. Avoid Ubuntu’s `docker.io` to keep pace with upstream fixes.
- **Compose CLI**: With the plugin installed, `docker compose version` must report the bundled Compose V2 binary; symlink `/usr/local/bin/docker-compose` only if some tooling still expects the legacy command.
- **Kernel / cgroup prep**: Ubuntu 22.04 already ships with cgroup v2 enabled. Document (and codify) any `/boot/firmware/cmdline.txt` tweaks should we discover resource issues once workloads like Pi-hole are deployed.
- **User + groups**: Ensure the `eduardo` account (and any future automation user) is part of the `docker` group. Consider `group_vars/pi_docker.yml` to list additional users so future apps inherit the same treatment.
- **Directories**: Standardize on `/srv/docker/<app>` for compose stacks. Provision `pi-base` role variables such as `docker_data_root: /srv/docker` and create the directory with `0750` permissions owned by `root:docker` to keep secrets on disk under control.
- **Validation tasks**:
  - `docker version` and `docker info` with `changed_when: false` to assert the daemon responds.
  - `docker run --rm hello-world` to confirm image pulls work post-install.
  - `docker compose version` and a no-op `docker compose --project-directory /srv/docker/pi-hole config` once the initial project skeleton exists.
- **Services**: Enable and start `docker.service` and `containerd.service` via systemd, and drop a `/etc/docker/daemon.json` template to configure log rotation (e.g., `max-size`, `max-file`) and a default bridge MTU suited for the LAN.

### Preparing for First Application (Pi-hole)

- Treat Pi-hole as the seed `compose` project to validate the platform. Define a `docker_applications/pi-hole/compose.yml` skeleton with bind mounts rooted in `/srv/docker/pi-hole`.
- Capture DNS-specific prerequisites (port 53 ownership, LAN firewall rules, static DHCP reservations) in documentation so future playbooks can enforce them.
- Once the base roles are complete, create a follow-up playbook (`playbooks/pi-hole.yml`) that depends on `pi-docker` and deploys the stack, keeping this repo Pi-hole-ready without bundling the actual app yet.

## Sensitive Data Handling

- Host-specific variables (IPs, SSH usernames, initial passwords, etc.) belong in `host_vars/<hostname>.yml`. Keep secrets out of git by mirroring `host_vars` inside `non_comitted_files/` or use `ansible-vault` if you must check them in. Document which path you used so future sessions know where to source credentials.

## Immediate Next Steps

1. Extend the inventory with a dedicated `[raspberry_pi_boxes]` group and stub host entries so we have concrete targets.
2. Sketch `pi-base` + `pi-docker` roles (tasks/main.yml + defaults) focusing on apt updates, package installs, Docker CE repo, docker-compose plugin, user group membership, and service enablement.
3. Draft a `playbooks/pi-docker.yml` that ties the roles together and documents the required vars.
4. Decide how sensitive host data (passwords, Wi‑Fi creds) will be stored—plain vars, `host_vars`, or `ansible-vault`. Document the expectation in README + this file.
5. Add verification steps to `scripts/ansible-smoke.sh` or a dedicated Molecule scenario once roles exist, so we keep the Pi automation tested even before touching hardware.
