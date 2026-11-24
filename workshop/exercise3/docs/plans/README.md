# Plans

One file per change, `docs/plans/<slug>.md`, where the slug is short and kebab-case. `plan-requirements` creates it. Every later skill appends its own section at the end and never edits another skill's section. A skill that is run again rewrites only its own section. Use the Edit or Write tool for this, not shell redirection. The file records what was decided and why.

| Section | Appended by | Gate |
|---|---|---|
| Requirements | `plan-requirements` | Validator passes |
| Design | `design-solution` | Every criterion mapped to files |
| Build log | `build-feature` | Maintainability check clean and tests passing |
| Test report | `verify-tests` | Every criterion traced to a passing test |
| Security review | `secure-review` | No open Critical, High or Medium |
| Scorecard | `verify-scorecard` | Informs the verdict |
| Runbook | `operate-runbook` | Every failure mode complete |
| Release readiness | `release-readiness` | All gates pass |

Each section starts with a `## ` heading and sub-points use `###` and `####`. Acceptance criteria are `#### AC-n` headings, and tests refer to them as `[AC-n]`.
