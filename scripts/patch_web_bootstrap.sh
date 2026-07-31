#!/usr/bin/env bash
# Post-process Flutter web output:
# 1) Strip serviceWorkerSettings so browsers do not re-cache old main.dart.js.
# 2) Remove empty wasm-dry-run build entries that can confuse FlutterLoader.
# 3) Cache-bust main.dart.js / flutter.js URLs with TICKETMAKER_BUILD_ID.
# 4) Stamp index.html build id (and script src query params when present).
#
# Keep flutter_service_worker.js (unregistering) for clients that already have a SW.
# Requires: flutter build web first (or run via scripts/build_web.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BOOTSTRAP="$ROOT/build/web/flutter_bootstrap.js"
INDEX="$ROOT/build/web/index.html"

if [[ ! -f "$BOOTSTRAP" && ! -f "$INDEX" ]]; then
  echo "Missing build/web output — run flutter build web (or ./scripts/build_web.sh) first." >&2
  exit 1
fi

BUILD_ID="${TICKETMAKER_BUILD_ID:-}"
if [[ -z "$BUILD_ID" ]]; then
  BUILD_ID="$(git rev-parse --short HEAD 2>/dev/null || true)"
  if [[ -z "$BUILD_ID" ]]; then
    BUILD_ID="$(date -u +%Y%m%d%H%M%S)"
  fi
  BUILD_ID="${BUILD_ID}-$(date -u +%Y%m%d%H%M%S)"
fi
export TICKETMAKER_BUILD_ID="$BUILD_ID"

python3 - <<'PY'
from pathlib import Path
import os
import re
import json

build_id = os.environ["TICKETMAKER_BUILD_ID"]
web = Path("build/web")

def cache_bust_js_urls(text: str) -> str:
    """Append ?v=<build_id> to Flutter entrypoint / loader JS references."""
    patterns = (
        r'(["\'])(main\.dart\.js(?:\?[^"\']*)?)(["\'])',
        r'(["\'])(flutter\.js(?:\?[^"\']*)?)(["\'])',
        r'(["\'])(flutter_bootstrap\.js(?:\?[^"\']*)?)(["\'])',
        r'(["\'])(flutter_service_worker\.js(?:\?[^"\']*)?)(["\'])',
    )
    out = text
    for pat in patterns:
        def repl(m: re.Match[str]) -> str:
            q1, url, q2 = m.group(1), m.group(2), m.group(3)
            if "v=" in url:
                return m.group(0)
            sep = "&" if "?" in url else "?"
            return f"{q1}{url}{sep}v={build_id}{q2}"

        out = re.sub(pat, repl, out)
    return out


def patch_bootstrap(path: Path) -> None:
    text = path.read_text()

    # Replace any _flutter.loader.load({ ... serviceWorkerSettings ... }) with a bare load.
    pattern = re.compile(
        r"_flutter\.loader\.load\(\s*\{[\s\S]*?serviceWorkerSettings\s*:[\s\S]*?\}\s*\)\s*;",
        re.M,
    )
    new_text, n = pattern.subn("_flutter.loader.load();", text, count=1)

    if n == 0:
        if re.search(r"_flutter\.loader\.load\(\s*\{[^}]*serviceWorkerSettings", text):
            raise SystemExit("Could not strip serviceWorkerSettings from flutter_bootstrap.js")
        new_text = re.sub(
            r"_flutter\.loader\.load\([\s\S]*\)\s*;\s*$",
            "_flutter.loader.load();",
            text,
            count=1,
        )

    # Drop empty wasm-dry-run build objects: "builds":[{...},{}] → "builds":[{...}]
    def _clean_builds(match: re.Match[str]) -> str:
        prefix = match.group(1)
        raw = match.group(2)
        try:
            builds = json.loads(raw)
        except json.JSONDecodeError:
            return match.group(0)
        cleaned = [b for b in builds if isinstance(b, dict) and b.get("compileTarget")]
        return f'{prefix}{json.dumps(cleaned, separators=(",", ":"))}'

    new_text2, cleaned_n = re.subn(
        r'(_flutter\.buildConfig\s*=\s*\{[^{]*"builds"\s*:\s*)(\[[\s\S]*?\])',
        _clean_builds,
        new_text,
        count=1,
    )
    if cleaned_n == 0:
        new_text2, cleaned_n = re.subn(
            r',"builds":\[(\{.*?\}),\{\}\]', r',"builds":[\1]', new_text, count=1
        )

    new_text2 = cache_bust_js_urls(new_text2)
    path.write_text(new_text2)
    print(
        f"patched {path} (serviceWorkerSettings stripped; "
        f"empty builds removed={cleaned_n > 0}; cache-bust v={build_id})"
    )


def patch_index(path: Path) -> None:
    text = path.read_text()
    text = text.replace("{{TICKETMAKER_BUILD_ID}}", build_id)
    text = re.sub(
        r'window\.__TICKETMAKER_BUILD_ID__\s*=\s*["\'][^"\']*["\']',
        f'window.__TICKETMAKER_BUILD_ID__ = "{build_id}"',
        text,
        count=1,
    )
    # If the built index still loads bootstrap/flutter via <script src=...>.
    text = re.sub(
        r'(<script[^>]+src=["\'])(flutter_bootstrap\.js)(["\'])',
        rf'\1\2?v={build_id}\3',
        text,
    )
    text = re.sub(
        r'(<script[^>]+src=["\'])(flutter\.js)(["\'])',
        rf'\1\2?v={build_id}\3',
        text,
    )
    text = cache_bust_js_urls(text)
    path.write_text(text)
    print(f"patched {path} (BUILD_ID={build_id})")


bootstrap = web / "flutter_bootstrap.js"
index = web / "index.html"
if bootstrap.is_file():
    patch_bootstrap(bootstrap)
if index.is_file():
    patch_index(index)
PY
