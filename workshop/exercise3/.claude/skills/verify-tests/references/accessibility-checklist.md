# Accessibility checklist (WCAG 2.2 AA)

Automate what can be automated in component tests. Check the rest by hand and record how.

| Item | How to check |
|---|---|
| Every control has a programmatic label | `getByLabelText` finds it |
| Errors are tied to their field | the field has `aria-invalid` and `aria-describedby` pointing at the message |
| Errors and success are announced | the message sits in a `role="alert"` or `role="status"` element |
| Focus moves to the first error on a failed submit | assert `toHaveFocus()` on that field |
| The whole flow works with the keyboard only | tab through it in the browser. Record the result |
| Visible focus indicator | tab through it in the browser |
| Text contrast is at least 4.5:1, large text 3:1 | check the colour pairs against the `brand-*` palette |
| Nothing relies on colour alone | errors have text, not only a red border |
| Touch targets are at least 24 by 24 CSS pixels | inspect the button and input sizes |
