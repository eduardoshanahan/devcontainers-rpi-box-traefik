# Adding a Docker App Behind Traefik (Ansible Teams)

Use this checklist when deploying a new Docker application that should be
reachable through Traefik.

## Prerequisites

- Traefik is already deployed on the target and bound to ports 80/443.
- The shared external Docker network exists (default: `web`).
- DNS points the app hostname to the Traefik host.
- TLS certificate covers the hostname (e.g. `*.rpi-box-02.hhlab.home.arpa`).

## Required App Settings

1. Attach the service to the shared network:
   - `networks: [web]`
2. Do not bind host ports 80/443 in the app.
3. Add Traefik labels to the service.

## Example Compose Snippet

```yaml
services:
  myapp:
    image: myorg/myapp:latest
    container_name: myapp
    restart: unless-stopped
    networks:
      - web
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=web"
      - "traefik.http.routers.myapp.rule=Host(`myapp.rpi-box-02.hhlab.home.arpa`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls=true"
      - "traefik.http.services.myapp.loadbalancer.server.port=8080"

networks:
  web:
    external: true
```

## Ansible Role Pattern (Recommended)

- Create a role per app.
- Use `defaults/main.yml` for env-driven settings.
- Template a `docker-compose.yml` with the labels above.
- Deploy with `community.docker.docker_compose_v2`.

## Validation

- Confirm the router appears in Traefik (optional):
  `curl -s http://127.0.0.1:8080/api/http/routers | jq '.[].rule'`
- Confirm the app responds:
  `https://myapp.rpi-box-02.hhlab.home.arpa`

## Common Pitfalls

- Missing `traefik.docker.network` label.
- App not attached to the `web` network.
- Host ports 80/443 still mapped on the app container.
- DNS or certificate missing for the hostname.
