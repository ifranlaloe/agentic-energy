---
name: operate-runbook
description: Writes an operational runbook for a feature before it is released with ownership, service levels, failure modes, detection, recovery, rollback, escalation and honest monitoring gaps, plus a blameless postmortem template. Use when a feature needs operating guidance before release, or when asked for a runbook, support notes or a postmortem.
metadata:
  version: "1.0"
  phase: operate
  leadership-question: "Can we run it and recover fast?"
  artifact: docs/plans/<slug>.md, section Runbook
  gate: every failure mode complete
---

# Operate runbook

Give whoever is on call what they need at 3am. Every statement must be true today.

- Entry: the plan has Design, Build log and Security review sections.
- Exit: a Runbook section in the plan with every failure mode complete.

## Procedure

1. Read the whole plan and the feature's code. Derive failure modes from the design's loading, empty and error states and from every dependency.
2. Append `assets/runbook-section.md` to `docs/plans/<slug>.md`. Do not edit other sections.
3. Fill the service overview, the dependencies and proposed service level objectives. Mark each objective "not measured today" when nothing measures it.
4. Write the failure modes table. For each failure give the user-visible symptom, how it would be detected, the likely cause, the recovery and the severity from `docs/standards/severity.md`.
5. Copy the rollback from the Design section. Add the escalation path.
6. Fill Known gaps with the monitoring and alerting that should exist and does not.
7. Check before finishing:
   - every failure mode has all five columns
   - no recovery step says "investigate" or "look into it"
   - the owner and escalation path say `Not assigned` and appear under Known gaps

For a postmortem, append `assets/postmortem-section.md` to the plan.

## Gotchas

- Northwind has no server, logs or alerting. Write "not monitored" and list it under Known gaps. Never invent monitoring.
- Write `Not assigned` for the owner and escalation path and list it under Known gaps. Never invent names, teams or channels.
- A recovery step is an action someone can take, such as "redeploy the previous build". "Check the logs" is not a recovery.
- Postmortems are blameless. Describe what the system and the process allowed, not who made a mistake.
