#!/usr/bin/env bash
# Idempotent Cloud Agent bootstrap: Higgsfield CLI, media tooling, and auth wiring.
set -euo pipefail

LOCAL_BIN="${HOME}/.local/bin"
export PATH="${LOCAL_BIN}:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

log() {
  printf '→ %s\n' "$1"
}

install_apt_packages() {
  local packages=("$@")
  local missing=()

  for pkg in "${packages[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      missing+=("$pkg")
    fi
  done

  if [ "${#missing[@]}" -eq 0 ]; then
    return 0
  fi

  log "Installing apt packages: ${missing[*]}"
  if command -v sudo >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${missing[@]}"
  else
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${missing[@]}"
  fi
}

install_higgsfield_cli() {
  if command -v higgsfield >/dev/null 2>&1; then
    log "higgsfield CLI already installed: $(higgsfield version 2>&1 | head -1)"
    return 0
  fi

  log "Installing higgsfield CLI to ${LOCAL_BIN}"
  mkdir -p "${LOCAL_BIN}"
  curl -fsSL https://raw.githubusercontent.com/higgsfield-ai/cli/main/install.sh \
    | sh -s -- --prefix="${HOME}/.local" --no-hf
}

wire_higgsfield_credentials() {
  local creds_dir="${HOME}/.config/higgsfield"
  local creds_file="${creds_dir}/credentials.json"

  mkdir -p "${creds_dir}"

  if [ -n "${HIGGSFIELD_CREDENTIALS_JSON:-}" ]; then
    log "Writing Higgsfield credentials from HIGGSFIELD_CREDENTIALS_JSON secret"
    printf '%s' "${HIGGSFIELD_CREDENTIALS_JSON}" > "${creds_file}"
    chmod 600 "${creds_file}"
  elif [ -n "${higgsfield_access_token:-}" ] && [ -n "${higgsfield_refresh_token:-}" ]; then
    log "Writing Higgsfield credentials from higgsfield_access_token + higgsfield_refresh_token secrets"
    jq -n \
      --arg access_token "${higgsfield_access_token}" \
      --arg refresh_token "${higgsfield_refresh_token}" \
      '{access_token: $access_token, refresh_token: $refresh_token}' > "${creds_file}"
    chmod 600 "${creds_file}"
  elif [ -n "${HIGGSFIELD_CREDENTIALS_PATH:-}" ] && [ -f "${HIGGSFIELD_CREDENTIALS_PATH}" ]; then
    log "Using credentials at HIGGSFIELD_CREDENTIALS_PATH=${HIGGSFIELD_CREDENTIALS_PATH}"
    creds_file="${HIGGSFIELD_CREDENTIALS_PATH}"
  fi

  if [ -f "${creds_file}" ]; then
    export HIGGSFIELD_CREDENTIALS_PATH="${creds_file}"
    grep -q 'HIGGSFIELD_CREDENTIALS_PATH=' "${HOME}/.bashrc" 2>/dev/null \
      || printf '\nexport HIGGSFIELD_CREDENTIALS_PATH="%s"\n' "${creds_file}" >> "${HOME}/.bashrc"
  fi
}

ensure_path_persisted() {
  grep -q '${HOME}/.local/bin' "${HOME}/.bashrc" 2>/dev/null \
    || printf '\nexport PATH="${HOME}/.local/bin:/usr/local/bin:/usr/bin:/bin:${PATH}"\n' >> "${HOME}/.bashrc"
}

verify_higgsfield() {
  if ! command -v higgsfield >/dev/null 2>&1; then
    echo "higgsfield CLI is missing from PATH after install." >&2
    exit 1
  fi

  log "higgsfield version: $(higgsfield version 2>&1 | head -1)"

  if higgsfield account status >/dev/null 2>&1; then
    log "higgsfield auth: $(higgsfield account status 2>&1 | head -1)"
  else
    echo "higgsfield CLI is installed but not authenticated." >&2
    echo "Add higgsfield_access_token and higgsfield_refresh_token to Cursor Cloud Agent secrets." >&2
    echo "See AGENTS.md → Cursor Cloud specific instructions." >&2
  fi
}

install_apt_packages curl jq ffmpeg
install_higgsfield_cli
wire_higgsfield_credentials
ensure_path_persisted
verify_higgsfield

log "Cloud dependencies ready."
