#!/usr/bin/env bash
# Strip Flutter web serviceWorkerSettings so browsers do not re-cache old main.dart.js.
# Also remove empty wasm-dry-run build entries that can confuse FlutterLoader.
# Keep flutter_service_worker.js (unregistering) for clients that already have a SW.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BOOTSTRAP="$ROOT/build/web/flutter_bootstrap.js"

if [[ ! -f "$BOOTSTRAP" ]]; then
  echo "Missing $BOOTSTRAP — run flutter build web first." >&2
  exit 1
fi

python3 - <<'PY'
from pathlib import Path
import re
import json

path = Path("build/web/flutter_bootstrap.js")
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
    # Fallback: remove literal ,{}] from builds arrays.
    new_text2, cleaned_n = re.subn(r',"builds":\[(\{.*?\}),\{\}\]', r',"builds":[\1]', new_text, count=1)

path.write_text(new_text2)
print(
    f"patched {path} (serviceWorkerSettings stripped={n > 0 or new_text != text}; "
    f"empty builds removed={cleaned_n > 0})"
)
PY
