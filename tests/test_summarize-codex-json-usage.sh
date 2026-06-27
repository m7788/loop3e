#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAMPLE="$(mktemp)"
trap 'rm -f "$SAMPLE"' EXIT

cat >"$SAMPLE" <<'EOF'
{"type":"thread.started","thread_id":"019f"}
{"type":"turn.completed","usage":{"input_tokens":100,"cached_input_tokens":40,"output_tokens":7,"reasoning_output_tokens":2}}
{"type":"turn.completed","usage":{"input_tokens":10,"cached_input_tokens":5,"output_tokens":3,"reasoning_output_tokens":1}}
EOF

json="$(python3 "$ROOT_DIR/scripts/summarize-codex-json-usage.py" "$SAMPLE")"
grep -Fq '"root_total_tokens": 120' <<<"$json"
grep -Fq '"root_input_tokens": 110' <<<"$json"
grep -Fq '"root_cached_input_tokens": 45' <<<"$json"
grep -Fq '"root_output_tokens": 10' <<<"$json"
grep -Fq '"root_reasoning_output_tokens": 3' <<<"$json"

csv="$(python3 "$ROOT_DIR/scripts/summarize-codex-json-usage.py" --csv-values "$SAMPLE")"
test "$csv" = "120,110,45,10,3"
