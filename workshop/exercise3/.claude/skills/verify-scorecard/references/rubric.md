# Rubric

Score against production standards, not workshop standards. A 10 means production-ready with no meaningful gaps. Deduct for every real shortcoming.

| Score | Meaning |
|---|---|
| 9 to 10 | Production-ready, nothing meaningful missing |
| 7 to 8 | Minor issues only, could ship with small fixes |
| 5 to 6 | Notable gaps, would not pass a team code review as-is |
| 3 to 4 | Multiple serious issues, significant rework needed |
| 1 to 2 | Fundamental problems throughout |

## Ceilings

Apply these first, then adjust further for what you find.

- No automated tests: Maintainability scores at most 5. Untested code is not maintainable by definition.
- Simulated API and no real backend: Architecture scores at most 5.
- Unvalidated form inputs: Security scores at most 5.

The overall score is the mean of the four dimension scores, rounded to one decimal.

## Dimensions

### Code Quality

Magic strings and numbers not extracted as named constants, inconsistent naming, dead or commented-out code, copy-paste duplication between components or pages, components over 150 lines, hardcoded copy or data that belongs in a data file, missing or incorrect TypeScript types (`any`, missing return types, missing `interface` or `type` definitions).

### Maintainability

Zero test coverage (count the `.test.` and `.spec.` files, their absence is a finding), no error boundaries, components that mix data fetching with rendering, unclear or abbreviated names, no documentation for non-obvious decisions, anything that would make onboarding a new developer difficult.

### Security

`dangerouslySetInnerHTML`, unvalidated or unsanitised user input written to state or rendered, sensitive values hardcoded in source, unsafe `eval` or `Function`, third-party dependencies with known risk patterns, personal data logged or stored in the browser. The absence of a backend does not raise the score. It only limits the attack surface.

### Architecture

Tight coupling between data shape and UI rendering, page components that do too much, repeated inline logic that belongs in a shared utility or component, missing loading or error states for async operations, a fake API layer that would need significant rework to replace with a real backend, business logic mixed into view components.
