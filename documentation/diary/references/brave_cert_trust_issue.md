# Brave Certificate Trust Issue (Box 03)

## Summary

Brave continued to show `ERR_CERT_AUTHORITY_INVALID` for Box 03 endpoints even
after the CA was installed via the helper script. OpenSSL verification succeeded,
and the served certificate matched the mkcert CA, so the issue was isolated to
Brave's trust store behavior.

## Symptoms

- `whoami.rpi-box-03.hhlab.home.arpa` showed "Your connection is not private" in Brave.
- OpenSSL verification against the installed CA succeeded.
- Brave only trusted the cert after manual import into the browser.

## Root Cause

Brave did not honor the system or NSS trust store for this profile. It required
manual CA import into Brave's Authorities store (or enabling system trust via
flags).

## What We Checked

1. Verified mkcert CA on the controller:
   - `mkcert -CAROOT`
   - `/workspace/certs/rootCA.pem` fingerprint matched mkcert CA.
2. Verified the target cert on Box 03 and ensured Traefik served a cert signed by
   the local mkcert CA.
3. Verified CA presence on the host system:
   - `/usr/local/share/ca-certificates/rpi-ca/ca-ca.rpi-box-03.hhlab.home.arpa.crt`
4. Verified NSS database:
   - `certutil -L -d sql:$HOME/.pki/nssdb` showed `rpi-box-ca`.
5. Verified the server chain with OpenSSL:
   - `openssl s_client ... | openssl verify -CAfile ...` returned OK.

## What Resolved It

Manual import into Brave:

1. Open `brave://settings/certificates`
2. Authorities → Import
3. Select `/usr/local/share/ca-certificates/rpi-ca/ca-ca.rpi-box-03.hhlab.home.arpa.crt`
4. Trust for identifying websites
5. Restart Brave

If available, enabling "Use system certificate store" in `brave://flags` also
helps avoid manual imports.
