# ADR-0006: Pin Ansible toolchain versions in devcontainer build

## Status

Accepted

## Context

Unpinned developer tooling (Ansible, ansible-lint, yamllint) can drift over time, creating inconsistent behavior between machines and across sessions.
This can surface as formatting changes, lint rule differences, or playbook execution differences.

## Decision

Pin the Ansible toolchain versions as devcontainer build arguments sourced from `.env`:

- `ANSIBLE_CORE_VERSION`
- `ANSIBLE_LINT_VERSION`
- `YAMLLINT_VERSION`

The devcontainer image installs these specific versions (via `pip`) during build.

Also pin `PYTHON_VERSION` (the interpreter the toolchain runs on) so the tooling runtime is reproducible.

## Consequences

- Reproducible tooling across contributors and time
- Easier debugging when linting or playbook behavior changes
- Requires updating `.env.example` / `.env` versions intentionally when upgrading
- Requires periodic review to keep the pinned versions current

## Review cadence (monthly)

Once per month (or when you hit a tooling bug), review whether the pinned toolchain should be updated:

- Compare current pins in `.env` to upstream releases for `ansible-core`, `ansible-lint`, and `yamllint`.
- Check whether the current `PYTHON_VERSION` is still supported by `ansible-core` and `ansible-lint`.
- Skim release notes for:
  - security fixes
  - rule changes that may cause new lint failures
  - behavior changes that may affect playbook runs

## Upgrade procedure (recommended)

- Update one pin at a time (for example bump `ansible-lint` first).
- Rebuild the devcontainer image so the new versions are installed.
- Run `./scripts/ansible-smoke.sh src/playbooks/pi-base.yml src/inventory/hosts.ini <host-or-group>` and fix any new lint failures.
- Record the upgrade (what changed and why) in the daily diary under `documentation/diary/`.

## Alternatives Considered

- Install latest versions (rejected: non-deterministic)
- Pin only in documentation (rejected: enforcement is too weak)
