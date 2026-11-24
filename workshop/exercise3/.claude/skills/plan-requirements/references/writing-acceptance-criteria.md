# Writing acceptance criteria

## Format

Each criterion is a `#### AC-n <title>` heading followed by Given, When and Then lines. The validator and the test traceability script both read this shape.

## Rules

- One behaviour per criterion. If the Then line needs "and", split it.
- Observable outcome only: text on screen, a focus position, a value passed to the API. Not "the system handles it".
- Include the data. "An email without an @" is testable. "An invalid email" is not.
- Cover the unhappy paths: empty input, input over the limit, the API failing, submitting twice.
- Cover the boundaries: the shortest and longest accepted value, and one beyond each. `maxLength` stops typing at the limit, so prove the one-over case on the validator and not by typing.

## Replace vague words

| Vague | Testable |
|---|---|
| fast, quickly | "within 300 ms of the last keystroke" |
| easy, intuitive, user-friendly | "reachable in two clicks from the home page" |
| properly, appropriate | state the exact message or behaviour |
| robust | list the failure and the expected recovery |

## Prompts for non-functional requirements

- Accessibility: every control has a label, errors are announced to screen readers, the whole flow works with the keyboard alone.
- Security and privacy: which fields are personal data, what are the length limits and allowed characters, is anything logged or stored in the browser.
- Performance: loading and submitting states appear within a stated time, and double submission is prevented.

## Example

```markdown
#### AC-2 Reject an email without an @

Given the callback form with every other field valid
When I submit with the email "emma.example.com"
Then no request is sent
And the email field shows "Enter an email address like name@example.com"
And focus moves to the email field
```

The `And` lines are part of one outcome, so this is still one behaviour.
