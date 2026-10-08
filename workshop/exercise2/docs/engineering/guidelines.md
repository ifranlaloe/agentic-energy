# Engineering guidelines

These guidelines apply to changes made to the Northwind Energy application.

---

## Reuse existing components

The application has a reusable component set in `src/components/ui/`:
Button, Card, Badge, Field, Container, PageHeader, Skeleton, RadioCard.

Before creating a new component, check whether an existing one can be used or adapted.
Consistency is more valuable than a perfect fit for every edge case.

---

## Keep changes local

Add new files in the directory that best fits the change:
- A new page → `src/pages/`
- Components for a specific feature → `src/components/<feature-name>/`
- Shared utility → `src/lib/`

Do not restructure unrelated directories.

---

## Avoid unnecessary new dependencies

The application already has React, Tailwind CSS, React Router, and Lucide icons.
These should be sufficient for most feature work.

If a new dependency seems necessary, consider whether the feature can be built with
what is already available.

---

## Follow the existing data pattern

Data lives in `src/data/`. The fake API client in `src/lib/api.ts` loads data from
those files and returns it with a short delay.

New features that need data should:
1. Add a typed data structure to `src/data/`
2. Add a corresponding function to `src/lib/api.ts`
3. Use the `useAsync` hook to load data in components

---

## Keep changes small and easy to understand

A change that is easy to understand is also easy to review, adjust, and extend.
Prefer straightforward code over clever abstractions for a feature of this scope.

---

## Do not restructure unrelated areas

The existing pages and components are part of the workshop baseline. Reorganising them
can break other participants' experience and create difficult-to-resolve conflicts.
Keep changes within the relevant feature.
