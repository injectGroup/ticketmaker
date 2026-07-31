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

echo "==> verify web plugin registrant is complete"
python3 - <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(".")
deps_path = root / ".flutter-plugins-dependencies"
if not deps_path.exists():
    print("ERROR: .flutter-plugins-dependencies missing after build", file=sys.stderr)
    sys.exit(1)

deps = json.loads(deps_path.read_text())
web_plugins = [p["name"] for p in deps.get("plugins", {}).get("web", [])]
if not web_plugins:
    print("ERROR: no web plugins listed in .flutter-plugins-dependencies", file=sys.stderr)
    sys.exit(1)

registrants = sorted(
    (root / ".dart_tool" / "flutter_build").glob("*/web_plugin_registrant.dart"),
    key=lambda p: p.stat().st_mtime,
    reverse=True,
)
if not registrants:
    print("ERROR: no web_plugin_registrant.dart found under .dart_tool/flutter_build", file=sys.stderr)
    sys.exit(1)

registrant = registrants[0]
text = registrant.read_text()
missing = [name for name in web_plugins if f"package:{name}/" not in text]
if missing:
    print(f"ERROR: {registrant} is missing web plugins: {', '.join(missing)}", file=sys.stderr)
    print("Refusing to ship a build with an incomplete plugin registrant.", file=sys.stderr)
    sys.exit(1)

print(f"OK: {registrant.name} registers all {len(web_plugins)} web plugins")
PY

echo "==> patch bootstrap + cache-bust JS (BUILD_ID=${TICKETMAKER_BUILD_ID})"
"${ROOT}/scripts/patch_web_bootstrap.sh"

echo "==> web build ready under build/web"
