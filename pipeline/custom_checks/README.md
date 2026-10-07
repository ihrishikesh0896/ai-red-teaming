# custom_checks — Template, Not a Working Suite

Promptfoo/Garak/PyRIT test the model. They know nothing about **how your specific deployment
serves it**: your auth scheme, your privilege tiers, whether tools/agents are wired up, your
rate limits. That's this folder's job, and it can't be pre-built generically — it has to be
written against your actual API.

Everything in here is a **template with `TODO`s**, not something to run as-is. Before filling
these in:

1. Get the test accounts/credentials from `model_security_notes/prerequisites_request.md`
   (section D — separate creds for anonymous/user/privileged/admin).
2. Get written sign-off per `model_security_notes/rules_of_engagement.md` — these scripts do
   things like cross-user data access attempts and should only ever run against a non-prod
   environment unless explicitly authorized otherwise.
3. Point `BASE_URL` at that environment, never at prod, unless the rules of engagement say so
   explicitly.

## Files

* [`authz_idor_test.py`](authz_idor_test.py) — template for the User A → User B /
  privilege-escalation tests from `model_security_checklist.md` §Authorization. This is the
  highest-value custom check to fill in first — it's P0 on the master tracker and no
  off-the-shelf tool does it for you, since it requires real multi-tier credentials.
* [`excessive_agency_test.py`](excessive_agency_test.py) — template for §Agent/tool security:
  attempts a destructive/external-facing tool action (as defined by your deployment) via a
  prompt, and asserts a human-approval gate exists rather than silent execution.

## Why these aren't wired into CI

Unlike the Promptfoo/ModelScan steps, these make real authenticated calls that attempt
privilege escalation and tool abuse. Running them automatically on every PR against a live
environment is itself a risk if misconfigured (e.g. pointed at prod by a bad env var). Wire
them into CI yourself once filled in, scoped to a dedicated test environment, and gated the
same way any other destructive test suite would be.
