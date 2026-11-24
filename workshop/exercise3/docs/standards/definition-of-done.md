# Definition of done

A change is done when every line below is true and the evidence is in the feature's plan, `docs/plans/<slug>.md`.

| Area | Criterion | Evidence |
|---|---|---|
| Requirements | Every acceptance criterion has an ID, and every ambiguity is recorded as a decision | Requirements section |
| Design | Approach, alternatives and rollback recorded. A new pattern or cross-module data change has an ADR | Design section, `docs/adr/` |
| Code | `npm run typecheck` and `npm run build` pass. Maintainability check reports no findings. No new dependency | gate output |
| Tests | Every acceptance criterion has at least one test named with its ID. All tests pass | Test report section |
| Security | No open Critical, High or Medium finding | Security review section |
| Accessibility | Keyboard operation, labels, error announcement and focus are proven by tests. Items that need a browser or screen reader are listed as Not checked, and are known gaps, not failures | Test report section |
| Privacy | Personal data is identified, minimised and never logged | Security review section |
| Release | Release notes, version bump and rollback plan recorded. Runbook exists for user-facing change | Release readiness and Runbook sections, `CHANGELOG.md` |

A check that was not run counts as failed.
