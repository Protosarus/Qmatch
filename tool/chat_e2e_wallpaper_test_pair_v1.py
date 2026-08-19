#!/usr/bin/env python3
"""Auth-backed chat E2E pair for two existing Stage B2 seed profiles.

Creates Firebase Auth for `qmatch_stage_b2_seed_01` and `_02` only, then
invokes trusted `likeAndMaybeCreateMatch` twice so the live backend writes
the match/thread/system_match_v1. Does not rewrite assessment/canonical
docs. Does not touch any other UID.

Default is dry-run (no Firebase init, no writes).

  export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/sa.json
  export QMATCH_CHAT_E2E_PASSWORD='choose-a-test-only-password'
  python3 tool/chat_e2e_wallpaper_test_pair_v1.py
  python3 tool/chat_e2e_wallpaper_test_pair_v1.py --execute --confirm CREATE_CHAT_E2E_WALLPAPER_PAIR
  python3 tool/chat_e2e_wallpaper_test_pair_v1.py --cleanup --confirm DELETE_CHAT_E2E_WALLPAPER_PAIR
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CREDENTIALS_ENV = "QMATCH_FIRESTORE_ADMIN_CREDENTIALS"
PASSWORD_ENV = "QMATCH_CHAT_E2E_PASSWORD"
PROJECT_ID = "qmatch-53d62"
POLICY = "chat_e2e_wallpaper_test_pair_v1"
COHORT_ID = "chat_e2e_wallpaper_v1"
EXECUTE_CONFIRM = "CREATE_CHAT_E2E_WALLPAPER_PAIR"
CLEANUP_CONFIRM = "DELETE_CHAT_E2E_WALLPAPER_PAIR"
CALLABLE_NAME = "likeAndMaybeCreateMatch"
CALLABLE_URL = (
    f"https://us-central1-{PROJECT_ID}.cloudfunctions.net/{CALLABLE_NAME}"
)
# Same iOS key as lib/firebase_options.dart (already in the client binary).
IOS_WEB_API_KEY = "AIzaSyCY-U17fN5Vg1AB1lNPjvo3w1Jtqu8fPms"

UID_01 = "qmatch_stage_b2_seed_01"
UID_02 = "qmatch_stage_b2_seed_02"
EMAIL_01 = "qmatch.seed.01.e2e@example.com"
EMAIL_02 = "qmatch.seed.02.e2e@example.com"
NAME_01 = "TEST Seed 01"
NAME_02 = "TEST Seed 02"
ORIGINAL_NAME_01 = "[TEST] B2-01 Exact structural clone"
ORIGINAL_NAME_02 = "[TEST] B2-02 Clone 20D / stale extras"
PAIR_ID = f"{UID_01}_{UID_02}"

TEST_TAG = {
    "is_test_data": True,
    "test_cohort_id": COHORT_ID,
    "seed_policy": POLICY,
}


def credentials_path() -> str:
    cred_path = os.environ.get(CREDENTIALS_ENV, "").strip()
    if not cred_path or not os.path.isabs(cred_path) or not os.path.isfile(cred_path):
        raise SystemExit(
            f"ERROR: set {CREDENTIALS_ENV} to an absolute existing file outside the repo."
        )
    try:
        Path(cred_path).resolve().relative_to(ROOT.resolve())
        raise SystemExit("ERROR: credentials must live outside the repo.")
    except ValueError:
        pass
    return cred_path


def require_password() -> str:
    password = os.environ.get(PASSWORD_ENV, "").strip()
    if len(password) < 8:
        raise SystemExit(
            f"ERROR: set {PASSWORD_ENV} to a test-only password of at least 8 characters."
        )
    return password


def init_admin():
    import firebase_admin
    from firebase_admin import auth, credentials, firestore

    cred_path = credentials_path()
    if not firebase_admin._apps:
        firebase_admin.initialize_app(
            credentials.Certificate(cred_path),
            {"projectId": PROJECT_ID},
        )
    return firestore.client(), auth


def http_json(url: str, payload: dict[str, Any], headers: dict[str, str] | None = None) -> dict[str, Any]:
    raw = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=raw,
        headers={"Content-Type": "application/json", **(headers or {})},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        raise SystemExit(f"ERROR HTTP {e.code} {url}: {body}") from e


def sign_in_email(email: str, password: str) -> str:
    url = (
        "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"
        f"?key={IOS_WEB_API_KEY}"
    )
    data = http_json(url, {"email": email, "password": password, "returnSecureToken": True})
    token = data.get("idToken")
    if not isinstance(token, str) or not token:
        raise SystemExit(f"ERROR: no idToken for {email}")
    return token


def call_like(id_token: str, target_uid: str) -> str:
    data = http_json(
        CALLABLE_URL,
        {"data": {"target_uid": target_uid}},
        headers={"Authorization": f"Bearer {id_token}"},
    )
    result = data.get("result") if isinstance(data, dict) else None
    outcome = result.get("outcome") if isinstance(result, dict) else None
    if not isinstance(outcome, str):
        raise SystemExit(f"ERROR: unexpected callable payload {data}")
    return outcome


def print_plan() -> None:
    print(f"{POLICY} project={PROJECT_ID} cohort={COHORT_ID}")
    print("Default: dry-run. No Auth/Firestore writes.")
    print()
    print("1. Auth users to create (uid preserved to existing user docs):")
    print(f"   {UID_01}  email={EMAIL_01}  password=${PASSWORD_ENV}")
    print(f"   {UID_02}  email={EMAIL_02}  password=${PASSWORD_ENV}")
    print("   custom claims: is_test_data=true, test_cohort_id=chat_e2e_wallpaper_v1")
    print()
    print("2. Minimal profile field (display-name gate is 2–24 graphemes):")
    print(f"   users/{UID_01}.name  {ORIGINAL_NAME_01!r} -> {NAME_01!r}")
    print(f"   users/{UID_02}.name  {ORIGINAL_NAME_02!r} -> {NAME_02!r}")
    print("   original names restored on cleanup. No assessment/canonical writes.")
    print()
    print("3. Trusted calls:")
    print(f"   POST {CALLABLE_URL}")
    print(f"   as {UID_01} -> likeAndMaybeCreateMatch({UID_02})  expected no_match")
    print(f"   as {UID_02} -> likeAndMaybeCreateMatch({UID_01})  expected created_new_match")
    print()
    print(f"4. Expected match/thread id: {PAIR_ID}")
    print("   plus threads/{id}/messages/system_match_v1")
    print()
    print("5. Phone sign-in: app Login email/password as seed_01")
    print(f"   email: {EMAIL_01}")
    print(f"   password: value of {PASSWORD_ENV}")
    print("   then Messages → thread with TEST Seed 02")
    print()
    print("6. Cleanup removes Auth 01/02, 01↔02 swipes, match/thread/system message,")
    print("   restores original names. Leaves seed profile/canonical docs.")


def ensure_auth_user(auth_mod: Any, uid: str, email: str, password: str) -> str:
    from firebase_admin.auth import UserNotFoundError

    try:
        user = auth_mod.get_user(uid)
        if user.email != email:
            raise SystemExit(
                f"ERROR: Auth uid {uid} exists with email {user.email!r}, expected {email!r}."
            )
        auth_mod.update_user(uid, password=password, email_verified=True, disabled=False)
        action = "updated"
    except UserNotFoundError:
        auth_mod.create_user(
            uid=uid,
            email=email,
            password=password,
            email_verified=True,
            disabled=False,
            display_name=NAME_01 if uid == UID_01 else NAME_02,
        )
        action = "created"
    auth_mod.set_custom_user_claims(
        uid,
        {"is_test_data": True, "test_cohort_id": COHORT_ID},
    )
    return action


def patch_display_name(db: Any, uid: str, new_name: str, original: str) -> None:
    ref = db.document(f"users/{uid}")
    snap = ref.get()
    if not snap.exists:
        raise SystemExit(f"ERROR: missing Firestore user doc {uid}")
    data = snap.to_dict() or {}
    if data.get("is_test_data") is not True:
        raise SystemExit(f"ERROR: refusing to patch non-test user {uid}")
    current = data.get("name")
    payload = {
        "name": new_name,
        "chat_e2e_original_name": current if isinstance(current, str) else original,
        **TEST_TAG,
    }
    ref.set(payload, merge=True)


def tag_pair_docs(db: Any) -> None:
    from google.cloud.firestore_v1 import SERVER_TIMESTAMP

    tag = {**TEST_TAG, "chat_e2e_tagged_at": SERVER_TIMESTAMP}
    db.document(f"matches/{PAIR_ID}").set(tag, merge=True)
    db.document(f"threads/{PAIR_ID}").set(tag, merge=True)
    db.document(f"users/{UID_01}/swipes/{UID_02}").set(tag, merge=True)
    db.document(f"users/{UID_02}/swipes/{UID_01}").set(tag, merge=True)


def execute() -> None:
    password = require_password()
    db, auth_mod = init_admin()
    a1 = ensure_auth_user(auth_mod, UID_01, EMAIL_01, password)
    a2 = ensure_auth_user(auth_mod, UID_02, EMAIL_02, password)
    print(f"auth {UID_01}: {a1}")
    print(f"auth {UID_02}: {a2}")
    patch_display_name(db, UID_01, NAME_01, ORIGINAL_NAME_01)
    patch_display_name(db, UID_02, NAME_02, ORIGINAL_NAME_02)
    print("display names patched for 2–24 grapheme gate")

    token_01 = sign_in_email(EMAIL_01, password)
    out_01 = call_like(token_01, UID_02)
    print(f"like {UID_01}->{UID_02}: {out_01}")
    if out_01 not in {"no_match", "existing_active_match", "created_new_match"}:
        raise SystemExit(f"ERROR: unexpected first outcome {out_01}")

    token_02 = sign_in_email(EMAIL_02, password)
    out_02 = call_like(token_02, UID_01)
    print(f"like {UID_02}->{UID_01}: {out_02}")
    if out_02 not in {"created_new_match", "existing_active_match"}:
        raise SystemExit(f"ERROR: expected created_new_match, got {out_02}")

    match = db.document(f"matches/{PAIR_ID}").get()
    thread = db.document(f"threads/{PAIR_ID}").get()
    sysmsg = db.document(f"threads/{PAIR_ID}/messages/system_match_v1").get()
    if not (match.exists and thread.exists and sysmsg.exists):
        raise SystemExit("ERROR: trusted path did not create match/thread/system message")
    md = match.to_dict() or {}
    if md.get("state") != "active":
        raise SystemExit(f"ERROR: match state {md.get('state')!r} is not active")
    tag_pair_docs(db)
    print(f"READY match/thread={PAIR_ID}")
    print(f"Phone login email={EMAIL_01} password=${PASSWORD_ENV}")


def cleanup() -> None:
    db, auth_mod = init_admin()
    from firebase_admin.auth import UserNotFoundError

    for uid, email, original in (
        (UID_01, EMAIL_01, ORIGINAL_NAME_01),
        (UID_02, EMAIL_02, ORIGINAL_NAME_02),
    ):
        try:
            user = auth_mod.get_user(uid)
            if user.email != email:
                print(f"SKIP auth delete {uid}: email {user.email!r} is not the test email")
            else:
                auth_mod.delete_user(uid)
                print(f"deleted Auth {uid}")
        except UserNotFoundError:
            print(f"auth {uid}: already absent")

        ref = db.document(f"users/{uid}")
        snap = ref.get()
        if snap.exists:
            data = snap.to_dict() or {}
            restore = data.get("chat_e2e_original_name")
            if not isinstance(restore, str) or not restore:
                restore = original
            ref.set(
                {
                    "name": restore,
                    "chat_e2e_original_name": None,
                    "test_cohort_id": data.get("test_cohort_id")
                    if data.get("test_cohort_id") != COHORT_ID
                    else "stage_b2_dual_path_v2",
                },
                merge=True,
            )
            print(f"restored name {uid} -> {restore!r}")

    for path in (
        f"users/{UID_01}/swipes/{UID_02}",
        f"users/{UID_02}/swipes/{UID_01}",
        f"threads/{PAIR_ID}/messages/system_match_v1",
        f"threads/{PAIR_ID}",
        f"matches/{PAIR_ID}",
    ):
        ref = db.document(path)
        if ref.get().exists:
            ref.delete()
            print(f"deleted {path}")
        else:
            print(f"absent {path}")
    print("cleanup complete; seed profile/canonical docs left intact")


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Auth-backed chat E2E pair for seed 01/02.")
    p.add_argument("--execute", action="store_true")
    p.add_argument("--cleanup", action="store_true")
    p.add_argument("--confirm", default="")
    return p.parse_args()


def main() -> int:
    args = parse_args()
    if args.execute and args.cleanup:
        print("ERROR: use --execute or --cleanup, not both.", file=sys.stderr)
        return 2
    if args.execute:
        if args.confirm != EXECUTE_CONFIRM:
            print(f"ERROR: --execute requires --confirm {EXECUTE_CONFIRM}", file=sys.stderr)
            return 2
        execute()
        return 0
    if args.cleanup:
        if args.confirm != CLEANUP_CONFIRM:
            print(f"ERROR: --cleanup requires --confirm {CLEANUP_CONFIRM}", file=sys.stderr)
            return 2
        cleanup()
        return 0
    print_plan()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
