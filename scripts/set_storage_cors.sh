#!/usr/bin/env bash
# Apply Storage CORS from repo-root cors.json.
# Usage: ./scripts/set_storage_cors.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CORS_FILE="${ROOT}/cors.json"

if [[ ! -f "$CORS_FILE" ]]; then
  echo "Missing $CORS_FILE" >&2
  exit 1
fi

# Prefer the bucket name in firebase_options / Console; fall back to classic appspot.
CANDIDATES=(
  "gs://quick-ticket-maker-sandbox.firebasestorage.app"
  "gs://quick-ticket-maker-sandbox.appspot.com"
)

for bucket in "${CANDIDATES[@]}"; do
  echo "==> Trying $bucket"
  if gsutil ls "$bucket" >/dev/null 2>&1; then
    gsutil cors set "$CORS_FILE" "$bucket"
    echo "==> Applied CORS:"
    gsutil cors get "$bucket"
    exit 0
  fi
  echo "    (bucket missing or inaccessible)"
done

echo >&2
echo "No Storage bucket found. Enable Billing + Firebase Storage (Console → Build → Storage → Get started)," >&2
echo "then re-run:" >&2
echo "  gsutil cors set cors.json gs://quick-ticket-maker-sandbox.firebasestorage.app" >&2
exit 1
