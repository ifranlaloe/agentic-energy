---
name: secure-review
description: Reviews a change for security and privacy defects against an OWASP ASVS based checklist, verifies each lead by reading the code, rates findings with the shared severity scale and writes a review with a pass or fail verdict. Read-only. Use after any change touching user input, forms, rendering, storage or dependencies, or when asked for a security review.
metadata:
  version: "1.0"
  phase: secure
  leadership-question: "What risk are we taking on?"
  artifact: docs/plans/<slug>.md, section Security review
  gate: no open Critical, High or Medium finding
---

# Secure review

Find real defects and prove them. You are read-only: never edit `src/`. Fixes go back through `build-feature`. Your only write is appending your section to the plan.

- Entry: the plan's Build log lists the changed files. `git` is denied, so that list is the scope.
- Exit: a Security review section in the plan with a verdict. When you are run again, rewrite your own section.

## Procedure

1. Scope: every file in the plan's Build log, in the progress table and in other files changed, plus any file they import that handles user data.
2. Run the scanner and treat each line as a lead, not a finding:

   ```
   node .claude/skills/secure-review/scripts/scan.mjs
   ```

3. Walk every row of `references/asvs-checklist.md` against the scoped code. Record Pass, Fail or Not applicable, with `file:line` evidence.
4. Dependencies: run `npm audit --omit=dev`. If the registry is unreachable, record "not run". Review any dependency added in the build log.
5. Privacy: list each personal data field, where it flows, whether it is stored, and whether it is logged.
6. Ask the `security-reviewer` subagent for an independent read of the scoped files. Treat what it reports as leads.
7. Verify each candidate finding. Re-read the code, then state what an attacker does and what they gain. Discard anything you cannot show.
8. Rate each finding with `docs/standards/severity.md`. Add the CWE and a concrete fix.
9. Append `assets/security-review-section.md` to `docs/plans/<slug>.md` and fill it. Do not edit other sections. Verdict is Pass only with no open Critical, High or Medium finding. Low findings may stay open.

## Gotchas

- A clean scan does not mean secure. The scanner cannot see missing validation, so step 3 is the real review.
- No backend does not mean no risk. Input rendered back into the page is still an injection path, and client-side validation is not a security control.
- Do not inflate severity. A finding without an attacker action and an impact is a note, not a finding.
- Do not report style or maintainability here.
- Judge what the change introduces or touches. Record anything else as a Pre-existing note. A pre-existing note never blocks release.
- Medium findings block release, like Critical and High. List each with its fix so `build-feature` can apply it.
