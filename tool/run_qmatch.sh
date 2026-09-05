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

v2_internal=false
for arg in "$@"; do
  case "$arg" in
    --dart-define=QMATCH_FREQUENCY_V2_INTERNAL=true)
      v2_internal=true
      ;;
  esac
done

echo ""
if [[ "$v2_internal" == true ]]; then
  echo "=============================================="
  echo "QMatch runtime: INTERNAL FREQUENCY V2"
  echo "=============================================="
else
  echo "=============================================="
  echo "QMatch runtime: DEFAULT FREQUENCY V1"
  echo "=============================================="
fi
echo ""

exec flutter run --dart-define-from-file="$SECRETS_FILE" "$@"
