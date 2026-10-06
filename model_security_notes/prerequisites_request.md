# Internally Hosted Model — Security Assessment Prerequisites Request

Send this to the model owner / application team **before** any testing starts. Do not begin
assessment work until the items marked **(blocking)** are provided — without them you don't
know what you're testing, and you have no legal/operational cover to test it.

---

## 0. Scoping question — ask this first

> **"Are we assessing the foundation model itself, the model-serving API, or the complete AI
> application built around the model (RAG, tools, agents, backend integrations)?"**

These are three different assessments with different scope, time, and tooling. Get this answer
in writing before scheduling anything else below.

---

## A. Scope & ownership (blocking)

* [ ] Model name and version
* [ ] Model owner / team (technical point of contact)
* [ ] Business/application owner (risk-acceptance authority)
* [ ] Assessment environment — DEV / TEST / UAT / PROD (prefer a dedicated non-prod environment)
* [ ] Explicit written authorization to perform security testing
* [ ] Assessment start/end date
* [ ] Approved tester source IPs / networks
* [ ] Emergency contact during testing window
* [ ] Incident escalation contact
* [ ] Known production dependencies that must not be impacted

## B. Model information

**Architecture**
* [ ] Base/foundation model and model family
* [ ] Parameter count, context window, quantization
* [ ] Fine-tuned or base model; fine-tuning methodology (RLHF/DPO/other)
* [ ] System prompt / policy layer
* [ ] Safety/guardrail model and content-moderation layer, if any
* [ ] Input/output filtering in place
* [ ] Embedding model and reranker, if applicable

**Provenance** (where the artifact came from — this is where supply-chain risk starts)
* [ ] Original model source / repository
* [ ] Model artifact hash/checksum
* [ ] Model conversion process
* [ ] Training and fine-tuning dataset provenance
* [ ] Third-party models/components, open-source dependencies, license info

## C. Architecture diagram (blocking)

Request an **end-to-end data-flow diagram**:

```
User → API Gateway (Auth/WAF) → AI Application (Prompt Builder)
                                      ├── RAG / Vector DB
                                      └── Tools / APIs / DB
                                      ↓
                                 LLM Inference
                                      ↓
                              Output Filters → User
```

If the team cannot produce this, **do not start red teaming** — push back and get the diagram
first.

## D. API access

* [ ] API base URL and OpenAPI spec / documentation
* [ ] Authentication mechanism
* [ ] Test credentials for **separate privilege levels**: anonymous, normal user, privileged
      user, administrator (critical for authorization testing — ask for this explicitly)
* [ ] Request/response format; streaming vs non-streaming endpoints
* [ ] File upload endpoints, conversation/session APIs
* [ ] Model-selection, temperature/top-p and other inference parameters
* [ ] Function/tool-calling API, RAG endpoints, admin endpoints (if in scope)

## E. Data handling

Ask whether the model receives: PII, financial data, credentials/secrets, internal documents,
source code, customer data, HR data, health data, confidential documents, or sensitive training
data.

* [ ] Request a **synthetic test dataset** (e.g. `TEST_CUSTOMER_001`, `TEST_CARD_001`,
      `TEST_SECRET_001`) — never ask for real production secrets to test leakage.

## F. Logging access

Request read access to, or exports of:

* [ ] API access logs, authentication logs, application logs
* [ ] Model inference/prompt/response logs
* [ ] RAG retrieval logs, tool invocation logs
* [ ] Security events, rate-limit events, error logs

Ideally each log line correlates: request ID, user ID, timestamp, model version, prompt,
retrieved documents, tools invoked, response, security decision, latency, token usage.

This is what lets you distinguish *"I performed prompt injection"* from *"I performed prompt
injection and caused an unauthorized backend action"* — the second is the finding that matters.

---

## Next document

Once this is filled in, get the **[Rules of Engagement](rules_of_engagement.md)** signed off
before touching the system, then work through the
**[Model Security Checklist](model_security_checklist.md)**.
