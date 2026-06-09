# Agent guide

Read this before changing anything. This repo is a **full-stack starter template**
that is already wired for infrastructure. Your job is to build application
features **on top of it** — not to re-architect the infrastructure.

## The golden rule: one origin

Everything is served from a single public origin: the **nginx gateway** at
`APP_PUBLIC_BASE_URL` (default `http://localhost:8080`). The gateway routes:

| Path     | Goes to            |
|----------|--------------------|
| `/`      | frontend (the SPA) |
| `/api/`  | backend            |
| `/auth/` | keycloak           |

Because everything is one origin, **there is no cross-origin problem**: cookies,
CORS, OIDC redirects and the JWT issuer all already line up. Do **not** add CORS
config, do **not** call services on other ports, and do **not** expose new public
ports. If you find yourself fighting CORS, you are doing it wrong — route through
the gateway instead.

## What is GIVEN (do not rebuild)

- **Gateway routing** — `infra/nginx/default.conf`.
- **Keycloak** identity provider + an imported realm with a **frontend (public)**
  client and a **backend (confidential)** client — `infra/keycloak/`.
- **Two PostgreSQL databases** — one for the app, one for Keycloak.
- **Docker wiring, healthchecks and boot order** — `docker-compose.yml`.
- **Runtime config injection** for the frontend (see below).
- **A DataSource + Flyway** wired in the backend (connection is given; **schema is
  the task** — ship no scripts until you add them).
- **Minimal booting skeletons** for backend and frontend so the stack comes up
  green before you write any feature code.
- **Deployment**: a production compose overlay with a **Caddy TLS edge** (automatic
  HTTPS). Don't hand-roll TLS or a second proxy — use the overlay (see "Running it").

## What is the TASK (you implement)

These are intentionally **not** done for you:

- **Auth integration in the app.** Keycloak runs and the realm/clients exist, but
  the app is not secured yet. Implement login in the SPA and JWT validation in the
  backend.
- **Roles & authorization.** The realm ships with **no application roles**. Define
  whatever role model the task needs (e.g. `guest` / `user` / `admin`), assign
  them, and enforce them in both backend and frontend.
- **Database schema & data access.** The DataSource and Flyway are wired, but the
  schema is empty. Add migrations under `backend/src/main/resources/db/migration`
  (`V1__init.sql`, `V2__...`) — they run automatically on startup. Pick your own
  data-access layer (JPA, JdbcTemplate, jOOQ) on top of the existing DataSource.
- **Payments** (if the task requires it). Only env-var plumbing is provided.
- **The actual pages, dashboards and business logic.**

## Do NOT change the infrastructure

The infrastructure is proven and working. Build your features **on top of it**;
do not modify, "improve", or re-architect it. Treat these as read-only:

- `docker-compose.yml`, `docker-compose.override.yml`, `docker-compose.prod.yml`
  (services, networks, ports, healthchecks, boot order, volumes).
- `infra/nginx/default.conf` (gateway routing), `infra/caddy/Caddyfile` (TLS edge).
- `infra/keycloak/**` — the Dockerfile, entrypoint, and the realm import's clients,
  scopes, mappers and flows.
- `frontend/Dockerfile`, `frontend/nginx.conf`, `frontend/docker-entrypoint.sh`,
  `backend/Dockerfile`, and the runtime config-injection mechanism.

**The only allowed changes outside `frontend/src` and `backend/src` are these
additive extension points:**

- `backend/pom.xml` — add dependencies you need (e.g. resource-server, JPA).
- `backend/src/main/resources/db/migration/` — add Flyway SQL migrations.
- `infra/keycloak/import/realm-export.json` — add application **roles** only, and
  only when the project idea needs them (see "Keycloak / realm").
- A new runtime/config value — add it additively in the documented places
  (`.env.example`, the `frontend/docker-entrypoint.sh` heredoc, `src/env.d.ts`, and
  the relevant `environment:` passthrough in `docker-compose.yml`) **without**
  changing existing services, routing, or wiring.

If a task seems to require an infrastructure change beyond these, stop and flag it
rather than re-architecting.

## Where code goes

```
backend/   Spring Boot app (Java 21, Maven). Entry: com.example.app.Application
frontend/  Vite + React + TypeScript SPA. Source in frontend/src/
infra/     Gateway + Keycloak config — read-only (see "Do NOT change the infrastructure").
```

### Backend conventions

- Map all HTTP endpoints under **`/api`** (the gateway forwards `/api/` here with
  the prefix preserved). Example: `frontend/src` calls `GET /api/ping` and the
  controller is `@RequestMapping("/api") @GetMapping("/ping")`.
- `GET /actuator/health` must stay reachable — the compose healthcheck depends on
  it. If you add Spring Security, **explicitly permit `/actuator/health`** or the
  backend container will be marked unhealthy and the gateway won't start.
- These env vars are already passed by compose (use them, don't hardcode):
  - `SPRING_DATASOURCE_URL` / `SPRING_DATASOURCE_USERNAME` / `SPRING_DATASOURCE_PASSWORD`
  - `SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI`
  - `SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK_SET_URI`
  - `KEYCLOAK_INTERNAL_BASE_URL`, `KEYCLOAK_BACKEND_CLIENT_ID`, `KEYCLOAK_BACKEND_CLIENT_SECRET`
- For JWT auth, add `spring-boot-starter-oauth2-resource-server`; the issuer/JWK
  env vars above are already correct (issuer is the public URL, keys are fetched
  over the internal Docker network).
- The build produces `target/app.jar`. Keep `<finalName>app</finalName>` in
  `pom.xml` so the Dockerfile's `COPY target/*.jar` keeps working.

### Frontend conventions

- Read runtime config from **`window.__ENV__`** (typed in `src/env.d.ts`), never
  from build-time `import.meta.env` for deploy-specific values. Available keys:
  `APP_PUBLIC_BASE_URL`, `KEYCLOAK_REALM`, `KEYCLOAK_FRONTEND_CLIENT_ID`,
  `PAYMENTS_PROVIDER`, `STRIPE_PUBLISHABLE_KEY`.
- Call the API with **relative paths** (`fetch("/api/...")`). Same origin — no
  base URL, no CORS.
- For Keycloak login, use the public client id `window.__ENV__.KEYCLOAK_FRONTEND_CLIENT_ID`
  and realm `window.__ENV__.KEYCLOAK_REALM`; the OIDC authority is
  `${APP_PUBLIC_BASE_URL}/auth/realms/${KEYCLOAK_REALM}`. Authorization Code +
  PKCE is the expected flow (the client is already configured for it).
- The build must output to `dist/` (Vite default) — the Dockerfile serves that.
- If you add a new runtime config key, add it in three places: `.env.example`,
  the `frontend/docker-entrypoint.sh` heredoc, and `src/env.d.ts`.
- **Styling is Tailwind CSS v4** (set up and ready); the `@` alias maps to `src/`.
  A Stitch design brings its own Tailwind config/styling, which you use directly
  (see "Consuming a design"). shadcn/ui is NOT preinstalled — add it only if you
  want it (`npx shadcn@latest init`). Keep API calls relative (`/api/...`).

### Consuming a design (Stitch "React App" export)

A Stitch "React App" export is pasted into `design/stitch-export.html` (a staging
file — not built or served). It's a standalone HTML prototype: CDN Tailwind +
inline `tailwind.config`, UMD React + babel-standalone, `MemoryRouter`, `class=`
attributes, Material Symbols font. When asked to build from it, convert it into the
app like this:

1. Drop the CDN `<script>` tags (Tailwind CDN, React/ReactDOM/Router UMD,
   babel-standalone) and the in-HTML bootstrap; render via the existing `main.tsx`.
   Do NOT introduce Next.js.
2. Split the components and pages into `.tsx` files under `src/`
   (e.g. `src/components/`, `src/pages/`).
3. Convert every `class=` to `className=`; fix any JSX/TS issues.
4. **Bring the export's own Tailwind config in as the source of truth**: save it as
   `frontend/tailwind.config.js` and reference it from `src/index.css` with
   `@config "../tailwind.config.js";`. The template ships plain Tailwind v4 only —
   just use the design's classes and replace the placeholder `App.tsx`.
5. Move font `<link>`s into `index.html`.
6. Use `BrowserRouter` (not `MemoryRouter`); keep the routes.
7. Keep mock data for now; where data would be fetched, call relative `/api/...`.
   Don't build the backend as part of this step.
8. Ensure `npm run build` succeeds and the app renders.

### Keycloak / realm

- Treat `infra/keycloak/import/realm-export.json` as **given infrastructure**. The
  realm, the frontend (public) and backend (confidential) clients, and the auth
  flows are already configured — do **not** change clients, mappers, scopes, or
  flows.
- **The ONLY change you may make to the realm import is adding application roles,
  and ONLY when the project idea actually calls for roles.** Add exactly the roles
  the idea needs (e.g. `user`, `admin`) under `roles.realm`, and assign them as
  needed. If the idea has a single user type / no roles, leave the realm import
  untouched.
- Define roles in the export (reproducible), not by clicking in the admin console.
  The import only applies to an empty database, so after editing reset with:
  `docker compose down -v && docker compose up -d --build`.

## Running it

**Local development** (HTTP on localhost; `docker-compose.override.yml` auto-loads
the dev host ports):

```bash
cp .env.example .env          # then replace every "change-me"
docker compose up -d --build
docker compose ps             # wait until all services are healthy
```

App: `http://localhost:8080` · API: `/api/` · Keycloak: `/auth/`

> If the app is served at a URL other than `http://localhost:8080` (e.g. a forwarded
> dev URL), `APP_PUBLIC_BASE_URL` must match it exactly or auth breaks. The
> `.devcontainer` setup script sets this automatically for forwarded-URL
> environments; otherwise set it in `.env` yourself. Don't hardcode `localhost`.

**Production** (HTTPS via the Caddy edge; gateway + DBs stay internal). Set
`APP_DOMAIN`, `ACME_EMAIL`, and `APP_PUBLIC_BASE_URL=https://<domain>` in `.env`,
point DNS at the server, open ports 80/443, then:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

First boot takes ~1 minute (Keycloak initializes and imports the realm); in
production add the time for Caddy's ACME certificate challenge.

> Changing the public origin? `APP_PUBLIC_BASE_URL` drives Keycloak's issuer,
> redirect URIs and CORS. It must exactly match how the browser reaches the app
> (scheme, host, no stray port), or logins fail.

## Verify before finishing

Every feature is **full-stack**: build the UI in `frontend/` **and** its API under
`/api` in `backend/` (plus any Flyway migration in
`backend/src/main/resources/db/migration/`). Don't finish with only one side.

`docker compose up -d --build` is the command used to run this app — including on
the deployment server — so it MUST pass. After your changes, verify:

1. **The whole stack builds and runs** (this builds the frontend with npm and the
   backend with Maven inside Docker — the authoritative check):

```bash
docker compose up -d --build
docker compose ps        # every service must be healthy (gateway/frontend: running)
```

2. **Smoke-test through the gateway** (single origin):
   - `http://localhost:8080/` serves the app
   - `http://localhost:8080/api/<your endpoint>` responds
   - `http://localhost:8080/auth/` is reachable; login works if implemented

3. **Faster inner-loop checks** while iterating on one side (optional):
   - frontend: `cd frontend && npm install && npm run build`
   - backend:  `docker compose build backend`  (compiles with Maven)

4. If a service is unhealthy, read `docker compose logs <service>`, fix, and repeat.

## Gotchas

- After recreating a backing container, restart the gateway so nginx re-resolves
  its IP: `docker compose restart gateway`.
- Don't commit `.env` (it's gitignored). Keep secrets out of source.
- Don't publish extra host ports or add a second public entrypoint.
