#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Iterable, TextIO


FIELDS = (
    "input_tokens",
    "cached_input_tokens",
    "output_tokens",
    "reasoning_output_tokens",
)


def iter_lines(paths: list[str]) -> Iterable[str]:
    if not paths:
        yield from sys.stdin
        return
    for raw_path in paths:
        with Path(raw_path).open(encoding="utf-8") as handle:
            yield from handle


def summarize(lines: Iterable[str]) -> dict[str, int]:
    totals = {field: 0 for field in FIELDS}
    for line in lines:
        if not line.strip():
            continue
        event = json.loads(line)
        if event.get("type") != "turn.completed":
            continue
        usage = event.get("usage") or {}
        for field in FIELDS:
            totals[field] += int(usage.get(field) or 0)

    return {
        "root_total_tokens": totals["input_tokens"] + totals["output_tokens"],
        "root_input_tokens": totals["input_tokens"],
        "root_cached_input_tokens": totals["cached_input_tokens"],
        "root_output_tokens": totals["output_tokens"],
        "root_reasoning_output_tokens": totals["reasoning_output_tokens"],
    }


def write_csv_values(result: dict[str, int], output: TextIO) -> None:
    output.write(
        ",".join(
            str(result[key])
            for key in (
                "root_total_tokens",
                "root_input_tokens",
                "root_cached_input_tokens",
                "root_output_tokens",
                "root_reasoning_output_tokens",
            )
        )
    )
    output.write("\n")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Summarize token usage from codex exec --json JSONL output."
    )
    parser.add_argument("--csv-values", action="store_true", help="print one CSV value row")
    parser.add_argument("jsonl", nargs="*", help="JSONL file paths; stdin is used when omitted")
    args = parser.parse_args()

    result = summarize(iter_lines(args.jsonl))
    if args.csv_values:
        write_csv_values(result, sys.stdout)
    else:
        json.dump(result, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
