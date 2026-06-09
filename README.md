# Full-Stack Starter Template

A containerized full-stack starter: **React SPA + Spring Boot API + Keycloak (OIDC) + PostgreSQL**, fronted by a single **nginx gateway**. Everything runs with one `docker compose up`, and every service is reached through one origin so cookies, CORS, OIDC redirect URIs and the JWT issuer all line up.

> **Template, not a finished app.** `frontend/` and `backend/` ship **minimal booting skeletons** — a Spring Boot API exposing `/api/ping` + `/actuator/health`, and a React SPA that renders and reads its runtime config. The stack comes up green out of the box; you build your features on top (see [Adding your code](#adding-your-code)). The auth infrastructure, gateway, database and wiring are done for you — but app-level auth, roles, schema and payments are intentionally left for you to implement.
>
> Working with an AI agent on this template? See [`AGENTS.md`](AGENTS.md) for the conventions and the given-vs-task boundary.

---

## Architecture

```
                          ┌─────────────────────────────────────────┐
  browser  ──:8080──▶     │            nginx gateway                 │
                          │  /      → frontend (SPA static server)   │
                          │  /api/  → backend  (Spring Boot)         │
                          │  /auth/ → keycloak                        │
                          └─────────────────────────────────────────┘
                                  │            │             │
                            ┌─────▼────┐  ┌─────▼────┐  ┌─────▼──────┐
                            │ frontend │  │ backend  │  │  keycloak  │
                            │  nginx   │  │ (Java21) │  │   (26.6)   │
                            └──────────┘  └────┬─────┘  └─────┬──────┘
                                               │              │
                                         ┌─────▼────┐   ┌─────▼────┐
                                         │  app-db  │   │  kc-db   │
                                         │ Postgres │   │ Postgres │
                                         └──────────┘   └──────────┘
```

Everything is exposed through a single public origin (`APP_PUBLIC_BASE_URL`, default `http://localhost:8080`). The gateway is the only entry point; the application containers are not published to the host directly.

### Services

| Service     | Image / Build                              | Role                                                              |
|-------------|--------------------------------------------|-------------------------------------------------------------------|
| `gateway`   | `nginx:stable-alpine`                      | Reverse proxy / single public entrypoint (`:8080`). Routes only.  |
| `frontend`  | `frontend/Dockerfile` (Node 26 → nginx)    | Builds the SPA (Vite) and serves the static bundle.               |
| `backend`   | `backend/Dockerfile` (Maven/Java 21)       | Spring Boot 3 REST API; OAuth2 resource server (validates JWTs).  |
| `keycloak`  | `infra/keycloak/Dockerfile` (Keycloak 26.6)| Identity provider; realm + clients auto-imported on first boot.   |
| `app-db`    | `postgres:18.4`                            | Application database.                                             |
| `kc-db`     | `postgres:18.4`                            | Keycloak database (kept separate from app data).                  |

### Why two nginx instances?

They do different jobs and are **not** redundant:

- **`frontend` nginx** is a *static file server*: it serves the built SPA, does SPA fallback routing (`try_files … /index.html`), sets cache headers, and serves the runtime-generated `/config.js`.
- **`gateway` nginx** is a *router*: it serves no files and just proxies `/`, `/api/`, `/auth/` to the right service so the whole stack lives behind one origin.

### Networks

Traffic is segmented across three bridge networks so each database is only reachable by its owner:

- `app-net` — gateway ⇄ frontend, backend, keycloak
- `app-db-net` — backend ⇄ app-db
- `kc-db-net` — keycloak ⇄ kc-db

### Boot order

Healthchecks enforce startup ordering: `postgres → keycloak → backend → frontend → gateway`. First boot takes ~1 minute while Keycloak initializes and imports the realm.

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) with Docker Compose v2 (`docker compose`, not `docker-compose`)

---

## Getting started

```bash
# 1. Configure environment
cp .env.example .env        # then edit .env and replace every "change-me"

# 2. Build and start the whole stack
docker compose up -d --build

# 3. Watch it come up (wait for all services to be healthy)
docker compose ps
docker compose logs -f
```

Once healthy, open:

| What                | URL                                                |
|---------------------|----------------------------------------------------|
| App (frontend)      | http://localhost:8080                              |
| API                 | http://localhost:8080/api/                         |
| Keycloak console    | http://localhost:8080/auth/                        |
| OIDC discovery      | http://localhost:8080/auth/realms/<realm>/.well-known/openid-configuration |

To stop:

```bash
docker compose down           # stop & remove containers (keeps DB volumes)
docker compose down -v        # also delete database volumes (full reset)
```

### Dev container

The repo ships a `.devcontainer`, so any tool that supports dev containers (GitHub
Codespaces, VS Code's Dev Containers, etc.) gives a ready workspace with Docker
included and port `8080` forwarded. On creation it runs `.devcontainer/setup.sh`,
which creates `.env` — and if the environment serves the app at a forwarded HTTPS
URL instead of `localhost:8080`, it points `APP_PUBLIC_BASE_URL` at that URL (and
relaxes `KEYCLOAK_SSL_REQUIRED` for that dev environment) so Keycloak login works.
Then just:

```bash
docker compose up -d --build
```

and open the forwarded port (8080). Production keeps the strict defaults.

---

## Configuration

All configuration is environment-driven via `.env` (copied from `.env.example`). `.env` is gitignored — **never commit real secrets.**

| Variable                          | Description                                                        |
|-----------------------------------|--------------------------------------------------------------------|
| `APP_PUBLIC_BASE_URL`             | Public origin of the whole app. Local: `http://localhost:8080`. Production: `https://your-domain.com`. |
| `APP_DOMAIN`                      | *(production)* Domain Caddy provisions a TLS cert for.             |
| `ACME_EMAIL`                      | *(production)* Email for Let's Encrypt registration.              |
| `COMPOSE_PROJECT_NAME`            | *(optional)* Prefix for container/volume names.                    |
| `APP_DB_USER` / `_PASSWORD` / `_NAME` | Application Postgres credentials.                              |
| `KC_DB_USER` / `_PASSWORD` / `_NAME`  | Keycloak Postgres credentials.                                |
| `KC_BOOTSTRAP_ADMIN_USERNAME` / `_PASSWORD` | Keycloak admin console bootstrap user.                  |
| `KEYCLOAK_REALM`                  | Realm name (imported on first boot).                               |
| `KEYCLOAK_FRONTEND_CLIENT_ID`     | Public client used by the SPA.                                     |
| `KEYCLOAK_BACKEND_CLIENT_ID`      | Confidential client used by the backend.                           |
| `KEYCLOAK_BACKEND_CLIENT_SECRET`  | Secret for the backend client.                                     |
| `PAYMENTS_PROVIDER`               | *(optional)* `none` (default) or `stripe`.                         |
| `STRIPE_SECRET_KEY` / `_WEBHOOK_SECRET` / `_PUBLISHABLE_KEY` | *(optional)* Stripe keys when payments are enabled. |

---

## Authentication (Keycloak)

The realm and its clients are imported automatically from `infra/keycloak/import/realm-export.json` on first boot, with `${...}` placeholders substituted from your `.env`.

**Admin console:** http://localhost:8080/auth/ — log in with `KC_BOOTSTRAP_ADMIN_USERNAME` / `KC_BOOTSTRAP_ADMIN_PASSWORD`, then switch from the `master` realm to your `KEYCLOAK_REALM` via the top-left dropdown.

**Pre-configured clients:**

| Client                            | Type         | Flow                                  | Used by   |
|-----------------------------------|--------------|---------------------------------------|-----------|
| `KEYCLOAK_FRONTEND_CLIENT_ID`     | public       | Authorization Code (+ PKCE)           | SPA       |
| `KEYCLOAK_BACKEND_CLIENT_ID`      | confidential | Service account (client credentials)  | Backend   |

The backend runs as an **OAuth2 resource server**: it validates incoming JWTs against the issuer `APP_PUBLIC_BASE_URL/auth/realms/<realm>` and fetches signing keys from Keycloak over the internal network.

> **Note on `KC_HOSTNAME`.** It is set to `APP_PUBLIC_BASE_URL/auth` so that the relative path (`/auth`) is part of the base URL Keycloak advertises (issuer, redirects, admin console). The path here must match the served path, or browser redirects drop the `/auth` prefix and 404.

---

## Adding your code

This template provides the infrastructure and a minimal booting skeleton in each app; build your features on top of the existing source.

### Backend (`backend/`)

A minimal Spring Boot (Java 21, Maven) skeleton is provided and already boots:

```
backend/
├── Dockerfile        # provided (cached dep layer; runs as non-root)
├── pom.xml           # provided (web + actuator + jdbc + Flyway)
└── src/
    ├── main/java/... # provided: Application + a /api/ping controller
    └── main/resources/db/migration/   # empty — add Flyway scripts (V1__init.sql)
```

It builds with `mvn clean package` and runs the resulting `target/app.jar`. A DataSource and **Flyway** are wired: migrations under `src/main/resources/db/migration` run automatically on startup (none ship with the template). Extend the skeleton and wire your Spring Boot app to these environment variables (already passed by compose):

- `SPRING_DATASOURCE_URL` / `_USERNAME` / `_PASSWORD`
- `SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI` and `…_JWK_SET_URI`
- `KEYCLOAK_INTERNAL_BASE_URL`, `KEYCLOAK_BACKEND_CLIENT_ID` / `_SECRET`
- `CORS_ALLOWED_ORIGINS`
- Map your controllers under `/api` (the gateway routes `/api/` to the backend, preserving the prefix).

### Frontend (`frontend/`)

A minimal Vite + React + TypeScript skeleton is provided (outputs to `dist/`) and already renders:

```
frontend/
├── Dockerfile             # provided
├── nginx.conf             # provided (SPA routing + cache rules)
├── docker-entrypoint.sh   # provided (runtime config injection)
├── package.json           # provided (React 19 + Vite + Tailwind v4)
├── vite.config.ts         # provided (Tailwind plugin + "@" -> src alias)
├── tsconfig.json          # provided
├── index.html             # provided (loads /config.js)
└── src/
    ├── index.css          # Tailwind v4 entry
    └── App.tsx            # demo page (config + /api/ping)
```

Styling is preconfigured with **Tailwind CSS v4**. A design exported from Google Stitch brings its own Tailwind config and can be ported in directly. See [`PROMPTS.md`](PROMPTS.md) for the design → build workflow.

**Runtime config injection:** the container writes `/config.js` from environment variables at startup, so the same image works in any environment. To consume it:

1. Add `<script src="/config.js"></script>` to `index.html` `<head>` (before your app bundle).
2. Read values from `window.__ENV__`, e.g. `window.__ENV__.KEYCLOAK_REALM`.

Available keys: `APP_PUBLIC_BASE_URL`, `KEYCLOAK_REALM`, `KEYCLOAK_FRONTEND_CLIENT_ID`, `PAYMENTS_PROVIDER`, `STRIPE_PUBLISHABLE_KEY`.

---

## Project structure

```
.
├── docker-compose.yml          # the core stack (internal services)
├── docker-compose.override.yml # local dev host ports (auto-loaded)
├── docker-compose.prod.yml     # production: Caddy TLS edge (opt-in via -f)
├── .env.example                # configuration template (copy to .env)
├── .devcontainer/              # dev container (auto-configures .env per environment)
├── AGENTS.md                   # conventions for AI agents building on the template
├── PROMPTS.md                  # design (Stitch) + build prompts
├── design/                     # staging area: paste a design export here
│   ├── README.md
│   └── stitch-export.html

├── backend/                    # Spring Boot API (booting skeleton)
│   ├── Dockerfile
│   ├── pom.xml
│   ├── src/                    # Application + /api/ping
│   └── .dockerignore
├── frontend/                   # React SPA (booting skeleton)
│   ├── Dockerfile
│   ├── nginx.conf              # SPA static-serving config
│   ├── docker-entrypoint.sh    # runtime env → /config.js
│   ├── package.json
│   ├── vite.config.ts
│   ├── tsconfig.json
│   ├── index.html
│   ├── src/                    # App.tsx + main.tsx + env.d.ts
│   └── .dockerignore
└── infra/
    ├── nginx/
    │   └── default.conf        # gateway routing (/, /api/, /auth/)
    ├── caddy/
    │   └── Caddyfile           # production TLS edge (auto Let's Encrypt)
    └── keycloak/
        ├── Dockerfile          # optimized Keycloak build (relative path /auth)
        ├── docker-entrypoint.sh
        └── import/
            └── realm-export.json   # realm + clients (templated from .env)
```

---

## Common commands

```bash
docker compose up -d --build           # build + start everything
docker compose ps                      # status / health
docker compose logs -f <service>       # tail logs (e.g. keycloak, gateway)
docker compose restart gateway         # restart gateway (see note below)
docker compose up -d --build backend   # rebuild & restart a single service
docker compose down -v                 # stop and wipe DB volumes (clean slate)
```

**Host ports:** `8080` → gateway (the app), `5432` → app-db, `5433` → kc-db.

> **Gateway upstreams:** nginx resolves service names once at startup. If you recreate a backing container (e.g. `keycloak`) and it gets a new IP, restart the gateway too: `docker compose restart gateway`.

---

## Deploying to production

The repo ships two compose layers so the same stack runs locally over HTTP and in production over HTTPS, with no architectural changes:

| File | Loaded when | Adds |
|------|-------------|------|
| `docker-compose.yml`          | always                         | the core stack (internal only) |
| `docker-compose.override.yml` | local `docker compose up`      | dev host ports (`8080`, `5432`, `5433`) |
| `docker-compose.prod.yml`     | only with explicit `-f`        | a **Caddy** TLS edge (ports `80`/`443`) with automatic Let's Encrypt certs |

In production the gateway and databases are **not** published to the host — only Caddy is public.

### Steps on the server

1. Point your domain's DNS **A/AAAA record** at the server, and open ports **80** and **443**.
2. `cp .env.example .env` and set:
   - `APP_DOMAIN=your-domain.com`
   - `ACME_EMAIL=you@example.com`
   - `APP_PUBLIC_BASE_URL=https://your-domain.com` *(no port)*
   - strong, non-default values for **every** `change-me` secret (DB passwords, Keycloak DB, `KC_BOOTSTRAP_ADMIN_PASSWORD`, backend client secret).
3. Deploy:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

Caddy obtains and renews the TLS certificate automatically and forwards to the internal gateway; Keycloak issues tokens/redirects on the `https://` origin. First boot waits on the ACME challenge — make sure DNS resolves before starting.

### Still your responsibility

The deployment path is provided, but for a hardened, long-lived service also consider: off-host database backups, container resource limits, monitoring/alerting, a multi-node Keycloak if you need HA, and an app-specific `Content-Security-Policy` (left out because it depends on your app).

## License

Released under the [MIT License](LICENSE). © 2026 Ivan Ivanoski
