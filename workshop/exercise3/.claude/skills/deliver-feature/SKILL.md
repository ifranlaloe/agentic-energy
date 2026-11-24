---
name: deliver-feature
description: Takes a feature request from idea to a release-ready change by running every SDLC skill in order on one plan, deciding and recording each choice itself and fixing what the checks find. Use when asked to build, add or change a feature, or to deliver something end to end.
metadata:
  version: "1.0"
  phase: all
  leadership-question: "Can we go from idea to a safe, shippable change with no hand-holding?"
  artifact: docs/plans/<slug>.md
  gate: release readiness verdict is Ready
---

# Deliver feature

Run the whole lifecycle from one request. Do not stop between phases and do not ask for approval. Pick the safest option that meets the requirements and record every decision in the plan.

## Procedure

1. Run these skills in order, each appending its section to the same plan, `docs/plans/<slug>.md`:
   1. `plan-requirements`
   2. `design-solution`
   3. `build-feature`
   4. `verify-tests`
   5. `secure-review`
   6. `verify-scorecard`
   7. `operate-runbook`
   8. `release-readiness`
2. Fix loop: if `verify-tests` fails, `secure-review` reports an open Critical, High or Medium finding, or `release-readiness` says Not ready, go back to `build-feature`, fix the cause, and run the failing phase again. Try at most two rounds per phase. If a fix changed code after `verify-scorecard` ran, run `verify-scorecard` again.
3. If a phase still fails after two rounds, continue to the end with the honest verdict and list the blockers. Do not hide a failure.
4. Finish with a summary of at most ten lines: what was built, the release verdict, the decisions you made, the scorecard overall, and the path of the plan.

## Gotchas

- Ask the user only when the request cannot be interpreted at all. Otherwise decide, and record it under Assumptions and decisions.
- Never report a check as passed when it did not run.
- A skill that is run again rewrites its own section. It never edits another skill's section.
