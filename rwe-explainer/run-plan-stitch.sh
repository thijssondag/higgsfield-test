#!/usr/bin/env bash
# Stitch the three RWE explainer clips into rwe-first-45s.mp4.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

for clip in scene01.mp4 scene02.mp4 scene03.mp4; do
  if [ ! -s "rwe-explainer/videos/$clip" ]; then
    echo "Missing rwe-explainer/videos/$clip" >&2
    exit 1
  fi
done

cat > /tmp/rwe-concat.txt <<EOF
file '$(pwd)/rwe-explainer/videos/scene01.mp4'
file '$(pwd)/rwe-explainer/videos/scene02.mp4'
file '$(pwd)/rwe-explainer/videos/scene03.mp4'
EOF

ffmpeg -y -f concat -safe 0 -i /tmp/rwe-concat.txt -c copy rwe-explainer/videos/rwe-first-45s.mp4
echo "Done: rwe-explainer/videos/rwe-first-45s.mp4"
