#!/usr/bin/env bash
# ================================================================
#  dc.sh — Docker Compose Orchestrator
#  Reads .env feature flags → auto-selects profiles → runs compose
#
#  Usage:
#    ./dc.sh up -d --build        # start stack
#    ./dc.sh down                 # stop stack
#    ./dc.sh logs -f              # follow logs
#    ./dc.sh ps                   # show status
#    ./dc.sh config               # validate merged config
#    ./dc.sh <any compose command>
# ================================================================
set -euo pipefail

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

expand_env_refs() {
  local value="$1"
  local ref replacement
  while [[ "$value" =~ \$\{([A-Za-z_][A-Za-z0-9_]*)\} ]]; do
    ref="${BASH_REMATCH[1]}"
    replacement="${!ref-}"
    value="${value//\$\{$ref\}/$replacement}"
  done
  printf '%s' "$value"
}

load_env_file() {
  local env_file="${1:-.env}"
  local line key value

  [ -f "$env_file" ] || return 0

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    [ -z "$(trim "$line")" ] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" != *=* ]] && continue

    key="$(trim "${line%%=*}")"
    value="$(trim "${line#*=}")"

    if [ "${#value}" -ge 2 ]; then
      if [[ "$value" == \"*\" && "$value" == *\" ]]; then
        value="${value:1:${#value}-2}"
      elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
        value="${value:1:${#value}-2}"
      fi
    fi

    # Backward-compatible with legacy .env entries that escaped "$" as "$$".
    value="${value//\$\$/\$}"
    value="$(expand_env_refs "$value")"
    export "$key=$value"
  done < "$env_file"
}

# ── Load .env ─────────────────────────────────────────────────────
if [ -f .env ]; then
  load_env_file .env
else
  echo "⚠️  .env not found — using defaults. Run: cp .env.example .env" >&2
fi

# ── Detect OS (uname-based, not RUNNER_OS) ─────────────────────
UNAME_S="$(uname -s)"
UNAME_R="$(uname -r)"

if echo "$UNAME_R" | grep -qi "microsoft\|wsl"; then
  _OS="windows"
elif [ "$UNAME_S" = "Darwin" ]; then
  _OS="macos"
else
  _OS="${CUR_OS:-linux}"
fi

# ── Build --profile arguments from ENABLE_* flags ──────────────
PROFILE_ARGS=()

if [ "${ENABLE_DOZZLE:-true}" = "true" ]; then
  PROFILE_ARGS+=(--profile dozzle)
fi

if [ "${ENABLE_FILEBROWSER:-true}" = "true" ]; then
  PROFILE_ARGS+=(--profile filebrowser)
fi

if [ "${ENABLE_WEBSSH:-true}" = "true" ]; then
  if [ "$_OS" = "windows" ]; then
    PROFILE_ARGS+=(--profile webssh-windows)
  else
    PROFILE_ARGS+=(--profile webssh-linux)
  fi
fi

if [ "${ENABLE_TAILSCALE:-false}" = "true" ]; then
  if [ "$_OS" = "windows" ]; then
    PROFILE_ARGS+=(--profile tailscale-windows)
  else
    PROFILE_ARGS+=(--profile tailscale-linux)
  fi
fi

# ── Compose file list ──────────────────────────────────────────
FILES=(
  -f compose.core.yml
  -f compose.ops.yml
  -f compose.access.yml
  -f compose.apps.yml
)

# ── Debug info (set DC_VERBOSE=1 to show) ─────────────────────
if [ "${DC_VERBOSE:-0}" = "1" ]; then
  echo "── dc.sh debug ──────────────────────────────────"
  echo "  OS        : $_OS"
  echo "  STACK_NAME: ${STACK_NAME:-mystack}"
  echo "  PROJECT   : ${PROJECT_NAME:-?}"
  echo "  DOMAIN    : ${DOMAIN:-?}"
  echo "  PROFILES  : ${PROFILE_ARGS[*]:-<none>}"
  echo "  FILES     : ${FILES[*]}"
  echo "─────────────────────────────────────────────────"
fi

# ── Execute ───────────────────────────────────────────────────
exec docker compose \
  "${FILES[@]}" \
  --project-name "${STACK_NAME:-mystack}" \
  "${PROFILE_ARGS[@]}" \
  "$@"
