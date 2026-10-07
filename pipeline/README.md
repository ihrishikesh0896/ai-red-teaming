# pipeline — Automated Model Security Checks

Turns parts of `model_security_notes/model_security_checklist.md` into something that actually
runs, instead of staying a document people read once. Three pieces, each covering a different
slice of the checklist — they are **not interchangeable**, and none of them alone is a
complete assessment.

| Piece | Tool | Checklist mapping | Runs |
|---|---|---|---|
| [`promptfoo/`](promptfoo/) | [Promptfoo](https://www.promptfoo.dev/) | Pass 2 — model-level (prompt injection, jailbreak, PII leakage, excessive agency) | Every PR / on a schedule, CI-gated pass/fail |
| [`modelscan/`](modelscan/) | [ModelScan](https://github.com/protectai/modelscan) (Protect AI) | §19 Model supply chain (unsafe serialization, pickle-based artifacts) | Pre-deploy, gates artifact promotion |
| [`custom_checks/`](custom_checks/) | hand-written scripts | Pass 1 AuthN/AuthZ, Pass 3 Agent/tool excessive agency, Pass 4 infra/availability | **Not automated yet** — template only, see below |

## What's deliberately not scaffolded here

`custom_checks/` is a skeleton, not a working test suite. The reason: authZ, tool/agent
excessive-agency, rate-limiting, and infra tests are inherently specific to *how your model is
actually served* — your auth scheme, your privilege levels, your tool-calling setup, your rate
limits. Promptfoo/Garak/PyRIT don't know any of that, and neither do I without the specifics.
Fill in `custom_checks/` against your real deployment, using the test accounts and API details
from `model_security_notes/prerequisites_request.md` and the thresholds/limits from
`model_security_notes/rules_of_engagement.md`.

## Running locally — single entrypoint

`config.yaml` is the single place that defines what gets scanned: targets (model/API/host) and
which modules run. `entrypoint.sh` (macOS/Linux) and `entrypoint.ps1` (Windows) both read it and
drive every module below — you edit `config.yaml` and `.env`, not the module configs or scripts.

```bash
cp pipeline/.env.example pipeline/.env   # fill in secrets for any target that needs one

cd pipeline
./entrypoint.sh                 # uses config.yaml
# or: pwsh ./entrypoint.ps1
```

Out of the box, `config.yaml` points at a local Ollama server (`localhost:11434`) with
`promptfoo` enabled. To scan a different model/API, add or edit an entry under `targets:` in
`config.yaml` — no need to touch `promptfooconfig.yaml` or either entrypoint script. To also run
ModelScan, set `modules.modelscan.enabled: true` and `artifact_path` in `config.yaml`.

Requires: `python3` + `PyYAML`, `jq` (bash path only), and `npx`/Node for Promptfoo. The
entrypoints check for these and fail with a clear message if missing.

## Running a module directly

```bash
# Model-level red team (Promptfoo)
cd pipeline/promptfoo
npx promptfoo@latest redteam run -c promptfooconfig.yaml

# Supply-chain scan (ModelScan)
cd pipeline/modelscan
./run_modelscan.sh /path/to/model/artifact
```

Note on the Promptfoo config: plugin/strategy IDs shift between releases. Before relying on
`promptfooconfig.yaml` as-is, run `npx promptfoo@latest redteam init` once and diff its output
against this file to catch any renamed/new plugins. Also note `promptfooconfig.yaml`'s request
body is shaped for Ollama's native `/api/generate` endpoint (`config.yaml` `type: ollama`) — an
`openai-compatible` target needs a `messages` array instead, so update `body`/`transformResponse`
if you add one.

## CI

[`.github/workflows/ai-security.yml`](../.github/workflows/ai-security.yml) wires the first two
pieces into GitHub Actions (PR + nightly schedule). `custom_checks/` is intentionally **not**
wired into CI yet — don't add it until the scripts are filled in and pointed at a non-prod
environment per the rules of engagement.
