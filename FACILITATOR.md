# Facilitator guide – Session 1: Work differently with AI

## Before the workshop

### Participant machines need

| Requirement | Check |
|---|---|
| Node.js 22.x | `node --version` → `v22.*` |
| npm 10+ | `npm --version` |
| VS Code | Open and launch |
| Claude Code VS Code extension | Installed and signed in |

> **Node version floor**: Vite 8 requires Node ≥ 20.19 or ≥ 22.12.
> Node 18 or 20.x < 20.19 will not start the dev server.
> Use `nvm use 22` or install from nodejs.org.

---

## Distribution

Share the `workshop/exercise1/` and `workshop/exercise2/` folders with participants
(e.g. as a zip, USB, or shared drive). Each folder is a self-contained project —
no git, no shared dependencies.

Participants only ever open **one folder** in VS Code. They should not see the
other folder. Opening `workshop/exercise1/` means Claude Code only has that folder in scope.

```
workshop/
├── exercise1/   ← open this for Exercise 1
└── exercise2/   ← open this for Exercise 2
```

---

## Starting each exercise

### Exercise 1

1. Open the `workshop/exercise1/` folder in VS Code.
2. Open a terminal inside that folder.
3. Run `npm install` (once only, takes ~30 s).
4. Run `npm run dev`.
5. Open http://localhost:5173 in a browser.

Confirm: Home, My contract, and Contact pages load. No comparison page exists —
that is what participants will build.

The plan teasers section on Home shows a **"Plan comparison coming soon"** stub.
That is the intended hook — participants ask Claude to build the comparison.

### Exercise 2

1. Open the `workshop/exercise2/` folder in VS Code.
2. `npm install` (if not done yet — dependencies are identical).
3. `npm run dev`.
4. Open http://localhost:5173/offers and confirm the comparison feature is visible.
5. Confirm that the `docs/` directory is present and readable by Claude Code.

---

## Claude Code behaviour for participants

`.claude/settings.json` is pre-committed inside each exercise folder:

- **`defaultMode: acceptEdits`** — the agent applies file edits without asking.
  Participants watch the agent work and see results in the browser immediately.
- **`Bash(git *)` denied** — the agent cannot inspect the git repo,
  so participants cannot accidentally discover the other exercise's content.
- `npm run dev` and `npm run build` are pre-allowed.

If a participant sees a permission dialog for a non-git command, check that
their `.claude/settings.json` exists and has the expected content.

---

## Recovery

### "The app is broken and I can't get it back"

The cleanest reset is to re-extract a fresh copy of the exercise folder:

1. Delete the broken exercise folder.
2. Re-extract it from the original zip / copy from your facilitator machine.
3. `npm install` inside the fresh folder (node_modules is not in the zip).
4. `npm run dev`.

There is no git history — no stash, no rebase, no conflict. It is always a
clean slate.

### "I accidentally opened the wrong folder and Claude saw both"

Close VS Code, open a new VS Code window, open only the correct exercise folder.
Claude Code's context is scoped to the open workspace folder.

---

## Exercise 1 – recovery scenarios

**Participant does not know what to ask**
Say: "Tell Claude to add a page where you can compare the three energy plans."
That is enough to get a visible result.

**Agent makes no visible change**
Check that `npm run dev` is running and the browser is at http://localhost:5173.

**App does not run / dev server error**
Re-extract a fresh `workshop/exercise1/` folder (see Recovery above).
If that fails, check `node --version` — must be `v22.*`.

**Agent breaks the app (compilation error)**
Vite strips TypeScript at runtime — a type error never blanks the screen.
A blank white screen is a JavaScript runtime error.
Re-extract a fresh copy.

**Participant finishes early (10+ min to spare)**
Ask: "What decisions did Claude make that you did not ask for?"
Good debrief: "Can you ask Claude to justify one decision it made?"

---

## Exercise 2 – recovery scenarios

**Agent starts implementing before research/plan**
Interrupt early. Ask: "Can you ask Claude to first tell you what it found
and what it plans to do, without changing any code yet?"
Good prompt: "Before you change anything, read the docs in `/docs` and
explain your plan in plain language."

**Agent ignores `/docs`**
Ask: "Did Claude mention the docs? Let's ask it to read
`/docs/product/recommendation-policy.md` and explain what it says."

**Plan is too technical to judge**
Say: "Can you ask Claude to restate the plan as product decisions?
What did it decide about what questions to ask, and when to recommend?"

**Plan contains an unsupported rule**
Example: agent recommends the cheapest plan.
Facilitator: "Where in the context does it say to recommend the cheapest plan?"
Then: "The recommendation policy says you should not recommend purely on price.
Can you ask Claude to revise the plan?"

**Participant does not know how to challenge the plan**
Provide: "Ask Claude: 'Does every question you plan to ask actually change
the recommendation?'"

**Implementation fails after a good plan**
Re-extract a fresh `workshop/exercise2/`, then ask the participant to implement again
using the same plan as a prompt. If it fails twice, pair with them.

**Participant finishes early**
"Can you ask Claude to explain what would happen if a customer's answers
conflict — they want the cheapest price and renewable sourcing?"

---

## Debrief prompts (after Exercise 1)

- "What did the agent decide that you did not explicitly ask for?"
- "Could a different participant have ended up with a very different result?"
- "If this had been a real product change, what would you want to review before shipping?"

---

## Debrief prompts (after Exercise 2)

- "What was different about the plan you saw before any code was written?"
- "Was there anything in the plan you would have changed?"
- "What would it take to know whether what was built is actually correct?"
  *(Leave this open — it is the Session 1 closing question.)*

---

## Scope intentionally out of this session

Do not introduce these; they are Session 2 material:

- automated tests
- CI/CD pipelines
- MCP servers
- background agents or multi-agent orchestration

If a participant asks "how would we know the agent got it right?", close with:
"That's exactly what Session 2 is about."
