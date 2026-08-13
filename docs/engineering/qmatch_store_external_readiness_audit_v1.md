# QMatch Store Credential & Console Readiness Audit v1

| Field | Value |
| --- | --- |
| Document id | `qmatch_store_external_readiness_audit_v1` |
| Status | `store_external_readiness_audit_v1` · `audit_only_not_deployed` |
| Scope | Repo/config evidence only — Apple + Play credentials, console SKUs, Functions secrets, webhook deploy readiness |
| Non-goals | Code changes, deploy, App Store Connect / Play Console mutations, client Billing SDK |
| Audit date | 2026-08-13 |
| Parents | [Store Notification Backend v1](./qmatch_store_notification_backend_v1.md) · [Purchase Verification Contract](./qmatch_store_purchase_verification_contract_v1.md) · [Store Creation Readiness](../product/qmatch_store_creation_readiness_v1.md) · [Store Product Identity](../product/qmatch_store_product_identity_v1.md) |

---

## 0. Classification legend

| Class | Meaning |
| --- | --- |
| `ready` | Present and sufficient in repo/config for the next ops step without further product debate |
| `needs_user_action` | Human must supply a value / create a key / assign owners (not purely “click in console later”) |
| `needs_external_setup` | Apple / Google / Firebase / Pub/Sub console or account work outside this repo |
| `needs_code` | Repo must change before credentials can be injected or endpoints hardened for prod |
| `blocked` | Cannot proceed until a named prerequisite clears |

**Evidence rule:** Anything not present in this repository or local project config is treated as **missing** (unresolved). Live console state is **not** queried in this audit.

---

## 1. Firebase / Functions surface (shared)

| Item | Class | Evidence |
| --- | --- | --- |
| Firebase project id in FlutterFire / `firebase.json` | `ready` | `qmatch-53d62` in `firebase.json`, `GoogleService-Info.plist`, Android `google-services.json` |
| `firebase.json` Functions codebase | `ready` | `functions` source + ignore list configured |
| Callable exports `verifyAndApplyPurchase` / `restorePurchases` | `ready` | `functions/index.js` — fail closed until env present |
| HTTP exports `appStoreServerNotification` / `playRealtimeDeveloperNotification` | `ready` | Exported `onRequest` us-central1; handlers unit-tested |
| Apple root CAs in repo | `ready` | Public DER under `functions/certs/apple/` (not secrets) |
| Product ID map in code | `ready` | `entitlement_schema.js` + `store_product_map.js` match identity freeze |
| Functions v2 Secret Manager binding (`defineSecret` / `secrets:`) | `ready` (code) | Implemented in `functions/src/store_iap_secrets.js`; bound on verify/restore/ASSN/RTDN. **Secret values** still `needs_external_setup` |
| Webhook invoker / Pub/Sub OIDC auth | `needs_code` | HTTP handlers accept body; no push-auth verification in code |
| Live deploy of entitlement / notification Functions | `needs_external_setup` | Docs mark `engineering_validated_not_deployed`; no deploy in this audit |
| Private keys / `.p8` / SA JSON in git | `ready` (absent = correct) | No committed Apple/Play private credentials found |

### 1.1 Webhook deploy-readiness verdict

| Question | Verdict |
| --- | --- |
| Are handlers exportable via `firebase deploy --only functions`? | **Structurally yes** — exports exist |
| Are they credential-ready today? | **No** — missing secrets + Secret Manager wiring |
| Are they console-ready today? | **No** — ASSN URL / RTDN topic not configured; sandbox SKUs not created |
| Safe to point Apple/Google at endpoints now? | **blocked** on secrets wiring + sandbox SKUs + explicit deploy authorization |

---

## 2. Apple readiness

| # | Item | Class | Notes |
| --- | --- | --- | --- |
| A1 | App Store Connect API key (In-App Purchase / Server API capability) | `needs_external_setup` | Must be created in App Store Connect; not in repo |
| A2 | Issuer ID | `needs_user_action` | Required env `APPLE_IAP_ISSUER_ID`; no value in repo |
| A3 | Key ID | `needs_user_action` | Required env `APPLE_IAP_KEY_ID`; no value in repo |
| A4 | Private key secret (`.p8` → `APPLE_IAP_PRIVATE_KEY`) | `needs_external_setup` + `needs_code` | Key create/store is external; Functions must bind Secret Manager → env |
| A5 | Bundle id | `ready` | `com.qmatch.app` in Xcode `PRODUCT_BUNDLE_IDENTIFIER` + `GoogleService-Info.plist` |
| A6 | Apple app id (`APPLE_IAP_APP_APPLE_ID`) | `needs_user_action` | Numeric ASC app id **not** in repo; required for Production verifier; recommended for Sandbox |
| A7 | Environment flag `APPLE_IAP_ENVIRONMENT` | `needs_user_action` | Must be `Sandbox` or `Production`; unset ⇒ `verification_not_configured` |
| A8 | Resonance subscription group | `needs_external_setup` | Identity frozen (“Resonance”); **not created** in console per product docs |
| A9 | Four launch products | `needs_external_setup` | IDs frozen (`qmatch.resonance.monthly` / `.annual`, `qmatch.super_resonance.x1`, `qmatch.boost.x1`); console create **not authorized / not present** |
| A10 | Sandbox tester | `needs_external_setup` | Blocked on A8–A9 for useful E2E |
| A11 | ASSN v2 endpoint configuration (App Store Connect URLs) | `needs_external_setup` | Handler ready in code; ASC Production + Sandbox URL fields unset; needs deploy URL |
| A12 | Functions secrets for Apple | `needs_external_setup` + `needs_code` | Create secrets in GCP/Firebase; bind via `defineSecret` (missing) |

### 2.1 Apple env contract (code expects)

| Secret / env | Required |
| --- | --- |
| `APPLE_IAP_ISSUER_ID` | yes |
| `APPLE_IAP_KEY_ID` | yes |
| `APPLE_IAP_PRIVATE_KEY` | yes (PEM; `\n` escaped OK) |
| `APPLE_IAP_BUNDLE_ID` | yes (expected `com.qmatch.app`) |
| `APPLE_IAP_ENVIRONMENT` | yes (`Sandbox` \| `Production`) |
| `APPLE_IAP_APP_APPLE_ID` | yes for Production; recommended always |
| `APPLE_IAP_ENABLE_ONLINE_CHECKS` | optional (default on) |

---

## 3. Google Play readiness

| # | Item | Class | Notes |
| --- | --- | --- | --- |
| G1 | Play Console app / package | `ready` (string) + `needs_external_setup` (console) | Gradle `applicationId = com.qmatch.app`. Confirm Play app record matches. **Caveat:** `android/app/google-services.json` also lists stale client `com.example.qmatch` — clean/confirm before linking Publisher API |
| G2 | Subscription product `qmatch.resonance` | `needs_external_setup` | Identity frozen; not created |
| G3 | Base plans `monthly` / `annual` | `needs_external_setup` | Identity frozen; not created |
| G4 | Super Resonance ×1 `qmatch.super_resonance.x1` | `needs_external_setup` | Consumable ID frozen; not created |
| G5 | Boost ×1 `qmatch.boost.x1` | `needs_external_setup` | Consumable ID frozen; not created |
| G6 | Publisher API service account | `needs_external_setup` | Must exist in GCP and be invited in Play Console |
| G7 | Permissions (`androidpublisher` scope + Play Console API access) | `needs_external_setup` | Code uses `https://www.googleapis.com/auth/androidpublisher` |
| G8 | RTDN Pub/Sub topic + push subscription → Function URL | `needs_external_setup` | Handler parses Pub/Sub push envelope; topic/sub not in repo |
| G9 | License / sandbox testers | `needs_external_setup` | Blocked on G2–G5 for useful E2E |
| G10 | Functions secrets for Play | `needs_external_setup` + `needs_code` | Same Secret Manager binding gap as Apple |

### 3.1 Play env contract (code expects)

| Secret / env | Required |
| --- | --- |
| `PLAY_IAP_PACKAGE_NAME` | yes (expected `com.qmatch.app`) |
| `PLAY_IAP_CLIENT_EMAIL` | yes\* |
| `PLAY_IAP_PRIVATE_KEY` | yes\* |
| `GOOGLE_APPLICATION_CREDENTIALS` | alternative\* (file path — **poor fit** for Cloud Functions; prefer inline email+key secrets) |
| `PLAY_IAP_REQUIRE_ACCOUNT_BINDING` | optional (default true) |

\*Either inline email+key **or** credentials path.

---

## 4. Required secrets (inventory)

Create in Secret Manager / Firebase Functions secrets (names recommended to match env):

| Secret name | Platform | Used by |
| --- | --- | --- |
| `APPLE_IAP_ISSUER_ID` | Apple | API client + ASSN path |
| `APPLE_IAP_KEY_ID` | Apple | API client |
| `APPLE_IAP_PRIVATE_KEY` | Apple | API client (`.p8` PEM) |
| `APPLE_IAP_BUNDLE_ID` | Apple | Verifier binding (may be plain config, not secret) |
| `APPLE_IAP_ENVIRONMENT` | Apple | Sandbox/Production (config) |
| `APPLE_IAP_APP_APPLE_ID` | Apple | Production SignedDataVerifier |
| `PLAY_IAP_PACKAGE_NAME` | Play | API package binding (config) |
| `PLAY_IAP_CLIENT_EMAIL` | Play | JWT auth |
| `PLAY_IAP_PRIVATE_KEY` | Play | JWT auth |

**Not secrets (already in repo):** Apple root CA DERs under `functions/certs/apple/`.

**Must never commit:** `.p8`, Play SA JSON, raw private keys.

---

## 5. Code gaps before credentials can be added usefully

| Gap | Class | Why it matters |
| --- | --- | --- |
| No `defineSecret` / `secrets:` on `onCall` / `onRequest` | ~~`needs_code`~~ **done** (`store_iap_secrets_binding_v1`) | Bindings present; values still must be created in Secret Manager |
| Prefer Secret Manager over `GOOGLE_APPLICATION_CREDENTIALS` file path | `needs_code` (ops preference) | File-path credentials are awkward on Cloud Functions; loaders already support inline key |
| RTDN HTTP endpoint lacks Pub/Sub OIDC / audience checks | `needs_code` | Anyone who discovers the URL can POST junk (fail-closed for grants, but noisy / DoS-ish) |
| ASSN HTTP endpoint has no shared-secret / network restriction beyond JWS verify | `needs_code` (hardening) | JWS verify mitigates forgery when Apple config present; still open HTTP until IAM/Cloud Armor |
| Client Billing / StoreKit / Play Billing SDK | out of scope | Not required to add server credentials; required later for E2E purchase |

**Not a code gap:** verifier + notification logic already fail closed with `verification_not_configured` when env missing.

---

## 6. Console actions needed (when authorized)

### Apple (App Store Connect)

1. Create App Store Connect API key; record Issuer ID, Key ID; store `.p8` out of git.  
2. Confirm app record for `com.qmatch.app`; record numeric Apple app id.  
3. Create subscription group **Resonance**.  
4. Create four launch products with frozen IDs + agreed pricing.  
5. Create Sandbox Apple ID tester(s).  
6. After Functions deploy: set ASSN v2 Production + Sandbox URLs to `appStoreServerNotification` HTTPS endpoint.

### Google Play

1. Confirm Play app package `com.qmatch.app` (resolve `com.example.qmatch` Firebase client drift).  
2. Create service account; grant Play Console **View financial data** / **Manage orders and subscriptions** (or current Publisher API equivalent); link Cloud project.  
3. Create subscription `qmatch.resonance` + base plans `monthly` / `annual`.  
4. Create consumables `qmatch.super_resonance.x1` and `qmatch.boost.x1`.  
5. Create license testers.  
6. Enable RTDN → Pub/Sub topic; push subscription to `playRealtimeDeveloperNotification`.

**This audit does not authorize those console creates.**

---

## 7. Blockers

| Blocker | Blocks |
| --- | --- |
| No Apple API key / issuer / key id / `.p8` | Apple verify + ASSN verify path |
| No Play Publisher SA + permissions | Play verify + RTDN re-fetch |
| No Secret Manager → Functions binding (`needs_code`) | Runtime use of any provisioned secrets |
| No sandbox SKUs | E2E purchase / restore / renew / revoke tests |
| No ASSN / RTDN URL wiring | Live lifecycle notifications |
| Explicit deploy not authorized | Public webhook URLs |
| Console SKU creation not authorized | Product existence in stores |

---

## 8. Exact next step

**Provision App Store Connect API key + Play Publisher service account into Secret Manager under the frozen names (`APPLE_IAP_*`, `PLAY_IAP_*`) — Function `defineSecret` bindings already exist. Still no console SKU creation and no webhook deploy until separately authorized.**

Rationale: secret *mounting* code is ready; remaining hard gap is **human credential creation** + sandbox SKUs.

---

## Trace checklist

| Check | Verdict |
| --- | --- |
| Apple items classified | Yes (§2) |
| Google items classified | Yes (§3) |
| Required secret names listed | Yes (§4) |
| Code gaps before credentials | Yes (§5) |
| Console actions listed without executing | Yes (§6) |
| Blockers + exact next step | Yes (§7–8) |
| No code / deploy / console changes in this audit | Yes |
