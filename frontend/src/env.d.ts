/// <reference types="vite/client" />

// Runtime config injected at container start into /config.js (see
// frontend/docker-entrypoint.sh). Read values from window.__ENV__.
interface AppEnv {
  APP_PUBLIC_BASE_URL: string;
  KEYCLOAK_REALM: string;
  KEYCLOAK_FRONTEND_CLIENT_ID: string;
  PAYMENTS_PROVIDER: string;
  STRIPE_PUBLISHABLE_KEY: string;
}

interface Window {
  __ENV__?: Partial<AppEnv>;
}
