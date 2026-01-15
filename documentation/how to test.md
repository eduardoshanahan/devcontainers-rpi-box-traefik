# How to Test

This document lists lightweight validation checks for the app deployment repo.

## Test Scenarios (Recommended Order)

We intentionally test in two phases:

1. **Baseline (fresh box / fresh network)**: validate bootstrap and steady-state deploy on a box that does not already run Pi-hole or any legacy services.
2. **Coexistence (existing Pi-hole present)**: validate behavior and failure modes when a box already has Pi-hole/DNS and might conflict with ports 80/443 and/or name resolution expectations.

Unless explicitly testing DNS enforcement, start with `NAME_RESOLUTION_MODE=hosts` to avoid coupling early bootstrap to DNS availability.

### Scenario A: Baseline on `rpi-box-03` (fresh)

- Use `rpi_box_03` inventory/host_vars and confirm SSH connectivity:

  ```bash
  cd src
  ansible rpi_box_03 -m ping
  ```

- Set controller env vars for bootstrap:
  - `NAME_RESOLUTION_MODE=hosts`
  - `DNS_PREFLIGHT_CHECK=target` (default)
  - Optional: start with `CA_SHARE_ENABLED=false` for the first deploy, then enable it after Traefik + cert flow is confirmed.

- Generate and install a client `/etc/hosts` snippet (so the FQDNs resolve without DNS):
  - The apps playbook prints this snippet automatically in `NAME_RESOLUTION_MODE=hosts`, or you can generate it explicitly:

  ```bash
  ./scripts/generate-hosts-snippet.sh
  ```

- Deploy:

  ```bash
  cd src
  ansible-playbook playbooks/pi-full.yml -l rpi_box_03
  ```

- Validate idempotency (second run should report `changed=0` for all hosts):

  ```bash
  cd src
  ansible-playbook playbooks/pi-full.yml -l rpi_box_03
  ```

### Scenario B: Coexistence with existing Pi-hole

- Before deploying Traefik, confirm ports 80/443 are free on the target (or expect an early failure):
  - If Pi-hole (or any other container) binds 80/443, Traefik will not start until those bindings are removed or changed.
- If testing DNS enforcement, switch:
  - `NAME_RESOLUTION_MODE=dns`
  - `DNS_PREFLIGHT_CHECK=target|controller|both` (use `both` for strictest validation)
- Run the deploy and confirm preflight failures happen early when DNS does not resolve.

## Lint Only

- Run `ansible-lint` on the apps playbook:

  ```bash
  ./scripts/ansible-lint.sh src/playbooks/pi-full.yml
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
  ./scripts/ansible-smoke.sh src/playbooks/pi-full.yml src/inventory/hosts.ini
  ```

  To target a different inventory group, set `SMOKE_GROUP` (default: `raspberry_pi_boxes`):

  ```bash
  SMOKE_GROUP=rpi_box_01 ./scripts/ansible-smoke.sh src/playbooks/pi-full.yml src/inventory/hosts.ini
  ```
