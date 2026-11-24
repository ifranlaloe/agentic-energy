---
name: build-feature
description: Implements the design in the plan one acceptance criterion at a time, writing each criterion's test first, following Northwind conventions, running typecheck, format and maintainability checks after every slice, and keeping a build log. Use when asked to implement, add, build or change a feature in the app.
metadata:
  version: "1.0"
  phase: build
  leadership-question: "Is the work flowing to plan?"
  artifact: docs/plans/<slug>.md, section Build log
  gate: maintainability check clean and tests passing
---

# Build feature

Build exactly what the design says, in small verified slices.

- Entry: the plan has Requirements and Design sections. If not, use `plan-requirements` and `design-solution` first.
- Exit: every criterion implemented with a passing `[AC-n]` test, `check-maintainability.mjs` reports no findings, build log complete.

## Procedure

1. Append `assets/build-log-section.md` to `docs/plans/<slug>.md`. You may keep updating your own section while you build. Do not edit other sections.
2. Re-read the criteria and the design's traceability table. Build in this order: types and data, pure logic, hooks and API, UI, wiring (route in `src/App.tsx`, link in `SiteHeader`).
3. Work one criterion at a time, test first:
   - write the test for the criterion, named `[AC-n] behaviour`, and run `npm test` to see it fail for the right reason
   - implement until it passes. The typecheck hook runs on every edit. Fix every error before continuing
   - `npm run format`
   - `node .claude/skills/build-feature/scripts/check-maintainability.mjs`, then fix every finding and run it again
   - update the build log row for that criterion with its test file
4. If the design cannot be followed, take the closest safe alternative that still meets the criteria and record the deviation and the reason in the build log. Never deviate silently.
5. Run `npm test` for the whole suite. Report each criterion as met or not met, with the file that implements it and the test that proves it.

Read `references/test-patterns.md` before writing the first test. Read `references/forms-and-validation.md` before building any form. Read `references/maintainability.md` when a slice grows past one screen or a component starts doing two jobs.

## Write maintainable code

The next developer should understand a change without asking you. `verify-scorecard` grades these same points.

- Name things for what they mean: `callbackRequest`, not `data`. A name that needs a comment is the wrong name.
- Keep components under 150 lines and functions to one job.
- Put fetching in `src/lib/` and state in hooks. Components only render.
- Extract magic strings and numbers into named constants. Move copy and fixtures into `src/data/`.
- Type every boundary: props, API results, form values. No `any`. Narrow `unknown` before use.
- Use early returns and guard clauses instead of nested `if` blocks.
- Handle loading and error states explicitly for every async call.
- Remove dead code and unused imports before reporting done.
- Do not add comments that restate the code. Leave existing comments as they are.
- When the same logic appears a second time, extract a shared helper or component.

## Write tests

A test proves one acceptance criterion. Write it before the code, so it fails first and you know it can fail.

- One behaviour per test, named `[AC-n] behaviour`. With `it.each`, put the ID in a literal `describe` title so traceability can find it.
- Arrange, act, assert, with no section comments.
- Test pure logic such as validators and formatters directly. Test components the way a user does: render, act, assert what is visible.
- Query by role and label, never by class name or test id.
- Cover the unhappy paths and the boundaries of every criterion, not only the happy path. `references/test-patterns.md` lists the input cases.
- The fake API waits 200 to 250 ms. Use `findBy*` queries or fake timers. Never sleep.
- Assert on behaviour, not implementation. No whole-page snapshots.
- Never throw in a test. Use assertions. Never commit `.only` or `.skip`.
- Each test sets up its own state and uses meaningful data such as `emma@example.com`.
- Do not write tests for coverage alone.

## Gotchas

- Styling is Tailwind CSS v4. Use `brand-*` colours such as `bg-brand-700`, never raw hex values.
- Format money with `formatEuro` from `src/lib/format.ts`. Never inline it.
- Components in `src/components/ui/` take a `className` prop. Compose classes with `cn` from `src/lib/cn.ts`.
- A page that is not registered in `src/App.tsx` and linked from `SiteHeader` is unreachable.
- `git` is denied here. Track what you changed in the build log, because the security review and release check use it as their scope.
- Do not add dependencies. Solve it with the existing stack and record the decision in the build log.
