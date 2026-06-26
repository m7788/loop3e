#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_contains() {
  local file="$1"
  local text="$2"
  grep -Fq "$text" "$file" || {
    echo "expected '$text' in $file" >&2
    exit 1
  }
}

assert_not_contains() {
  local file="$1"
  local text="$2"
  if grep -Fq "$text" "$file"; then
    echo "did not expect '$text' in $file" >&2
    exit 1
  fi
}

SKILL="$ROOT_DIR/codex/skills/mloop/SKILL.md"
GENERATOR="$ROOT_DIR/codex/agents/loop_generator.toml"
EVALUATOR="$ROOT_DIR/codex/agents/loop_evaluator.toml"
DOC="$ROOT_DIR/docs/codex-superpowers-loop3e.md"

assert_contains "$SKILL" "## Root Checkpoints"
assert_contains "$SKILL" 'Root MUST invoke `superpowers:using-superpowers`'
assert_contains "$SKILL" 'MUST invoke `superpowers:brainstorming`'
assert_contains "$SKILL" 'Generator MUST invoke `superpowers:writing-plans`'
assert_contains "$SKILL" 'MUST use either `superpowers:subagent-driven-development` or `superpowers:executing-plans`'
assert_contains "$SKILL" 'MUST invoke `superpowers:verification-before-completion`'
assert_contains "$SKILL" 'Consider `superpowers:dispatching-parallel-agents`'
assert_contains "$SKILL" 'Use conditional Superpowers skills when their trigger applies'
assert_not_contains "$SKILL" 'MUST invoke `superpowers:finishing-a-development-branch`'
assert_contains "$SKILL" "Keep normal checkpoint output under 6 lines."
assert_contains "$SKILL" 'Generator must read `.loop3e/plan_review.json`'
assert_contains "$SKILL" "Root owns evolution aggregation"

assert_contains "$GENERATOR" "先读取 .loop3e/plan_review.json"
assert_contains "$GENERATOR" "只有 status=APPROVED 才能实现"
assert_contains "$GENERATOR" "REQUEST_CHANGES 时只修改 implementation plan"
assert_contains "$GENERATOR" "必须调用 superpowers:writing-plans"
assert_contains "$GENERATOR" "使用 superpowers:executing-plans 或 superpowers:subagent-driven-development"
assert_contains "$GENERATOR" "按 using-superpowers 触发"
assert_contains "$GENERATOR" "必须调用 superpowers:verification-before-completion"

assert_contains "$EVALUATOR" "Evolution 最终由 Root 汇总"

assert_contains "$DOC" "Root Checkpoint Output"
assert_contains "$DOC" '`superpowers:using-superpowers` | mloop 启动时必须先调用'
assert_contains "$DOC" '必须调用 `superpowers:brainstorming`'
assert_contains "$DOC" '`superpowers:writing-plans` | Generator 写 implementation plan 前必须调用'
assert_contains "$DOC" '`superpowers:subagent-driven-development` / `superpowers:executing-plans` | approved plan 执行时二选一'
assert_contains "$DOC" '`superpowers:test-driven-development` | 条件使用'
assert_contains "$DOC" '`superpowers:requesting-code-review` | 条件使用'
assert_contains "$DOC" '`superpowers:receiving-code-review` | 条件使用'
assert_contains "$DOC" '`superpowers:systematic-debugging` | 条件使用'
assert_contains "$DOC" '`superpowers:verification-before-completion` | 任何完成声明前必须调用'
assert_contains "$DOC" '`superpowers:finishing-a-development-branch` | 用户要求 merge / PR / cleanup 时使用'
assert_contains "$DOC" '`superpowers:dispatching-parallel-agents` | 仅 2+ 独立问题域'
assert_contains "$DOC" 'Generator 必须读取 `.loop3e/plan_review.json`'
assert_contains "$DOC" "Root owns evolution aggregation"
