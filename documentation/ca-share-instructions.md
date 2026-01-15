# CA Share Endpoint (Root CA Download)

This endpoint serves the mkcert root CA (`rootCA.pem`) so client devices can
install it and trust HTTPS for Traefik-hosted apps.

## Enable the Endpoint

1. In `.env`, set:

```
CA_SHARE_ENABLED=true
```

2. Ensure name resolution exists for the CA host:
   - In `NAME_RESOLUTION_MODE=hosts`: use the generated `/etc/hosts` snippet (dns_preflight prints it).
   - In `NAME_RESOLUTION_MODE=dns`: ensure DNS points `ca.<box>.<SITE_DOMAIN>` to the Traefik host IP.

3. Optional: override `ca_share_host` in host_vars for edge cases. By default it is derived as `ca.<box_name>.<SITE_DOMAIN>`.

4. Run the playbook:

```
ansible-playbook src/playbooks/pi-edge.yml -l rpi_box_02
```

The CA file will be available at:

```
https://ca.rpi-box-02.hhlab.home.arpa/rootCA.pem
```

Note: The CA file is exported by the Traefik role into
`TRAEFIK_LOCAL_CERT_DIR/rootCA.pem` and then copied to the target.

If the mkcert CA changes, re-run the playbook. It will re-issue the Traefik
certificate and restart Traefik automatically. Clients must install the new CA.

## Ubuntu Client Install

If you want to automate this step, run:

```
sudo ./scripts/install-ubuntu-ca.sh
```

The script reads CA hostnames from `scripts/ca-hosts.txt` by default (one per line) and downloads
`https://<ca-host>/rootCA.pem` from each host, so each box must have CA share deployed.

1. Download the CA file:

```
curl -k -O https://ca.rpi-box-02.hhlab.home.arpa/rootCA.pem
```

2. Install into the system trust store:

```
sudo cp rootCA.pem /usr/local/share/ca-certificates/mkcert-rootCA.crt
sudo update-ca-certificates
```

3. Restart the browser and test:
`https://whoami.rpi-box-02.hhlab.home.arpa`

Note: Firefox may need manual import or “Use system certificates” enabled.

## Windows Client Install

1. Download the CA file from the endpoint.

2. Open an elevated PowerShell and run:

```
certutil -addstore -f "Root" rootCA.pem
```

3. Close and reopen the browser, then test:
`https://whoami.rpi-box-02.hhlab.home.arpa`

## Android Client Install

1. Download the CA file from the endpoint.

2. Open Settings → Security → Encryption & credentials → Install a certificate → CA certificate.

3. Select the downloaded file and confirm.

Note: User-installed CAs are trusted by browsers, but many apps do not trust
user CAs by default.

## Security Notes

- The endpoint should only be reachable on your LAN.
- It exposes only the public root CA file (no private keys).
