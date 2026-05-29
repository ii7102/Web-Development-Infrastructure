#!/bin/bash
# Substitute env placeholders into the realm import file.
# We use bash parameter expansion: literal, no escaping needed
# for slashes/&/etc. in values, and only the listed placeholders are touched.
set -euo pipefail

content=$(cat /opt/keycloak/data/import-template/realm-export.json)
content=${content//'${KEYCLOAK_REALM}'/$KEYCLOAK_REALM}
content=${content//'${KEYCLOAK_BACKEND_CLIENT_ID}'/$KEYCLOAK_BACKEND_CLIENT_ID}
content=${content//'${KEYCLOAK_BACKEND_CLIENT_SECRET}'/$KEYCLOAK_BACKEND_CLIENT_SECRET}
content=${content//'${KEYCLOAK_FRONTEND_CLIENT_ID}'/$KEYCLOAK_FRONTEND_CLIENT_ID}
content=${content//'${APP_PUBLIC_BASE_URL}'/$APP_PUBLIC_BASE_URL}
printf '%s' "$content" > /opt/keycloak/data/import/realm-export.json

exec /opt/keycloak/bin/kc.sh "$@"
