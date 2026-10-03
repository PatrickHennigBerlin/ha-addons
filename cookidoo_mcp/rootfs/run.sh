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

export ADDON_AUTH="$(bashio::config 'auth')"
export FASTMCP_HOME=/data/fastmcp

# Zufallswerte einmal erzeugen und in /data behalten
new_secret() {
    if [ ! -s "$1" ]; then
        head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$1"
        chmod 600 "$1"
    fi
    cat "$1"
}
rm -f /data/path_secret  # alter Pfad aus 0.1.0, stand im Chat
export ADDON_PATH_SECRET="$(new_secret /data/path_secret_v2)"
export ADDON_JWT_KEY="$(new_secret /data/jwt_key)"

if [ "${ADDON_AUTH}" = "github" ]; then
    export ADDON_GITHUB_CLIENT_ID="$(bashio::config 'github_client_id')"
    export ADDON_GITHUB_CLIENT_SECRET="$(bashio::config 'github_client_secret')"
    export ADDON_ALLOWED_GITHUB_USERS="$(bashio::config 'allowed_github_users')"
fi

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
export ADDON_PUBLIC_URL="https://${TS_DNS}"

if [ "${ADDON_AUTH}" = "github" ] && { [ -z "${ADDON_GITHUB_CLIENT_ID}" ] || [ -z "${ADDON_GITHUB_CLIENT_SECRET}" ]; }; then
    bashio::log.warning "GitHub-Login ist gewählt, aber Client-ID oder Secret fehlen."
    bashio::log.warning "Lege auf github.com unter Settings → Developer settings → OAuth Apps eine App an:"
    bashio::log.warning "  Homepage URL:               ${ADDON_PUBLIC_URL}"
    bashio::log.warning "  Authorization callback URL: ${ADDON_PUBLIC_URL}/auth/callback"
    bashio::exit.nok "Danach Client-ID und Secret in der Konfiguration eintragen und neu starten."
fi

# Öffentlich über Funnel, nur Port 443 auf den lokalen Server
if ! tailscale funnel --bg 8001; then
    bashio::log.error "Funnel ließ sich nicht aktivieren. Im Tailscale-Admin unter DNS die HTTPS-Zertifikate einschalten und Funnel für diesen Knoten erlauben, dann das Add-on neu starten."
fi

bashio::log.info "-----------------------------------------------------------"
if [ "${ADDON_AUTH}" = "github" ]; then
    bashio::log.info "Connector-URL für Claude (Login mit GitHub, erlaubt: ${ADDON_ALLOWED_GITHUB_USERS}):"
    bashio::log.info "${ADDON_PUBLIC_URL}/mcp"
else
    bashio::log.info "Connector-URL für Claude (ohne Login, geheim halten wie ein Passwort):"
    bashio::log.info "${ADDON_PUBLIC_URL}/${ADDON_PATH_SECRET}/mcp"
fi
bashio::log.info "-----------------------------------------------------------"

exec python3 /addon_server.py
