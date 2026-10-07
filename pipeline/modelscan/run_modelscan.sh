#!/usr/bin/env bash
# Scans a model artifact for supply-chain risk (unsafe pickle/serialization, suspicious
# operators) before it's promoted to serving. Maps to model_security_checklist.md §19 Model
# supply chain. Not a substitute for hash/provenance verification against the source listed
# in model_security_notes/prerequisites_request.md section B.
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <path-or-uri-to-model-artifact> [extra modelscan args...]" >&2
  exit 1
fi

TARGET="$1"
shift

if ! command -v modelscan >/dev/null 2>&1; then
  echo "modelscan not found. Install with: pip install modelscan" >&2
  exit 1
fi

modelscan scan -p "$TARGET" "$@"
STATUS=$?

if [ $STATUS -ne 0 ]; then
  echo "modelscan reported findings — do not promote this artifact until reviewed." >&2
fi

exit $STATUS
