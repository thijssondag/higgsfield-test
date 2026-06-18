# Agent instructions

This repository is a Higgsfield AI skills workspace for image and video generation via the `higgsfield` CLI.

## Skills

Higgsfield skills live in `.agents/skills/`:

- `higgsfield-generate` — images, videos, 3D, audio, Marketing Studio, Virality Predictor
- `higgsfield-soul-id` — train face-faithful Soul Characters
- `higgsfield-product-photoshoot` — brand product imagery with prompt enhancement
- `higgsfield-marketplace-cards` — marketplace listing image sets

Read the relevant `SKILL.md` before running generation commands.

## Local development

```bash
# Install CLI (if missing)
curl -fsSL https://raw.githubusercontent.com/higgsfield-ai/cli/main/install.sh | sh

# Authenticate (interactive browser login)
higgsfield auth login

# Verify
higgsfield account status
```

## Cursor Cloud specific instructions

Cloud agents use `.cursor/environment.json`. On startup, the `install` script runs `.cursor/scripts/install-cloud-deps.sh`, which:

1. Installs `jq` and `ffmpeg` (needed by skills and video stitching)
2. Installs the `higgsfield` CLI to `~/.local/bin`
3. Wires credentials from Cursor secrets
4. Verifies the CLI is on `PATH`

### Required: Higgsfield authentication secret

Cloud agents cannot run interactive `higgsfield auth login`. Provide credentials via Cursor Cloud Agent secrets.

**One-time setup on your local machine:**

```bash
higgsfield auth login
higgsfield account status   # confirm authenticated
cat ~/.config/higgsfield/credentials.json
```

**In Cursor → Dashboard → Cloud Agents → Secrets**, add:

| Secret name | Value |
|---|---|
| `HIGGSFIELD_CREDENTIALS_JSON` | Full contents of `~/.config/higgsfield/credentials.json` |

The install script writes this to `~/.config/higgsfield/credentials.json` and sets `HIGGSFIELD_CREDENTIALS_PATH`. Credentials are persisted across cloud sessions via `persistedDirectories` in `environment.json`.

### Verify cloud setup

After secrets are configured, start a cloud agent and ask it to run:

```bash
higgsfield account status
higgsfield model list --json | jq 'length'
```

For a smoke test generation:

```bash
higgsfield generate create z_image --prompt "minimal test gradient" --wait
```

### Generation defaults

Follow the higgsfield-generate skill:

- Images: `gpt_image_2` (default), `nano_banana_2` for character/stylized work
- Video: `seedance_2_0` with `--start-image` / `--end-image` for transitions
- Always pass `--wait` so jobs block until a result URL is printed

### Video workflows

When stitching clips (e.g. RWE explainer plan in `.cursor/plans/`), use `ffmpeg` after generating individual Seedance clips. Review seams at reduced playback speed before final export.

### Auth errors in cloud

| Error | Fix |
|---|---|
| `Not authenticated` | Add or refresh `HIGGSFIELD_CREDENTIALS_JSON` secret |
| `Session expired` | Re-run `higgsfield auth login` locally, copy fresh `credentials.json` to secrets |
| `higgsfield: command not found` | Re-run environment install; check `~/.local/bin` is on `PATH` |
