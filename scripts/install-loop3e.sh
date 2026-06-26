#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
APPLY=0

usage() {
  cat <<'USAGE'
Usage: scripts/install-loop3e.sh [--dry-run] [--apply] [--codex-home PATH]

Installs Loop3E project assets into a Codex home.

Defaults:
  --dry-run                 Print actions without writing files.
  --codex-home ~/.codex     Override with CODEX_HOME or this flag.

This script does not change root-level model/model_provider defaults.
This script does not write model_providers; copy the README examples manually if needed.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      APPLY=0
      shift
      ;;
    --apply)
      APPLY=1
      shift
      ;;
    --codex-home)
      CODEX_HOME="${2:?missing value for --codex-home}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

log() {
  printf '%s\n' "$*"
}

run() {
  if [[ "$APPLY" -eq 1 ]]; then
    "$@"
  else
    log "dry-run: $*"
  fi
}

backup_if_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then
    local backup="${path}.bak.$(date +%Y%m%d%H%M%S)"
    run cp -R "$path" "$backup"
  fi
}

install_file() {
  local src="$1"
  local dst="$2"
  run mkdir -p "$(dirname "$dst")"
  backup_if_exists "$dst"
  run cp "$src" "$dst"
}

install_dir() {
  local src="$1"
  local dst="$2"
  run mkdir -p "$(dirname "$dst")"
  backup_if_exists "$dst"
  if [[ "$APPLY" -eq 1 ]]; then
    rm -rf "$dst"
  else
    log "dry-run: rm -rf $dst"
  fi
  run cp -R "$src" "$dst"
}

install_file "$ROOT_DIR/codex/agents/loop_generator.toml" "$CODEX_HOME/agents/loop_generator.toml"
install_file "$ROOT_DIR/codex/agents/loop_evaluator.toml" "$CODEX_HOME/agents/loop_evaluator.toml"
install_dir "$ROOT_DIR/codex/skills/mloop" "$CODEX_HOME/skills/mloop"

log "Loop3E install target: $CODEX_HOME"
log "Configure model_providers manually from README before provider smoke tests."
