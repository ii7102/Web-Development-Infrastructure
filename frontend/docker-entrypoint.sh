#!/bin/sh
# Runtime environment injection for the SPA.
#
# A static build bakes values in at build time, but this image is environment-
# agnostic: it reads the env vars passed by docker-compose at *container start*
# and writes them to /config.js, which the SPA loads BEFORE its own bundle.
#
# To consume this in your frontend app:
#   1. Add  <script src="/config.js"></script>  to index.html <head>
#      (before the app bundle is loaded).
#   2. Read values from window.__ENV__, e.g. window.__ENV__.KEYCLOAK_REALM.
#
# This script lives in /docker-entrypoint.d/, which the official nginx image
# runs automatically before starting nginx -- so it must NOT start nginx itself.
set -eu

: "${APP_PUBLIC_BASE_URL:=}"
: "${KEYCLOAK_REALM:=}"
: "${KEYCLOAK_FRONTEND_CLIENT_ID:=}"
: "${PAYMENTS_PROVIDER:=none}"
: "${STRIPE_PUBLISHABLE_KEY:=}"

cat > /usr/share/nginx/html/config.js <<EOF
window.__ENV__ = {
  APP_PUBLIC_BASE_URL: "${APP_PUBLIC_BASE_URL}",
  KEYCLOAK_REALM: "${KEYCLOAK_REALM}",
  KEYCLOAK_FRONTEND_CLIENT_ID: "${KEYCLOAK_FRONTEND_CLIENT_ID}",
  PAYMENTS_PROVIDER: "${PAYMENTS_PROVIDER}",
  STRIPE_PUBLISHABLE_KEY: "${STRIPE_PUBLISHABLE_KEY}"
};
EOF
