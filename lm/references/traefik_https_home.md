# Traefik + HTTPS for `home.arpa` on a Raspberry Pi (Docker + Ansible)

## 1. Goal

Provide a **standard, repeatable way** to run multiple web applications on a single Raspberry Pi using Docker, all exposed via **clean hostnames** and **HTTPS**, inside a private LAN using the `home.arpa` domain.

Key objectives:

- One single entry point on ports **80/443**
- No port conflicts between applications
- Hostname-based routing (e.g. `whoami.home.arpa`, `grafana.home.arpa`)
- HTTPS everywhere, **without browser warnings**
- Fully automatable using **Ansible**

---

## 2. Non-Goals / Constraints

- No public exposure of services
- No dependency on public Certificate Authorities (e.g. Let's Encrypt)
- No per-application reverse proxy configuration files

---

## 3. High-Level Architecture

```text
Client Browser
   |
   | https://app.home.arpa
   v
Trusted Local CA
   |
   v
Traefik (ports 80/443)
   |
   +--> app1 (HTTP, internal)
   +--> app2 (HTTP, internal)
   +--> appN (HTTP, internal)
```

- Traefik is the **only container** binding ports 80 and 443
- Applications expose **internal HTTP ports only**
- Routing is based on the HTTP `Host` header

---

## 4. DNS Design (Local DNS)

All application hostnames resolve to the **same IP address** (the Raspberry Pi running Traefik).

Example records:

```text
grafana.home.arpa  -> 192.168.1.58
whoami.home.arpa   -> 192.168.1.58
```

DNS is authoritative only inside the LAN.

---

## 5. HTTPS Strategy (Important)

### 5.1 Why Let's Encrypt Is Not Used

Public CAs **do not issue certificates** for:

- `.arpa`
- `.lan`
- Private IP ranges

Therefore, HTTPS must be provided via a **private Certificate Authority**.

---

### 5.2 Chosen Solution: Local CA + Wildcard Certificate

- A **local CA** is created (e.g. using `mkcert` or `step-ca`)
- A **wildcard certificate** is issued for:

```text
*.home.arpa
```

- This single certificate is mounted into Traefik
- All HTTPS traffic is terminated at Traefik

Benefits:

- One certificate for all services
- No re-issuance when adding apps
- Clean browser experience (🔒)

---

## 6. Trust Model

Each client device must trust the local CA **once**:

- Linux: system trust store
- macOS: Keychain
- Windows: Trusted Root Certification Authorities
- Mobile: OS certificate profile

This step is outside Docker/Traefik and must be handled by endpoint management or documentation.

---

## 7. Docker Networking Model

A shared external Docker network is used:

```text
web (external network)
```

- Traefik and all web applications attach to this network
- No container-to-container port exposure is required

---

## 8. Traefik Responsibilities

Traefik is deployed **once** and remains mostly static.

Responsibilities:

- Bind ports 80 and 443
- Discover Docker containers dynamically
- Route requests based on hostname
- Terminate TLS using the wildcard certificate

Traefik **does not need to be modified** when new applications are added.

---

## 9. Application Responsibilities

Applications:

- Do NOT need to know about Traefik
- Run plain HTTP internally
- Are exposed via **Docker labels only**

Each application defines:

- Hostname rule
- Internal port
- Optional middleware (later)

---

## 10. Example: Traefik Deployment (Conceptual)

Key characteristics:

- Docker provider enabled
- `exposedByDefault=false`
- HTTPS entrypoint enabled
- Static wildcard certificate loaded

Traefik configuration is intentionally minimal and stable.

---

## 11. Example: Application Exposure Pattern

Each application adds labels similar to:

```
traefik.enable=true
traefik.http.routers.app.rule=Host(`app.home.arpa`)
traefik.http.routers.app.entrypoints=websecure
traefik.http.routers.app.tls=true
traefik.http.services.app.loadbalancer.server.port=XXXX
```

No Traefik restart is required.

---

## 12. Ansible Implementation Guidance

Recommended Ansible structure:

- Role: `docker`
  - Install Docker + Docker Compose plugin

- Role: `traefik`
  - Create external Docker network (`web`)
  - Deploy Traefik compose stack
  - Install TLS certificates

- Role: `apps/*`
  - Deploy each application independently
  - Attach to `web` network
  - Add Traefik labels

Important principles:

- Traefik role runs **before** app roles
- App roles must not manage ports 80/443
- App roles must not modify Traefik config

---

## 13. Operational Notes

- Adding a new application requires:
  1. DNS record
  2. Docker Compose service with labels

- Removing an app automatically removes routing
- HTTPS remains valid without changes

---

## 14. Common Pitfalls

❌ Binding ports 80/443 in applications
❌ Using IP-based URLs instead of hostnames
❌ Expecting Let's Encrypt to work with `.arpa`
❌ Centralizing routes inside Traefik config

---

## 15. Summary

This design provides:

- Clean internal URLs
- Secure HTTPS everywhere
- Zero-touch Traefik scaling
- Simple Ansible automation

It is well-suited for:

- Home labs
- Edge deployments
- Small on-prem environments

---

## 16. Future Extensions (Optional)

- HTTP → HTTPS redirect
- Authentication middleware
- IP allowlists
- mTLS for internal services
- Integration with secrets managers
