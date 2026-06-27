#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$ROOT_DIR/e2e-workspace/comparison"
RESET=0

usage() {
  cat <<'USAGE'
Usage: scripts/setup-comparison-workspaces.sh [--root PATH] [--reset]

Creates local ignored benchmark workspaces for comparing no-Superpowers, Superpowers, and mloop runs.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      TARGET="${2:?missing value for --root}"
      shift 2
      ;;
    --reset)
      RESET=1
      shift
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

write_file() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  cat >"$path"
}

write_executable() {
  local path="$1"
  write_file "$path"
  chmod +x "$path"
}

init_run_git() {
  local run_dir="$1"
  (
    cd "$run_dir"
    git init -q
    git config user.email "loop3e-benchmark@example.invalid"
    git config user.name "Loop3E Benchmark"
    git add .
    git commit -q -m "baseline"
  )
}

if [[ "$RESET" -eq 1 ]]; then
  rm -rf "$TARGET"
fi

mkdir -p "$TARGET/baselines" "$TARGET/cases" "$TARGET/runs" "$TARGET/results"

write_file "$TARGET/README.md" <<'EOF'
# Loop3E Comparison Workspace

Purpose: compare no-Superpowers, Superpowers, and mloop Codex runs on the same tasks.

Run one directory at a time:

```bash
cd runs/plain-no-superpowers/todo-cli/01-summary
codex exec --dangerously-bypass-approvals-and-sandbox "$(cat case_prompt.md)"
bash check.sh
```

Use the matching `runs/plain-superpowers/...` or `runs/mloop/...` directory for
the other modes. For token accounting, run Codex with `--json` and summarize the
JSONL with `scripts/summarize-codex-json-usage.py` from the Loop3E repository.
Record metrics in `results/results.csv`.
EOF

if [[ ! -f "$TARGET/results/results.csv" ]]; then
  write_file "$TARGET/results/results.csv" <<'EOF'
project,case,mode,start,end,elapsed_seconds,codex_session_id,root_total_tokens,root_input_tokens,root_cached_input_tokens,root_output_tokens,root_reasoning_output_tokens,check_result,changed_files,notes
EOF
fi

create_todo_cli() {
  local dir="$TARGET/baselines/todo-cli"
  mkdir -p "$dir/tests"
  write_file "$dir/AGENTS.md" <<'EOF'
# Benchmark Project

Keep changes minimal. Add or update tests for behavior changes. Do not commit git changes.
EOF
  write_file "$dir/README.md" <<'EOF'
# todo-cli

Counts Markdown todo checkboxes.
EOF
  write_file "$dir/todo_count.py" <<'EOF'
from __future__ import annotations

import re
import sys
from pathlib import Path

TODO_RE = re.compile(r"^\s*-\s\[(?P<state>[ xX])\]")


def count_todos(text: str) -> tuple[int, int]:
    completed = 0
    remaining = 0
    for line in text.splitlines():
        match = TODO_RE.match(line)
        if not match:
            continue
        if match.group("state") in {"x", "X"}:
            completed += 1
        else:
            remaining += 1
    return completed, remaining


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    if len(args) != 1:
        print("usage: todo_count.py <todo-file>", file=sys.stderr)
        return 2
    completed, remaining = count_todos(Path(args[0]).read_text(encoding="utf-8"))
    print(f"completed={completed} remaining={remaining}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
EOF
  write_file "$dir/tests/test_todo_count.py" <<'EOF'
import subprocess
import sys
from pathlib import Path

from todo_count import count_todos


def test_count_todos_counts_markdown_checkboxes():
    assert count_todos("- [x] done\n- [X] also done\n- [ ] todo\n") == (2, 1)


def test_cli_default_output(tmp_path):
    todo_file = tmp_path / "todo.md"
    todo_file.write_text("- [x] done\n- [ ] todo\n", encoding="utf-8")

    result = subprocess.run(
        [sys.executable, str(Path(__file__).resolve().parents[1] / "todo_count.py"), str(todo_file)],
        text=True,
        capture_output=True,
        check=False,
    )

    assert result.returncode == 0
    assert result.stdout == "completed=1 remaining=1\n"
EOF
}

create_csv_stats() {
  local dir="$TARGET/baselines/csv-stats"
  mkdir -p "$dir/tests"
  write_file "$dir/AGENTS.md" <<'EOF'
# Benchmark Project

Keep changes minimal. Add or update tests for behavior changes. Do not commit git changes.
EOF
  write_file "$dir/README.md" <<'EOF'
# csv-stats

Prints basic totals for a CSV file with `amount` and `status` columns.
EOF
  write_file "$dir/csv_stats.py" <<'EOF'
from __future__ import annotations

import csv
import sys
from pathlib import Path


def summarize(text: str) -> tuple[int, float]:
    rows = list(csv.DictReader(text.splitlines()))
    total = sum(float(row["amount"]) for row in rows)
    return len(rows), total


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    if len(args) != 1:
        print("usage: csv_stats.py <csv-file>", file=sys.stderr)
        return 2
    rows, total = summarize(Path(args[0]).read_text(encoding="utf-8"))
    print(f"rows={rows} total={total:.2f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
EOF
  write_file "$dir/tests/test_csv_stats.py" <<'EOF'
import subprocess
import sys
from pathlib import Path

from csv_stats import summarize


def test_summarize_counts_rows_and_total():
    assert summarize("amount,status\n10.00,paid\n2.50,open\n") == (2, 12.5)


def test_cli_default_output(tmp_path):
    csv_file = tmp_path / "sales.csv"
    csv_file.write_text("amount,status\n10.00,paid\n2.50,open\n", encoding="utf-8")

    result = subprocess.run(
        [sys.executable, str(Path(__file__).resolve().parents[1] / "csv_stats.py"), str(csv_file)],
        text=True,
        capture_output=True,
        check=False,
    )

    assert result.returncode == 0
    assert result.stdout == "rows=2 total=12.50\n"
EOF
}

create_cases() {
  write_file "$TARGET/cases/todo-cli-01-summary.prompt.md" <<'EOF'
给 `todo_count.py` 加个 `--summary` 输出，一行里能看出完成、未完成、总数。原来的默认输出别坏，自己补测试并跑 pytest。不要提交 git。
EOF
  write_executable "$TARGET/cases/todo-cli-01-summary.check.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
python3 -m pytest tests/test_todo_count.py -q
sample="$(mktemp)"
trap 'rm -f "$sample"' EXIT
printf '%s\n' '- [x] done' '- [ ] todo' >"$sample"
test "$(python3 todo_count.py --summary "$sample")" = "completed=1 remaining=1 total=2"
test "$(python3 todo_count.py "$sample")" = "completed=1 remaining=1"
EOF

  write_file "$TARGET/cases/todo-cli-02-json.prompt.md" <<'EOF'
我想让 `todo_count.py` 支持 `--json`，方便脚本读取；默认文本输出继续保持现在这样。补测试并跑 pytest，不要提交 git。
EOF
  write_executable "$TARGET/cases/todo-cli-02-json.check.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
python3 -m pytest tests/test_todo_count.py -q
sample="$(mktemp)"
trap 'rm -f "$sample"' EXIT
printf '%s\n' '- [x] done' '- [ ] todo' >"$sample"
test "$(python3 todo_count.py --json "$sample")" = '{"completed":1,"remaining":1}'
test "$(python3 todo_count.py "$sample")" = "completed=1 remaining=1"
EOF

  write_file "$TARGET/cases/todo-cli-03-percent.prompt.md" <<'EOF'
给 `todo_count.py` 加一个百分比输出模式，能看到完成率；没有 todo 的文件也别崩。默认输出不能坏，补测试并跑 pytest，不要提交 git。
EOF
  write_executable "$TARGET/cases/todo-cli-03-percent.check.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
python3 -m pytest tests/test_todo_count.py -q
sample="$(mktemp)"
empty="$(mktemp)"
trap 'rm -f "$sample" "$empty"' EXIT
printf '%s\n' '- [x] done' '- [ ] todo' '- [ ] later' >"$sample"
printf '%s\n' 'notes only' >"$empty"
test "$(python3 todo_count.py --percent "$sample")" = "percent=33%"
test "$(python3 todo_count.py --percent "$empty")" = "percent=0%"
EOF

  write_file "$TARGET/cases/csv-stats-01-average.prompt.md" <<'EOF'
`csv_stats.py` 的输出里我还想看到平均金额，保留现有 rows/total 格式，追加 average 就行。补测试并跑 pytest，不要提交 git。
EOF
  write_executable "$TARGET/cases/csv-stats-01-average.check.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
python3 -m pytest tests/test_csv_stats.py -q
sample="$(mktemp)"
trap 'rm -f "$sample"' EXIT
printf '%s\n' 'amount,status' '10.00,paid' '2.50,open' >"$sample"
test "$(python3 csv_stats.py "$sample")" = "rows=2 total=12.50 average=6.25"
EOF

  write_file "$TARGET/cases/csv-stats-02-filter-status.prompt.md" <<'EOF'
给 `csv_stats.py` 加个按 status 过滤的能力，比如只看 paid。默认不带过滤时保持现在的总计。补测试并跑 pytest，不要提交 git。
EOF
  write_executable "$TARGET/cases/csv-stats-02-filter-status.check.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
python3 -m pytest tests/test_csv_stats.py -q
sample="$(mktemp)"
trap 'rm -f "$sample"' EXIT
printf '%s\n' 'amount,status' '10.00,paid' '2.50,open' '1.25,paid' >"$sample"
test "$(python3 csv_stats.py --status paid "$sample")" = "rows=2 total=11.25"
test "$(python3 csv_stats.py "$sample")" = "rows=3 total=13.75"
EOF

  write_file "$TARGET/cases/csv-stats-03-bad-amount.prompt.md" <<'EOF'
现在 CSV 里 amount 写错会直接炸 traceback。改成用户能看懂的错误，退出码用 2；正常文件行为别变。补测试并跑 pytest，不要提交 git。
EOF
  write_executable "$TARGET/cases/csv-stats-03-bad-amount.check.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
python3 -m pytest tests/test_csv_stats.py -q
bad="$(mktemp)"
trap 'rm -f "$bad"' EXIT
printf '%s\n' 'amount,status' 'oops,paid' >"$bad"
set +e
out="$(python3 csv_stats.py "$bad" 2>&1 >/tmp/csv-stats-bad.out)"
code=$?
set -e
test "$code" -eq 2
printf '%s' "$out" | grep -Fqi 'amount'
! printf '%s' "$out" | grep -Fq 'Traceback'
EOF

  write_file "$TARGET/cases/csv-stats-04-report.prompt.md" <<'EOF'
我想让 `csv_stats.py` 多一个 `--report` 模式，给运营同事直接看：
1. 输出第一行总览：`rows=<有效行数> total=<总金额> invalid=<坏金额行数>`。
2. 后面按 status 分组，每行 `status=<状态> rows=<数量> total=<金额>`，status 按字母排序。
3. `--status paid --report` 只统计 paid 这一组。
4. amount 写错不要 traceback，跳过那行并计入 invalid。
5. 默认不带 `--report` 的原输出保持不变。
补测试并跑 pytest，不要提交 git。
EOF
  write_executable "$TARGET/cases/csv-stats-04-report.check.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
python3 -m pytest tests/test_csv_stats.py -q
sample="$(mktemp)"
trap 'rm -f "$sample"' EXIT
printf '%s\n' 'amount,status' '10.00,paid' 'oops,paid' '2.50,open' '1.25,paid' >"$sample"
expected_all="$(printf '%s\n' \
  'rows=3 total=13.75 invalid=1' \
  'status=open rows=1 total=2.50' \
  'status=paid rows=2 total=11.25')"
test "$(python3 csv_stats.py --report "$sample")" = "$expected_all"
expected_paid="$(printf '%s\n' \
  'rows=2 total=11.25 invalid=1' \
  'status=paid rows=2 total=11.25')"
test "$(python3 csv_stats.py --status paid --report "$sample")" = "$expected_paid"
test "$(python3 csv_stats.py "$sample" 2>/dev/null)" = "rows=4 total=13.75"
EOF
}

copy_run() {
  local project="$1"
  local case_id="$2"
  local mode="$3"
  local prompt="$TARGET/cases/${project}-${case_id}.prompt.md"
  local check="$TARGET/cases/${project}-${case_id}.check.sh"
  local run_dir="$TARGET/runs/$mode/$project/$case_id"

  mkdir -p "$(dirname "$run_dir")"
  rm -rf "$run_dir"
  cp -R "$TARGET/baselines/$project" "$run_dir"
  cp "$prompt" "$run_dir/case_prompt.md"
  case "$mode" in
    plain-no-superpowers)
      sed -i.bak '1s/^/本次是 benchmark 的 no-Superpowers 组：不要调用或加载 Superpowers skills，不要使用 mloop；直接按项目 AGENTS.md 最小实现、补测试并验证。 /' "$run_dir/case_prompt.md"
      rm "$run_dir/case_prompt.md.bak"
      ;;
    plain-superpowers)
      sed -i.bak '1s/^/本次是 benchmark 的 Superpowers 组：使用适用的 Superpowers skills，但不要使用 mloop。 /' "$run_dir/case_prompt.md"
      rm "$run_dir/case_prompt.md.bak"
      ;;
    mloop)
      sed -i.bak '1s/^/$mloop 本次 benchmark 低风险最小设计已预先确认；如果没有业务取舍、破坏性迁移或外部权限问题，不要停在设计确认，继续走 spec\/plan\/Generator\/Evaluator 闭环。 /' "$run_dir/case_prompt.md"
      rm "$run_dir/case_prompt.md.bak"
      ;;
  esac
  cp "$check" "$run_dir/check.sh"
  init_run_git "$run_dir"
}

create_todo_cli
create_csv_stats
create_cases

for mode in plain-no-superpowers plain-superpowers mloop; do
  copy_run todo-cli 01-summary "$mode"
  copy_run todo-cli 02-json "$mode"
  copy_run todo-cli 03-percent "$mode"
  copy_run csv-stats 01-average "$mode"
  copy_run csv-stats 02-filter-status "$mode"
  copy_run csv-stats 03-bad-amount "$mode"
  copy_run csv-stats 04-report "$mode"
done

printf 'Created comparison workspace: %s\n' "$TARGET"
