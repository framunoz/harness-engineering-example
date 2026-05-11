# Escalation Rules

Escalate early when any of the following occur:

- Unclear or conflicting requirements.
- Architecture uncertainty or boundary conflicts.
- Repeated verification/test failures with no clear local fix.
- Blockers that require external decisions, credentials, approvals, or scope changes.
- Scope ambiguity that prevents reliable completion criteria.

Escalation path:

1. Capture facts, attempted actions, and impact in current session log.
2. Update `.agents/progress/CURRENT.md` with blocker status.
3. Mark affected feature(s) as `blocked` in `.agents/progress/feature_list.json` when appropriate.
4. Request decision/clarification from maintainer or user with concise options.
