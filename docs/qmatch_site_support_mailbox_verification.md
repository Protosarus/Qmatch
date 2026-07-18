# qmatch.site Support Mailbox Verification (Phase 3P-A24)

Date: 2026-07-18
Mode: **Documentation only** — no DNS/deploy/Firebase changes in this phase

Related: `docs/qmatch_site_live_verification.md`, `docs/support_and_legal_url_readiness.md`

---

## Summary

| Item | Value |
|------|--------|
| Support email | **`support@qmatch.site`** |
| Destination inbox | **`sirinumit@gmail.com`** (Cloudflare Email Routing) |
| Verification method | Manual: Cloudflare routing configured; test message sent to `support@qmatch.site` |
| Result | **Confirmed receiving** — test email arrived in destination inbox |
| Monitoring | Via `sirinumit@gmail.com` unless otherwise stated |
| Send-as `support@qmatch.site` from Gmail | **Optional / future** — **not** a launch blocker |

---

## What was verified

1. Cloudflare Email Routing delivers mail addressed to `support@qmatch.site` to `sirinumit@gmail.com`.
2. A test email was **received successfully**.
3. Ops can monitor support (and deletion-related) mail in that Gmail inbox.

---

## Remaining email limitations

| Limitation | Notes |
|------------|--------|
| Reply “From:” identity | Replies may currently show as `sirinumit@gmail.com` unless Gmail “Send mail as” is set up |
| SPF/DKIM for outbound as `support@qmatch.site` | May still need Gmail + DNS sender setup for branded outbound |
| Auto-reply / ticketing | Not required for launch; optional |
| Deletion mail labeling | Still recommended (folder/label + runbook) — process, not mailbox receive |

**Launch stance:** **Receive + monitor** is enough to clear the mailbox **P0** blocker. Branded outbound send-as is a nice-to-have.

---

## Optional next step (not required for store submit)

Configure Gmail **Settings → Accounts → Send mail as** for `support@qmatch.site` (and any Cloudflare/Gmail verification SMTP steps) so replies appear from the support address.

---

## Explicit non-actions (this phase)

- No hosting deploy
- No DNS modification by this documentation phase
- No Cloudflare settings changed by this agent
- No Firestore / Admin SDK / rules / Functions
- No app behavior changes
- No commit / push

(Email routing and URL verification were done manually by the operator **before** this doc update.)
