#!/usr/bin/env bash
# Prepares .env for the current dev environment.
#
# Some environments serve the app at a forwarded/proxied HTTPS URL instead of
# http://localhost:8080. Keycloak's issuer, redirect URIs and CORS all follow
# APP_PUBLIC_BASE_URL, so it must match the URL the browser actually uses or login
# breaks. This script auto-detects that case and points APP_PUBLIC_BASE_URL at it;
# run on a normal localhost setup it just keeps the defaults.
set -euo pipefail

# Repo root (this script lives in .devcontainer/).
cd "$(dirname "$0")/.."

# Create .env from the template on first run.
if [ ! -f .env ]; then
  cp .env.example .env
fi

set_var() {
  local key="$1" val="$2"
  if grep -q "^${key}=" .env; then
    sed -i "s|^${key}=.*|${key}=${val}|" .env
  else
    printf '%s=%s\n' "$key" "$val" >> .env
  fi
}

# Auto-detect a forwarded-URL dev environment. (GitHub Codespaces exposes these
# variables; with other tools that serve a forwarded URL, set APP_PUBLIC_BASE_URL
# in .env manually instead.)
if [ -n "${CODESPACE_NAME:-}" ]; then
  URL="https://${CODESPACE_NAME}-8080.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
  echo "Forwarded dev environment detected — configuring the app for: $URL"

  # Public origin the browser uses (drives Keycloak issuer / redirects / CORS).
  set_var APP_PUBLIC_BASE_URL "$URL"

  # The forwarding tunnel terminates TLS upstream, so internally the gateway sees
  # plain HTTP. Relax Keycloak's SSL requirement for THIS dev environment only;
  # production keeps the strict "external" default.
  set_var KEYCLOAK_SSL_REQUIRED none

  echo "Configured. Start the stack with:  docker compose up -d --build"
else
  echo "Local environment — keeping .env defaults (http://localhost:8080)."
fi
