# How to Test

This document lists lightweight validation checks for the app deployment repo.

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
