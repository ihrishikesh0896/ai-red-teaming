#!/usr/bin/env bash
# Runs every enabled module in pipeline/ against every enabled target in
# pipeline/config.yaml. To change what gets scanned, edit config.yaml (and
# pipeline/.env for secrets) -- don't edit this script or the module configs.
#
# Usage:
#   ./entrypoint.sh                 # use pipeline/config.yaml
#   ./entrypoint.sh my-config.yaml  # use an alternate config file
set -euo pipefail

PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PIPELINE_DIR"

CONFIG_FILE="${1:-config.yaml}"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "error: config file not found: $CONFIG_FILE" >&2
  exit 1
fi

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

command -v python3 >/dev/null 2>&1 || { echo "error: python3 is required" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "error: jq is required (brew install jq)" >&2; exit 1; }
python3 -c "import yaml" >/dev/null 2>&1 || { echo "error: PyYAML is required (pip install pyyaml)" >&2; exit 1; }

RESOLVED="$(python3 scripts/resolve_config.py "$CONFIG_FILE")"

TARGET_COUNT="$(echo "$RESOLVED" | jq '.targets | length')"
if [ "$TARGET_COUNT" -eq 0 ]; then
  echo "error: no enabled targets in $CONFIG_FILE" >&2
  exit 1
fi

PROMPTFOO_ENABLED="$(echo "$RESOLVED" | jq -r '.modules.promptfoo.enabled // false')"
PROMPTFOO_CONFIG="$(echo "$RESOLVED" | jq -r '.modules.promptfoo.config // "promptfoo/promptfooconfig.yaml"')"
PROMPTFOO_EXTRA_ARGS=()
while IFS= read -r arg; do
  [ -n "$arg" ] && PROMPTFOO_EXTRA_ARGS+=("$arg")
done < <(echo "$RESOLVED" | jq -r '.modules.promptfoo.extra_args[]? // empty')

MODELSCAN_ENABLED="$(echo "$RESOLVED" | jq -r '.modules.modelscan.enabled // false')"
MODELSCAN_ARTIFACT="$(echo "$RESOLVED" | jq -r '.modules.modelscan.artifact_path // ""')"

CUSTOM_CHECKS_ENABLED="$(echo "$RESOLVED" | jq -r '.modules.custom_checks.enabled // false')"

mkdir -p results

if [ "$PROMPTFOO_ENABLED" = "true" ]; then
  for i in $(seq 0 $((TARGET_COUNT - 1))); do
    TARGET="$(echo "$RESOLVED" | jq -c ".targets[$i]")"
    TARGET_ID="$(echo "$TARGET" | jq -r '.id')"
    export TARGET_API_URL="$(echo "$TARGET" | jq -r '.api_url')"
    export TARGET_API_KEY="$(echo "$TARGET" | jq -r '.api_key')"
    export TARGET_MODEL="$(echo "$TARGET" | jq -r '.model')"

    echo "== promptfoo redteam run :: target=$TARGET_ID url=$TARGET_API_URL model=$TARGET_MODEL =="
    npx --yes promptfoo@latest redteam run \
      -c "$PROMPTFOO_CONFIG" \
      -d "$TARGET_ID" \
      --tag "target=$TARGET_ID" \
      ${PROMPTFOO_EXTRA_ARGS[@]+"${PROMPTFOO_EXTRA_ARGS[@]}"}
  done
  echo "Promptfoo run(s) complete. View results with: npx promptfoo@latest view"
else
  echo "== promptfoo: disabled in $CONFIG_FILE, skipping =="
fi

if [ "$MODELSCAN_ENABLED" = "true" ]; then
  if [ -z "$MODELSCAN_ARTIFACT" ]; then
    echo "error: modules.modelscan.enabled is true but artifact_path is empty in $CONFIG_FILE" >&2
    exit 1
  fi
  echo "== modelscan :: artifact=$MODELSCAN_ARTIFACT =="
  ./modelscan/run_modelscan.sh "$MODELSCAN_ARTIFACT"
else
  echo "== modelscan: disabled in $CONFIG_FILE, skipping =="
fi

if [ "$CUSTOM_CHECKS_ENABLED" = "true" ]; then
  echo "== custom_checks: enabled in $CONFIG_FILE, but these are templates, not a runnable suite =="
  echo "   fill in pipeline/custom_checks/*.py against your deployment first -- see custom_checks/README.md"
else
  echo "== custom_checks: disabled in $CONFIG_FILE, skipping =="
fi
