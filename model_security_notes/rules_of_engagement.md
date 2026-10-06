# Rules of Engagement — AI Model / Application Security Assessment

Get this signed by the model owner **and** the business/application owner before testing
begins. This is distinct from the [prerequisites request](prerequisites_request.md) — that
document gets you *information*, this one gets you *permission*.

## Engagement details

* **Model/application under test:** ______________________
* **Environment:** DEV / TEST / UAT / PROD (circle one — prod requires explicit extra sign-off)
* **Assessment window:** start ______ → end ______
* **Tester(s) / source IPs:** ______________________
* **Emergency contact (team side):** ______________________
* **Escalation contact (security side):** ______________________
* **Approved by (model owner):** ______________________ Date: ______
* **Approved by (business/application owner):** ______________________ Date: ______

## Allowed, within agreed limits

* Prompt injection (direct, indirect, multi-turn, encoded, multilingual)
* Jailbreaking
* System prompt / developer instruction extraction
* Sensitive-data extraction using **synthetic test data only**
* Model behavior manipulation
* RAG poisoning tests (against test/synthetic documents)
* Tool abuse and tool-chaining tests
* API fuzzing
* Authentication and authorization testing (including cross-privilege-level testing with the
  provided test accounts)
* Rate-limit testing
* DoS/resource-exhaustion testing **within agreed limits** (see below)
* File upload testing, malicious document testing (synthetic payloads only)
* Model extraction testing **within a defined query-volume limit**

## Explicitly prohibited unless separately approved in writing

* Any DoS testing against production
* Destructive database actions
* Access to real customer data
* Real credential extraction
* Destructive tool calls (delete, send, purchase, deploy, approve) against live systems
* Malware execution
* Exploitation of external/third-party systems
* High-volume GPU exhaustion beyond the agreed threshold
* Network scanning outside explicitly approved infrastructure

## Thresholds to set explicitly before testing

These numbers should come from the model owner, not be assumed by the tester:

* [ ] Acceptable model-extraction query volume
* [ ] Acceptable concurrent-request / resource-exhaustion ceiling before stopping
* [ ] What counts as "production impact" that triggers an immediate stop
* [ ] Whether logits/probabilities/embeddings may be queried, and how much

## Stop conditions

Testing stops immediately and the emergency contact is notified if:

* A prohibited action occurs accidentally
* Real (non-synthetic) sensitive data is encountered or exposed
* Production availability is measurably impacted
* An unauthorized backend action is triggered via tool/agent chaining (not just a model
  response — an actual side effect)

---

Next: work through the **[Model Security Checklist](model_security_checklist.md)**.
