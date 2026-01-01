# CA Share Endpoint (Root CA Download)

This endpoint serves the mkcert root CA (`rootCA.pem`) so client devices can
install it and trust HTTPS for Traefik-hosted apps.

## Enable the Endpoint

1. In `.env`, set:

```
CA_SHARE_ENABLED=true
```

2. In the host vars for the target (e.g. `src/inventory/host_vars/rpi_box_02.yml`), set:

```
ca_share_host: "ca.rpi-box-02.hhlab.home.arpa"
```

3. Ensure DNS points `ca.rpi-box-02.hhlab.home.arpa` to the Traefik host IP.

4. Run the playbook:

```
ansible-playbook src/playbooks/pi-apps.yml -l rpi_box_02
```

The CA file will be available at:

```
https://ca.rpi-box-02.hhlab.home.arpa/rootCA-ca.rpi-box-02.hhlab.home.arpa.pem
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

1. Download the CA file:

```
curl -k -O https://ca.rpi-box-02.hhlab.home.arpa/rootCA-ca.rpi-box-02.hhlab.home.arpa.pem
```

2. Install into the system trust store:

```
sudo cp rootCA-ca.rpi-box-02.hhlab.home.arpa.pem /usr/local/share/ca-certificates/mkcert-rootCA.crt
sudo update-ca-certificates
```

3. Restart the browser and test:
`https://whoami.rpi-box-02.hhlab.home.arpa`

Note: Firefox may need manual import or “Use system certificates” enabled.

## Windows Client Install

1. Download the CA file from the endpoint.

2. Open an elevated PowerShell and run:

```
certutil -addstore -f "Root" rootCA-ca.rpi-box-02.hhlab.home.arpa.pem
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
