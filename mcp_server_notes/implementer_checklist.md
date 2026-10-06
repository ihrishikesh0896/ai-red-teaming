# MCP Server Security Checklist — Implementer Side

For reviewing an MCP server **you build or maintain**. Same ten categories as
[`consumer_checklist.md`](consumer_checklist.md), inverted: there you're deciding whether to
trust someone else's server; here you're making sure your server deserves that trust from
whoever connects to it.

---

## 1. Supply chain of your own release

* [ ] Dependencies pinned, not floating — don't make your consumers inherit an unreviewed
      upstream change just because they run `your-server@latest`.
* [ ] Signed releases / published with provenance (npm provenance, sigstore, etc.) where the
      ecosystem supports it.
* [ ] No postinstall scripts or native binaries beyond what's necessary and documented.
* [ ] Dependency vulnerability scanning in your release pipeline (Trivy/Gitleaks-class tooling).

## 2. Honest, minimal tool descriptions

* [ ] Tool descriptions state only what the tool does — no hidden instructions aimed at the
      calling model, now or via a future update.
* [ ] If descriptions are generated dynamically (templated from config/data), validate that
      user- or data-controlled strings can't inject instruction-like text into them.
* [ ] Tool implementation matches its description exactly — no side effects beyond what's
      declared (a `read_file` tool must not also write).
* [ ] Parameter schemas are strict (types, enums, required fields) — don't accept free-form
      strings where a structured type would do, since loose schemas are easier to smuggle
      instructions through.

## 3. Versioning discipline (the implementer side of "rug-pull")

* [ ] Behavior changes ship with a version bump and changelog entry — don't silently change
      what an already-approved tool does under the same version/name.
* [ ] If you run a remote server, consider how a client could detect/pin against your behavior
      changing between their sessions (ETags, version headers, explicit schema versioning).

## 4. Namespacing (the implementer side of "shadowing")

* [ ] Tool names are specific and namespaced to your server, not generic names likely to
      collide with other servers a user might also connect (`send_email` vs
      `acme_crm.send_email`).
* [ ] Don't rely on being the only server connected — assume a malicious server may be present
      alongside yours and design tool names/descriptions so they can't be easily impersonated.

## 5. Output hygiene (the implementer side of injection-via-output)

* [ ] Tool/resource output you return is clearly data, not instructions — don't embed
      meta-instructions in your own output formatting that could be confused with user content.
* [ ] If your tool fetches external/attacker-reachable content (web pages, user-submitted
      files) and returns it, document for your consumers that this content is untrusted and
      should be treated as data, not instruction.
* [ ] Don't echo back raw unsanitized upstream content if a more structured extraction is
      possible (e.g. return the parsed fields you need, not the full raw page/document).

## 6. Least privilege (the implementer side of confused-deputy)

* [ ] Each tool requests only the credential/scope it needs — don't hold one broad service
      credential and expose fine-grained tools on top of it if scoped credentials are available
      per tool/operation instead.
* [ ] Destructive or external-facing operations (delete, send, execute, deploy) are separate,
      clearly-named tools — not optional parameters on a generic tool — so clients can gate
      them individually rather than approving one broad tool once.
* [ ] Don't silently fall back to a higher-privileged credential if a scoped one is unavailable.

## 7. Local (stdio) server hygiene

* [ ] Request/use only the filesystem and network access your server actually needs — don't
      rely on "runs as the user" to paper over scope creep.
* [ ] Secrets your server needs are read from a scoped location (not broadly-readable env/files
      shared with unrelated processes) and never logged or echoed back in tool output.

## 8. Remote (HTTP/SSE) server hygiene

* [ ] Proper authentication (OAuth preferred) on every endpoint — no silent anonymous access.
* [ ] TLS enforced; reject plaintext.
* [ ] Session isolation between tenants/users verified with a test, not assumed.
* [ ] Validate and restrict any server-initiated outbound requests triggered by tool parameters
      — don't let a parameter cause your server to fetch attacker-chosen internal URLs (SSRF).

## 9. Sampling requests (if your server uses this primitive)

* [ ] Only request sampling when functionally necessary, and document why in the tool/server
      description so a reviewing consumer can judge it.
* [ ] Don't use sampling requests as a side channel to pull conversation context beyond what's
      needed for the stated function.

## 10. Server-side logging & redaction

* [ ] Log tool invocations (what was called, with what parameters, what was returned) in a
      form that supports a consumer's incident reconstruction.
* [ ] Redact secrets/credentials from your own logs by default.

---

Back to [`README.md`](README.md) for the index, or
[`consumer_checklist.md`](consumer_checklist.md) for the client-side review.
