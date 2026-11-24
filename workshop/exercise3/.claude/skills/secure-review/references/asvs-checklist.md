# Checklist (OWASP ASVS 4.0.3, client-side subset)

Walk every row. Record Pass, Fail or Not applicable with `file:line` evidence.

| ASVS | Requirement | CWE | What to check in Northwind |
|---|---|---|---|
| V5.1.3 | Input is validated with allow lists | CWE-20 | Each form field has a validator that defines what is valid |
| V5.1.4 | Structured data is typed and validated | CWE-20 | Values are typed, and the API function receives validated values only |
| V5.2.2 | Unstructured data is limited by allowed characters and length | CWE-20 | Every text input has a maximum length in the validator and `maxLength` |
| V5.3.3 | Output is escaped for its context | CWE-79 | No `dangerouslySetInnerHTML`, no `innerHTML`, input rendered as text |
| V8.2.2 | Browser storage holds no sensitive data or PII | CWE-922 | No personal data in `localStorage`, `sessionStorage` or cookies |
| V8.3.4 | Sensitive data is identified and handled by policy | CWE-359 | The privacy table is complete |
| V7.1.2 | Personal data is not logged | CWE-532 | No `console` calls that include field values |
| V11.1.4 | Anti-automation controls limit abuse | CWE-770 | Submit is disabled while pending. Note the absence of server-side rate limiting |
| V14.2.1 | Components are up to date | CWE-1104 | `npm audit --omit=dev` result |
| V14.4.3 | A content security policy is in place | CWE-1021 | A CSP is normally set by hosting. Record a missing one as a Low note, unless the change loads external scripts or adds inline script, then it is Medium |

## OWASP Top 10 (2021) mapping

Injection and XSS are A03. Missing validation and rate limiting are A04. Outdated dependencies are A06. Missing or sensitive logging is A09.
