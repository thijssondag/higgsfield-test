#!/usr/bin/env bash
# Execute the RWE explainer video plan (first 45s).
# Usage:
#   run-plan.sh [--frames all|skip] [--videos cli|browser|skip|stitch-only]
#
#   --videos browser  Skip CLI Seedance; use Chrome DevTools MCP + harvest-videos.sh
#   --videos cli      Default: generate clips via higgsfield CLI (--mode fast)
#   --videos skip     Frames only (or use with --frames skip for stitch-only)
#   --videos stitch-only  Only run ffmpeg concat (requires scene01-03.mp4)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FRAMES_MODE="all"
VIDEOS_MODE="cli"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --frames)
      FRAMES_MODE="${2:-all}"
      shift 2
      ;;
    --videos)
      VIDEOS_MODE="${2:-cli}"
      shift 2
      ;;
    -h|--help)
      sed -n '2,10p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

export PATH="${HOME}/.local/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

bash "$ROOT/.cursor/scripts/install-cloud-deps.sh" >/dev/null

if ! higgsfield account status >/dev/null 2>&1; then
  echo "Higgsfield not authenticated." >&2
  echo "Add higgsfield_access_token and higgsfield_refresh_token to Cursor Cloud Agent secrets, then restart the agent." >&2
  exit 1
fi

mkdir -p rwe-explainer/frames rwe-explainer/videos
cp -f image.png rwe-explainer/style-reference.png

download_result() {
  local url="$1"
  local out="$2"
  curl -fsSL "$url" -o "$out"
  echo "Saved $out"
}

run_image() {
  local out="$1"
  local prompt="$2"
  if [ -s "rwe-explainer/frames/$out" ]; then
    echo "Frame exists, skipping: rwe-explainer/frames/$out"
    return 0
  fi
  local url
  url="$(higgsfield generate create gpt_image_2 \
    --prompt "$prompt" \
    --aspect_ratio 16:9 \
    --resolution 2k \
    --image ./rwe-explainer/style-reference.png \
    --wait)"
  download_result "$url" "rwe-explainer/frames/$out"
}

run_video() {
  local out="$1"
  local prompt="$2"
  local start="$3"
  local end="$4"
  if [ -s "rwe-explainer/videos/$out" ]; then
    echo "Video exists, skipping: rwe-explainer/videos/$out"
    return 0
  fi
  local url attempt
  for attempt in 1 2 3 4 5; do
    url="$(higgsfield generate create seedance_2_0 \
      --prompt "$prompt" \
      --start-image "$start" \
      --end-image "$end" \
      --mode fast \
      --duration 15 \
      --aspect_ratio 16:9 \
      --resolution 720p \
      --wait 2>&1)" || true
    if printf '%s' "$url" | grep -q '^https'; then
      download_result "$url" "rwe-explainer/videos/$out"
      return 0
    fi
    echo "[$out] attempt $attempt failed: $url"
    sleep 5
  done
  echo "[$out] FAILED after retries" >&2
  return 1
}

if [ "$FRAMES_MODE" != "skip" ]; then
  echo "=== Step 1: Generate frames ==="

  run_image scene01-start.png '16:9 isometric 3D diorama miniature landscape. Warm pink terracotta sandy ground, sage green grass tufts, winding light blue river. Center-left: large floating white UI card reading "What is Real World Evidence?" in bold Inter-style sans-serif, dark charcoal text. Tiny simplified 3D people walking along the river bank. Soft diffused daylight, tilt-shift depth of field, airy negative space, clean SaaS healthcare explainer aesthetic. Verbatim headline text — no extra characters, no substitutions.'

  run_image scene01-end.png 'Same isometric diorama world as reference: pink ground, green grass hill, blue river. Camera closer to a green mound. Floating white card reads "RWE = clinical insight from data outside randomised controlled trials" in Inter-style sans-serif, dark charcoal, two lines max. One tiny 3D figure on the hill pointing at the card. Identical lighting, palette, and isometric angle as start frame. Verbatim text — no extra characters.'

  run_image scene02-end.png 'Isometric 3D diorama, same pink terrain and lighting. Split composition: LEFT green island labeled "RWD" with raw ingredient cylinders, sand piles, binary data blocks — floating card "The ingredient". RIGHT green island labeled "RWE" with a white plate holding a miniature finished landscape — floating card "The dish". Center blue river connects both islands. Tiny 3D figures between islands. Inter-style sans-serif labels on white cards. Verbatim: "RWD" and "RWE" and "The ingredient" and "The dish". Clean SaaS explainer, soft daylight.'

  run_image scene03-end.png 'Isometric 3D diorama, same world. Five sage-green grass mounds in an arc, each with a 3D icon and white floating label card in Inter-style sans-serif: "EHR", "Claims", "Registries", "Wearables", "Patient apps / ePRO". Icons: medical chart, receipt, clipboard, smartwatch, smartphone — as physical 3D objects on each mound. Blue river weaves between mounds. Header card top-center: "Five real-world data sources". Pink ground, soft daylight, identical palette and camera height as previous scenes. Verbatim text — no extra characters.'

  cp -f rwe-explainer/frames/scene01-end.png rwe-explainer/frames/scene02-start.png
  cp -f rwe-explainer/frames/scene02-end.png rwe-explainer/frames/scene03-start.png
fi

case "$VIDEOS_MODE" in
  cli)
    echo "=== Step 2: Animate with Seedance 2.0 (CLI --mode fast) ==="

    run_video scene01.mp4 \
    'Opening frame is the start image. Closing frame is the end image.
Single continuous take, 15 seconds, 16:9 isometric diorama.

[0-5s]   Wide establishing hold. Blue river flows gently. Title card stable center-left.
[5-10s]  Slow smooth dolly-in along the river path begins. Camera glides forward at constant speed.
[10-15s] Camera descends slightly toward the green definition hill. Settle into closing frame.

Camera: one move only — slow dolly-in along river, locked horizon, no orbit.
Ambient: tiny figures walk along bank, grass sways subtly, river flows.
Constraints: smooth motion, stable framing, no jitter, no warping, UI cards stay fixed and readable, no text morphing, single continuous take.' \
      rwe-explainer/frames/scene01-start.png \
      rwe-explainer/frames/scene01-end.png

    run_video scene02.mp4 \
    'Opening frame is the start image. Closing frame is the end image.
Single continuous take, 15 seconds, 16:9 isometric diorama.

[0-5s]   Hold on RWD ingredients island left. River flows between islands.
[5-10s]  Slow left-to-right pan begins at constant speed across the landscape.
[10-15s] Pan completes revealing RWE dish island right. Settle into closing frame.

Camera: one move only — slow pan left-to-right, locked horizon, no zoom.
Ambient: tiny figures stable between islands, river flows gently.
Constraints: smooth motion, stable framing, no jitter, no warping, UI cards stay fixed and readable, no text morphing, single continuous take.' \
      rwe-explainer/frames/scene01-end.png \
      rwe-explainer/frames/scene02-end.png

    run_video scene03.mp4 \
    'Opening frame is the start image. Closing frame is the end image.
Single continuous take, 15 seconds, 16:9 isometric diorama.

[0-5s]   Camera holds at current height. First data-source mound visible.
[5-10s]  Slow smooth crane-up begins with gentle forward drift at constant speed.
[10-15s] All five source islands revealed in arc. Icons and label cards settle. Land on closing frame.

Camera: one move only — slow crane-up with gentle forward drift, locked horizon.
Ambient: icons ease into place with subtle pop, tiny figures walk between mounds, river flows.
Constraints: smooth motion, stable framing, no jitter, no warping, UI cards stay fixed and readable, no text morphing, no hard cuts, single continuous take.' \
      rwe-explainer/frames/scene02-end.png \
      rwe-explainer/frames/scene03-end.png
    ;;
  browser)
    echo "=== Step 2: Seedance via browser (Chrome DevTools MCP) ==="
    echo "See rwe-explainer/BROWSER-SEEDANCE.md"
    echo "1. bash .cursor/scripts/start-chrome-debug.sh"
    echo "2. Agent creates 3 clips in Higgsfield UI (Enhanced Seedance 2.0 Fast UNLIMITED)"
    echo "3. bash rwe-explainer/harvest-videos.sh"
    echo "4. bash rwe-explainer/run-plan-stitch.sh"
    exit 0
    ;;
  skip)
    echo "=== Step 2: Skipped (--videos skip) ==="
    ;;
  stitch-only)
    echo "=== Step 2: Skipped (stitch-only) ==="
    ;;
  *)
    echo "Unknown --videos mode: $VIDEOS_MODE" >&2
    exit 1
    ;;
esac

if [ "$VIDEOS_MODE" != "browser" ]; then
  echo "=== Step 3: Stitch clips ==="
  bash "$ROOT/rwe-explainer/run-plan-stitch.sh"
fi
