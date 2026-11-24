# Severity

One scale for security findings, defects and incidents.

| Severity | Definition | Example | Release impact | Expected response |
|---|---|---|---|---|
| Critical | Exploitable now with serious impact, or customer data exposed | Stored script runs for every visitor | Blocks release | Fix before anything else |
| High | Exploitable with some effort, or a core journey is broken | Form input rendered unescaped | Blocks release | Fix before release |
| Medium | Weakness that needs another flaw to matter, or a degraded journey | No input length limit | Blocks release | Fix before release |
| Low | Hardening or polish | Missing `rel="noopener"` on a trusted link | Does not block | Backlog |
