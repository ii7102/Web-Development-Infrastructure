# design/

Staging area for an AI-generated UI design before it's built into the app.

## Workflow

1. Generate a design with Google Stitch — see [`../PROMPTS.md`](../PROMPTS.md)
   (prompt 1).
2. Export it with **"Stitch React App"** and paste it into
   [`stitch-export.html`](stitch-export.html), replacing the placeholder contents.
3. In your coding environment, ask the AI to build from it — e.g. "integrate the
   Stitch design in design/stitch-export.html, then implement [features]." The AI
   follows `AGENTS.md` (which has the full integration recipe); see
   [`../PROMPTS.md`](../PROMPTS.md) prompt 2 for a starter.
4. Once integrated, you can delete `stitch-export.html`.

Nothing in this folder is built or served — it's just a handoff point between the
design tool and the coding AI.
