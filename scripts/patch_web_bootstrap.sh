#!/usr/bin/env bash
# Strip Flutter web serviceWorkerSettings so browsers do not re-cache old main.dart.js.
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

path = Path("build/web/flutter_bootstrap.js")
text = path.read_text()

# Replace any _flutter.loader.load({ ... serviceWorkerSettings ... }) with a bare load.
pattern = re.compile(
    r"_flutter\.loader\.load\(\s*\{[\s\S]*?serviceWorkerSettings\s*:[\s\S]*?\}\s*\)\s*;",
    re.M,
)
new_text, n = pattern.subn("_flutter.loader.load();", text, count=1)

if n == 0:
    # Already bare, or different formatting — force trailing call to bare load().
    if re.search(r"_flutter\.loader\.load\(\s*\{[^}]*serviceWorkerSettings", text):
        raise SystemExit("Could not strip serviceWorkerSettings from flutter_bootstrap.js")
    # Ensure we end with load(); not load({serviceWorkerSettings:...})
    new_text = re.sub(
        r"_flutter\.loader\.load\([\s\S]*\)\s*;\s*$",
        "_flutter.loader.load();",
        text,
        count=1,
    )

path.write_text(new_text)
print(f"patched {path} (serviceWorkerSettings stripped={n > 0 or new_text != text})")
PY
