# QMatch Store Notification Backend v1

| Field | Value |
| --- | --- |
| Document id | `qmatch_store_notification_backend_v1` |
| Status | `store_notification_backend_v1` · `engineering_validated_not_deployed` |
| Parents | [Store Purchase Verification Contract](./qmatch_store_purchase_verification_contract_v1.md) · [Entitlement Firestore Schema](./qmatch_resonance_entitlement_firestore_schema_v1.md) |
| Implementation | `functions/src/store_notification_apple.js` · `store_notification_play.js` · `store_purchase_index.js` · `store_notification_http.js` |
| Tests | `functions/test/store_notification_foundation.test.js` |
| Draft / freeze date | 2026-08-13 |

---

## 0. Purpose

Freeze the **implemented** App Store Server Notifications v2 (ASSN) and Google Play Real-time Developer Notifications (RTDN) backend behavior so deployment work cannot redefine trust, idempotency, or lifecycle mapping.

**Status meaning:** engineering-validated against unit/fixture tests. **Not deployed.** Does **not** authorize store-console creation, credential provisioning into production, or client Billing SDK work.

### Ratification / freeze lock (2026-08-13)

| Lock | Rule |
| --- | --- |
| ASSN v2 | Verifies `signedPayload` with official Apple `SignedDataVerifier` before any trust |
| RTDN | **Signal only** — never grants from Pub/Sub body fields alone |
| Re-fetch | Both paths **re-fetch authoritative store state** before entitlement mutation |
| Idempotency | Duplicate notifications are idempotent (ledger noop) |
| Lifecycle | renew / grace / billing_retry / expire / refund / revoke mappings frozen below |
| Uid binding | Via verified store identity and/or `store_purchase_index` |
| Fail closed | Unknown uid / unknown product → no mutation |
| Side effects | Notifications **never** alter compatibility scores or `discover_eligible` |
| Deploy | Prerequisites listed in §6 remain **unresolved** until explicitly authorized |

---

## 1. Frozen notification contract

### 1.1 Apple ASSN v2

| Step | Behavior |
| --- | --- |
| 1 | Receive HTTPS body with `signedPayload` |
| 2 | `SignedDataVerifier.verifyAndDecodeNotification(signedPayload)` — invalid JWS → fail closed |
| 3 | Dedupe key: `notificationUUID` |
| 4 | Resolve uid from decoded `appAccountToken` **or** `store_purchase_index/ios:original:{originalTransactionId}` |
| 5 | Re-fetch via existing Apple verifier (`getTransactionInfo` + status) |
| 6 | Apply trusted result to `entitlements/{uid}` + purchase ledger (`verification_source=webhook`) |
| 7 | Unknown uid / product_not_allowed / API failure → **no** entitlement write |

HTTP entry (not activated for prod): `appStoreServerNotification` → `handleAppleAssnNotification`.

### 1.2 Google Play RTDN

| Step | Behavior |
| --- | --- |
| 1 | Parse authenticated Pub/Sub push (base64 `message.data` or pre-decoded developer notification) |
| 2 | Treat payload as **signal only** |
| 3 | Dedupe key: Pub/Sub `messageId` (+ event type in ledger id) |
| 4 | Resolve uid from `store_purchase_index/android:token:{sha256(purchaseToken)}` |
| 5 | Re-fetch via existing Play verifier using `purchaseToken` (`subscriptionsv2` / products) |
| 6 | Apply trusted result (`verification_source=webhook`) |
| 7 | Unknown uid / unknown SKU / API failure → **no** entitlement write |

HTTP entry (not activated for prod): `playRealtimeDeveloperNotification` → `handlePlayRtdnNotification`.

### 1.3 Shared hard rules

| Rule | Spec |
| --- | --- |
| No blind trust | Notification fields never grant Resonance or consumable credits alone |
| Authoritative store | Mutation only after `isTrustedVerified` from Apple/Play re-fetch |
| Index | `store_purchase_index` Admin-only (Firestore rules deny client R/W) |
| Schema | Uses frozen `entitlements/{uid}` + `purchase_ledger` only |
| Matching | No writes to compatibility / Persona / ranking |
| Discover | No writes to `discover_eligible` |
| Client SDK | Out of scope |
| Console SKUs | Not authorized by this freeze |

---

## 2. Lifecycle mapping (frozen)

Authoritative **subscription_state** always comes from re-fetched store status. Notification type only selects a **lifecycle hint** and which events are handled.

### 2.1 Apple ASSN → hint → expected entitlement outcome (after re-fetch)

| ASSN `notificationType` | Lifecycle hint | Typical re-fetched outcome |
| --- | --- | --- |
| `DID_RENEW` / `SUBSCRIBED` / `OFFER_REDEEMED` / `RENEWAL_EXTENDED` | `renew` | `active` → Resonance access |
| `DID_FAIL_TO_RENEW` | `billing_or_grace` | `grace` or `billing_retry` → access preserved while store entitles |
| `EXPIRED` / `GRACE_PERIOD_EXPIRED` | `expire` | `expired` → deny Resonance |
| `REFUND` / `REVOKE` | `revoke` | `revoked` → deny Resonance immediately |
| `TEST` | n/a | Ack only — no mutation |
| Other types | ignored | No mutation |

### 2.2 Play RTDN subscriptionNotification → hint

| `notificationType` | Name | Lifecycle hint | Typical re-fetched outcome |
| --- | --- | --- | --- |
| 1 / 2 / 4 / 7 | RECOVERED / RENEWED / PURCHASED / RESTARTED | `renew` | `active` → access |
| 5 / 6 | ON_HOLD / IN_GRACE_PERIOD | `billing_or_grace` | `billing_retry` / `grace` → access while entitled |
| 3 / 13 | CANCELED / EXPIRED | `expire` | `expired` (or still active until period end per Play re-fetch) |
| 12 | REVOKED | `revoke` | `revoked` → deny |
| Other | ignored | No mutation |

### 2.3 One-time / voided (Play)

| Signal | Behavior |
| --- | --- |
| OTP PURCHASED (frozen SKUs only) | Re-fetch product purchase → credit intent / ledger if PURCHASED |
| OTP CANCELED | No credit |
| Voided purchase | Re-fetch path; revoke/deny when store confirms |

Canonical `subscription_state` values remain: `none` \| `active` \| `billing_retry` \| `grace` \| `expired` \| `revoked`.

Access invariant unchanged:

```
resonance_access = (tier == resonance) && state ∈ {active, grace, billing_retry}
```

---

## 3. Trust / idempotency / uid binding

### 3.1 Trust

| Input | Trusted? |
| --- | --- |
| Raw ASSN JSON fields without JWS verify | **No** |
| Raw RTDN developerNotification fields | **No** (signal only) |
| Apple JWS-verified + API re-fetch result | **Yes** (when `isTrustedVerified`) |
| Play API re-fetch via purchaseToken | **Yes** (when `isTrustedVerified`) |

### 3.2 Idempotency ledger ids

| Platform | Ledger id pattern |
| --- | --- |
| Apple ASSN | `ios:sub:{originalTransactionId}:{notificationType}:{notificationUUID}` |
| Play RTDN | `android:sub:{token:<sha256(purchaseToken)>}:{eventType}:{messageId}` |

Duplicate id → ledger **noop** (safe Pub/Sub / ASSN retry).

### 3.3 Uid binding

| Source | Use |
| --- | --- |
| Apple `appAccountToken` | Prefer when present and equals Firebase uid |
| `store_purchase_index` | `ios:original:{originalTransactionId}` / `android:token:{sha256}` → `{ uid }` |
| Missing both | `unknown_uid` — fail closed |

Index is written on successful trusted purchase apply (Admin). Client cannot read/write index.

### 3.4 Fail closed

| Condition | Code / behavior |
| --- | --- |
| Missing Apple/Play credentials | `verification_not_configured` |
| Invalid ASSN signature | `invalid_jws` |
| Invalid Pub/Sub payload | `invalid_message` |
| Unknown / unbound uid | `unknown_uid` |
| Non-frozen product | `product_not_allowed` |
| Store API error | `store_verification_failed` |

---

## 4. Code map (validated)

| Module | Role |
| --- | --- |
| `store_notification_apple.js` | ASSN verify + re-fetch + apply |
| `store_notification_play.js` | RTDN parse + re-fetch + apply |
| `store_purchase_index.js` | Admin uid index |
| `store_notification_http.js` | HTTP adapters |
| `functions/index.js` | `appStoreServerNotification` · `playRealtimeDeveloperNotification` exports |
| `firestore.rules` | `store_purchase_index` deny-all for clients |

---

## 5. Exact next steps (not this freeze)

1. Provision secrets (see §6) in Secret Manager / Functions config.  
2. Create sandbox SKUs (separate authorization).  
3. Register ASSN URL + RTDN Pub/Sub push to the Functions endpoints.  
4. Deploy Functions + rules.  
5. Sandbox E2E: renew / expire / revoke / grace.  

**This document does not deploy or create console SKUs.**

---

## 6. Deployment prerequisites (**unresolved**)

| Prerequisite | Purpose | Status |
| --- | --- | --- |
| Apple App Store Connect API key (Issuer ID, Key ID, `.p8`) | Server API + ASSN verify path | **Unresolved** |
| Apple bundle id + app Apple id | JWS / API binding | **Unresolved** |
| ASSN v2 production + sandbox HTTPS endpoints configured in App Store Connect | Deliver notifications | **Unresolved** |
| Apple root CAs (repo has public DER under `functions/certs/apple/`) | `SignedDataVerifier` | Present (public) — env wiring still required |
| Play Publisher service account | `subscriptionsv2` / products re-fetch | **Unresolved** |
| `PLAY_IAP_PACKAGE_NAME` + private key / credentials | Play verifier | **Unresolved** |
| RTDN topic + push subscription → Cloud Function | Deliver Play signals | **Unresolved** |
| Firebase / Cloud Functions secrets for `APPLE_IAP_*` and `PLAY_IAP_*` | Runtime config | **Unresolved** |
| Sandbox store products (frozen IDs) + sandbox test accounts | E2E | **Unresolved** — console creation **not** authorized here |
| Client Billing / StoreKit SDK | Out of scope | Deferred |

Do **not** commit private keys or service-account JSON to git.

---

## Trace checklist

| Check | Verdict |
| --- | --- |
| ASSN verifies signedPayload | Yes (§1.1) |
| RTDN signal-only + re-fetch | Yes (§1.2) |
| Idempotent duplicates | Yes (§3.2) |
| Lifecycle renew/grace/billing/expire/revoke | Yes (§2) |
| Uid index + fail closed | Yes (§3.3–3.4) |
| No matching / discover_eligible effects | Yes (§1.3) |
| Deployment prerequisites listed, unresolved | Yes (§6) |
| Status | `store_notification_backend_v1` · `engineering_validated_not_deployed` |
| Functions tests | `store_notification_foundation` covered in suite (114 passing at freeze) |
