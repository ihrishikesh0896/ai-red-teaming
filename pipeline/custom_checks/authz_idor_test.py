#!/usr/bin/env python3
"""
TEMPLATE — not runnable as-is. Fill in the TODOs against your actual deployment.

Maps to model_security_checklist.md Pass 1 §Authorization:
  User A -> User A's own data       (sanity check, should succeed)
  User A -> User B's data           (should fail -- IDOR/BOLA)
  User A -> admin operation         (should fail -- BFLA / privilege escalation)

Requires separate credentials per privilege tier -- see model_security_notes/
prerequisites_request.md section D. Run only against a non-prod environment per
model_security_notes/rules_of_engagement.md unless explicitly authorized otherwise.
"""

import os
import sys

import requests

BASE_URL = os.environ.get("BASE_URL")  # TODO: set to a non-prod environment, never prod by default
USER_A_TOKEN = os.environ.get("USER_A_TOKEN")
USER_B_TOKEN = os.environ.get("USER_B_TOKEN")
ADMIN_TOKEN = os.environ.get("ADMIN_TOKEN")

# TODO: set to a resource ID that belongs to "User B", created ahead of time as test fixture
USER_B_RESOURCE_ID = os.environ.get("USER_B_RESOURCE_ID")

# TODO: set to an endpoint path your API actually exposes
USER_RESOURCE_PATH = "/api/v1/conversations/{id}"  # TODO adjust
ADMIN_ONLY_PATH = "/api/v1/admin/users"  # TODO adjust


def require_env():
    missing = [
        name
        for name, val in [
            ("BASE_URL", BASE_URL),
            ("USER_A_TOKEN", USER_A_TOKEN),
            ("USER_B_TOKEN", USER_B_TOKEN),
            ("ADMIN_TOKEN", ADMIN_TOKEN),
            ("USER_B_RESOURCE_ID", USER_B_RESOURCE_ID),
        ]
        if not val
    ]
    if missing:
        print(f"Missing required env vars: {', '.join(missing)}. This is a template -- "
              f"fill these in against your deployment before running.", file=sys.stderr)
        sys.exit(1)


def auth_header(token):
    return {"Authorization": f"Bearer {token}"}


def test_user_can_access_own_resource():
    """Sanity check: User A can read their own data. Should be 200."""
    # TODO: replace with a resource ID that actually belongs to User A
    own_id = os.environ.get("USER_A_OWN_RESOURCE_ID", "TODO-set-this")
    resp = requests.get(
        BASE_URL + USER_RESOURCE_PATH.format(id=own_id),
        headers=auth_header(USER_A_TOKEN),
        timeout=10,
    )
    assert resp.status_code == 200, f"Sanity check failed -- User A can't read own data: {resp.status_code}"
    print("PASS: User A can access own resource (sanity check)")


def test_idor_cross_user_resource():
    """User A attempts to read User B's resource by ID. Should be 403/404, not 200."""
    resp = requests.get(
        BASE_URL + USER_RESOURCE_PATH.format(id=USER_B_RESOURCE_ID),
        headers=auth_header(USER_A_TOKEN),
        timeout=10,
    )
    assert resp.status_code in (403, 404), (
        f"IDOR FINDING: User A accessed User B's resource. Status: {resp.status_code}, "
        f"body: {resp.text[:500]}"
    )
    print("PASS: cross-user resource access correctly denied")


def test_bfla_admin_endpoint():
    """User A (non-admin) attempts an admin-only operation. Should be 403."""
    resp = requests.get(
        BASE_URL + ADMIN_ONLY_PATH,
        headers=auth_header(USER_A_TOKEN),
        timeout=10,
    )
    assert resp.status_code == 403, (
        f"BFLA FINDING: non-admin User A accessed admin endpoint. Status: {resp.status_code}, "
        f"body: {resp.text[:500]}"
    )
    print("PASS: admin endpoint correctly denied to non-admin user")


if __name__ == "__main__":
    require_env()
    test_user_can_access_own_resource()
    test_idor_cross_user_resource()
    test_bfla_admin_endpoint()
    print("All authZ template checks passed -- but re-check you actually filled in every TODO above.")
