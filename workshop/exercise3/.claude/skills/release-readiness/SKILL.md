---
name: release-readiness
description: Decides whether a change is ready to ship by running the quality gates, walking the definition of done, classifying release risk, adding a changelog entry and proposing a version bump, and checking rollback. Gives a Ready or Not ready verdict with the fix for each blocker. Use before declaring work done, before handing off, or when asked if something is ready to release.
metadata:
  version: "1.0"
  phase: release
  leadership-question: "Is it safe to ship?"
  artifact: docs/plans/<slug>.md, section Release readiness
  gate: all gates pass
---

# Release readiness

Give an honest verdict and say how to fix every blocker.

- Entry: the plan has Requirements, Design, Build log, Test report, Security review and Runbook sections. List any that are missing and give a Not ready verdict.
- Exit: a Release readiness section in the plan with a verdict. When you are run again, rewrite your own section.

## Procedure

1. Run the gates and keep the output verbatim:

   ```
   node .claude/skills/release-readiness/scripts/gates.mjs <slug>
   ```

2. Walk every row of `docs/standards/definition-of-done.md`. Mark each Pass or Fail and cite the artifact or output.
3. Classify the release risk using `references/release-policy.md` and note the recommended rollout.
4. Propose the SemVer bump and add an entry under Unreleased in `CHANGELOG.md`. Create the file from `references/release-policy.md` if it does not exist. Do not change the version in `package.json`.
5. State the rollback: exact steps, how long they take, and whether data or state written by the new version breaks the old one.
6. Append `assets/readiness-section.md` to `docs/plans/<slug>.md` and fill it. Do not edit other sections.

## Verdict

- Ready: every gate passes and every row of the definition of done passes.
- Not ready: anything else. List each blocker with the fix.

A gate that did not run, including `NOT CONFIGURED`, is a failure. Accessibility items listed as Not checked in the Test report are known gaps, not failures.

## Gotchas

- `git` is denied. Summarise changes from the build log, not from a diff.
- Do not hide a failed gate to reach a Go. Report it and say what would fix it.
