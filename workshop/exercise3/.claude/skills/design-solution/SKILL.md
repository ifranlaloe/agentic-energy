---
name: design-solution
description: Researches the codebase and appends a design to the plan with options, a decision by explicit rule, a requirement-to-file traceability table, a security and privacy pass and a rollback plan, plus an architecture decision record when warranted. Use after requirements exist, for any change touching more than one file, or when asked to plan, design or propose an approach.
metadata:
  version: "1.0"
  phase: design
  leadership-question: "Is the approach sound and reversible?"
  artifact: docs/plans/<slug>.md, section Design
  gate: every criterion mapped to files
---

# Design solution

Decide how to build it, and what it costs, before any code changes. Write designs, not implementations: signatures and types are fine, function bodies are not. Make the decision yourself and record why.

- Entry: `node .claude/skills/plan-requirements/scripts/validate-requirements.mjs <slug>` prints OK. If it does not, fix the Requirements section first.
- Exit: a Design section appended to the plan, passing the self-check.

## Procedure

Progress:
- [ ] 1. Build the reuse inventory
- [ ] 2. Generate options
- [ ] 3. Decide by rule
- [ ] 4. Write the design
- [ ] 5. Record an ADR if triggered
- [ ] 6. Self-check

1. Read `AGENTS.md`, the Requirements section and every file the change will touch or sit next to. List what can be reused: components, hooks, helpers, data.
2. Produce at least two options. One must be the smallest change that could satisfy every criterion.
3. Decide by this rule: pick the option that meets every criterion and non-functional requirement with the fewest files, no new dependency and the easiest rollback. Break ties toward the safer option.
4. Append `assets/design-section.md` to `docs/plans/<slug>.md` and fill every subsection. Do not edit other sections. Run the threat pass from `references/stride-quick-pass.md` for the security and privacy subsection.
5. Write an ADR in `docs/adr/` when the design introduces a new pattern, changes a data shape used by more than one module, or makes a security-relevant choice. Use `assets/adr-template.md` with `Status: Accepted`. The number is the highest existing one plus one.
6. Self-check:
   - every acceptance criterion appears in the traceability table
   - every threat has a mitigation
   - loading, empty, error and success states are described
   - rollback is concrete

## Gotchas

- Do not design in a new dependency. The existing stack covers most features, including testing.
- Keep all data access behind `src/lib/api.ts`. Replacing the fake API with real HTTP should then touch one file.
- `Field` renders its `error` text but sets neither `aria-invalid` nor `aria-describedby`. A design that adds validation must change `Field`, and `Field` is shared. List every page that uses it under risks.
- `useAsync` runs once on mount. It does not suit submit actions. Design an explicit submit handler with a submitting state instead of reusing it.
