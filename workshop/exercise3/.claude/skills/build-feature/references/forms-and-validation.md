# Forms and validation

## Validation module

Put validation in `src/lib/` as a pure function that returns a discriminated union. It needs no library and is trivial to test.

```ts
export type ValidationResult<T> =
  | { valid: true; value: T }
  | { valid: false; errors: Partial<Record<keyof T, string>> }

const MAX_NAME_LENGTH = 80
const PHONE_PATTERN = /^\+?[0-9 ()-]{7,20}$/

export function validateCallbackRequest(input: CallbackInput): ValidationResult<CallbackRequest> {
  const name = input.name.trim()
  const phone = input.phone.trim()
  const errors: Partial<Record<keyof CallbackRequest, string>> = {}

  if (!name) errors.name = 'Enter your name'
  else if (name.length > MAX_NAME_LENGTH) errors.name = `Use at most ${MAX_NAME_LENGTH} characters`
  if (!PHONE_PATTERN.test(phone)) errors.phone = 'Enter a phone number like +31 6 1234 5678'

  return Object.keys(errors).length > 0 ? { valid: false, errors } : { valid: true, value: { name, phone } }
}
```

## Rules

- Allow-list, do not block-list. Define what is valid, reject the rest.
- Trim first, then check length, then check format.
- Set a maximum length on every text input and textarea, in the validator and with `maxLength`.
- Accept real names: `O'Brien`, `Zoë`, `Nguyễn`, `Van der Berg`. Do not restrict names to ASCII letters.
- The client check is a usability aid. Validate again wherever the data is actually used.

## Accessibility

- Every control has a visible label. Connect it with `htmlFor` and `id`.
- Set `aria-invalid` on a field in error and `aria-describedby` to the id of its error text. `Field` does not do this yet. Change it once, in the shared component.
- On a failed submit, move focus to the first invalid field.
- Use `autoComplete` tokens: `given-name`, `family-name`, `email`, `tel`.
- Announce success with `role="status"` and failure of the request with `role="alert"`.
- Disable the submit button while the request is pending to prevent double submission.

## Rendering

- Render user input as text. Never use `dangerouslySetInnerHTML`.
- Never log field values. They are personal data.
