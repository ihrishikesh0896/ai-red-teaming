#!/usr/bin/env python3
"""
Reads pipeline/config.yaml and prints resolved target/module settings as JSON.

entrypoint.sh and entrypoint.ps1 both call this so the "what counts as a
target, what env vars does a module need" logic lives in exactly one place,
instead of being duplicated per-shell. Secrets are read from the process
environment (the entrypoints source .env before calling this script) -- this
script never reads .env itself.
"""

import json
import os
import sys

import yaml

TYPE_PATH_SUFFIX = {
    "ollama": "/api/generate",
    "openai-compatible": "/v1/chat/completions",
}


def resolve_target(target):
    target_id = target["id"]
    target_type = target.get("type", "custom-http")
    base_url = target.get("base_url", "").rstrip("/")

    if target_type == "custom-http":
        api_url = target.get("api_url", base_url)
    else:
        suffix = TYPE_PATH_SUFFIX.get(target_type)
        if suffix is None:
            print(f"error: target '{target_id}' has unknown type '{target_type}'", file=sys.stderr)
            sys.exit(1)
        api_url = base_url + suffix

    api_key_env = target.get("api_key_env") or ""
    api_key = os.environ.get(api_key_env, "") if api_key_env else ""
    if api_key_env and not api_key:
        print(f"warning: target '{target_id}' sets api_key_env={api_key_env} but it's empty/unset in .env", file=sys.stderr)

    return {
        "id": target_id,
        "type": target_type,
        "base_url": target.get("base_url", ""),
        "model": target.get("model", ""),
        "api_url": api_url,
        "api_key": api_key,
    }


def main():
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <config.yaml>", file=sys.stderr)
        sys.exit(1)

    with open(sys.argv[1]) as f:
        config = yaml.safe_load(f) or {}

    targets = [
        resolve_target(t)
        for t in config.get("targets", [])
        if t.get("enabled", True)
    ]

    modules = config.get("modules", {})

    print(json.dumps({"targets": targets, "modules": modules}, indent=2))


if __name__ == "__main__":
    main()
