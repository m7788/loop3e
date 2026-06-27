#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/setup-comparison-workspaces.sh"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

"$SCRIPT" --root "$TMP_ROOT/comparison" --reset >/tmp/loop3e-comparison-setup.out

test -f "$TMP_ROOT/comparison/runs/plain-no-superpowers/todo-cli/01-summary/todo_count.py"
test -f "$TMP_ROOT/comparison/runs/plain-superpowers/todo-cli/01-summary/todo_count.py"
test -f "$TMP_ROOT/comparison/runs/mloop/todo-cli/01-summary/todo_count.py"
test -f "$TMP_ROOT/comparison/runs/plain-no-superpowers/csv-stats/03-bad-amount/csv_stats.py"
test -f "$TMP_ROOT/comparison/runs/plain-superpowers/csv-stats/03-bad-amount/csv_stats.py"
test -f "$TMP_ROOT/comparison/runs/mloop/csv-stats/03-bad-amount/csv_stats.py"
test -f "$TMP_ROOT/comparison/runs/plain-no-superpowers/csv-stats/04-report/csv_stats.py"
test -f "$TMP_ROOT/comparison/runs/plain-superpowers/csv-stats/04-report/csv_stats.py"
test -f "$TMP_ROOT/comparison/runs/mloop/csv-stats/04-report/csv_stats.py"

test -d "$TMP_ROOT/comparison/runs/mloop/csv-stats/03-bad-amount/.git"
(cd "$TMP_ROOT/comparison/runs/mloop/csv-stats/03-bad-amount" && test -z "$(git status --short)")

grep -Fq 'root_total_tokens,root_input_tokens,root_cached_input_tokens,root_output_tokens,root_reasoning_output_tokens' "$TMP_ROOT/comparison/results/results.csv"
grep -Fq '$mloop 本次 benchmark' "$TMP_ROOT/comparison/runs/mloop/todo-cli/01-summary/case_prompt.md"
grep -Fq '给 `todo_count.py`' "$TMP_ROOT/comparison/runs/mloop/todo-cli/01-summary/case_prompt.md"
grep -Fq '低风险最小设计已预先确认' "$TMP_ROOT/comparison/runs/mloop/todo-cli/01-summary/case_prompt.md"
grep -Fq 'no-Superpowers 组' "$TMP_ROOT/comparison/runs/plain-no-superpowers/todo-cli/01-summary/case_prompt.md"
grep -Fq 'Superpowers 组' "$TMP_ROOT/comparison/runs/plain-superpowers/todo-cli/01-summary/case_prompt.md"
grep -Fq -- '--report' "$TMP_ROOT/comparison/runs/mloop/csv-stats/04-report/case_prompt.md"

(cd "$TMP_ROOT/comparison/runs/plain-no-superpowers/todo-cli/01-summary" && python3 -m pytest tests/test_todo_count.py -q >/tmp/loop3e-comparison-todo-pytest.out)
(cd "$TMP_ROOT/comparison/runs/plain-no-superpowers/csv-stats/01-average" && python3 -m pytest tests/test_csv_stats.py -q >/tmp/loop3e-comparison-csv-pytest.out)
(cd "$TMP_ROOT/comparison/runs/plain-no-superpowers/csv-stats/04-report" && python3 -m pytest tests/test_csv_stats.py -q >/tmp/loop3e-comparison-csv-report-pytest.out)
