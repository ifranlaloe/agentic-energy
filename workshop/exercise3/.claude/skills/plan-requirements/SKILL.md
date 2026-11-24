---
name: plan-requirements
description: Turns a request into testable requirements (story, Given/When/Then acceptance criteria with IDs, non-functional requirements, scope, recorded decisions) at the start of a feature plan, resolving every ambiguity itself with the safest choice. Use when starting a feature, when a request is vague, or when asked to scope, refine or write requirements or user stories.
metadata:
  version: "1.0"
  phase: plan
  leadership-question: "Are we building the right thing?"
  artifact: docs/plans/<slug>.md, section Requirements
  gate: validator passes
---

# Plan requirements

Turn a request into requirements a test can prove. Nothing is designed or built in this phase. Decide every ambiguity yourself and record it. Do not ask.

- Entry: a request from the user, however vague.
- Exit: the Requirements section passes the validator.

## Procedure

Progress:
- [ ] 1. Start the plan
- [ ] 2. Gather context
- [ ] 3. Write story and criteria
- [ ] 4. Write non-functional requirements
- [ ] 5. Record scope and decisions
- [ ] 6. Validate

1. Pick a kebab-case slug such as `callback-request`. Create `docs/plans/<slug>.md` from `assets/requirements-section.md` with the Write tool. This starts the plan. Every later skill appends its own section to it.
2. Read `docs/standards/definition-of-done.md`, `AGENTS.md` and the pages and data the request touches.
3. Write the story, then the criteria. Follow `references/writing-acceptance-criteria.md`: one behaviour per criterion, observable outcomes, negative and boundary cases included.
4. Address accessibility, security and privacy, and performance. Write "None" only with a reason.
5. List what is out of scope. For every ambiguity in the request, pick the safest and narrowest interpretation that still satisfies it, and record it under Assumptions and decisions as `ambiguity -> choice because reason`.
6. Validate and repeat until it prints OK:

   ```
   node .claude/skills/plan-requirements/scripts/validate-requirements.mjs <slug>
   ```

## Gotchas

- Northwind has no backend. "Saved" and "sent" mean the fake API in `src/lib/api.ts`. Record that as a decision.
- Name, email, phone and address are personal data under GDPR. Say so in the non-functional requirements even when the data only goes to fixtures.
- When unsure, choose the smaller scope and the stricter validation.
- Do not renumber criteria once a later phase refers to them. Tests and release notes use these IDs.
