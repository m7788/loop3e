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

assert_contains "$SKILL" "## 快速流程"
assert_contains "$SKILL" "## 铁律"
assert_contains "$SKILL" "## 角色契约"
assert_contains "$SKILL" "## 常见失败"
assert_contains "$SKILL" 'Root 调用 `superpowers:using-superpowers`'
assert_contains "$SKILL" 'Root 在写 spec 前调用 `superpowers:brainstorming`'
assert_contains "$SKILL" 'spec 的结构、深度和用户确认流程由 `superpowers:brainstorming` 统一决定'
assert_contains "$SKILL" 'Root Token Budget 不适用于 spec 或 plan 完整性'
assert_contains "$SKILL" 'mloop 启动时不得立刻调用 `create_goal`'
assert_contains "$SKILL" 'Root 写完 spec 并更新 `.loop3e/current_spec.txt` 后，才进入 Goal Creation Gate'
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
assert_contains "$SKILL" 'Root 必须在 `superpowers:brainstorming` 流程内纳入用户明确要求、Root 推断假设、待用户确认、用户已接受的降级'
assert_contains "$SKILL" 'Root 不能把推断假设当作用户授权'
assert_contains "$SKILL" '涉及用户可见页面、交互流程、导航、弹窗、表格列或空态时，Root 必须让 `superpowers:brainstorming` 覆盖产品/交互设计确认'
assert_contains "$SKILL" '设计确认只描述入口、信息位置、显示/空态、是否改变页面结构和用户需确认的取舍'
assert_contains "$SKILL" '有多个合理 UX 方案或会改变用户工作流时先 `ASK_USER`'
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

assert_contains "$DOC" "Root 检查点输出"
assert_contains "$DOC" "Root Token 预算"
assert_contains "$DOC" "Root Token Budget 不适用于 spec 或 plan 完整性"
assert_contains "$DOC" "Goal Creation Gate"
assert_contains "$DOC" 'mloop 启动时不得立刻调用 `create_goal`'
assert_contains "$DOC" 'Root 写完 spec 并更新 `.loop3e/current_spec.txt` 后才创建或复用 goal'
assert_contains "$DOC" 'Goal objective 只引用当前 spec 的绝对路径和完成标准，不写 spec 摘要'
assert_contains "$DOC" 'Loop3E: complete <absolute spec path>. Done only after approved plan, Generator implementation, fresh Evaluator PASS, Root product acceptance, and recorded verification.'
assert_contains "$DOC" 'goal 工具不可用或 goal feature 未开启时返回 `ASK_USER`'
assert_contains "$DOC" '同一阻塞条件连续 3 轮且无法继续推进时，才调用 `update_goal(status="blocked")`'
assert_contains "$DOC" "质量 > 效率 > 成本"
assert_contains "$DOC" "token / speed 优化不得删除必要 review、verification、Superpowers phase gate、Generator / Evaluator 调度或验收证据"
assert_contains "$DOC" "产物读取预算"
assert_contains "$DOC" 'Generator plan 必须以 `Gate Summary` 开头'
assert_contains "$DOC" 'Root 默认只读 plan 前 80 行'
assert_contains "$DOC" 'plan 的结构、深度、任务颗粒度和执行顺序由 `superpowers:writing-plans` 统一决定'
assert_contains "$DOC" '不得为了 token budget 压缩必要计划内容'
assert_contains "$DOC" 'Evaluator 做 package review 时必须按需读取完整 plan'
assert_contains "$DOC" "Loop 根目录"
assert_contains "$DOC" 'Root 启动 mloop 时必须把当前工作目录绝对路径记录为 `loop_root`'
assert_contains "$DOC" '每次 `$mloop` 启动都创建新的 `run_id`'
assert_contains "$DOC" '`.loop3e/current_run.txt`'
assert_contains "$DOC" '`.loop3e/runs/<run_id>/`'
assert_contains "$DOC" 'Root、Generator、Evaluator 只能使用当前运行目录里的 package review、report、verdict 和 run_log'
assert_contains "$DOC" '根目录旧 `verdict.json`、`generator_report.md`、`evaluator_report.md`、`package_review.json`、`run_log.md` 不得参与门禁判断'
assert_contains "$DOC" '不得用 git top-level 或父 workspace 替代 `loop_root`'
assert_contains "$DOC" 'Root 给 Generator / Evaluator 的 handoff 只传 artifact 路径、当前运行目录和短 phase brief'
assert_contains "$DOC" '不要粘贴完整 spec、plan、diff、report'
assert_contains "$DOC" '实现重活应主要消耗在 `loop_generator`'
assert_contains "$DOC" "Root 只授权执行边界，不拆分实现子任务"
assert_contains "$DOC" "是否并行、如何拆分和最终集成由 Generator 在 approved package 内决定"
assert_contains "$DOC" "质量契约"
assert_contains "$DOC" "质量指目标产物质量"
assert_contains "$DOC" "参考 agency-agents 的可取部分"
assert_contains "$DOC" "每个角色都要有身份、使命、交付物、成功指标"
assert_contains "$DOC" "角色定义"
assert_contains "$DOC" "Agency 对应关系"
assert_contains "$DOC" "Agency 提取矩阵"
assert_contains "$DOC" "product-manager"
assert_contains "$DOC" "engineering-minimal-change-engineer"
assert_contains "$DOC" "testing-evidence-collector"
assert_contains "$DOC" "拒绝照搬的 Agency 模式"
assert_contains "$DOC" "固定技术栈"
assert_contains "$DOC" "Root = 产品 + 设计 + 项目编排"
assert_contains "$DOC" "Generator = 工程"
assert_contains "$DOC" "Evaluator = QA + 证据/现实校验"
assert_contains "$DOC" "用户 = 需求方/授权方"
assert_contains "$DOC" "Root 是编排者和冲突仲裁者"
assert_contains "$DOC" 'spec 的结构、深度和用户确认流程由 `superpowers:brainstorming` 统一决定'
assert_contains "$DOC" 'Root 必须在 `superpowers:brainstorming` 流程内纳入用户明确要求、Root 推断假设、待用户确认、用户已接受的降级'
assert_contains "$DOC" '涉及用户可见页面、交互流程、导航、弹窗、表格列或空态时，Root 必须让 `superpowers:brainstorming` 覆盖产品/交互设计确认'
assert_contains "$DOC" "设计确认只描述入口、信息位置、显示/空态、是否改变页面结构和用户需确认的取舍"
assert_contains "$DOC" '有多个合理 UX 方案或会改变用户工作流时先 `ASK_USER`'
assert_contains "$DOC" "Root 必须沉淀问题、用户结果、不做事项、质量标准、风险和变更控制决策"
assert_contains "$DOC" "Root 产品验收"
assert_contains "$DOC" "Evaluator PASS + Root Product Acceptance"
assert_contains "$DOC" "Root 产品验收只检查原始用户目标、输出/UX/API 行为、范围边界和 human approval"
assert_contains "$DOC" "不替代 Evaluator 的代码级证据裁判"
assert_contains "$DOC" "P0 需求包含外部系统、相邻仓库、第三方服务或生产配置时"
assert_contains "$DOC" "只写文档或替代验证不等于真实交付"
assert_contains "$DOC" "除非 spec 明确记录用户接受降级"
assert_contains "$DOC" "Generator 是目标产物负责人"
assert_contains "$DOC" "Generator 负责工程取舍：设计契合度、可维护性、可靠性、安全、性能和聚焦测试"
assert_contains "$DOC" "Evaluator 是独立证据裁判"
assert_contains "$DOC" "Evaluator 的证据包必须包含命令、输出、检查过的产物、复现步骤和严重级别"
assert_contains "$DOC" "阻塞问题必须具体、可复现、可定位、可修复"
assert_contains "$DOC" "硬边界、软判断"
assert_contains "$DOC" "Root 表达用户意图和可观察质量目标，不写死实现细节或精确输出文本"
assert_contains "$DOC" "Generator 在不扩大 scope、不修改 spec、不破坏验收的前提下，主动提升目标产物质量"
assert_contains "$DOC" "Evaluator 可以按 P0 原始用户需求裁判目标产物质量"
assert_not_contains "$DOC" "用户可见错误的验收至少覆盖消息形态"
assert_contains "$DOC" 'Evaluator 新鲜度守卫'
assert_contains "$DOC" 'Root 在派发 `loop_evaluator` 前必须覆盖当前运行目录的 `verdict.json` 为 `PENDING`'
assert_contains "$DOC" 'Freshness 判断只能以 Root 写入 `PENDING` 后采集的文件系统 mtime / ctime 为准'
assert_contains "$DOC" '只有本轮新鲜的 Evaluator `PASS` verdict 才能进入 Root 产品验收'
assert_contains "$DOC" '`superpowers:using-superpowers` | mloop 启动时必须先调用'
assert_contains "$DOC" "Superpowers skill 是工程纪律，不是官僚关卡"
assert_contains "$DOC" "不要为了使用 skill 而使用 skill"
assert_contains "$DOC" "TDD、debugging、code review、parallel agents、finishing branch 按触发条件使用"
assert_contains "$DOC" '必须调用 `superpowers:brainstorming`'
assert_contains "$DOC" '`superpowers:writing-plans` | `loop_generator` 写 implementation plan 前必须调用'
assert_contains "$DOC" '`superpowers:subagent-driven-development` / `superpowers:executing-plans` | 当前运行目录的 `package_review.json` 为 `APPROVED` 之后二选一'
assert_contains "$DOC" '当前运行目录的 `package_review.json` 为 `APPROVED` 之前不得加载执行类 skill'
assert_contains "$DOC" 'mloop 固定使用 Root + `loop_generator` + `loop_evaluator` 三角色三模型'
assert_contains "$DOC" 'Root 必须用 Codex subagent spawn 机制启动 `loop_generator` 和 `loop_evaluator`'
assert_contains "$DOC" '当前 Codex surface 不能 spawn subagent 时必须 `STOP`'
assert_contains "$DOC" 'Root 不得使用 full-history fork'
assert_contains "$DOC" 'Root 不承担 Generator inline 工作'
assert_contains "$DOC" '显式 `mloop` 请求等于用户已经选择 Generator / Evaluator 调度'
assert_contains "$DOC" '“审慎使用 subagent”只能约束交接压缩，不能取消三角色闭环'
assert_contains "$DOC" 'Root spec 写需求、设计和验收，不写具体实现选择'
assert_contains "$DOC" 'Root 不创建、不更新 `docs/superpowers/plans/` 或 `.loop3e/current_plan.txt`'
assert_contains "$DOC" 'Root 不做 plan 细节评审'
assert_contains "$DOC" 'Evaluator 一次性评审 spec+plan package'
assert_not_contains "$DOC" 'Generator 是 workflow role，不一定是单独 subagent'
assert_not_contains "$DOC" 'execution_mode='
assert_contains "$DOC" '`superpowers:test-driven-development` | 条件使用'
assert_contains "$DOC" '`superpowers:requesting-code-review` | 条件使用'
assert_contains "$DOC" '`superpowers:receiving-code-review` | 条件使用'
assert_contains "$DOC" '`superpowers:systematic-debugging` | 条件使用'
assert_contains "$DOC" '`superpowers:verification-before-completion` | 任何完成声明前必须调用'
assert_contains "$DOC" '`superpowers:finishing-a-development-branch` | 用户要求 merge / PR / cleanup 时使用'
assert_contains "$DOC" '`superpowers:dispatching-parallel-agents` | 仅 2+ 独立问题域'
assert_contains "$DOC" "Root 不用它拆实现任务"
assert_contains "$DOC" "IMPLEMENT_MODE 的执行拆分由 Generator 决定"
assert_contains "$DOC" "满足并行条件时 Generator 默认并行"
assert_contains "$DOC" "不并行必须在 generator_report 说明理由"
assert_contains "$DOC" "并行前 Generator 必须写紧凑 execution split"
assert_contains "$DOC" 'Generator 必须读取当前运行目录的 `package_review.json`'
assert_contains "$DOC" "Root owns final aggregation"
assert_not_contains "$DOC" "Root owns evolution aggregation"
