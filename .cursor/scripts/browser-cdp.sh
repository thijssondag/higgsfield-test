#!/usr/bin/env bash
# CDP CLI fallback: control Desktop Chrome on port 9222 when DevTools MCP is unavailable.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CDP_DIR="${SCRIPT_DIR}/browser-cdp"
PORT="${CHROME_DEBUG_PORT:-9222}"
export CHROME_DEBUG_URL="${CHROME_DEBUG_URL:-http://127.0.0.1:${PORT}}"

if ! curl -fsS "${CHROME_DEBUG_URL}/json/version" >/dev/null 2>&1; then
  echo "Chrome is not listening on ${CHROME_DEBUG_URL}." >&2
  echo "Run: bash .cursor/scripts/start-chrome-debug.sh" >&2
  exit 1
fi

if [ ! -d "${CDP_DIR}/node_modules/puppeteer-core" ]; then
  echo "Installing browser-cdp dependencies..." >&2
  npm install --prefix "${CDP_DIR}" --no-fund --no-audit --silent
fi

exec node "${CDP_DIR}/cli.mjs" "$@"
