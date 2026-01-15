# Fast start

If everything is set up already and you are in the devcontainer, this is a quick reference for the most-used commands.

If there are problems, start with the [documentation index](README.md).

## Conventions used below

- Run commands from the repo root unless noted.
- `rpi_box_01` is an example host; substitute your target (for example `rpi_box_03`).

## Start the standard tmux workspace

  ```bash
  make workspace
  ```

  Run this from the host machine (outside the devcontainer).

## Quick checks

  ```bash
  cd src
  ansible --version
  ansible-inventory --graph
  ```

## Test connectivity from Ansible to the box

  ```bash
  cd src
  ansible rpi_box_01 -m ping
  ```

  Optional: dump facts (useful when debugging distro/codename/arch issues):

  ```bash
  cd src
  ansible rpi_box_01 -m setup -a 'filter=ansible_distribution*'
  ansible rpi_box_01 -m setup -a 'filter=ansible_architecture'
  ```

## Deploy everything (full run)

  ```bash
  cd /workspace/src && ansible-playbook playbooks/pi-full.yml -l rpi_box_01
  ```

## Name resolution (hosts mode)

  If `NAME_RESOLUTION_MODE=hosts`, the play writes a hosts-compatible snippet to `hosts-snippet.txt` in the repo root:

  ```bash
  sudo tee -a /etc/hosts < hosts-snippet.txt
  ```

## Switch to DNS (Pi-hole / real DNS)

  Once DNS records exist for `whoami.<box>.<SITE_DOMAIN>`, `ca.<box>.<SITE_DOMAIN>`, and `traefik.<box>.<SITE_DOMAIN>`:

  ```bash
  # In .env
  NAME_RESOLUTION_MODE=dns
  DNS_PREFLIGHT_CHECK=both
  ```

  Then remove any previously-added `/etc/hosts` overrides for those names (they will mask DNS).

## Dry-run and review changes (recommended on existing boxes)

  Before applying to a box that already runs services (for example Traefik/Pi-hole),
  do a check-mode run with diffs and review anything touching DNS/resolved, Docker
  daemon config, and reboot behavior:

  ```bash
  cd src
  ansible-playbook playbooks/pi-full.yml -l rpi_box_01 --check --diff
  ```

## Deploy only a subset

  Deploy only edge components (Traefik + CA share):

  ```bash
  cd src
  ansible-playbook playbooks/pi-edge.yml -l rpi_box_01
  ```

## Local lint + idempotency smoke test

  This runs `ansible-lint`, `yamllint`, then executes the playbook twice and fails if the second pass reports changes:

  ```bash
  ./scripts/ansible-smoke.sh src/playbooks/pi-full.yml src/inventory/hosts.ini
  ```

  Limit to a single box:

  ```bash
  ./scripts/ansible-smoke.sh src/playbooks/pi-full.yml src/inventory/hosts.ini rpi_box_03
  ```

## Lint only

  Run only `ansible-lint` (no playbook execution):

  ```bash
  ./scripts/ansible-lint.sh src/playbooks/pi-full.yml
  ```
