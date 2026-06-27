#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$ROOT_DIR/scripts/install-loop3e.sh"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

assert_file() {
  test -f "$1" || {
    echo "missing file: $1" >&2
    exit 1
  }
}

assert_contains() {
  local file="$1"
  local text="$2"
  grep -Fq "$text" "$file" || {
    echo "expected '$text' in $file" >&2
    exit 1
  }
}

assert_file "$ROOT_DIR/codex/agents/loop_generator.toml"
assert_file "$ROOT_DIR/codex/agents/loop_evaluator.toml"
assert_file "$ROOT_DIR/codex/skills/mloop/SKILL.md"
test ! -e "$ROOT_DIR/codex/agents/loop_planner.toml"
test ! -e "$ROOT_DIR/agents"
test ! -e "$ROOT_DIR/skills"

"$INSTALLER" --dry-run --codex-home "$TMP_HOME" >/tmp/loop3e-dry-run.out
test ! -e "$TMP_HOME/config.toml"
test ! -e "$TMP_HOME/agents"
test ! -e "$TMP_HOME/skills"

"$INSTALLER" --apply --codex-home "$TMP_HOME" >/tmp/loop3e-apply.out

test ! -e "$TMP_HOME/config.toml"
assert_file "$TMP_HOME/agents/loop_generator.toml"
assert_file "$TMP_HOME/agents/loop_evaluator.toml"
assert_file "$TMP_HOME/skills/mloop/SKILL.md"
test ! -e "$TMP_HOME/agents/loop_planner.toml"

assert_contains "$TMP_HOME/skills/mloop/SKILL.md" "name: mloop"
assert_contains "$TMP_HOME/agents/loop_generator.toml" 'model_provider = "loop3e_generator"'
assert_contains "$TMP_HOME/agents/loop_evaluator.toml" 'model_provider = "loop3e_evaluator"'
assert_contains "$TMP_HOME/agents/loop_generator.toml" 'model = "MiniMax-M3"'
assert_contains "$TMP_HOME/agents/loop_evaluator.toml" 'model = "deepseek-v4-pro"'
assert_contains "$TMP_HOME/agents/loop_generator.toml" 'model_reasoning_effort = "medium"'
assert_contains "$TMP_HOME/agents/loop_evaluator.toml" 'model_reasoning_effort = "high"'

mkdir -p "$TMP_HOME/skills/mloop.bak.20000101000000"
cp "$TMP_HOME/skills/mloop/SKILL.md" "$TMP_HOME/skills/mloop.bak.20000101000000/SKILL.md"

"$INSTALLER" --apply --codex-home "$TMP_HOME" >/tmp/loop3e-apply-again.out
test ! -e "$TMP_HOME/config.toml"
test ! -e "$TMP_HOME/skills/mloop.bak.20000101000000"
find "$TMP_HOME/backups/loop3e" -path '*/skills/mloop.bak.20000101000000/SKILL.md' | grep -q .
