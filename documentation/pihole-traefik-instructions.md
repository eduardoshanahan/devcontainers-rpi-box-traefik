# Pi-hole + Traefik (Docker) Integration Notes

These notes are for the Pi-hole team to enable HTTPS via Traefik when Traefik
is present on the host.

Note: This repository does not deploy or manage Pi-hole/DNS. These are external
integration notes for running Pi-hole behind Traefik on the same Docker host.

## Goals

- Keep Pi-hole DNS services unchanged.
- Expose the Pi-hole web UI through Traefik using HTTPS.
- Avoid binding ports 80/443 directly on the Pi-hole container.

## Requirements

- Traefik is running on the host and bound to ports 80/443.
- Pi-hole container joins the same external Docker network as Traefik
  (default: `web`).
- DNS record exists for the Pi-hole UI hostname, for example:
  `pihole.rpi-box-02.hhlab.home.arpa -> <pi-ip>`.

## Compose Changes (Example)

Key changes:

- Remove direct 80/443 host port bindings.
- Keep DNS ports (53/67/547) as needed.
- Add Traefik labels for routing.

```yaml
services:
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    restart: unless-stopped
    networks:
      - web
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "67:67/udp"  # DHCP (optional)
      - "547:547/udp" # DHCPv6 (optional)
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=web"
      - "traefik.http.routers.pihole.rule=Host(`pihole.rpi-box-02.hhlab.home.arpa`)"
      - "traefik.http.routers.pihole.entrypoints=websecure"
      - "traefik.http.routers.pihole.tls=true"
      - "traefik.http.services.pihole.loadbalancer.server.port=80"

networks:
  web:
    external: true
```

## Notes

- The UI is still under `/admin/` (Traefik routes the hostname only).
- If Traefik is not present, you can temporarily map `8081:80` (and/or
  `8443:443`) to access the UI directly, but remove those bindings once
  Traefik is enabled.
- The Pi-hole container should not bind ports 80/443 on the host while Traefik
  is running.

## UniFi DNS Notes

If you use a UniFi gateway (UCG Max) and Pi-hole for local DNS, ensure clients are
actually using the Pi-holes as resolvers (not the gateway IP), and that both Pi-holes
have the same local records. See `documentation/unifi-ucg-pihole-dns-notes.md`.
