# Changelog

## 2026-06-18 — Persist rotated Higgsfield credentials

**Author:** Cursor Cloud Agent

### Changed

- `.cursor/scripts/install-cloud-deps.sh` — `wire_higgsfield_credentials` now preserves an existing, still-valid `credentials.json` instead of unconditionally overwriting it from the static secret tokens. The CLI rotates the refresh token on use; clobbering it with the original secret reverted to a stale token and caused `Session expired`. Secret tokens now act only as a bootstrap/fallback when no working credentials exist.
- `AGENTS.md` — documented credential persistence behavior and the one-time Desktop-pane login path.

### Why

After an interactive login the rotated refresh token is persisted in `~/.config/higgsfield` (a persisted directory), but the startup script was overwriting it from the original secrets on every boot, breaking auth. Preserving valid credentials makes a one-time login durable across cloud sessions.

## 2026-06-18 — Cursor Cloud + Higgsfield CLI setup

**Author:** Cursor Cloud Agent

### Added

- `.cursor/environment.json` — Cloud Agent environment config with install hook and persisted credentials directory
- `.cursor/scripts/install-cloud-deps.sh` — Idempotent bootstrap for `higgsfield` CLI, `jq`, `ffmpeg`, and auth wiring from `HIGGSFIELD_CREDENTIALS_JSON`
- `AGENTS.md` — Agent and cloud-specific setup instructions, including secret configuration
- `.env.example` — Documents required Cursor Cloud secrets for Higgsfield authentication

### Why

Cloud agents need the Higgsfield CLI pre-installed and authenticated to run image/video generation skills in this repo. Interactive `higgsfield auth login` is not available in cloud VMs, so credentials are injected via Cursor secrets (`higgsfield_access_token` + `higgsfield_refresh_token`, or full `HIGGSFIELD_CREDENTIALS_JSON`).

## 2026-06-18 — Token secret support

**Author:** Cursor Cloud Agent

### Changed

- `.cursor/scripts/install-cloud-deps.sh` — builds `credentials.json` from `higgsfield_access_token` and `higgsfield_refresh_token` secrets
- `AGENTS.md`, `.env.example` — document separate token secret names matching Cursor Secrets UI
