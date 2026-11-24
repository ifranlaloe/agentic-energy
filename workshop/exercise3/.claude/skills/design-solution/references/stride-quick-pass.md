# STRIDE quick pass

Ask each question of the change. Record a threat only when the answer is yes, with its mitigation.

| Category | Question | Northwind prompts |
|---|---|---|
| Spoofing | Can someone act as another person? | The app has no login. Treat every submitter as anonymous and say so. |
| Tampering | Can input be altered to change behaviour? | Client-side validation can be bypassed. Validate again wherever the data is used. |
| Repudiation | Can an action be denied with no record? | No audit trail exists. Note it when the action matters to the business. |
| Information disclosure | Can data leak? | Personal data in URLs, logs, browser storage or error messages. |
| Denial of service | Can one actor exhaust the system? | Unbounded input size, repeated submission. Cap lengths and disable submit while pending. |
| Elevation of privilege | Can someone gain access they should not have? | No roles today. Mark not applicable and state why. |

## Output

```markdown
| Threat | Mitigation or accepted risk |
|---|---|
| Script tags typed into the message field render as markup | Render as text only, cap length at 1000, never use dangerouslySetInnerHTML |
```
