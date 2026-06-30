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

assert_contains "$SKILL" "## 快速流程"
assert_contains "$SKILL" "## 铁律"
assert_contains "$SKILL" "## 角色契约"
assert_contains "$SKILL" "## 常见失败"
assert_contains "$SKILL" 'Root 调用 `superpowers:using-superpowers`'
assert_contains "$SKILL" 'Root 先做 mloop preflight gate'
assert_contains "$SKILL" '只确认闭环门禁，不讨论需求方案、不写设计、不承诺实现'
assert_contains "$SKILL" '用户确认 preflight 后，才进入 `superpowers:brainstorming`'
assert_contains "$SKILL" 'design approval 只授权写 spec'
assert_contains "$SKILL" 'written spec approval 后才允许 Goal Creation Gate / Generator PLAN_WRITE_MODE / Evaluator package review'
assert_contains "$SKILL" 'Root 在写 spec 前进入 `superpowers:brainstorming` 阻塞子流程'
assert_contains "$SKILL" 'brainstorming 阶段只服从 `superpowers:brainstorming` 自身流程'
assert_contains "$SKILL" 'Brainstorming 未按其自身流程完成前，Root 不得写 spec、创建 goal、派发 Generator 或进入 PLAN_WRITE_MODE'
assert_contains "$SKILL" '用户 design approval 后，Root 只写 `docs/superpowers/specs/YYYY-MM-DD-<feature>-design.md`'
assert_contains "$SKILL" 'Root 必须停下让用户 review written spec'
assert_contains "$SKILL" '用户 approve written spec 前，不得创建 goal、派发 Generator 或进入 PLAN_WRITE_MODE'
assert_contains "$SKILL" '用户 approve written spec 后，Root 进入 Goal Creation Gate'
assert_not_contains "$SKILL" '无法表达质量目标时，只问一个澄清问题'
assert_contains "$SKILL" 'Root Token Budget 不适用于 brainstorming、spec 或 plan 完整性'
assert_contains "$SKILL" 'mloop 启动时不得立刻调用 `create_goal`'
assert_contains "$SKILL" 'Goal objective 只引用当前 spec 的绝对路径和完成标准，不写 spec 摘要'
assert_contains "$SKILL" 'Loop3E: complete <absolute spec path>. Done only after approved plan, Generator implementation, fresh Evaluator PASS, Root product acceptance, and recorded verification.'
assert_contains "$SKILL" 'Root 先调用 `get_goal`'
assert_contains "$SKILL" '没有 active goal 时调用 `create_goal`'
assert_contains "$SKILL" 'active goal 已包含当前 spec 绝对路径时复用'
assert_contains "$SKILL" 'active goal 与当前 spec 不匹配时 `ASK_USER`'
assert_contains "$SKILL" 'goal 工具不可用或 goal feature 未开启时 `ASK_USER`'
assert_contains "$SKILL" '只有 Evaluator fresh `PASS`、Root 产品验收通过且验证证据已记录后，才调用 `update_goal(status="complete")`'
assert_contains "$SKILL" '只有同一阻塞条件连续 3 轮且无法继续推进，才调用 `update_goal(status="blocked")`'
assert_contains "$SKILL" 'Generator 必须以 `loop_generator` 派发'
assert_contains "$SKILL" 'Evaluator 必须以 `loop_evaluator` 派发'
assert_contains "$SKILL" 'Root 必须通过 Codex subagent 机制启动 `loop_generator` 和 `loop_evaluator`'
assert_contains "$SKILL" '如果当前 Codex surface 不能 spawn subagent，Root 必须 `STOP`'
assert_contains "$SKILL" '不得 inline 承担 Generator 工作'
assert_contains "$SKILL" 'Root 不得使用 full-history fork'
assert_contains "$SKILL" '用户显式请求 `mloop` 时，不得降级成 Root inline 实现'
assert_contains "$SKILL" 'Root spec 只写需求、设计和验收，不写具体实现选择'
assert_contains "$SKILL" 'mloop preflight 只确认流程门禁，不讨论需求方案、技术方案或实现承诺'
assert_contains "$SKILL" '不得把 Generator / Evaluator 后续步骤夹带进 design approval'
assert_contains "$SKILL" 'Root 必须在 `superpowers:brainstorming` 流程内纳入用户明确要求、Root 推断假设、待用户确认、用户已接受的降级'
assert_contains "$SKILL" 'Root 不能把推断假设当作用户授权'
assert_contains "$SKILL" 'mloop 不规定 brainstorming 的问题数量、确认节奏或设计分段'
assert_contains "$SKILL" '这些由 `superpowers:brainstorming` 自身决定'
assert_contains "$SKILL" 'Root 不得创建或更新 `docs/superpowers/plans/` 或 `.loop3e/current_plan.txt`'
assert_contains "$SKILL" 'Root 只授权执行边界，不拆分实现子任务'
assert_contains "$SKILL" '是否并行、如何拆分和最终集成由 Generator 在 approved package 内决定'
assert_contains "$SKILL" 'Root 只以 `PLAN_WRITE_MODE` 派发 `loop_generator`'
assert_contains "$SKILL" 'Root 不做 plan 细节评审'
assert_contains "$SKILL" 'Generator 必须调用 `superpowers:writing-plans`'
assert_contains "$SKILL" 'Generator 读取 spec；有问题返回 `SPEC_ISSUE`，否则写 plan'
assert_contains "$SKILL" 'plan 的结构、深度、任务颗粒度和执行顺序由 `superpowers:writing-plans` 统一决定'
assert_contains "$SKILL" 'mloop 只要求 plan 顶部提供紧凑的 `Gate Summary`'
assert_contains "$SKILL" 'Evaluator 一次性评审 spec+plan package'
assert_contains "$SKILL" 'Generator 才能使用 `superpowers:subagent-driven-development` 或 `superpowers:executing-plans`'
assert_contains "$SKILL" '当前运行目录的 `package_review.json` 为 `APPROVED` 后'
assert_not_contains "$SKILL" 'Generator is a workflow role, not necessarily a separate subagent.'
assert_not_contains "$SKILL" 'Root may perform the Generator role inline'
assert_not_contains "$SKILL" 'execution_mode'
assert_contains "$SKILL" '声明完成前，Root 调用 `superpowers:verification-before-completion`'
assert_contains "$SKILL" '代码行为变更触发 TDD'
assert_contains "$SKILL" '失败、bug 或 Evaluator `FAIL` 触发 debugging'
assert_contains "$SKILL" 'Superpowers skill 是工程纪律，不是官僚关卡'
assert_contains "$SKILL" '不要为了使用 skill 而使用 skill'
assert_contains "$SKILL" 'TDD、debugging、code review、parallel agents、finishing branch 按触发条件使用'
assert_not_contains "$SKILL" 'MUST invoke `superpowers:finishing-a-development-branch`'
assert_contains "$SKILL" "checkpoint：phase、artifact、blocking、next"
assert_contains "$SKILL" "质量 > 效率 > 成本"
assert_contains "$SKILL" "token 或速度优化不得删除 review、verification、Superpowers phase gate、Generator/Evaluator 调度或验收证据"
assert_contains "$SKILL" "## 准出条件与测试证据"
assert_contains "$SKILL" "准出条件属于 Superpowers spec 的质量要求，不是额外 spec 模板"
assert_contains "$SKILL" "Root spec 必须定义可观察准出条件"
assert_contains "$SKILL" "Generator plan 必须把每个准出条件映射到实现任务和验证方式"
assert_contains "$SKILL" "Evaluator package review 必须检查准出条件是否完整、可执行、未弱化原始需求"
assert_contains "$SKILL" "Final PASS 只能基于本轮证据满足准出条件"
assert_contains "$SKILL" "测试证据规划属于 Generator 的 Superpowers implementation plan"
assert_contains "$SKILL" "代码行为变更必须说明测试层级：unit / integration / API / E2E / manual probe"
assert_contains "$SKILL" "只有 happy path、无断言或表面覆盖的测试不能单独支撑 PASS"
assert_contains "$SKILL" "无法自动化测试时，Generator 必须提供可复现的替代验证证据"
assert_contains "$SKILL" "不得新增单独的 exit-criteria 文档、测试矩阵模板或第二套 plan 流程"
assert_contains "$SKILL" 'Generator plan 必须以紧凑的 `Gate Summary` 开头'
assert_contains "$SKILL" 'Root 先读 plan 前 80 行'
assert_contains "$SKILL" '只有 summary 缺失、自相矛盾或存在阻塞时才读完整 plan'
assert_contains "$SKILL" '不得为了 token budget 压缩必要计划内容'
assert_contains "$SKILL" 'Evaluator 做 package review 时必须按需读取完整 plan'
assert_contains "$SKILL" 'IMPLEMENT_MODE 中，Generator 可在 approved package 内自主选择直接执行或并行执行'
assert_contains "$SKILL" '只有存在 2 个以上文件所有权清晰、可独立验证、不会编辑同一批文件的任务时才并行'
assert_contains "$SKILL" '满足并行条件时 Generator 默认并行；不并行必须在 generator_report 说明理由'
assert_contains "$SKILL" '由 Generator 负责最终集成和验证'
assert_contains "$SKILL" 'Root 记录 `loop_root` 为当前工作目录绝对路径'
assert_contains "$SKILL" '每次 `$mloop` 启动都必须创建新的 `run_id`'
assert_contains "$SKILL" '写入 `.loop3e/current_run.txt`'
assert_contains "$SKILL" '`.loop3e/runs/<run_id>/`'
assert_contains "$SKILL" '当前运行目录'
assert_contains "$SKILL" 'Root、Generator、Evaluator 只能读写当前运行目录下的 package review、report、verdict 和 run_log'
assert_contains "$SKILL" '根目录旧 `verdict.json`、`generator_report.md`、`evaluator_report.md`、`package_review.json`、`run_log.md` 不得参与任何门禁判断'
assert_contains "$SKILL" '交接只传 `loop_root`、当前运行目录、artifact 路径和短 phase brief'
assert_contains "$SKILL" 'Root 写 Evaluator 新鲜度守卫'
assert_contains "$SKILL" '覆盖当前运行目录的 `verdict.json` 为 `PENDING`'
assert_contains "$SKILL" 'Root 只根据写入 PENDING 后的文件系统元数据判断 freshness'
assert_contains "$SKILL" '只有 fresh 且 `status=PASS` 的 Evaluator verdict 可以进入 Root 产品验收'
assert_contains "$SKILL" 'Evaluator fresh `PASS` 后，Root 必须做产品验收'
assert_contains "$SKILL" 'Root 产品验收检查原始用户目标、输出/UX/API 行为、范围边界和 human approval'
assert_contains "$SKILL" 'P0 需求包含外部系统、相邻仓库、第三方服务或生产配置时'
assert_contains "$SKILL" '只写文档或替代验证不等于真实交付'
assert_contains "$SKILL" '除非 spec 明确记录用户接受降级'
assert_contains "$SKILL" 'Evolution 默认只由 Root 聚合'
assert_contains "$SKILL" '不触发 subagent 并行验收'
assert_contains "$SKILL" 'Evaluator PASS + Root 产品验收通过，才能宣称完成'
assert_contains "$SKILL" 'Generator 实现前必须读取当前运行目录的 `package_review.json`'
assert_contains "$SKILL" '`PASS` 后 Root 做产品验收和最终总结'
assert_contains "$SKILL" "当前运行目录默认只保留"
assert_contains "$SKILL" '`current_spec.txt`、`current_plan.txt`、`package_review.json`、`generator_report.md`、`verdict.json`、`evaluator_report.md`、`run_log.md`'
assert_not_contains "$SKILL" "current_batch.md"
assert_not_contains "$SKILL" "spec_review.md"
assert_not_contains "$SKILL" "plan_review.md"
assert_not_contains "$SKILL" "spec_review.json"
assert_not_contains "$SKILL" "plan_review.json"
assert_not_contains "$SKILL" "lessons.md"
assert_not_contains "$SKILL" "evolution_proposal.md"
assert_not_contains "$SKILL" "rule_update_proposal.md"
assert_not_contains "$SKILL" "regression_candidates.md"
assert_contains "$SKILL" "Root：编排者和冲突仲裁者"
assert_contains "$SKILL" "输出 P0 意图、不做事项、质量标准、未决问题、风险、角色交接、门禁决策和产品验收结论"
assert_contains "$SKILL" "该 checkpoint 限制不适用于 brainstorming"
assert_contains "$SKILL" '本节不适用于 `superpowers:brainstorming`'
assert_contains "$SKILL" 'brainstorming 的提问、方案比较、分段确认和 written spec review 节奏由 `superpowers:brainstorming` 自身决定'
assert_contains "$SKILL" '跳过 mloop preflight，直接把需求方案和后续实现承诺混进 brainstorming'
assert_contains "$SKILL" 'Brainstorming 未按 `superpowers:brainstorming` 自身流程完成，就写 spec、创建 goal 或派发 Generator 写 plan'
assert_contains "$SKILL" '用户只批准 design 后，Root 写完 spec 就继续创建 goal 或派发 Generator；必须先停下等待用户 review written spec'
assert_contains "$SKILL" "Generator：目标产物负责人"
assert_contains "$SKILL" "输出实现决策、变更产物、质量提升、验证命令和剩余风险"
assert_contains "$SKILL" "Evaluator：独立证据裁判"
assert_contains "$SKILL" "输出裁决、阻塞问题、证据、复现方式、非阻塞建议和回归候选"
assert_contains "$SKILL" "阻塞问题必须具体、可复现、可定位、可由 Generator 修复"
assert_contains "$SKILL" "把 Agency 来源、长人设、固定技术栈或外部团队模板写进运行时提示"
assert_not_contains "$SKILL" "## Role Cards"
assert_not_contains "$SKILL" "参考来源"
assert_not_contains "$SKILL" "Agency 对应关系"
assert_not_contains "$SKILL" "Agency-derived contract"
assert_contains "$SKILL" "在不扩大 scope、不修改 spec、不破坏验收的前提下提升目标产物质量"
assert_not_contains "$SKILL" "For user-facing errors, acceptance MUST cover the human message shape"

assert_contains "$GENERATOR" "先读取当前运行目录的 package_review.json"
assert_contains "$GENERATOR" "只有 status=APPROVED 才能实现"
assert_contains "$GENERATOR" "不能把 Root 推断假设当作用户授权"
assert_contains "$GENERATOR" "遇到降级、跨系统未落地或兼容性破坏时返回 SPEC_ISSUE 或 ASK_USER"
assert_contains "$GENERATOR" "REQUEST_CHANGES 时只修改 implementation plan"
assert_contains "$GENERATOR" "必须调用 superpowers:writing-plans"
assert_contains "$GENERATOR" "plan 的结构、深度、任务颗粒度和执行顺序由 superpowers:writing-plans 统一决定"
assert_contains "$GENERATOR" "Gate Summary 只是给 Root/Evaluator 的索引"
assert_contains "$GENERATOR" "不得为了 Root token budget 压缩必要计划内容"
assert_contains "$GENERATOR" "自行决定直接执行或并行执行"
assert_contains "$GENERATOR" "Root 只授权边界，不拆分实现子任务"
assert_contains "$GENERATOR" "若存在 2 个以上文件所有权清晰、可独立验证、不会编辑同一批文件的任务"
assert_contains "$GENERATOR" "满足并行条件时默认使用 superpowers:subagent-driven-development"
assert_contains "$GENERATOR" "不并行必须在 generator_report 说明理由"
assert_contains "$GENERATOR" "并行前写紧凑 execution split"
assert_contains "$GENERATOR" "负责最终集成、冲突处理和验证"
assert_contains "$GENERATOR" "package_review.json APPROVED 之前不得加载执行类 skill"
assert_contains "$GENERATOR" 'model_reasoning_effort = "medium"'
assert_contains "$GENERATOR" "按 using-superpowers 触发"
assert_contains "$GENERATOR" "使用 Superpowers 子技能时必须说明触发原因"
assert_contains "$GENERATOR" "不要为了使用 skill 而使用 skill"
assert_contains "$GENERATOR" "必须调用 superpowers:verification-before-completion"
assert_contains "$GENERATOR" "Root handoff 只应包含 artifact 路径和短 phase brief"
assert_contains "$GENERATOR" "必须使用 Root 提供的 loop_root 作为唯一运行根"
assert_contains "$GENERATOR" "必须使用 Root 提供的当前运行目录"
assert_contains "$GENERATOR" "不得读取或写入根目录旧 package_review.json、generator_report.md、verdict.json、evaluator_report.md、run_log.md"
assert_contains "$GENERATOR" "plan 必须以 Gate Summary 开头"
assert_contains "$GENERATOR" "Gate Summary 必须包含 exit criteria mapping 和 test evidence plan"
assert_contains "$GENERATOR" "不得为了 Root token budget 压缩必要计划内容"
assert_contains "$GENERATOR" "在不扩大 scope、不修改 spec、不破坏验收的前提下，主动提升目标产物质量"
assert_contains "$GENERATOR" "目标产物负责人"
assert_contains "$GENERATOR" "高于最低验收线"
assert_contains "$GENERATOR" "工程取舍"
assert_contains "$GENERATOR" "可维护性、可靠性、安全、性能"
assert_contains "$GENERATOR" "返回置信度、风险和证据位置"
assert_contains "$GENERATOR" "输出必须包含：实现决策、变更产物、质量提升、验证命令、剩余风险"
assert_not_contains "$GENERATOR" ".loop3e/current_batch.md"
assert_contains "$GENERATOR" "工作原则"
assert_contains "$GENERATOR" "最小有效差异：每行变更必须服务已确认范围。"
assert_contains "$GENERATOR" "工程质量负责：主动处理用户体验、可靠性、安全、性能、可维护性和测试风险。"
assert_contains "$GENERATOR" "不照搬外部角色默认：拒绝固定技术栈、奢华默认、提前抽象和顺手重构。"
assert_not_contains "$GENERATOR" "Agency 衍生契约"
assert_not_contains "$GENERATOR" "Agency-derived contract"
assert_contains "$GENERATOR" "generator_report 必须说明关键质量判断"
assert_contains "$GENERATOR" "generator_report 必须说明准出条件到验证证据的映射"
assert_contains "$GENERATOR" "只有 happy path、无断言或表面覆盖的测试不能作为唯一完成证据"

assert_contains "$EVALUATOR" "最终总结由 Root 汇总"
assert_contains "$EVALUATOR" "一次性评审 spec+plan package"
assert_contains "$EVALUATOR" "检查 spec 是否区分用户明确要求、Root 推断假设、待用户确认、用户已接受的降级"
assert_contains "$EVALUATOR" "未获用户确认的降级不能 PASS"
assert_contains "$EVALUATOR" 'model_reasoning_effort = "high"'
assert_not_contains "$EVALUATOR" ".loop3e/spec_review.md"
assert_not_contains "$EVALUATOR" ".loop3e/plan_review.md"
assert_not_contains "$EVALUATOR" ".loop3e/spec_review.json"
assert_not_contains "$EVALUATOR" ".loop3e/plan_review.json"
assert_not_contains "$EVALUATOR" ".loop3e/regression_candidates.md"
assert_not_contains "$EVALUATOR" "current_batch.md"
assert_contains "$EVALUATOR" "必须覆盖 Root 写入的 PENDING verdict"
assert_contains "$EVALUATOR" '不要编造 `evaluated_at` / timestamp'
assert_contains "$EVALUATOR" "准出条件缺失、不完整、不可执行或弱化原始需求时返回 SPEC_ISSUE"
assert_contains "$EVALUATOR" "Final PASS 必须基于本轮证据满足准出条件"
assert_contains "$EVALUATOR" "必须检查测试是否覆盖主要路径、异常路径和边界条件"
assert_contains "$EVALUATOR" "只有 happy path、无断言或表面覆盖的测试不能单独支撑 PASS"
assert_contains "$EVALUATOR" "Root handoff 只应包含 artifact 路径和短 phase brief"
assert_contains "$EVALUATOR" "必须使用 Root 提供的 loop_root 作为唯一运行根"
assert_contains "$EVALUATOR" "必须使用 Root 提供的当前运行目录"
assert_contains "$EVALUATOR" "不得读取或写入根目录旧 package_review.json、generator_report.md、verdict.json、evaluator_report.md、run_log.md"
assert_contains "$EVALUATOR" "如果 spec 将用户原始质量意图弱化为过宽验收标准，返回 SPEC_ISSUE"
assert_contains "$EVALUATOR" "如果实现满足弱 spec 但明显低于用户原始质量意图，返回 FAIL"
assert_contains "$EVALUATOR" "这不是新增需求，而是在原 scope 内按 P0 原始需求裁判目标产物质量"
assert_contains "$EVALUATOR" "Superpowers 使用充分不能替代目标产物质量"
assert_contains "$EVALUATOR" "测试全绿不能替代用户目标闭环"
assert_contains "$EVALUATOR" "P0 需求包含外部系统、相邻仓库、第三方服务或生产配置时"
assert_contains "$EVALUATOR" "只写文档、ADR、handoff 或替代验证不等于真实交付"
assert_contains "$EVALUATOR" "除非 spec 明确记录用户接受降级"
assert_contains "$EVALUATOR" "package review 返回 SPEC_ISSUE，final evaluation 返回 FAIL"
assert_contains "$EVALUATOR" "独立证据裁判"
assert_contains "$EVALUATOR" "阻塞问题必须可复现、可定位、可修复"
assert_contains "$EVALUATOR" "区分阻塞问题、建议项和个人偏好"
assert_contains "$EVALUATOR" "证据包必须包含命令、输出、检查过的 artifact、复现步骤和严重级别"
assert_contains "$EVALUATOR" "输出必须包含：裁决、阻塞问题、证据、复现方式、非阻塞建议、回归候选"
assert_contains "$EVALUATOR" "工作原则"
assert_contains "$EVALUATOR" "证据链优先：没有命令、输出、产物或复现路径就不能 PASS/FAIL。"
assert_contains "$EVALUATOR" "现实校验：声明必须被真实 diff、测试和运行结果支撑。"
assert_contains "$EVALUATOR" "分级反馈：阻塞问题、建议项、个人偏好必须分开。"
assert_contains "$EVALUATOR" "不照搬外部角色默认：拒绝生产就绪表演、无证据评分、把建议或偏好当阻塞项。"
assert_not_contains "$EVALUATOR" "Agency 衍生契约"
assert_not_contains "$EVALUATOR" "Agency-derived contract"
