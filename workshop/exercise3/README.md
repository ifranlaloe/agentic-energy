# Northwind Energy – Agentic Harness

The same Northwind app as before, now with a harness around the agent. The model is unchanged. The harness makes the safe, best-practice decisions for you.

## Quick start

```bash
npm install
claude
```

## Try it

Type one prompt and watch:

> Add a contact form that lets customers request a callback.

The agent plans, designs, builds, tests, security-reviews, scores and release-checks the change by itself, then reports. Everything it decided is written to `docs/plans/`, in one file for this feature.

## The harness

| Layer | File | What it does |
|---|---|---|
| Context | `AGENTS.md` | Project layout, engineering rules and the instruction to decide instead of ask |
| Permissions | `.claude/settings.json` | Build, test, format and the skill scripts run without prompts. `git` is denied |
| Hook | `.claude/hooks/typecheck.mjs` | Typechecks after every TypeScript edit and sends errors back to the agent |
| Skills | `.claude/skills/` | One skill per SDLC phase plus `deliver-feature`, which runs them all. See [SKILLS.md](SKILLS.md) |
| Subagent | `.claude/agents/security-reviewer.md` | A read-only reviewer in its own context |
| Standards | `docs/standards/` | Definition of done and severity scale that the skills gate against |
| Tests | `package.json`, `vite.config.ts` | Vitest and Testing Library, already configured |

## Where to look afterwards

- `docs/plans/<feature>.md` shows every phase and every decision.
- `src/` and the `*.test.*` files show what was built and proven.
- `CHANGELOG.md` shows the release note.
