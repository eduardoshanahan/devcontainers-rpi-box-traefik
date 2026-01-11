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
  cd src
  ansible-playbook playbooks/pi-full.yml -l rpi_box_01
  ```

## Dry-run and review changes (recommended on existing boxes)

  Before applying to a box that already runs services (for example Traefik/Pi-hole),
  do a check-mode run with diffs and review anything touching DNS/resolved, Docker
  daemon config, and reboot behavior:

  ```bash
  cd src
  ansible-playbook playbooks/pi-full.yml -l rpi_box_01 --check --diff
  ```

## Deploy only a subset

  Run a single role (tags are used throughout the roles):

  ```bash
  cd src
  ansible-playbook playbooks/pi-base.yml -l rpi_box_01 --tags docker_engine
  ```

## Local lint + idempotency smoke test

  This runs `ansible-lint`, `yamllint`, then executes the playbook twice and fails if the second pass reports changes:

  ```bash
  ./scripts/ansible-smoke.sh src/playbooks/pi-base.yml src/inventory/hosts.ini
  ```

  Limit to a single box:

  ```bash
  ./scripts/ansible-smoke.sh src/playbooks/pi-base.yml src/inventory/hosts.ini rpi_box_03
  ```

## Lint only

  Run only `ansible-lint` (no playbook execution):

  ```bash
  ./scripts/ansible-lint.sh src/playbooks/pi-base.yml
  ```
