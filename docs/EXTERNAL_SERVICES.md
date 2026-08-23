# Q.Match External Services & Secrets Registry

This file is the recovery map for external services used by Q.Match.

Real private credentials must never be committed to Git.

## Flutter local configuration

Tracked template:

`config/secrets.example.json`

Real local configuration:

`config/secrets.local.json`

The local file is excluded from Git.

Run Q.Match with:

    ./tool/run_qmatch.sh

Equivalent command:

    flutter run --dart-define-from-file=config/secrets.local.json

Release iOS build:

    flutter build ipa --release --dart-define-from-file=config/secrets.local.json

## GIPHY

Purpose:

GIF search, trending GIFs and GIF sending inside Q.Match private chat.

Configuration variable:

`QMATCH_GIPHY_API_KEY`

Flutter implementation:

`lib/features/messages/services/giphy_service.dart`

Provider:

GIPHY Developers / Developer Dashboard

Registered application:

`Q.Match`

Current integration:

GIPHY Public API / iOS.

Recovery procedure:

1. Sign in to the GIPHY Developer Dashboard.
2. Find the Q.Match application.
3. Open its API key.
4. Copy the existing key or rotate/create a replacement.
5. Put the value in `config/secrets.local.json` as `QMATCH_GIPHY_API_KEY`.
6. Run the application with `./tool/run_qmatch.sh`.

The actual GIPHY API key is intentionally not stored in Git.

If a separate Android GIPHY application/key is introduced later, document
its configuration variable and dashboard entry here before release.

## Firebase

Firebase project:

`qmatch-53d62`

Services used by Q.Match include:

- Firebase Authentication
- Cloud Firestore
- Cloud Functions
- Firebase Cloud Messaging
- Firebase Storage
- Google Secret Manager bindings

FlutterFire-generated Firebase configuration is kept in the normal project
configuration files.

## Apple App Store / StoreKit server credentials

Server-side values are managed with Firebase / Google Secret Manager.

Secret names:

- `APPLE_IAP_ISSUER_ID`
- `APPLE_IAP_KEY_ID`
- `APPLE_IAP_PRIVATE_KEY`
- `APPLE_IAP_BUNDLE_ID`
- `APPLE_IAP_ENVIRONMENT`
- `APPLE_IAP_APP_APPLE_ID`

Definitions:

`functions/src/store_iap_secrets.js`

Runtime loader:

`functions/src/apple_iap_config.js`

Recovery:

Use the corresponding App Store Connect credentials and update the matching
Firebase Secret Manager values.

Never store the real private key in Git.

## Google Play server credentials

Secret names:

- `PLAY_IAP_PACKAGE_NAME`
- `PLAY_IAP_CLIENT_EMAIL`
- `PLAY_IAP_PRIVATE_KEY`

Definitions:

`functions/src/store_iap_secrets.js`

Runtime loader:

`functions/src/play_iap_config.js`

Recovery:

Use the Google Play / Google Cloud service-account configuration and update
the corresponding Firebase Secret Manager values.

## Non-secret Flutter dart-defines

Known feature/debug flags include:

- `QMATCH_DISCOVER_L2_US`
- `QMATCH_DEBUG_FORCE_PILOT_ASSESSMENT_SETS`
- `QMATCH_ENABLE_ASSESSMENT_FIRESTORE_SYNC`

These are feature/debug configuration flags, not external API credentials.

## Rule for every future API integration

Whenever Q.Match gains a new external API, SDK, service, key, credential,
token or secret:

1. Record the provider and dashboard here.
2. Record the exact configuration variable name.
3. Record the source file that consumes it.
4. Add a placeholder to a tracked example config when applicable.
5. Keep real values in an ignored local file or Secret Manager.
6. Record how to recover or rotate the credential.
7. Do not consider the integration complete until this registry is updated.

This file is deliberately tracked in Git so a fresh clone retains the
complete external-service recovery map.
