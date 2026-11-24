# Test patterns

## Shape

```tsx
it('[AC-2] rejects an email without an @', async () => {
  const user = userEvent.setup()
  render(<CallbackForm />)

  await user.type(screen.getByLabelText('Email'), 'emma.example.com')
  await user.click(screen.getByRole('button', { name: 'Request callback' }))

  expect(await screen.findByText(/name@example.com/)).toBeVisible()
})
```

## Parameterise input classes

Use `it.each` over a table of values for the same behaviour. Cover each class at least once. Put the ID in a literal `describe('[AC-2] rejects invalid emails', ...)` title, because `trace.mjs` looks for the text `[AC-2]` and cannot see a `%s` template. Tracing proves the ID is present. Passing is proven by `npm test`.

| Class | Examples |
|---|---|
| Empty | `''`, spaces only, a tab |
| Boundary | one below, at and one above the maximum length. Test the one-over case on the validator, because `maxLength` blocks typing it |
| Real names | `O'Brien`, `Zoë`, `Nguyễn`, `Van der Berg` |
| Markup | `<script>alert(1)</script>`, `"><img src=x onerror=alert(1)>` |
| Whitespace | leading and trailing spaces, inner double spaces |
| Unicode | emoji, right-to-left text |
| Email | `a@b`, `a@b.c`, `a+tag@b.nl`, `a@@b.nl` |
| Phone | `+31 6 1234 5678`, `0612345678`, `abc`, 30 digits |

For markup, assert that the text is rendered as text and that no element was created.

## Keep tests reliable

- Each test sets up its own state. No test depends on another.
- Control time with fake timers when a component waits. Never rely on real delays.
- A flaky test is a bug. Fix it or delete it. Do not retry it.
- Use meaningful data such as `emma@example.com`, not `test` or `foo`.
