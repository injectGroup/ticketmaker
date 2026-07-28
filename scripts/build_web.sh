#!/usr/bin/env bash
# Clean release web build with cache-busting for main.dart.js / bootstrap assets.
# Usage: ./scripts/build_web.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUILD_ID="$(git rev-parse --short HEAD 2>/dev/null || true)"
if [[ -z "${BUILD_ID}" ]]; then
  BUILD_ID="$(date -u +%Y%m%d%H%M%S)"
fi
# Unique per invocation so back-to-back deploys of the same commit still bust.
BUILD_ID="${BUILD_ID}-$(date -u +%Y%m%d%H%M%S)"
export TICKETMAKER_BUILD_ID="$BUILD_ID"

echo "==> flutter clean (enforce fresh release JS)"
flutter clean

echo "==> flutter pub get"
flutter pub get

echo "==> flutter build web --release (no PWA / service worker caching)"
flutter build web \
  --release \
  --pwa-strategy=none \
  --no-wasm-dry-run

echo "==> patch bootstrap + cache-bust JS (BUILD_ID=${TICKETMAKER_BUILD_ID})"
"${ROOT}/scripts/patch_web_bootstrap.sh"

echo "==> web build ready under build/web"
