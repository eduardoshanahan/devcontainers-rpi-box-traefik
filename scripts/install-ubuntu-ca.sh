#!/usr/bin/env bash

set -euo pipefail

# Optional behavior:
# - Set INSTALL_NSS=true to also import the CA into the current user's NSS DB (Firefox/Chromium).
#   Default: INSTALL_NSS=false

if [ "${EUID}" -ne 0 ]; then
    echo "This script must run as root. Try: sudo $0 [ca-host ...]" >&2
    exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
default_hosts_file="${script_dir}/ca-hosts.txt"

if [ $# -gt 0 ]; then
    ca_hosts=("$@")
elif [ -f "$default_hosts_file" ]; then
    mapfile -t ca_hosts < <(grep -E '^[^#[:space:]]' "$default_hosts_file")
    if [ "${#ca_hosts[@]}" -eq 0 ]; then
        echo "No CA hosts found in ${default_hosts_file}." >&2
        exit 1
    fi
else
    echo "No CA hosts provided and ${default_hosts_file} is missing." >&2
    exit 1
fi

install_dir="/usr/local/share/ca-certificates/rpi-ca"
mkdir -p "$install_dir"
rm -f "${install_dir}/"*.crt

for host in "${ca_hosts[@]}"; do
    filename="rootCA-${host}.pem"
    url="https://${host}/${filename}"
    dest="${install_dir}/ca-${host}.crt"
    echo "Downloading ${url}"
    curl -fsSLk -o "$dest" "$url"
done

if [ "${#ca_hosts[@]}" -gt 1 ]; then
    first_ca="${install_dir}/ca-${ca_hosts[0]}.crt"
    for host in "${ca_hosts[@]:1}"; do
        next_ca="${install_dir}/ca-${host}.crt"
        if [ -f "$next_ca" ] && cmp -s "$first_ca" "$next_ca"; then
            rm -f "$next_ca"
        fi
    done
fi

first_ca=""
for host in "${ca_hosts[@]}"; do
    candidate="${install_dir}/ca-${host}.crt"
    if [ -f "$candidate" ]; then
        first_ca="$candidate"
        break
    fi
done

echo "Updating CA trust store (fresh rebuild)"
update-ca-certificates --fresh

echo "Verifying endpoints against installed CA"
verify_failed=0
for host in "${ca_hosts[@]}"; do
    ca_file="${install_dir}/ca-${host}.crt"
    if [ ! -f "$ca_file" ] && [ -n "$first_ca" ]; then
        ca_file="$first_ca"
    fi
    if [ ! -f "$ca_file" ]; then
        echo "CA file missing for ${host}, skipping verify." >&2
        verify_failed=1
        continue
    fi
    cert_tmp="$(mktemp)"
    if ! openssl s_client -connect "${host}:443" -servername "${host}" </dev/null \
        | openssl x509 -out "$cert_tmp" >/dev/null 2>&1; then
        echo "Failed to fetch certificate for ${host}." >&2
        rm -f "$cert_tmp"
        verify_failed=1
        continue
    fi
    if ! openssl verify -CAfile "$ca_file" "$cert_tmp" >/dev/null 2>&1; then
        issuer_fp="$(openssl x509 -in "$cert_tmp" -noout -issuer -fingerprint 2>/dev/null || true)"
        ca_fp="$(openssl x509 -in "$ca_file" -noout -subject -fingerprint 2>/dev/null || true)"
        echo "Certificate verification failed for ${host}." >&2
        echo "Server issuer: ${issuer_fp}" >&2
        echo "Installed CA: ${ca_fp}" >&2
        rm -f "$cert_tmp"
        verify_failed=1
        continue
    fi
    rm -f "$cert_tmp"
done

if [ "$verify_failed" -ne 0 ]; then
    echo "One or more certificate verifications failed." >&2
    exit 1
fi

if [ "${INSTALL_NSS:-false}" = "true" ]; then
    if command -v certutil >/dev/null 2>&1; then
        nss_user="${SUDO_USER:-$USER}"
        nss_home="$(getent passwd "$nss_user" | cut -d: -f6)"
        nss_db="sql:${nss_home}/.pki/nssdb"
        nss_ca="$first_ca"
        if [ -z "$nss_ca" ] || [ ! -f "$nss_ca" ]; then
            nss_ca="${install_dir}/ca-${ca_hosts[0]}.crt"
        fi
        if [ -f "$nss_ca" ]; then
            echo "Importing CA into NSS database (${nss_db})"
            if [ ! -d "${nss_home}/.pki/nssdb" ]; then
                mkdir -p "${nss_home}/.pki/nssdb"
                chown -R "$nss_user":"$nss_user" "${nss_home}/.pki"
            fi
            if ! su - "$nss_user" -c "certutil -d \"$nss_db\" -L >/dev/null 2>&1"; then
                su - "$nss_user" -c "certutil -d \"$nss_db\" -N --empty-password"
            fi
            su - "$nss_user" -c "certutil -d \"$nss_db\" -A -t \"C,,\" -n \"rpi-box-ca\" -i \"$nss_ca\""
        else
            echo "NSS import skipped; CA file not found." >&2
        fi
    else
        echo "NSS import skipped; certutil not installed (install libnss3-tools)." >&2
    fi
fi
