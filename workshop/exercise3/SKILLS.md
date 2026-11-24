# SDLC skills

One skill per phase of the software delivery lifecycle, each answering the question leadership asks at that phase. `deliver-feature` runs them all from a single request. Every skill reads the plan so far, appends one section to `docs/plans/<slug>.md` and passes an automated gate. The harness makes the decisions and records them in the plan. Skills follow the [Agent Skills](https://agentskills.io/specification) format and are named `<phase>-<capability>`.

| Phase | Leadership question | Skill | Section appended to the plan | Gate |
|---|---|---|---|---|
| All | Can we go from idea to a safe, shippable change with no hand-holding? | `deliver-feature` | Runs the phases below | Verdict is Ready |
| Plan | Are we building the right thing? | `plan-requirements` | Requirements | Validator passes |
| Design | Is the approach sound and reversible? | `design-solution` | Design, plus `docs/adr/` when needed | Every criterion mapped to files |
| Build | Is the work flowing to plan? | `build-feature` | Build log, with each criterion's test written first | Maintainability check clean and tests passing |
| Verify | Can we prove it works? | `verify-tests` | Test report, an independent audit of the tests | Every criterion traced to a passing test |
| Secure | What risk are we taking on? | `secure-review` | Security review | No open Critical, High or Medium |
| Verify | How good is what we built? | `verify-scorecard` | Scorecard | Informs the verdict |
| Operate | Can we run it and recover fast? | `operate-runbook` | Runbook | Every failure mode complete |
| Release | Is it safe to ship? | `release-readiness` | Release readiness, plus `CHANGELOG.md` | All gates pass |

## Flow

```
plan-requirements -> design-solution -> build-feature -> verify-tests -> secure-review -> verify-scorecard -> operate-runbook -> release-readiness
```

There are no approval stops. When a check fails, the harness goes back to `build-feature`, fixes the cause and runs the check again, at most twice. If something still fails, the plan says so in the verdict.

## Standards

- `docs/standards/definition-of-done.md`: what done means, with the evidence for each line
- `docs/standards/severity.md`: one scale for findings, defects and incidents

## How each skill is built

- `SKILL.md` holds the procedure and gotchas. Detail loads on demand from `references/` and `assets/`.
- Scripts in `scripts/` do the deterministic checks: requirements validation, maintainability, security scan, test traceability and release gates. They are Node scripts, so they run on Windows and macOS.
- Every skill has entry and exit criteria and an automated check.
- A check that did not run counts as failed.
