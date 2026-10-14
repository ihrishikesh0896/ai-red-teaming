# Model Usage Guidelines — Organization Policy Template

Org-wide rules for *using* AI models — chat assistants, coding assistants, APIs, and models the
org hosts itself. The other docs in this folder are for the people securing a deployment
([`pre_deployment_checklist.md`](pre_deployment_checklist.md),
[`model_security_checklist.md`](model_security_checklist.md)); this one is for everyone else.
Adapt the bracketed placeholders, get sign-off from Security/Legal/Privacy, and publish it
somewhere people will actually read before their first prompt.

**Owner:** [team] · **Approved by:** [Security / Legal / Privacy] · **Version / date:** [ ] ·
**Review cadence:** every 6 months, or when a new tool tier is added

## 1. Scope & who this applies to

* Applies to all employees, contractors, and vendors acting on the org's behalf
* Covers: third-party AI tools (web chat, browser extensions, IDE plugins, AI features inside
  SaaS you already use), model APIs, and internally hosted/fine-tuned models
* Covers AI features that arrive silently — a SaaS vendor switching on "AI assist" is a new
  tool for the purposes of this policy, not a product update

## 2. Approved tools register

Maintain a single list of approved tools and what each is approved *for*. Usage outside the
register is not permitted, regardless of whether the tool is free or personal.

| Tool / model | Tier | Max data classification | Approved uses | Contract terms checked |
|---|---|---|---|---|
| [e.g. enterprise chat assistant] | Enterprise (SSO, no training on inputs) | Confidential | General drafting, analysis, code | ✅ DPA, retention, no-train |
| [e.g. coding assistant] | Enterprise | Internal + source code | Code completion/review in approved repos | ✅ |
| [e.g. self-hosted model] | Internal | Restricted (per deployment's model card) | Per [`model_card_template.md`](model_card_template.md) intended use | n/a |
| Consumer / personal accounts of any tool | Not approved | Public only | Nothing involving org data | ❌ |

* **Requesting a new tool:** [process / form link]. Security review covers data retention,
  training-on-inputs, data residency, SSO, audit logging, and sub-processors
* An enterprise tier and a consumer tier of the same product are *different tools* — the
  approval is for the contract, not the brand

## 3. Data handling — what can go into a prompt

Map your existing data classification scheme to AI use. Default rule: **if you wouldn't email
it to the vendor, don't paste it into their model.**

| Classification | Consumer/unapproved tools | Approved enterprise tools | Internally hosted models |
|---|---|---|---|
| Public | ✅ | ✅ | ✅ |
| Internal | ❌ | ✅ | ✅ |
| Confidential (customer data, financials, unreleased plans, source code) | ❌ | ✅ only if register says so | ✅ if deployment approved for it |
| Restricted (credentials, secrets, regulated data — PHI, PCI, government IDs) | ❌ | ❌ | ❌ unless explicitly approved per deployment |

Never put into any prompt:

* [ ] Passwords, API keys, tokens, private keys, connection strings — includes pasting logs,
      config files, or stack traces that contain them
* [ ] Customer/employee personal data beyond what the approved use strictly needs
* [ ] Data you're contractually or legally barred from sharing with third parties (check
      customer contracts and NDAs — some prohibit AI processing outright)
* [ ] Material under legal hold or privilege

Attachments, screenshots, voice, and "connect your Drive/email" integrations count as prompts.
Connecting an AI tool to a mailbox or file store grants it everything that account can read.

## 4. Acceptable use

**Generally fine (with approved tools):** drafting and editing, summarizing documents you're
allowed to share with the tool, brainstorming, code assistance, research starting points,
translating, data analysis on appropriately classified data.

**Not permitted:**

* Making or fully automating decisions with significant effect on people — hiring, firing,
  performance ratings, credit, pricing for individuals, eligibility — without documented human
  review and Legal sign-off
* Generating content that impersonates a real person, or that is presented as human-written
  where disclosure is required (see §6)
* Circumventing a tool's safety controls, or the org's own guardrails, outside an authorized
  red-team engagement (see [`rules_of_engagement.md`](rules_of_engagement.md))
* Using AI to process data or produce output that would violate any existing policy —
  harassment, discrimination, IP, export control, security policy — "the model wrote it" is
  not an exception
* Uploading third-party copyrighted or licensed material in ways the license doesn't permit

## 5. Verify output — you own what you ship

AI output is a draft from an unreliable colleague. The person who uses it is accountable for it.

* [ ] **Facts, citations, numbers, legal/medical/financial claims** — verify against a primary
      source. Models fabricate references and statistics fluently
* [ ] **Code** — review it like a stranger's PR. Check for: hardcoded secrets, injection flaws,
      insecure defaults, invented or typosquatted package names (verify every new dependency
      actually exists and is the intended one), licensing of reproduced snippets. Normal code
      review and CI security scanning apply unchanged
* [ ] **Customer-facing content** — human review before it's sent or published
* [ ] **Commands and scripts** — read before running, especially anything touching production,
      deleting data, or changing permissions

## 6. Transparency & disclosure

* Disclose AI involvement where a reader would reasonably expect to know, and always where law
  or contract requires it (e.g. customer-facing chatbots must identify as AI; [jurisdiction-
  specific requirements — e.g. EU AI Act transparency obligations])
* Don't label AI-generated work as solely your own in contexts where authorship matters —
  publications, legal filings, academic work, formal reports
* AI-generated images/audio/video depicting real people require [Legal / Comms] approval

## 7. Agents, integrations & automation

Anything where the model *takes actions*, not just produces text, carries more risk and
needs more approval.

* [ ] Agents/automations with write access to org systems (email send, ticket updates, code
      merge, payments, record changes) need a security review before go-live — see
      [`../thickclient_ai_notes/checklist.md`](../thickclient_ai_notes/checklist.md) for
      low-code platforms
* [ ] Run agents under a scoped service identity, not your personal account with all its access
* [ ] Human approval step for irreversible or external-facing actions
* [ ] MCP servers, plugins, and extensions follow the same approval as tools — see
      [`../mcp_server_notes/consumer_checklist.md`](../mcp_server_notes/consumer_checklist.md)
* [ ] Treat any content the model reads (web pages, emails, documents, tool output) as
      potentially carrying instructions — prompt injection is the reason agents shouldn't hold
      more privilege than the least-trusted input they process

## 8. Building with models (product & engineering)

Using a model inside something the org ships or operates internally:

* [ ] API keys in a secrets manager, per-environment, rotated; never in code, notebooks, or
      client-side bundles
* [ ] Use org-managed accounts/billing for model APIs — no personal keys on company work
* [ ] Before hosting or exposing a model: [`pre_deployment_checklist.md`](pre_deployment_checklist.md)
      and a completed [`model_card_template.md`](model_card_template.md)
* [ ] Downloaded open-weight models come from official sources and are scanned
      (`pipeline/modelscan/`) before loading — model files can execute code
* [ ] Spending limits and usage alerts set on every API account

## 9. Incidents & reporting

Report to [security contact / channel] promptly if you:

* Pasted restricted or confidential data into an unapproved tool (early reporting lets us
  request deletion — it is not a disciplinary trap)
* See a model output that leaks other users' or org data
* Notice an agent or integration took an action nobody intended
* Find a jailbreak or guardrail bypass in an org-deployed model
* Discover a team using an unapproved AI tool on org data

## 10. Training & acknowledgment

* Everyone completes [AI usage training] before access to approved tools is provisioned;
  refresh annually
* Annual acknowledgment of this policy, tracked by [HR / GRC]
* Violations handled under the existing [acceptable use / disciplinary] policy

---

## Quick reference (one-pager for staff)

1. Use only tools on the approved register — consumer accounts are not approved for org data
2. No secrets, credentials, or regulated data in any prompt, ever
3. Match the data's classification to the tool's tier before you paste
4. Verify facts, code, and anything customer-facing — you own the output
5. No AI-only decisions about people
6. Disclose AI use where readers would expect to know
7. Agents that take actions need review and a scoped identity
8. Made a mistake? Report it fast to [contact]
