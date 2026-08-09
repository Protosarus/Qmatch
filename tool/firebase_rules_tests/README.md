# Firebase rules tests (P2C-1A)

## Prerequisites

- Node.js ≥ 18
- **Java 17+** for emulator runtime used by pinned `firebase-tools@12.9.1`
  - Host `firebase-tools` ≥15 requires **Java 21+**; this package pins v12 via `npx` for Java 17 hosts
- Network for first `npm install` / `npx` fetch

## Command

```bash
cd tool/firebase_rules_tests
npm install
npm test
```

`npm test` runs emulators from the **repository root** `firebase.json` (so rules paths stay inside the Firebase project directory):

```text
npx firebase-tools@12.9.1 emulators:exec --project demo-qmatch --only firestore,storage \
  "cd tool/firebase_rules_tests && npx mocha --timeout 20000 test/rules.test.js"
```

Uses repository root:

- `firestore.rules`
- `storage.rules`
- `firebase.json` emulator ports

Do **not** deploy from this folder.
