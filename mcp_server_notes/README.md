# mcp_server_notes — MCP Server Security

Checklist for the Model Context Protocol (MCP) ecosystem — servers that expose
tools/resources/prompts/sampling to an LLM client (Claude Desktop, Claude Code, IDE
extensions, custom agents). Split in two, since testing a server you only connect to is a
different job from reviewing one you build:

1. **[consumer_checklist.md](consumer_checklist.md)** — deciding whether to trust an MCP
   server you connect to, and verifying the client enforces consent/isolation boundaries:
   provenance, tool-description poisoning, rug-pull behavior changes, cross-server shadowing,
   injection via tool/resource output, confused-deputy tool execution, stdio-vs-remote trust,
   sampling abuse, logging.
2. **[implementer_checklist.md](implementer_checklist.md)** — the same ten categories from the
   implementer's side: supply-chain hygiene for your own releases, honest/minimal tool
   descriptions, versioning discipline, namespacing, output hygiene, least-privilege tool
   design, stdio/remote server hardening, sampling discipline, server-side logging.

Kept as its own full checklist rather than folded into `model_security_checklist.md`'s
Agent/tool section or `thickclient_ai_notes/checklist.md` — there's real overlap in the
confused-deputy and injection-via-output categories, but MCP's protocol-specific primitives
(tool poisoning, rug-pulls, cross-server shadowing, sampling) don't have a home in either of
those and are common enough to warrant a dedicated doc.
