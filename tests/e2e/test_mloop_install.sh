#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIXTURE="$ROOT_DIR/tests/fixtures/sample-project"
INSTALLER="$ROOT_DIR/scripts/install-loop3e.sh"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

CODEX_HOME="$TMP_ROOT/codex-home"
WORKSPACE="$TMP_ROOT/workspace"
PROJECT="$WORKSPACE/sample-project"

assert_file() {
  test -f "$1" || {
    echo "missing file: $1" >&2
    exit 1
  }
}

assert_absent() {
  test ! -e "$1" || {
    echo "unexpected path exists: $1" >&2
    exit 1
  }
}

snapshot() {
  (cd "$1" && find . -type f -maxdepth 5 -print | sort | xargs shasum)
}

assert_file "$FIXTURE/AGENTS.md"
assert_file "$FIXTURE/README.md"

mkdir -p "$WORKSPACE"
cp -R "$FIXTURE" "$PROJECT"
BEFORE="$(snapshot "$PROJECT")"

"$INSTALLER" --apply --codex-home "$CODEX_HOME" >/tmp/loop3e-e2e-install.out
AFTER="$(snapshot "$PROJECT")"

test "$BEFORE" = "$AFTER"

assert_file "$CODEX_HOME/agents/loop_generator.toml"
assert_file "$CODEX_HOME/agents/loop_evaluator.toml"
assert_file "$CODEX_HOME/skills/mloop/SKILL.md"
assert_absent "$CODEX_HOME/agents/loop_planner.toml"
assert_absent "$CODEX_HOME/config.toml"
assert_absent "$CODEX_HOME/AGENTS.md"
assert_absent "$PROJECT/.loop3e"
assert_absent "$PROJECT/docs/superpowers/specs"
assert_absent "$PROJECT/docs/superpowers/plans"
