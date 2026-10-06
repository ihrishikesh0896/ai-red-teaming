# AI Security Assessment

Working documents for assessing security of AI systems. Three tracks so far:

## Model / API security — `model_security_notes/`

For models and AI applications you (or your org) control end-to-end.

1. **[model_security_notes/prerequisites_request.md](model_security_notes/prerequisites_request.md)**
   — what to request from the model owner/application team before testing: scope, architecture
   diagram, API access/credentials at each privilege level, data handling, log access.
2. **[model_security_notes/rules_of_engagement.md](model_security_notes/rules_of_engagement.md)**
   — sign-off doc defining what's allowed, what's prohibited, thresholds, and stop conditions.
   Get this signed before touching anything.
3. **[model_security_notes/model_security_checklist.md](model_security_notes/model_security_checklist.md)**
   — the actual test checklist, organized in 4 passes (AppSec → model → AI
   application/RAG/agents → infrastructure/supply chain) plus a master priority tracker and
   automated red-team tooling.

Scope reminder before using the above: get a written answer to *are we assessing the
foundation model, the model-serving API, or the full application (RAG/agents/tools) around
it?* Each is a different assessment.

## Thick-client / low-code AI platforms — `thickclient_ai_notes/`

For AI features bolted onto platforms you don't fully control (M365 Copilot Studio, n8n, Power
Automate, etc.), where a non-security-trained "maker" wires an agent up to real credentials.

1. **[thickclient_ai_notes/checklist.md](thickclient_ai_notes/checklist.md)** — generic
   checklist: run-as identity, connector/credential security, trigger exposure, prompt
   injection → action chaining, knowledge-source oversharing, code-execution nodes,
   self-hosted hardening, thick-client local surface, governance/audit.
2. **[thickclient_ai_notes/m365_copilot_studio.md](thickclient_ai_notes/m365_copilot_studio.md)**
   — M365 Copilot Studio specifics. n8n notes to follow.

## MCP server security — `mcp_server_notes/`

For the Model Context Protocol ecosystem — servers exposing tools/resources/prompts/sampling
to an LLM client. Split by role, since trusting a server you connect to is a different job
from building one:

1. **[mcp_server_notes/consumer_checklist.md](mcp_server_notes/consumer_checklist.md)** —
   provenance, tool-description poisoning, rug-pull behavior changes, cross-server shadowing,
   injection via tool/resource output, confused-deputy tool execution, stdio-vs-remote trust,
   sampling abuse, logging.
2. **[mcp_server_notes/implementer_checklist.md](mcp_server_notes/implementer_checklist.md)**
   — the same categories from the server-builder's side: supply-chain hygiene, honest tool
   descriptions, versioning discipline, namespacing, output hygiene, least-privilege tool
   design, stdio/remote hardening, server-side logging.
