# How to Test

This document lists lightweight validation checks for the app deployment repo.

## Lint Only

- Run `ansible-lint` on the apps playbook:

  ```bash
  ./scripts/ansible-lint.sh src/playbooks/pi-apps.yml
  ```

## Apps Playbook

- Re-run for idempotency:

  ```bash
  cd src
  ansible-playbook playbooks/pi-apps.yml -l rpi_box_01
  ```

## Smoke Script

- Run the smoke tests against all Raspberry Pi hosts:

  ```bash
  ./scripts/ansible-smoke.sh src/playbooks/pi-apps.yml src/inventory/hosts.ini
  ```

  To target a different inventory group, set `SMOKE_GROUP` (default: `raspberry_pi_boxes`):

  ```bash
  SMOKE_GROUP=rpi_box_01 ./scripts/ansible-smoke.sh src/playbooks/pi-apps.yml src/inventory/hosts.ini
  ```
