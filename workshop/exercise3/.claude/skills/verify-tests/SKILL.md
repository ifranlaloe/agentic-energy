---
name: verify-tests
description: Independently audits the tests written during the build. Confirms every acceptance criterion is traced to a passing test, fills gaps and missing negative cases, runs a mutation sanity check, records an accessibility checklist and writes a test report. Use when asked to check, add or improve tests, prove a change works or check coverage of requirements.
metadata:
  version: "1.0"
  phase: verify
  leadership-question: "Can we prove it works?"
  artifact: docs/plans/<slug>.md, section Test report
  gate: every criterion traced to a passing test
---

# Verify with tests

Evidence that each requirement holds, not a coverage number. `build-feature` writes the tests as it builds. This phase checks them independently and closes the gaps.

- Entry: the plan's Build log shows every criterion built, each with a test.
- Exit: `trace.mjs` exits 0 and the whole test suite passes.

## Procedure

1. Tests run with `npm test`. Vitest, Testing Library and jsdom are already configured (see `docs/adr/0001-test-stack.md`). Run the suite and `node .claude/skills/verify-tests/scripts/trace.mjs <slug>` to see what is covered.
2. Read the tests written during the build. For each criterion, compare its cases with the negative and boundary cases in `.claude/skills/build-feature/references/test-patterns.md` and list what is missing.
3. Add tests only for gaps: every untraced criterion and every missing case. Do not rewrite a test that already proves its criterion. Follow the "Write tests" rules in `.claude/skills/build-feature/SKILL.md`, including the `[AC-n]` name.
4. Run the suite, then trace. Fix until both pass:

   ```
   npm test
   node .claude/skills/verify-tests/scripts/trace.mjs <slug>
   ```

5. Mutation check, per criterion: make the smallest change that breaks the behaviour, run its test and confirm it fails, then revert immediately and confirm the suite is green again. A test that cannot fail proves nothing.
6. Walk `references/accessibility-checklist.md` for any UI change. Record each item as Pass, Fail or Not checked.
7. Append `assets/test-report-section.md` to `docs/plans/<slug>.md` and fill it with real command output. Do not edit other sections.

## Gotchas

- A test that cannot fail, asserts nothing or is skipped is not proof. Rewrite or replace it.
- Flag any test that breaks the "Write tests" rules in `build-feature`, and fix it.
- "Not checked" is an honest result for items that need a browser or a screen reader. Do not mark an accessibility item Pass without evidence. Keyboard operation, labels, error announcement and focus are proven by tests.
