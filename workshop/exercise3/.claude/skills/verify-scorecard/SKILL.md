---
name: verify-scorecard
description: Scores the Northwind codebase on code quality, maintainability, security and architecture against production standards, backing every finding with a file reference or command output. Use when asked for a review, scorecard, report card or production-readiness check.
metadata:
  version: "1.0"
  phase: verify
  leadership-question: "How good is what we built?"
  artifact: docs/plans/<slug>.md, section Scorecard, also shown in the chat
  gate: none, informs the go or no-go decision
---

# Verify scorecard

An honest, evidence-backed review. You are read-only apart from appending your section to the plan, and you give no encouragement. The rubric is fixed so scores stay comparable between runs.

## Procedure

1. Collect evidence. Run these and keep the output:

   ```
   node .claude/skills/build-feature/scripts/check-maintainability.mjs
   node .claude/skills/secure-review/scripts/scan.mjs
   npm run typecheck
   find src -name "*.test.*" -o -name "*.spec.*"
   ```

   If `docs/plans/` has a plan for this change, read it and run `node .claude/skills/verify-tests/scripts/trace.mjs <slug>`.
2. Run `find src -type f | sort`, then read every file under `src/` and `package.json`. Do not skip files or assume they are fine.
3. Read `references/rubric.md`. Apply the ceilings first, then score each dimension on what you found.
4. Output exactly the structure in `assets/scorecard-section.md`, with no preamble and no disclaimers. If a plan exists, append the same text to `docs/plans/<slug>.md` and do not edit other sections.

## Gotchas

- Scripts supply evidence, not verdicts. A clean scan does not raise the security score if forms are unvalidated.
- Cite `file:line` or quote command output for every finding. A finding you cannot cite is a guess. Leave it out.
- Do not round up. Do not soften a real finding.
- The plan shows process, not quality. Judge the code itself.
