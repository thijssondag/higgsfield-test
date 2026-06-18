#!/usr/bin/env bash
# Execute the RWE explainer video plan (first 45s).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export PATH="${HOME}/.local/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

# Wire credentials from Cursor secrets if present.
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
  local url
  url="$(higgsfield generate create seedance_2_0 \
    --prompt "$prompt" \
    --start-image "$start" \
    --end-image "$end" \
    --duration 15 \
    --aspect_ratio 16:9 \
    --resolution 720p \
    --wait)"
  download_result "$url" "rwe-explainer/videos/$out"
}

echo "=== Step 1: Generate frames ==="

run_image scene01-start.png '16:9 isometric 3D diorama miniature landscape. Warm pink terracotta sandy ground, sage green grass tufts, winding light blue river. Center-left: large floating white UI card reading "What is Real World Evidence?" in bold Inter-style sans-serif, dark charcoal text. Tiny simplified 3D people walking along the river bank. Soft diffused daylight, tilt-shift depth of field, airy negative space, clean SaaS healthcare explainer aesthetic. Verbatim headline text — no extra characters, no substitutions.'

run_image scene01-end.png 'Same isometric diorama world as reference: pink ground, green grass hill, blue river. Camera closer to a green mound. Floating white card reads "RWE = clinical insight from data outside randomised controlled trials" in Inter-style sans-serif, dark charcoal, two lines max. One tiny 3D figure on the hill pointing at the card. Identical lighting, palette, and isometric angle as start frame. Verbatim text — no extra characters.'

run_image scene02-end.png 'Isometric 3D diorama, same pink terrain and lighting. Split composition: LEFT green island labeled "RWD" with raw ingredient cylinders, sand piles, binary data blocks — floating card "The ingredient". RIGHT green island labeled "RWE" with a white plate holding a miniature finished landscape — floating card "The dish". Center blue river connects both islands. Tiny 3D figures between islands. Inter-style sans-serif labels on white cards. Verbatim: "RWD" and "RWE" and "The ingredient" and "The dish". Clean SaaS explainer, soft daylight.'

run_image scene03-end.png 'Isometric 3D diorama, same world. Five sage-green grass mounds in an arc, each with a 3D icon and white floating label card in Inter-style sans-serif: "EHR", "Claims", "Registries", "Wearables", "Patient apps / ePRO". Icons: medical chart, receipt, clipboard, smartwatch, smartphone — as physical 3D objects on each mound. Blue river weaves between mounds. Header card top-center: "Five real-world data sources". Pink ground, soft daylight, identical palette and camera height as previous scenes. Verbatim text — no extra characters.'

cp -f rwe-explainer/frames/scene01-end.png rwe-explainer/frames/scene02-start.png
cp -f rwe-explainer/frames/scene02-end.png rwe-explainer/frames/scene03-start.png

echo "=== Step 2: Animate with Seedance 2.0 ==="

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

echo "=== Step 3: Stitch clips ==="

cat > /tmp/rwe-concat.txt <<EOF
file '$(pwd)/rwe-explainer/videos/scene01.mp4'
file '$(pwd)/rwe-explainer/videos/scene02.mp4'
file '$(pwd)/rwe-explainer/videos/scene03.mp4'
EOF

ffmpeg -y -f concat -safe 0 -i /tmp/rwe-concat.txt -c copy rwe-explainer/videos/rwe-first-45s.mp4

echo "Done: rwe-explainer/videos/rwe-first-45s.mp4"
