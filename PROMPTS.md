# Prompts

The design → build workflow on this template:

1. **Design** with Google Stitch using the prompt below.
2. **Export** with **"Stitch React App"** and paste it into
   `design/stitch-export.html`.
3. **Build** in the coding environment (e.g. Codespaces): point the AI at the
   export and describe your features — it follows `AGENTS.md` for the how.

Replace every `[PLACEHOLDER]` with your own text.

---

## 1. Design prompt — Google Stitch

Stitch is an external tool (it can't see this repo), so give it a full
product/screen description. It outputs its own HTML/CSS, so no tech-stack
constraints are needed.

```text
Design a clean, modern, responsive web app (desktop and mobile layouts).

APP IDEA:
[DESCRIBE YOUR APP — what it does, who uses it, main features.]

ROLES / ACCESS LEVELS (design a tailored experience for each, if any):
[NAME EACH ROLE AND WHAT IT CAN DO, or write "a single logged-in user" for none.]

SCREENS TO DESIGN:
- A public landing page for signed-out visitors.
- The core feature screens for the app idea.
- A main dashboard / authenticated home.
- Any role-specific management screens (e.g. an admin area with tables).
- If payments are relevant, a checkout/billing screen.
- A shared layout: top navigation, a user menu with avatar + log out, mobile nav.

STYLE:
- Modern, minimal, lots of whitespace, clear hierarchy.
- Light and dark theme.
- Friendly empty states.
```

### Filled example (for reference)

```text
APP IDEA:
An event ticketing platform called "Gather". People discover local events
(concerts, workshops, meetups), view event details, and buy tickets. Organizers
create and manage their own events and track ticket sales.

ROLES / ACCESS LEVELS:
- attendee: browse/search events, buy tickets, view their purchased tickets.
- organizer: also create/edit their events and see a sales dashboard.
- admin: review/remove any event and manage user accounts.
```

---

## 2. Build prompt — integrate the design + implement features

The coding AI reads `AGENTS.md`, which already contains the full recipe for turning
a Stitch export into the app plus all the project conventions. So you don't need a
long prompt — just point it at the export and describe the features you want:

```text
Integrate the Stitch design in design/stitch-export.html into this app, then
implement these features FULL-STACK (frontend UI + backend /api endpoints +
Postgres tables via Flyway): [LIST YOUR FEATURES — e.g. Keycloak login,
user/admin roles, the events API, ticket checkout].

When done, verify it runs with `docker compose up -d --build` and every service is
healthy (`docker compose ps`), then smoke-test http://localhost:8080/ and your
/api endpoints. Follow AGENTS.md.
```

Work in steps if it's large (integrate the UI first, then add features one at a
time), and re-run `docker compose up -d --build` to see changes.

---

## Tips

- **Keep API calls relative** (`/api/...`) so the single-origin model holds.
- **Let the Stitch design own the styling** — it ships its own Tailwind config
  (the AI wires it in via `tailwind.config.js` + `@config`).
- **Stitch's HTML is often Tailwind v3-style**; ~95% of classes are identical to
  v4, and the AI fixes the few differences.
