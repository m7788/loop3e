#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT_DIR/codex/skills/mloop/SKILL.md"
GENERATOR="$ROOT_DIR/codex/agents/loop_generator.toml"
EVALUATOR="$ROOT_DIR/codex/agents/loop_evaluator.toml"

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

# Contract tests only guard hard workflow boundaries and known regressions.
# They intentionally avoid checking prose shape, headings, or exact wording.

assert_contains "$SKILL" 'Generator 必须以 `loop_generator` 派发'
assert_contains "$SKILL" 'Evaluator 必须以 `loop_evaluator` 派发'
assert_contains "$SKILL" '不得 inline 承担 Generator 工作'
assert_contains "$SKILL" '如果当前 Codex surface 不能 spawn subagent，Root 必须 `STOP`'

assert_contains "$SKILL" 'mloop preflight'
assert_contains "$SKILL" 'superpowers:brainstorming'
assert_contains "$SKILL" 'design approval 只授权写 spec'
assert_contains "$SKILL" 'written spec approval'
assert_contains "$SKILL" 'mloop 不规定 brainstorming 的问题数量、确认节奏或设计分段'

assert_contains "$SKILL" 'Root spec 只写需求、设计和验收，不写具体实现选择'
assert_contains "$SKILL" 'Root 不得创建或更新 `docs/superpowers/plans/` 或 `.loop3e/current_plan.txt`'
assert_contains "$SKILL" 'Root 不做 plan 细节评审'
assert_contains "$SKILL" 'superpowers:writing-plans'
assert_contains "$SKILL" 'Evaluator 一次性评审 spec+plan package'
assert_contains "$SKILL" 'package_review.json` 为 `APPROVED`'

assert_contains "$SKILL" 'current_run.txt'
assert_contains "$SKILL" '`.loop3e/runs/<run_id>/`'
assert_contains "$SKILL" '根目录旧 `verdict.json`'
assert_contains "$SKILL" 'PENDING'
assert_contains "$SKILL" '文件系统元数据判断 freshness'
assert_contains "$SKILL" 'Evaluator PASS + Root 产品验收通过，才能宣称完成'

assert_contains "$SKILL" '最低成本验证方式'
assert_contains "$SKILL" '硬件或外部系统无法自动化'
assert_contains "$SKILL" '用户可见 UI 变更'
assert_contains "$SKILL" '可视证据'
assert_contains "$SKILL" '不得 Final PASS'
assert_contains "$SKILL" 'P0 需求包含外部系统、相邻仓库、第三方服务或生产配置'
assert_contains "$SKILL" '只写文档或替代验证不等于真实交付'

assert_contains "$GENERATOR" "只有 status=APPROVED 才能实现"
assert_contains "$GENERATOR" "package_review.json APPROVED 之前不得加载执行类 skill"
assert_contains "$GENERATOR" "必须使用 Root 提供的 loop_root 作为唯一运行根"
assert_contains "$GENERATOR" "plan 的结构、深度、任务颗粒度和执行顺序由 superpowers:writing-plans 统一决定"
assert_contains "$GENERATOR" "不得为了 Root token budget 压缩必要计划内容"
assert_contains "$GENERATOR" "准出条件到验证证据的映射"
assert_contains "$GENERATOR" "硬件或外部系统无法自动化时，必须列出可复现的替代验证证据"
assert_contains "$GENERATOR" "用户可见 UI 变更必须列出截图、录屏、真实渲染窗口或用户确认证据"

assert_contains "$EVALUATOR" "一次性评审 spec+plan package"
assert_contains "$EVALUATOR" "准出条件缺失、不完整、不可执行或弱化原始需求时返回 SPEC_ISSUE"
assert_contains "$EVALUATOR" "必须覆盖 Root 写入的 PENDING verdict"
assert_contains "$EVALUATOR" '不要编造 `evaluated_at` / timestamp'
assert_contains "$EVALUATOR" "只写文档、ADR、handoff 或替代验证不等于真实交付"
assert_contains "$EVALUATOR" "证据链优先"
assert_contains "$EVALUATOR" "用户可见 UI 变更缺少截图、录屏、真实渲染窗口或用户确认证据时不得 PASS"

assert_not_contains "$SKILL" 'execution_mode'
assert_not_contains "$SKILL" 'Root may perform the Generator role inline'
assert_not_contains "$SKILL" 'Generator is a workflow role, not necessarily a separate subagent'
assert_not_contains "$SKILL" '无法表达质量目标时，只问一个澄清问题'
assert_not_contains "$SKILL" 'Root 先读 plan 前 80 行'
assert_not_contains "$SKILL" 'current_batch.md'
assert_not_contains "$SKILL" 'spec_review.md'
assert_not_contains "$SKILL" 'plan_review.md'
assert_not_contains "$GENERATOR" ".loop3e/current_batch.md"
assert_not_contains "$EVALUATOR" ".loop3e/spec_review.md"
assert_not_contains "$EVALUATOR" ".loop3e/plan_review.md"
