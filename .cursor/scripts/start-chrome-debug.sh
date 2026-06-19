#!/usr/bin/env bash
# Launch Chrome with remote debugging for Chrome DevTools MCP attach mode.
# Log into higgsfield.ai once in this window; profile persists across sessions.
set -euo pipefail

PORT="${CHROME_DEBUG_PORT:-9222}"
PROFILE="${CHROME_USER_DATA_DIR:-${HOME}/.config/chrome-higgsfield-profile}"
URL="${1:-https://higgsfield.ai}"

mkdir -p "$PROFILE"

if command -v google-chrome >/dev/null 2>&1; then
  CHROME=google-chrome
elif command -v google-chrome-stable >/dev/null 2>&1; then
  CHROME=google-chrome-stable
elif command -v chromium >/dev/null 2>&1; then
  CHROME=chromium
else
  echo "Chrome not found. Install google-chrome or set CHROME to the binary path." >&2
  exit 1
fi

if curl -fsS "http://127.0.0.1:${PORT}/json/version" >/dev/null 2>&1; then
  echo "Chrome already listening on port ${PORT}."
  echo "Profile: ${PROFILE}"
  echo "Open: ${URL}"
  exit 0
fi

echo "Starting ${CHROME} (debug port ${PORT}, profile ${PROFILE})"
nohup "$CHROME" \
  --remote-debugging-port="${PORT}" \
  --user-data-dir="${PROFILE}" \
  --no-first-run \
  --no-default-browser-check \
  "${URL}" \
  >/tmp/chrome-debug.log 2>&1 &

for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${PORT}/json/version" >/dev/null 2>&1; then
    echo "Chrome ready at http://127.0.0.1:${PORT}"
    echo "Log in to Higgsfield in the Desktop pane, then tell the agent to proceed."
    exit 0
  fi
  sleep 1
done

echo "Chrome did not start listening on port ${PORT}. See /tmp/chrome-debug.log" >&2
exit 1
