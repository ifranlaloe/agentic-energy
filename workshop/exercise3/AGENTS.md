# Northwind Energy

Northwind Energy is a fictional residential energy self-service portal.
It is used as a workshop exercise. Do not treat it as a production system.

## Commands

| Command | Purpose |
|---|---|
| `npm run dev` | Start the app at http://localhost:5173 |
| `npm test` | Run the tests. One file: `npm test -- <file>` |
| `npm run typecheck` | Typecheck. A hook also runs it after every TypeScript edit |
| `npm run build` | Production build |
| `npm run format` | Format the code with Prettier |

## Project layout

| Path | What it contains |
|---|---|
| `src/pages/` | One file per page (Home, Offers, Contract, Contact) |
| `src/components/ui/` | Reusable UI components: Button, Card, Badge, Field, Container, PageHeader, Skeleton, RadioCard |
| `src/components/layout/` | SiteHeader, SiteFooter |
| `src/components/offers/` | OfferCard, ComparisonTable |
| `src/data/` | Fixture data: offers (Flex, Zeker, Groen), contract, usage |
| `src/lib/` | api.ts (fake async API), useAsync.ts, format.ts, cn.ts |
| `src/test/` | Test setup. Tests sit next to the code as `*.test.ts(x)` |
| `docs/standards/` | Definition of done and severity scale |
| `docs/adr/` | Architecture decision records |
| `docs/plans/` | One plan per change |
| `.claude/` | The harness: settings, hook, subagent and skills |

## Pages

| Route | Page |
|---|---|
| `/` | Home – brand hero, plan teasers, quick links |
| `/offers` | Energy plans – compare Flex / Zeker / Groen, select a plan |
| `/contract` | My contract – plan details, account info, usage |
| `/contact` | Contact – form and contact information |

## How data works

The app uses a fake in-process API (`src/lib/api.ts`). There is no backend server.
Data is defined in `src/data/` and the API functions return it after a short delay.
To add or change data, edit the files in `src/data/`.

## Components

Components in `src/components/ui/` accept a `className` prop for local overrides.
Styling uses Tailwind CSS v4. Brand colours are defined as `brand-*` (e.g. `bg-brand-700`, `text-brand-50`).

## Engineering rules

- Reuse components from `src/components/ui/` before creating new ones.
- Put new files where they belong: pages in `src/pages/`, feature components in `src/components/<feature>/`, utilities in `src/lib/`.
- Add no dependencies. Solve it with the existing stack.
- Keep data in `src/data/` and load it through `src/lib/api.ts`.
- Validate and sanitise every user input before it is stored or rendered.
- Every acceptance criterion has a test named `[AC-n] behaviour`.
- Before declaring a task done, `npm run typecheck`, `npm test` and `npm run build` pass.

## How changes are delivered

- A request to build, add or change a feature is delivered with the `deliver-feature` skill. It runs the skills in `.claude/skills/` in order: plan, design, build, verify, secure, scorecard, runbook, release.
- Each skill appends its section to one plan per change, `docs/plans/<slug>.md`. Quality bars are in `docs/standards/`.
- Never stop for approval. Choose the safest option that meets the request and record the decision in the plan. Ask the user only when the request cannot be interpreted at all.
- Change files with the Edit and Write tools, not shell commands.
- Never use `git`. It is denied.
