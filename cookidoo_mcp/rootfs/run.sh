#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

export COOKIDOO_EMAIL="$(bashio::config 'cookidoo_email')"
export COOKIDOO_PASSWORD="$(bashio::config 'cookidoo_password')"
export COOKIDOO_COUNTRY="$(bashio::config 'cookidoo_country')"
export COOKIDOO_LANGUAGE="$(bashio::config 'cookidoo_language')"
export COOKIDOO_QUALITY_BAR="$(bashio::config 'quality_bar')"
export ADDON_PORT=8001

if [ -z "${COOKIDOO_EMAIL}" ] || [ -z "${COOKIDOO_PASSWORD}" ]; then
    bashio::exit.nok "Bitte Cookidoo-E-Mail und -Passwort in der Konfiguration eintragen."
fi

# Geheimer Pfad: einmal erzeugen, in /data behalten, damit die Connector-URL gleich bleibt
if [ ! -s /data/path_secret ]; then
    head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > /data/path_secret
    chmod 600 /data/path_secret
fi
export ADDON_PATH_SECRET="$(cat /data/path_secret)"

# Eigener Tailscale-Knoten im Userspace-Modus, nur für die Funnel-Freigabe dieses Add-ons
mkdir -p /data/tailscale /var/run/tailscale
tailscaled --tun=userspace-networking \
    --statedir=/data/tailscale \
    --socket=/var/run/tailscale/tailscaled.sock \
    --port=0 >/dev/null 2>&1 &

for _ in $(seq 1 30); do
    [ -S /var/run/tailscale/tailscaled.sock ] && break
    sleep 1
done

TS_HOSTNAME="$(bashio::config 'tailscale_hostname')"
UP_ARGS=(--hostname="${TS_HOSTNAME}" --accept-dns=false --timeout=0)
if bashio::config.has_value 'tailscale_authkey'; then
    UP_ARGS+=(--auth-key="$(bashio::config 'tailscale_authkey')")
fi

if ! tailscale status >/dev/null 2>&1; then
    bashio::log.info "Tailscale-Anmeldung nötig. Den folgenden Link im Browser öffnen:"
fi
tailscale up "${UP_ARGS[@]}"

TS_DNS="$(tailscale status --json | python3 -c 'import json,sys; print(json.load(sys.stdin)["Self"]["DNSName"].rstrip("."))')"

# Öffentlich über Funnel, nur Port 443 auf den lokalen Server
if ! tailscale funnel --bg 8001; then
    bashio::log.error "Funnel ließ sich nicht aktivieren. Im Tailscale-Admin unter DNS die HTTPS-Zertifikate einschalten und Funnel für diesen Knoten erlauben, dann das Add-on neu starten."
fi

bashio::log.info "-----------------------------------------------------------"
bashio::log.info "Connector-URL für Claude (geheim halten, wie ein Passwort):"
bashio::log.info "https://${TS_DNS}/${ADDON_PATH_SECRET}/mcp"
bashio::log.info "-----------------------------------------------------------"

exec python3 /addon_server.py
