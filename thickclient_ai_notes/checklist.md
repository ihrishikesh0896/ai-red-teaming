# Security Checklist — Thick-Client / Low-Code AI Platforms

Scope: tools where a non-security-trained "maker" builds an AI agent/workflow on top of a
vendor-managed or self-hosted platform, which then holds credentials to other systems and can
take real actions. Examples: **M365 Copilot Studio**, **n8n**, Power Automate, Zapier AI,
UiPath (RPA+AI), Retool AI, Flowise/Langflow.

This is generic and platform-agnostic by design. Platform-specific detail (admin console
settings, concrete toggles, where identity actually comes from) lives in a sibling note per
platform — see [`m365_copilot_studio.md`](m365_copilot_studio.md) (n8n notes to follow).

This is distinct from `model_security_notes/` (which assumes you're testing a model/API you
control end-to-end). Here the platform itself is a trust boundary you don't own, and the
biggest risks come from **governance gaps**, not model weaknesses. The single highest-impact
scenario on these platforms is *prompt injection chained into a connector action* — i.e. the
existing Pass-2 (model) + Pass-3 (agent) tests from `model_security_checklist.md`, except the
"tool" is a pre-built connector holding a real OAuth token to a production system, wired up by
someone who may not have thought about authZ at all.

---

## 1. Run-as identity / privilege model (the #1 risk on these platforms)

The question that matters most: **when the agent takes an action, whose identity/permissions
is it using?**

* [ ] Does the agent run as the **end user** (delegated permissions) or as the
      **maker/publisher's** identity or a **service principal** (application permissions)?
* [ ] If it runs as a privileged service identity: can a low-privileged end user, through chat,
      cause the agent to perform an action the end user themselves couldn't do directly?
      (classic confused-deputy / privilege escalation)
* [ ] Is there a different answer for different trigger types (chat vs webhook vs scheduled vs
      email trigger) within the same platform?
* [ ] Check per-step/per-action authentication mode, not just the workflow as a whole — a
      single flow can mix "run as caller" and "run as service account" across different steps.

## 2. Connector / credential security

* [ ] How are credentials for connectors (OAuth tokens, API keys, DB connection strings) stored
      by the platform — vault, encrypted at rest, accessible to makers in plaintext?
* [ ] Can a maker who builds a workflow **reuse another maker's stored connection** without
      re-authenticating? (credential sharing across workflows/users)
* [ ] OAuth scope granted to each connector — is it broader than the workflow needs (e.g.
      `Mail.ReadWrite` granted when the flow only ever reads)?
* [ ] For community/third-party connectors or nodes: what code do they run, who vetted it, is
      it sandboxed from the host/other credentials in the same workflow?
* [ ] Can one node/action in a workflow read credentials or data intended for a different
      node/connector in the same workflow? (cross-connector data leakage within one workflow)

## 3. Trigger / entry-point exposure

This is where untrusted input gets into the system — treat every trigger like an unauthenticated
API endpoint until proven otherwise.

* [ ] Public chat widget / embedded copilot: is it reachable by anonymous/unauthenticated users?
* [ ] Webhook triggers: is the webhook URL unguessable, authenticated, rate-limited?
* [ ] Email-triggered flows: can an external sender trigger actions just by sending a crafted
      email (subject/body prompt injection → connector action)?
* [ ] File-upload/file-created triggers: can a file with injected instructions in its
      content/metadata reach the agent?
* [ ] Rate limiting / abuse controls on every trigger type, not just the main chat endpoint.

## 4. Prompt injection → action chaining

* [ ] Take every injection technique from `model_security_checklist.md` §Prompt Injection and
      re-run it, but this time check whether it can reach a **connector action** (send email,
      create/delete record, write file, post message) rather than just altering chat output.
* [ ] Indirect injection via a document/email/record the agent reads as "data," not as a
      trusted instruction — does the platform distinguish instructions from retrieved content
      at all, or is everything concatenated into one prompt?
* [ ] Multi-step workflows: can injection in step 1's output alter the behavior of step 3's
      action, several nodes downstream?
* [ ] Is there a human-approval/confirmation gate before any destructive or external-facing
      action (send email, post publicly, modify record) — or does the agent execute
      autonomously end to end?

## 5. Knowledge source oversharing (generative answers / RAG-on-existing-content)

Specific to platforms that let the agent answer from "whatever the index already has access
to":

* [ ] Does the agent's effective read access match the **querying user's** permissions, or the
      **index/service account's** permissions? (classic oversharing problem — the agent
      surfaces anything the underlying search index can see, exposing pre-existing permission
      misconfigurations that were previously just theoretically over-shared but practically
      undiscoverable)
* [ ] Run the oversharing test explicitly: as a low-privileged user, ask the agent for content
      you shouldn't have access to by topic/keyword rather than by exact file name, and see if
      it retrieves it anyway.
* [ ] Are data-loss-prevention policies configured to prevent combining a "sensitive" data
      source connector with an "open" one in the same flow — and can a maker bypass this by
      chaining through an intermediate connector/step?

## 6. Code-execution nodes

Many of these platforms expose a Code/Function node (arbitrary JS/Python) directly in the
workflow canvas.

* [ ] Is the code node sandboxed from the host OS, network, and filesystem, or does it run with
      full runtime privileges?
* [ ] Can code in this node read credentials/environment variables belonging to other nodes in
      the same workflow, or to other workflows on the same instance?
* [ ] Can an injected prompt (from §4 testing) cause the LLM to generate code that then runs
      unsanitized in this node? (prompt injection → arbitrary code execution is the worst-case
      chain on these platforms)
* [ ] Egress from the code node — can it reach internal network ranges / metadata endpoints
      (SSRF from inside a workflow)?

## 7. Self-hosted deployment hardening

Only applies when the platform is self-hosted rather than vendor-SaaS:

* [ ] Is the admin/editor UI exposed to the internet without authentication or behind weak
      default credentials?
* [ ] Are secrets (DB creds, encryption key, OAuth client secrets) stored in plaintext env vars
      / compose files that are readable by anyone with host/repo access?
* [ ] Workflow/template import from community marketplaces — vetted before import, or
      copy-pasted and run blind? (supply-chain risk, same category as malicious npm packages)
* [ ] Update/patch cadence — is the instance running a version with known CVEs?
* [ ] Multi-tenancy on one instance: can one tenant's workflows/credentials be reached from
      another tenant's workflow?

## 8. Thick-client specific surface (desktop/Office-embedded copilots)

Applies to client apps (Teams/Office-embedded Copilot, desktop RPA clients) rather than pure
web platforms:

* [ ] Where are session tokens / refresh tokens cached locally (DPAPI, keychain, plaintext
      config)? Can another local process/user read them?
* [ ] Local file access granted to the AI feature — scoped to what the user opened, or broader
      (e.g. full-disk/indexing access)?
* [ ] Local telemetry/diagnostic logs — do they capture full prompts/responses including
      sensitive content, and where do those logs end up (local disk, vendor telemetry pipeline)?
* [ ] Auto-update mechanism — signed updates, integrity-verified, or spoofable update channel?
* [ ] IPC between the client app and any local helper process/add-in — authenticated, or can a
      local unprivileged process inject messages?

## 9. Governance & audit (tenant-level, applies to both SaaS and self-hosted)

* [ ] Environment separation (dev/test/prod) actually enforced, or can a maker publish straight
      to prod with no gate?
* [ ] Who can publish/edit a workflow vs who can only run it — RBAC enforced at the platform
      level, not just social convention?
* [ ] Is there an audit log of: who created/edited a workflow, what connections it uses, when
      it ran, and what actions it took? Can a maker see/export another maker's workflow
      definition (IP/credential exposure) via sharing or export features?
* [ ] Kill-switch: can a single malicious/compromised workflow be disabled platform-wide
      quickly, and are affected connections rotated after?

---

## Platform notes

* [`m365_copilot_studio.md`](m365_copilot_studio.md) — Power Platform environments, DLP
  policies, topic/action auth modes, Dataverse security roles, Semantic Index oversharing,
  autonomous agents, admin-center settings to check.
* `n8n.md` — not yet written.
