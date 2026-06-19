# Browser Seedance workflow (Chrome DevTools MCP)

Use the **Enhanced Seedance 2.0 Fast / UNLIMITED** tier in the Higgsfield web UI instead of CLI `seedance_2_0` (CLI still bills ~52.5 credits per 15s clip even with `--mode fast`).

The agent automates the UI via **Chrome DevTools MCP** (`navigate_page`, `click`, `fill`, `upload_file`, `take_screenshot`). After each clip completes, download with the CLI (same account — no re-generation):

```bash
bash rwe-explainer/harvest-videos.sh
bash rwe-explainer/run-plan-stitch.sh
```

## One-time setup

1. Merge `.cursor/mcp.json` and **restart the cloud agent** so MCP loads.
2. Desktop pane:
   ```bash
   bash .cursor/scripts/start-chrome-debug.sh
   ```
3. Log into [higgsfield.ai](https://higgsfield.ai) in that Chrome window.
4. Confirm **Enhanced Seedance 2.0 Fast** shows **UNLIMITED** in the model picker.

Profile persists at `~/.config/chrome-higgsfield-profile`.

## Agent checklist (per clip)

1. Snapshot the page — confirm logged in.
2. Open video generation → **Enhanced Seedance 2.0 Fast** (start + end frame mode).
3. Settings: **15s**, **16:9**, **720p**.
4. `upload_file` start frame, then end frame (absolute paths below).
5. Paste the **motion-only** prompt (not frame descriptions).
6. Click Generate; wait until the job shows completed (poll UI or `higgsfield generate list --video`).
7. After all 3 clips: `bash rwe-explainer/harvest-videos.sh` then `bash rwe-explainer/run-plan-stitch.sh`.
8. Verify credits: `higgsfield account transactions --size 10` — browser UNLIMITED jobs should not show Seedance spend lines.

## Scene 1 (0:00–0:15)

| | Path |
|---|---|
| Start | `/workspace/rwe-explainer/frames/scene01-start.png` |
| End | `/workspace/rwe-explainer/frames/scene01-end.png` |

**Motion prompt:**

```
Opening frame is the start image. Closing frame is the end image.
Single continuous take, 15 seconds, 16:9 isometric diorama.

[0-5s]   Wide establishing hold. Blue river flows gently. Title card stable center-left.
[5-10s]  Slow smooth dolly-in along the river path begins. Camera glides forward at constant speed.
[10-15s] Camera descends slightly toward the green definition hill. Settle into closing frame.

Camera: one move only — slow dolly-in along river, locked horizon, no orbit.
Ambient: tiny figures walk along bank, grass sways subtly, river flows.
Constraints: smooth motion, stable framing, no jitter, no warping, UI cards stay fixed and readable, no text morphing, single continuous take.
```

## Scene 2 (0:15–0:30)

| | Path |
|---|---|
| Start | `/workspace/rwe-explainer/frames/scene01-end.png` |
| End | `/workspace/rwe-explainer/frames/scene02-end.png` |

**Motion prompt:**

```
Opening frame is the start image. Closing frame is the end image.
Single continuous take, 15 seconds, 16:9 isometric diorama.

[0-5s]   Hold on RWD ingredients island left. River flows between islands.
[5-10s]  Slow left-to-right pan begins at constant speed across the landscape.
[10-15s] Pan completes revealing RWE dish island right. Settle into closing frame.

Camera: one move only — slow pan left-to-right, locked horizon, no zoom.
Ambient: tiny figures stable between islands, river flows gently.
Constraints: smooth motion, stable framing, no jitter, no warping, UI cards stay fixed and readable, no text morphing, single continuous take.
```

## Scene 3 (0:30–0:45)

| | Path |
|---|---|
| Start | `/workspace/rwe-explainer/frames/scene02-end.png` |
| End | `/workspace/rwe-explainer/frames/scene03-end.png` |

**Motion prompt:**

```
Opening frame is the start image. Closing frame is the end image.
Single continuous take, 15 seconds, 16:9 isometric diorama.

[0-5s]   Camera holds at current height. First data-source mound visible.
[5-10s]  Slow smooth crane-up begins with gentle forward drift at constant speed.
[10-15s] All five source islands revealed in arc. Icons and label cards settle. Land on closing frame.

Camera: one move only — slow crane-up with gentle forward drift, locked horizon.
Ambient: icons ease into place with subtle pop, tiny figures walk between mounds, river flows.
Constraints: smooth motion, stable framing, no jitter, no warping, UI cards stay fixed and readable, no text morphing, no hard cuts, single continuous take.
```

## Troubleshooting

| Issue | Fix |
|---|---|
| MCP tools missing | Restart agent after adding `.cursor/mcp.json` |
| Cannot attach to Chrome | Run `start-chrome-debug.sh`; only one instance on port 9222 |
| `harvest-videos.sh` finds &lt; 3 jobs | Finish browser generations; check same account with `higgsfield account status` |
| NSFW false positive | Retry the clip in the browser |
