# mloop Comparison Benchmark

Use this to compare no-Superpowers, Superpowers, and mloop Codex runs on the same local tasks.

## Setup

```bash
bash scripts/setup-comparison-workspaces.sh --reset
```

This creates ignored local workspaces under:

```text
e2e-workspace/comparison/runs/plain-no-superpowers/
e2e-workspace/comparison/runs/plain-superpowers/
e2e-workspace/comparison/runs/mloop/
```

Projects:

- `todo-cli`: small Markdown todo counter.
- `csv-stats`: small CSV summary CLI.

Each project has three cases. Every case has:

- `case_prompt.md`: prompt to pass to Codex.
- `check.sh`: objective post-run check.
- project code and baseline tests.
- a local git baseline commit, so Codex sees only the test project diff.

## Run One Case

No Superpowers:

```bash
cd e2e-workspace/comparison/runs/plain-no-superpowers/todo-cli/01-summary
start="$(date +%s)"
codex exec --dangerously-bypass-approvals-and-sandbox "$(cat case_prompt.md)"
end="$(date +%s)"
bash check.sh
echo "elapsed=$((end-start))"
```

Superpowers:

```bash
cd e2e-workspace/comparison/runs/plain-superpowers/todo-cli/01-summary
start="$(date +%s)"
codex exec --dangerously-bypass-approvals-and-sandbox "$(cat case_prompt.md)"
end="$(date +%s)"
bash check.sh
echo "elapsed=$((end-start))"
```

mloop:

```bash
cd e2e-workspace/comparison/runs/mloop/todo-cli/01-summary
start="$(date +%s)"
codex exec --dangerously-bypass-approvals-and-sandbox "$(cat case_prompt.md)"
end="$(date +%s)"
bash check.sh
echo "elapsed=$((end-start))"
```

For token accounting, prefer JSONL output:

```bash
codex exec --json --dangerously-bypass-approvals-and-sandbox "$(cat case_prompt.md)" >codex-run.jsonl
python3 ../../../../../../scripts/summarize-codex-json-usage.py --csv-values codex-run.jsonl
```

Record results in:

```text
e2e-workspace/comparison/results/results.csv
```

## Metrics

- Efficiency: elapsed seconds and number of user interventions.
- Cost: `root_total_tokens`, `root_input_tokens`, `root_cached_input_tokens`, `root_output_tokens`, and `root_reasoning_output_tokens` for the Root Codex session. Provider-specific Generator/Evaluator tokens should be recorded separately when their gateways expose usage.
- Process: whether the run used the intended mode, and for mloop whether Generator/Evaluator, fresh verdict, spec, and plan artifacts exist.
- Target artifact quality: final user-visible behavior, code scope, tests, and docs. For user-facing errors, score message shape, relevant field/context, offending value or location when available, stdout/stderr placement, exit code, and absence of raw traceback.
- Quality evidence: `check.sh` result, tests added/updated, diff size, manual target-behavior probes, and for mloop the final `.loop3e/verdict.json`.

Use the same provider setup for both modes. Run each case from a fresh generated directory; do not reuse a directory after a failed run.
