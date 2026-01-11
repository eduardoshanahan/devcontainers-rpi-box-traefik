# Standardized Traefik + DNS + Admin UI Architecture for Raspberry Pi Boxes

## Purpose

This document defines the **standard, enforced approach** for exposing administration interfaces on Raspberry Pi boxes running Docker. It is intended for the **implementation team** and is designed to:

- Eliminate IP-based admin access
- Standardize URLs using FQDNs
- Avoid DNS/reverse-proxy bootstrap issues
- Enable strict, predictable automation with Ansible

This approach is opinionated by design.

---

## Core Principles (Non‑Negotiable)

1. **All administration UIs are exposed via FQDN behind Traefik**
2. **No long‑term admin access via raw IP addresses**
3. **Every box runs Traefik**, even if it currently hosts no UI
4. **DNS is the source of truth for service discovery**
5. **IP access is emergency / break‑glass only**
6. **Automation must fail fast if required DNS or environment data is missing**

---

## Reference Architecture

```
Clients
   ↓
DNS (Pi‑hole Primary)
   ↓
rpi-box-XX.home
   ↓
Traefik (per box)
   ↓
Application Admin UI (Pi‑hole, etc.)
```

Each Raspberry Pi box:
- Has a hostname (e.g. `rpi-box-01`)
- Has a static IP or DHCP reservation
- Runs Docker
- Runs Traefik

---

## DNS Strategy

### Local Domain

Example:
```
home
```

### Required DNS Records (Pi‑hole Local DNS)

| Record | Target IP |
|------|----------|
| pihole.rpi-box-01.home | 192.168.1.10 |
| traefik.rpi-box-01.home | 192.168.1.10 |

Notes:
- DNS must exist **before** admin UIs are exposed via Traefik
- DNS does **not** depend on Traefik
- Pi‑hole UI may temporarily be accessed via IP during bootstrap only

---

## Bootstrap Strategy (No Chicken‑and‑Egg)

### Phase 0 – Preconditions

- Static IP or DHCP reservation exists
- Hostname is set correctly
- SSH access confirmed

---

### Phase 1 – Bootstrap DNS (No Traefik)

- Deploy Pi‑hole primary
- Configure Local DNS records
- Validate name resolution from a client

Temporary access:
```
http://<ip>/admin
```

---

### Phase 2 – Deploy Traefik (DNS‑Agnostic)

Key points:
- Traefik does **not** require DNS to start
- It listens on ports 80 and 443
- Routers will match Host() rules later

---

### Phase 3 – Attach Admin UIs Behind Traefik

- Applications declare Traefik labels
- Access moves to:
```
https://<service>.<hostname>.home
```

---

### Phase 4 – Lock Down Direct IP Access (Recommended)

- Firewall restricts direct container ports
- Only Traefik is exposed publicly on the LAN

---

## Required Ansible Roles

### 1. `edge_traefik`

**Responsibilities**:
- Install Docker (if not present)
- Deploy Traefik container
- Configure static entrypoints (:80, :443)
- Load environment variables explicitly

**Must not**:
- Auto‑generate domains
- Guess certificates
- Enable features implicitly

---

### 2. `dns_pihole_primary`

**Responsibilities**:
- Deploy Pi‑hole primary
- Configure local DNS records
- Expose API credentials via `.env`

---

### 3. `app_pihole`

**Responsibilities**:
- Deploy Pi‑hole container
- Attach Traefik labels
- Disable direct port exposure (except emergency)

---

## Bootstrap Playbook Order

```yaml
- hosts: pihole_primary
  roles:
    - dns_pihole_primary

- hosts: all_boxes
  roles:
    - edge_traefik

- hosts: pihole_nodes
  roles:
    - app_pihole
```

---

## Mandatory Fail‑Fast Checks

### DNS Preconditions

Tasks must fail if:
- Required FQDN variables are missing
- Expected DNS records do not resolve

Example check:

```yaml
- name: Fail if FQDN is missing
  fail:
    msg: "fqdn must be defined"
  when: fqdn is not defined
```

---

### Environment Variable Enforcement

Rules:
- `.env` files are preferred
- No silent defaults
- Missing required variables = hard failure

---

## Reference Docker Compose (Pi‑hole + Traefik)

```yaml
services:
  pihole:
    image: pihole/pihole:latest
    env_file: .env
    labels:
      - traefik.enable=true
      - traefik.http.routers.pihole.rule=Host(`pihole.rpi-box-01.home`)
      - traefik.http.services.pihole.loadbalancer.server.port=80
    networks:
      - proxy

networks:
  proxy:
    external: true
```

Notes:
- No `ports:` section for Pi‑hole UI
- Traefik is the only entrypoint

---

## Emergency Access (Break‑Glass)

One of the following **must** exist:

- SSH access
- Temporary port exposure via override compose
- Management‑only firewall rule

Emergency access must be:
- Documented
- Auditable
- Disabled after use

---

## Summary Rules (TL;DR)

- Every box runs Traefik
- Every admin UI uses FQDN
- DNS exists first
- IP access is temporary and exceptional
- Ansible enforces everything

This architecture is designed to scale cleanly from 2 to N Raspberry Pi boxes without behavioral changes.
