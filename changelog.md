# Changelog

## 2026-06-18 — Cursor Cloud + Higgsfield CLI setup

**Author:** Cursor Cloud Agent

### Added

- `.cursor/environment.json` — Cloud Agent environment config with install hook and persisted credentials directory
- `.cursor/scripts/install-cloud-deps.sh` — Idempotent bootstrap for `higgsfield` CLI, `jq`, `ffmpeg`, and auth wiring from `HIGGSFIELD_CREDENTIALS_JSON`
- `AGENTS.md` — Agent and cloud-specific setup instructions, including secret configuration
- `.env.example` — Documents required Cursor Cloud secrets for Higgsfield authentication

### Why

Cloud agents need the Higgsfield CLI pre-installed and authenticated to run image/video generation skills in this repo. Interactive `higgsfield auth login` is not available in cloud VMs, so credentials are injected via Cursor secrets.
