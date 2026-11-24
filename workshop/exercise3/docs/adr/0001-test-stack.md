# 0001. Vitest and Testing Library for tests

Status: Accepted
Date: 2026-11-23

## Context

The app is built with Vite, so tests should share its configuration. Requirements are proven by tests, so a runner must be present from the start.

## Decision

Use Vitest with jsdom, Testing Library for React and user-event, and jest-dom matchers. Versions are pinned exactly, as for every other dependency.

## Consequences

### Positive

- Tests run with `npm test` and reuse the Vite configuration.
- Component tests query the page the way a user does.

### Negative

- Five more dev dependencies to keep updated.

## Alternatives considered

- Jest: needs a separate transform setup for Vite and TypeScript.
