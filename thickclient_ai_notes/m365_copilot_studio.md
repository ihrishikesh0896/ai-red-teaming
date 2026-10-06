# Platform Notes — Microsoft 365 Copilot Studio

Maps to the generic categories in [`checklist.md`](checklist.md). Use this alongside the
generic checklist, not instead of it.

## 1. Run-as identity / privilege model

* Copilot Studio agents run on the **Power Platform**, inside an **environment**. Every
  connector call an agent makes uses a **connection**, and every connection is owned by
  whoever created it — check if that's the maker, an admin, or a shared service account.
* Per-topic/per-action **authentication mode** is the concrete control to inspect:
  - *No authentication* — anonymous callers get whatever the topic does; dangerous if the
    topic triggers a connector action.
  - *Authenticate manually* — the end user authenticates via OAuth; actions run as that user
    (delegated permissions) — the safer default.
  - *Authenticate with [a specific connection]* — the action runs as whoever owns that stored
    connection, regardless of who's chatting. **This is the confused-deputy case**: a
    low-privileged chat user can trigger an action that runs with the connection owner's
    (often an admin's) permissions.
* Newer **autonomous/agentic triggers** (event-based, no human in the loop at invocation time)
  always run under a configured identity with no "caller" to delegate to — confirm what that
  identity can do and whether it's scoped down from a full admin/service account.
* Check Power Platform **Dataverse security roles** if the agent reads/writes Dataverse tables
  — row-level and column-level security still apply, but only if security roles are actually
  configured; a misconfigured "System Administrator"-equivalent role defeats this entirely.

## 2. Connector / credential security

* Connections are tied to an **environment**; a maker with "Environment Maker" role can create
  new connections but inherits whatever DLP policy applies to that environment.
* Check **connector classification**: Power Platform DLP policies bucket connectors into
  Business / Non-Business / Blocked. The test: can a maker build a flow that moves data from a
  Business-classified connector to a Non-Business one, bypassing the policy intent by routing
  through an intermediate step (e.g. HTTP connector, or a Non-Business connector that's
  accidentally left Business-classified)?
* Confirm whether connections are **shared** (visible/reusable by other makers in the
  environment) or **personal** — shared connections are the common way one maker's
  over-privileged credential ends up powering someone else's workflow.

## 3. Trigger / entry-point exposure

* Publishing **channels** each have a different exposure profile — check all that are enabled:
  Teams, a custom website (via Direct Line / embed code), Power Apps, a custom mobile app,
  Facebook/other third-party channels (if licensed). A copilot built for internal Teams use can
  end up live on a public-facing website channel without anyone re-reviewing authN.
* **Direct Line / API access**: if a secret/token for the Direct Line channel leaks, anyone can
  talk to the agent as if they were on the intended channel — check how that token is
  generated, rotated, and scoped.
* Tenant-wide toggle: **"allow users to create agents"** / web search grounding — if generative
  AI web search is enabled for an agent, it gains live internet access, which both expands
  prompt-injection surface (attacker-controlled web content becomes "retrieved content") and
  creates an SSRF/exfiltration-adjacent path (agent can be induced to fetch attacker URLs).

## 4. Prompt injection → action chaining

* Microsoft ships a **cross-prompt injection attack (XPIA) classifier** for Copilot Studio —
  confirm it's actually enabled for the agent/environment under test, don't assume it's on by
  default for every topic/action.
* Test the **orchestrator** specifically: with multiple topics defined, can injected content in
  one topic's response cause the orchestrator to route to or invoke a different topic/action
  than the one the end user asked for?
* For any topic wired to an **Action** (Power Automate flow or a plugin) that writes data or
  sends something externally: confirm there's a confirmation/adaptive-card approval step before
  execution, not direct autonomous execution from model output.

## 5. Knowledge source oversharing

* This is the single most consequential category for M365 Copilot specifically. Generative
  answers draw from the **Microsoft Graph connectors** and the **Semantic Index** — which
  mirrors whatever permissions already exist in SharePoint/OneDrive/Exchange, *including*
  pre-existing misconfigurations that were never practically discoverable before (no one was
  going to manually crawl every over-shared folder — a natural-language agent will).
- [ ] Explicit test: as a low-privileged test user, ask generative-answers questions about
      topics you know exist in a document you shouldn't have access to, without naming the
      file — if it answers from the content, that's a finding about SharePoint permissions,
      not about the model.
* Check whether the agent is scoped to specific SharePoint sites/Dataverse tables ("graph
  grounding" configured explicitly) vs. the tenant-wide default search index — the latter is
  much higher risk and much more common than teams realize.
* DLP policy check from §2 applies here too — a knowledge source connector classified
  Non-Business shouldn't be combinable with a Business action connector in the same agent.

## 6. Code-execution nodes

* Classic Copilot Studio topics use **Power Fx** expressions, not general-purpose code — lower
  arbitrary-code-execution risk than n8n's Code node, but Power Fx can still call connectors
  and construct dynamic values; check whether Power Fx expressions can be influenced by model
  output in a way that changes which connector/action gets called.
* If the agent has a **custom connector** backed by an Azure Function or external API the org
  controls: that function is effectively a code-execution node — apply the full `checklist.md`
  §6 test list to it directly (sandboxing, credential isolation, egress/SSRF).

## 7. Self-hosted deployment hardening

* Not applicable — Copilot Studio is vendor-SaaS. Skip, but confirm the org isn't also running
  a self-hosted bot framework alongside it that *does* need this section.

## 8. Thick-client specific surface

* Teams-embedded copilots: check how the Teams client caches conversation history and tokens
  locally, and whether a custom-engine agent can be **sideloaded** into Teams by a user without
  admin review (tenant setting: "allow sideloading of custom apps").
* Desktop M365 Copilot (the Office-embedded assistant, distinct from Copilot Studio): review
  what local file/content access it has (open documents vs. full local index) and what gets
  sent in telemetry.

## 9. Governance & audit

* Power Platform **environments** are the dev/test/prod boundary — confirm agents aren't being
  built and published directly in the tenant's **Default environment**, which typically has
  looser governance and broad maker access by default. This is the most common governance gap
  found in practice.
* **Microsoft Purview / unified audit log** should capture Copilot Studio agent creation,
  publishing, and (depending on licensing) interaction logs — confirm audit logging is actually
  enabled for Copilot/Power Platform activities, since it isn't always on by default per
  tenant.
* Admin center checklist to pull before testing: environment list + DLP policy per environment,
  "who can create agents" tenant setting, connector classification list, and the list of
  published channels per agent in scope.
