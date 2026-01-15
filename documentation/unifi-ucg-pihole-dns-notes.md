# UniFi UCG Max + Pi-hole DNS Notes

This is a short reference for the UniFi UCG Max + dual Pi-hole DNS setup used by this project.

## Symptoms

- Queries work when sent directly to Pi-hole primary, but fail via the gateway:
  - `dig @192.168.1.58 whoami.rpi-box-03.hhlab.home.arpa +short` → `192.168.1.10`
  - `dig @192.168.1.1 whoami.rpi-box-03.hhlab.home.arpa +short` → empty, with status `NXDOMAIN`

## Meaning of `NXDOMAIN`

`NXDOMAIN` means “this name does not exist” (the resolver is returning a negative answer, not timing out).

If `192.168.1.1` returns `NXDOMAIN` for `*.hhlab.home.arpa`, it means the gateway’s DNS service is not answering that zone (and is not forwarding it to Pi-hole in that path).

## Common UniFi “gotcha”

In UniFi, there is an important distinction:

- **Gateway/WAN DNS settings**: what the gateway uses for its own lookups.
- **LAN DHCP DNS settings**: what DHCP hands out to clients.

Even if the UCG UI shows Pi-hole IPs, a client can still end up querying `192.168.1.1` if:

- the client is statically configured (netplan) to use `192.168.1.1`, or
- DHCP DNS is not actually set for that network/VLAN, or
- the secondary Pi-hole doesn’t have the records and a client chooses it.

## Checks

On a client/box:

- Resolver configuration:
  - `resolvectl status`
  - `cat /etc/resolv.conf`
- Validate each DNS server:
  - `dig @192.168.1.58 whoami.rpi-box-03.hhlab.home.arpa +short`
  - `dig @192.168.1.59 whoami.rpi-box-03.hhlab.home.arpa +short`
  - `dig @192.168.1.1  whoami.rpi-box-03.hhlab.home.arpa +short`

## Recommended steady state

- Clients use Pi-hole primary + secondary as DNS servers (via DHCP or static config).
- Both Pi-holes have the same local DNS records (manual duplication or a sync mechanism).
- Once target-side DNS is correct, this repo can use `NAME_RESOLUTION_MODE=dns` with `DNS_PREFLIGHT_CHECK=both`.

