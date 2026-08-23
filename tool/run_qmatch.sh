#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_FILE="$ROOT_DIR/config/secrets.local.json"

if [[ ! -f "$SECRETS_FILE" ]]; then
  echo "Missing: config/secrets.local.json"
  echo "Copy config/secrets.example.json to config/secrets.local.json and fill in the required values."
  exit 1
fi

cd "$ROOT_DIR"
exec flutter run --dart-define-from-file="$SECRETS_FILE" "$@"
