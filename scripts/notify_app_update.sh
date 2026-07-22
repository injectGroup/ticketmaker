#!/usr/bin/env bash
# Local/CI helper: post an app-update message to Google Chat when GOOGLE_CHAT_WEBHOOK_URL is set.
# TaskManager Web UI milestones are recorded via MCP notify_milestone_reached (see .cursor/rules).
set -euo pipefail

MESSAGE="${1:-}"
if [ -z "$MESSAGE" ]; then
  echo "Usage: $0 \"App update: short description\"" >&2
  exit 1
fi

if [ -z "${GOOGLE_CHAT_WEBHOOK_URL:-${CHAT_WEBHOOK_URL:-}}" ]; then
  echo "GOOGLE_CHAT_WEBHOOK_URL (or CHAT_WEBHOOK_URL) is not set; skipping Chat notify." >&2
  exit 0
fi

WEBHOOK="${GOOGLE_CHAT_WEBHOOK_URL:-$CHAT_WEBHOOK_URL}"
TEXT="ticketmaker: ${MESSAGE}"
export TEXT WEBHOOK
python3 <<'PY'
import json, os, urllib.request
body = json.dumps({"text": os.environ["TEXT"]}).encode("utf-8")
req = urllib.request.Request(
    os.environ["WEBHOOK"],
    data=body,
    headers={"Content-Type": "application/json; charset=UTF-8"},
    method="POST",
)
with urllib.request.urlopen(req, timeout=30) as resp:
    print("Google Chat status:", resp.status)
PY
