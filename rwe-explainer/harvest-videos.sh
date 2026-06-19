#!/usr/bin/env bash
# Download completed Seedance clips from Higgsfield job history (browser or CLI jobs).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export PATH="${HOME}/.local/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

bash "$ROOT/.cursor/scripts/install-cloud-deps.sh" >/dev/null

OUT_DIR="rwe-explainer/videos"
mkdir -p "$OUT_DIR"

download_job() {
  local job_id="$1"
  local out_file="$2"
  if [ -s "$out_file" ]; then
    echo "[skip] $out_file already exists"
    return 0
  fi
  local url
  url="$(higgsfield generate get "$job_id" --json | jq -r '.result_url // empty')"
  if [ -z "$url" ] || [ "$url" = "null" ]; then
    echo "[fail] job $job_id has no result_url (status may not be completed)" >&2
    return 1
  fi
  curl -fsSL "$url" -o "$out_file"
  echo "[saved] $out_file"
}

# Usage: harvest-videos.sh [job_id sceneNN.mp4] ...
# With no args: download the 3 most recent completed Seedance videos to scene01..03.
if [ "$#" -gt 0 ]; then
  while [ "$#" -ge 2 ]; do
    download_job "$1" "$OUT_DIR/$2"
    shift 2
  done
  exit 0
fi

echo "Fetching latest completed Seedance jobs..."
mapfile -t JOBS < <(
  higgsfield generate list --video --size 20 --json \
    | jq -r '.[] | select(.status == "completed") | .id' \
    | head -3
)

if [ "${#JOBS[@]}" -lt 3 ]; then
  echo "Need 3 completed Seedance jobs; found ${#JOBS[@]}." >&2
  echo "Create clips in the browser first, then re-run." >&2
  exit 1
fi

# Jobs are newest-first; assign oldest of the three to scene01 for stable ordering.
download_job "${JOBS[2]}" "$OUT_DIR/scene01.mp4"
download_job "${JOBS[1]}" "$OUT_DIR/scene02.mp4"
download_job "${JOBS[0]}" "$OUT_DIR/scene03.mp4"

echo "Done. Videos in $OUT_DIR/"
