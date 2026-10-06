# thickclient_ai_notes — Thick-Client / Low-Code AI Platform Security

Checklist for assessing AI features bolted onto thick-client or low-code automation platforms
(M365 Copilot Studio, n8n, Power Automate, Zapier AI, UiPath, Retool AI, etc.) — where a
non-security-trained "maker" wires an agent up to real credentials and real connectors.

1. **[checklist.md](checklist.md)** — generic, platform-agnostic checklist: run-as identity,
   connector/credential security, trigger exposure, prompt-injection-to-action chaining,
   knowledge-source oversharing, code-execution nodes, self-hosted hardening, thick-client
   local surface, governance/audit.
2. **[m365_copilot_studio.md](m365_copilot_studio.md)** — M365 Copilot Studio specifics:
   Power Platform environments/DLP, topic/action auth modes, Dataverse security roles,
   Semantic Index oversharing, autonomous agents, admin-center settings to pull before testing.
3. `n8n.md` — not yet written.

This set is separate from `model_security_notes/` (which assumes you own the model/API
end-to-end). Here the platform itself is a trust boundary you don't control, and most findings
come from governance gaps rather than model weaknesses.
