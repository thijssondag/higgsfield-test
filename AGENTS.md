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

### Required: Higgsfield authentication secrets

Cloud agents cannot run interactive `higgsfield auth login` from the agent shell. Provide credentials via Cursor Cloud Agent secrets, or log in once via the Desktop pane (see "Credential persistence" below).

#### Credential persistence

`~/.config/higgsfield` is a `persistedDirectory` (see `.cursor/environment.json`), so `credentials.json` survives across cloud sessions. The CLI rotates the refresh token on each use and writes the new value back to that file, so the bootstrap script **does not overwrite an already-valid `credentials.json`** — it only writes from the secret tokens when no working credentials exist (the secrets are a bootstrap/fallback). This means a one-time Desktop-pane `higgsfield auth login` persists without needing to re-update the secrets. Note: if the VM sits idle past the refresh-token lifetime, auth can still expire and a fresh login (or updated secrets) is required.

**Recommended — separate token secrets (matches Cursor Secrets UI):**

| Secret name | Value |
|---|---|
| `higgsfield_access_token` | Access token from `higgsfield auth token` or `credentials.json` |
| `higgsfield_refresh_token` | Refresh token from `credentials.json` |

The install script writes these into `~/.config/higgsfield/credentials.json` as:

```json
{
  "access_token": "<higgsfield_access_token>",
  "refresh_token": "<higgsfield_refresh_token>"
}
```

**Alternative — full credentials JSON:**

| Secret name | Value |
|---|---|
| `HIGGSFIELD_CREDENTIALS_JSON` | Full contents of `~/.config/higgsfield/credentials.json` |

**One-time setup on your local machine:**

```bash
higgsfield auth login
higgsfield account status   # confirm authenticated
higgsfield auth token       # access token
cat ~/.config/higgsfield/credentials.json   # includes refresh_token
```

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
| `Not authenticated` | Add `higgsfield_access_token` + `higgsfield_refresh_token` secrets |
| `Session expired` | Refresh tokens locally and update both secrets |
| `higgsfield: command not found` | Re-run environment install; check `~/.local/bin` is on `PATH` |
