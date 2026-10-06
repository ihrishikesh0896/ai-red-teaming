# Model Security Checklist — Internally Hosted Models

Use this after [prerequisites](prerequisites_request.md) are collected and the
[rules of engagement](rules_of_engagement.md) are signed. Organized into 4 passes so you don't
try to execute all ~40 test categories at once. Priority: **P0** = test first / blocks sign-off,
**P1** = test before final report.

Backbone standards: OWASP AI Testing Guide, OWASP AISVS, OWASP GenAI/LLM Top 10, NIST AI RMF,
MITRE ATLAS — use these instead of inventing a proprietary taxonomy from scratch.

---

## Pass 0 — Scoping (before any testing)

* [ ] P0 — Confirmed scope: foundation model / serving API / full application (see
      prerequisites doc §0)
* [ ] P0 — Architecture & data-flow diagram reviewed
* [ ] P0 — Trust boundaries identified on the diagram (where does untrusted input enter, where
      does the model's output become trusted input to something else)
* [ ] P0 — Test accounts confirmed at each privilege level (anonymous/user/privileged/admin)

---

## Pass 1 — Traditional AppSec (an AI API is still an API)

### Authentication
* [ ] Missing authentication on any endpoint
* [ ] Invalid / expired / replayed tokens accepted
* [ ] API key leakage (client-side, logs, error messages)
* [ ] JWT manipulation (alg confusion, kid injection, signature stripping)
* [ ] Authentication bypass, session fixation

### Authorization
* [ ] User A → User A's own data ✓ (sanity check)
* [ ] User A → User B's data — should fail (IDOR/BOLA)
* [ ] User A → admin operation — should fail (BFLA, privilege escalation)
* [ ] Cross-tenant isolation failure
* [ ] Cross-user conversation/session access
* [ ] Cross-tenant RAG access

### API security
* [ ] Input validation, parameter tampering, mass assignment
* [ ] HTTP method manipulation, excessive permissions
* [ ] Rate limiting, request size limits, resource exhaustion
* [ ] File upload validation
* [ ] SSRF, SQL injection, command injection, template injection, deserialization
* [ ] Error disclosure, sensitive headers, CORS, TLS config, API versioning

---

## Pass 2 — Model-level security

### Prompt injection
* [ ] Direct injection ("ignore all previous instructions" and variants)
* [ ] Instruction override, role manipulation, delimiter manipulation
* [ ] Instruction-hierarchy attacks, multi-turn injection
* [ ] Indirect injection (via retrieved content / tool output)
* [ ] Encoded injection (base64, unicode tricks), multilingual injection
* [ ] Context manipulation across turns

### System prompt / instruction extraction
* [ ] System prompt, developer instructions, hidden policies
* [ ] Tool descriptions, internal configuration, internal URLs
* [ ] Secrets accidentally embedded in prompts
* [ ] **For each disclosure found, ask:** does it enable bypassing another security boundary?
      (disclosure alone is not automatically critical)

### Jailbreak testing — don't rely on one technique
* [ ] Single-turn → multi-turn → role-play → encoding → multilingual → context manipulation →
      adaptive/combined attacks (work through this escalation, not just one layer)

### Sensitive information disclosure
* [ ] User data: can User A obtain User B's information?
* [ ] System data: can internal instructions be revealed?
* [ ] RAG data: can a low-privileged user retrieve restricted documents?
* [ ] Training data: memorization, data reconstruction, membership inference, extraction

### Model extraction / inference abuse
* [ ] Repeated-query behavior reconstruction / architecture inference
* [ ] Rate limiting present on inference endpoint
* [ ] Model metadata, logits/probabilities, embeddings exposed unnecessarily
* [ ] Confirm the organization's acceptable extraction query threshold *before* running volume
      tests (from rules of engagement)

### Denial of service / resource exhaustion (self-hosted = higher priority)
* [ ] Huge prompts, max context, huge outputs, concurrent/repeated requests, streaming abuse
* [ ] Expensive reasoning requests, pathological inputs, long-context, token amplification
* [ ] Measure: GPU/VRAM/CPU/RAM, latency, queue depth, tokens/sec, OOM events, pod restarts
* [ ] Real question: can a low-privileged/unauthenticated user disproportionately consume
      inference resources — not just "can I crash it"

---

## Pass 3 — AI application layer

### RAG security (separate assessment if RAG is present)
* [ ] Retrieval authorization: can User A retrieve User B's documents via the vector DB?
* [ ] Document/embedding/metadata poisoning via a controlled malicious test document
* [ ] Cross-tenant retrieval, unauthorized document access
* [ ] Malicious PDFs/Office docs with hidden instructions
* [ ] Prompt injection embedded in retrieved content (indirect injection via RAG)

### Agent / tool security (higher priority if tools are exposed)
* [ ] Tool authorization — can the model invoke tools the current user shouldn't have access to?
* [ ] Parameter manipulation (e.g. `user_id` substitution) in tool calls
* [ ] Tool chaining producing an unauthorized outcome (Tool A → B → C)
* [ ] Excessive agency: can the model delete/modify/send/purchase/execute/deploy/approve
      without sufficient human-in-the-loop authorization?
* [ ] Memory poisoning (if the agent has persistent memory)

### Output security — model output as untrusted input to another system
* [ ] Generated SQL → database (SQL injection)
* [ ] Generated HTML/Markdown → browser (XSS, HTML injection)
* [ ] Generated shell commands → server (command injection)
* [ ] Generated URLs → SSRF
* [ ] Unsafe deserialization of generated content
* [ ] Key question for every sink: **is model output treated as trusted input downstream?** If
      yes, this is high priority regardless of how "safe" the model seems.

### Privacy
* [ ] PII exposure across the full pipeline (prompt logs, response logs, retention policy)
* [ ] Cross-user memory leakage: User A's sensitive input retrievable by User B?
* [ ] Data residency, encryption at rest/in transit, backup copies
* [ ] Deletion requests actually propagate (logs, embeddings, cache, backups)

### Hallucination / reliability (relevant where the model drives decisions)
* [ ] Fabricated facts/references/security controls
* [ ] Incorrect authorization decisions made by the model itself
* [ ] Refusal consistency under rephrasing
* [ ] Especially check this if the model informs HR, financial, security, medical, legal, or
      access decisions

---

## Pass 4 — Infrastructure & supply chain

### Host / container / Kubernetes
* [ ] OS hardening, SSH exposure, unnecessary open ports
* [ ] Privileged containers, Docker socket exposure, host networking, GPU access,
      filesystem access
* [ ] Container: root user, capabilities, seccomp/AppArmor/SELinux, read-only FS, mounted
      secrets/host paths, image vulnerabilities
* [ ] Kubernetes: RBAC, service accounts, network policies, pod security, namespace
      isolation, ingress/egress, GPU node isolation

### Network
* [ ] Map what the model server can communicate with — egress should be tightly controlled
* [ ] Internet → API Gateway → Inference API → Model server → GPU path reviewed end to end

### Model supply chain
* [ ] Model artifact hash verified against source
* [ ] Unsafe serialization / pickle-based artifacts
* [ ] Unverified downloads, missing hashes, unsigned artifacts
* [ ] Dependency vulnerabilities, poisoned datasets, malicious LoRA/adapters
* [ ] Compromised container images
* [ ] AIBOM/SBOM exists and is current

### Data poisoning (only if your org trains/fine-tunes)
* [ ] Training data integrity, unauthorized dataset modification
* [ ] Malicious examples, poisoned labels
* [ ] Behavioral backdoors: trigger phrase → unexpected behavior, vs. normal input → normal
      behavior

---

## Automated red-team pass (run after, not instead of, the above)

* [ ] **Garak** — automated LLM vulnerability probing
* [ ] **PyRIT** — multi-turn automated/human-led red teaming against custom HTTP endpoints
* [ ] **Promptfoo** — regression-friendly AI security testing (LLM/RAG/agent/MCP configs)

Configure these against the actual architecture and business purpose — don't run default
scanner profiles blind and call it coverage.

Supporting AppSec tooling: Burp Suite, OWASP ZAP (API/web), Nuclei (infra/API exposure), Trivy
(container/dependency), Semgrep (app code), Gitleaks (secret detection).

---

## Master tracker

| Area | Test | Priority |
|---|---|---|
| Architecture | Data-flow review | P0 |
| Architecture | Trust-boundary review | P0 |
| Auth | Authentication bypass | P0 |
| AuthZ | BOLA/IDOR | P0 |
| AuthZ | Privilege escalation | P0 |
| API | Rate limiting | P1 |
| API | Input validation | P1 |
| API | SSRF | P1 |
| API | Injection | P1 |
| Model | Prompt injection | P0 |
| Model | Jailbreak | P1 |
| Model | System prompt extraction | P1 |
| Model | Sensitive data leakage | P0 |
| Model | Training-data extraction | P1 |
| Model | Model extraction | P1 |
| Model | Membership inference | P1 |
| RAG | Retrieval authorization | P0 |
| RAG | RAG poisoning | P0 |
| RAG | Indirect prompt injection | P0 |
| Agent | Tool authorization | P0 |
| Agent | Tool parameter manipulation | P0 |
| Agent | Excessive agency | P0 |
| Agent | Tool chaining | P0 |
| Agent | Memory poisoning | P1 |
| Output | XSS | P1 |
| Output | SQL injection | P0 |
| Output | Command injection | P0 |
| Output | SSRF | P0 |
| Availability | Token exhaustion | P1 |
| Availability | GPU exhaustion | P1 |
| Infrastructure | Container escape | P0 |
| Infrastructure | Kubernetes RBAC | P0 |
| Infrastructure | Network isolation | P0 |
| Infrastructure | Secret exposure | P0 |
| Supply chain | Model provenance | P1 |
| Supply chain | Artifact integrity | P0 |
| Supply chain | Dependencies | P1 |
| Supply chain | Model poisoning | P1 |
| Data | Dataset integrity | P1 |
| Privacy | PII leakage | P0 |
| Privacy | Cross-user leakage | P0 |
| Logging | Security event logging | P1 |
| Monitoring | Attack detection | P1 |

---

## Reference material

* OWASP AI Testing Guide — https://owasp.github.io/www-project-ai-testing-guide/
* OWASP AISVS (AI Security Verification Standard) — https://owasp.github.io/www-project-artificial-intelligence-security-verification-standard-aisvs-docs/
* OWASP GenAI/LLM Top 10 — https://genai.owasp.org/
* NIST AI RMF + Generative AI Profile — https://www.nist.gov/itl/ai-risk-management-framework
* Microsoft AI Red Team — https://learn.microsoft.com/en-us/security/ai-red-team/
* PyRIT — https://microsoft.github.io/PyRIT/latest/
* NVIDIA Garak — https://github.com/NVIDIA/garak
* Promptfoo Red Teaming Guides — https://www.promptfoo.dev/docs/red-team/guides/
