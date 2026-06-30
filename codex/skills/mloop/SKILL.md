---
name: mloop
description: 当用户明确请求 "$mloop"、"mloop"、"loop3e"、多模型闭环、独立验收，或任务需要可验证的 spec/plan/evaluation 时使用。
---

# Loop3E + Superpowers 工作流

## 概览

`mloop` 是 Root + `loop_generator` + `loop_evaluator` 的三角色闭环。Root 负责用户意图、spec、门禁和汇总；Generator 负责 plan、实现和修复；Evaluator 负责独立证据验收。Generator 必须以 `loop_generator` 派发；Evaluator 必须以 `loop_evaluator` 派发。

不要用于一行修改、纯解释、纯翻译，或与代码/技术文档无关的任务。用户显式请求 `mloop` 时，不得降级成 Root inline 实现；如果当前 Codex surface 不能 spawn subagent，Root 必须 `STOP`。

## 快速流程

先记住阶段边界：mloop preflight 只确认闭环门禁；`superpowers:brainstorming` 负责需求和设计；design approval 只授权写 spec；written spec approval 才授权进入 Goal / Generator / Evaluator 闭环。

0. 启动
   - Root 调用 `superpowers:using-superpowers`。
   - Root 记录 `loop_root` 为当前工作目录绝对路径，检查 git status。
   - 每次 `$mloop` 启动都必须创建新的 `run_id`，写入 `.loop3e/current_run.txt`，并初始化 `.loop3e/runs/<run_id>/run_log.md`。

1. mloop preflight
   - Root 先做 mloop preflight gate：只确认闭环门禁，不讨论需求方案、不写设计、不承诺实现。
   - 用户确认 preflight 后，才进入 `superpowers:brainstorming`。
   - Preflight 必须说明：design approval 只授权写 spec；written spec approval 后才允许 Goal Creation Gate / Generator PLAN_WRITE_MODE / Evaluator package review。

2. Brainstorming
   - Root 在写 spec 前进入 `superpowers:brainstorming` 阻塞子流程。
   - brainstorming 阶段只服从 `superpowers:brainstorming` 自身流程。
   - Brainstorming 未按其自身流程完成前，Root 不得写 spec、创建 goal、派发 Generator 或进入 PLAN_WRITE_MODE。

3. Written spec
   - 用户 design approval 后，Root 只写 `docs/superpowers/specs/YYYY-MM-DD-<feature>-design.md`，做 spec self-review，并更新 `.loop3e/current_spec.txt` 和当前运行目录的 `current_spec.txt`。
   - Root 必须停下让用户 review written spec。
   - 用户 approve written spec 前，不得创建 goal、派发 Generator 或进入 PLAN_WRITE_MODE。

4. Goal
   - 用户 approve written spec 后，Root 进入 Goal Creation Gate。
   - mloop 启动时不得立刻调用 `create_goal`。

5. Plan package
   - Root 只以 `PLAN_WRITE_MODE` 派发 `loop_generator`。
   - Generator 读取 spec；有问题返回 `SPEC_ISSUE`，否则写 plan。
   - Generator 必须调用 `superpowers:writing-plans` 写 `docs/superpowers/plans/...-implementation.md` 和当前运行目录的 `current_plan.txt`，可同步 `.loop3e/current_plan.txt` 作为兼容指针。
   - Root 不做 plan 细节评审。
   - Evaluator 一次性评审 spec+plan package，并写当前运行目录的 `package_review.json`。

6. Implementation
   - 当前运行目录的 `package_review.json` 为 `APPROVED` 后，Generator 才能使用 `superpowers:subagent-driven-development` 或 `superpowers:executing-plans` 执行。
   - `REQUEST_CHANGES` 回 Generator 修改 plan；`SPEC_ISSUE` 回 Root 修改 spec；`ASK_USER`/`STOP` 停止。
   - 代码行为变更触发 TDD；失败、bug 或 Evaluator `FAIL` 触发 debugging；review findings 触发 receiving-code-review。

7. Evaluation
   - 声明完成前，Root 调用 `superpowers:verification-before-completion` 并记录新鲜验证证据。
   - Root 写 Evaluator 新鲜度守卫后派发 `loop_evaluator`：覆盖当前运行目录的 `verdict.json` 为 `PENDING`，覆盖当前运行目录的 `evaluator_report.md` 为 pending note。
   - `FAIL` 时 Generator 只修阻塞问题；实现/评估最多 3 轮。

8. Root acceptance
   - `PASS` 后 Root 做产品验收和最终总结。
   - Evaluator fresh `PASS` 后，Root 必须做产品验收。
   - 通过后才做最终总结；改进建议写在最终回复里，不默认落额外过程文件。

Preflight 输出形状：

```text
我会按 mloop 执行：
1. 先确认闭环门禁。
2. 然后进入 superpowers:brainstorming 做需求和设计。
3. 设计确认后我只写 spec，并停下请你 review written spec。
4. 你批准 written spec 后，才进入 Goal / Generator plan / Evaluator package review。
是否按这个流程继续？
```

## 铁律

- 质量 > 效率 > 成本；token 或速度优化不得删除 review、verification、Superpowers phase gate、Generator/Evaluator 调度或验收证据。
- Root Token Budget 不适用于 brainstorming、spec 或 plan 完整性；它只约束 checkpoint、handoff、report 读取和重复回显。
- Root 必须通过 Codex subagent 机制启动 `loop_generator` 和 `loop_evaluator`；不得 inline 承担 Generator 工作。
- 使用 explicit agent type 时，Root 不得使用 full-history fork；交接只传 `loop_root`、当前运行目录、artifact 路径和短 phase brief，不粘贴完整 spec、plan、diff 或 report。
- Root spec 只写需求、设计和验收，不写具体实现选择；Root 不得创建或更新 `docs/superpowers/plans/` 或 `.loop3e/current_plan.txt`，也不做 plan 细节评审。
- mloop preflight 只确认流程门禁，不讨论需求方案、技术方案或实现承诺；不得把 Generator / Evaluator 后续步骤夹带进 design approval。
- Root 必须在 `superpowers:brainstorming` 流程内纳入用户明确要求、Root 推断假设、待用户确认、用户已接受的降级；Root 不能把推断假设当作用户授权。
- mloop 不规定 brainstorming 的问题数量、确认节奏或设计分段；这些由 `superpowers:brainstorming` 自身决定。
- Goal objective 只引用当前 spec 的绝对路径和完成标准，不写 spec 摘要。模板：`Loop3E: complete <absolute spec path>. Done only after approved plan, Generator implementation, fresh Evaluator PASS, Root product acceptance, and recorded verification.`
- Root 只授权执行边界，不拆分实现子任务；是否并行、如何拆分和最终集成由 Generator 在 approved package 内决定。
- Generator 实现前必须读取当前运行目录的 `package_review.json`；非 `APPROVED` 不得写业务代码。
- Evaluator verdict 必须新鲜：Root 只根据写入 PENDING 后的文件系统元数据判断 freshness，不信任模型生成的 timestamp。
- 只有 fresh 且 `status=PASS` 的 Evaluator verdict 可以进入 Root 产品验收。
- Evaluator PASS + Root 产品验收通过，才能宣称完成。

## 准出条件与测试证据

准出条件属于 Superpowers spec 的质量要求，不是额外 spec 模板；测试证据规划属于 Generator 的 Superpowers implementation plan，不是第二套 plan 流程。

- Root spec 必须定义可观察准出条件，至少覆盖用户目标、范围边界、验证证据和关键失败场景。
- Generator plan 必须把每个准出条件映射到实现任务和验证方式。
- Evaluator package review 必须检查准出条件是否完整、可执行、未弱化原始需求。
- Final PASS 只能基于本轮证据满足准出条件。
- 代码行为变更必须说明测试层级：unit / integration / API / E2E / manual probe。
- 只有 happy path、无断言或表面覆盖的测试不能单独支撑 PASS。
- 无法自动化测试时，Generator 必须提供可复现的替代验证证据。
- 不得新增单独的 exit-criteria 文档、测试矩阵模板或第二套 plan 流程。

## Goal Creation Gate

Goal 是 Codex runtime 的长任务控制面，不是 spec/plan/verdict 的存储层。spec 是事实源，goal 只指向当前 spec。

Brainstorming 完成、用户确认 written spec review，并更新 `.loop3e/current_spec.txt` 后，先确认 spec 没有待用户确认、未授权降级或不可验证 acceptance。若存在这些问题，先 `ASK_USER`，不创建 goal。

Root 先调用 `get_goal`：

- 没有 active goal 时调用 `create_goal`，objective 使用当前 spec 绝对路径模板。
- active goal 已包含当前 spec 绝对路径时复用，并写入当前运行目录的 `run_log.md`。
- active goal 与当前 spec 不匹配时 `ASK_USER`，不得覆盖或静默降级。
- goal 工具不可用或 goal feature 未开启时 `ASK_USER`，提示开启 goals 或明确接受 file-only loop 降级。

只有 Evaluator fresh `PASS`、Root 产品验收通过且验证证据已记录后，才调用 `update_goal(status="complete")`。只有同一阻塞条件连续 3 轮且无法继续推进，才调用 `update_goal(status="blocked")`。`ASK_USER`、普通 `REQUEST_CHANGES`、单次 provider 超时或一次 Evaluator `FAIL` 不得标记 blocked。

## 角色契约

- Root：编排者和冲突仲裁者。输出 P0 意图、不做事项、质量标准、未决问题、风险、角色交接、门禁决策和产品验收结论。每个 gate 后输出 6 行以内 checkpoint：phase、artifact、blocking、next；该 checkpoint 限制不适用于 brainstorming。
- Generator：目标产物负责人。输出实现决策、变更产物、质量提升、验证命令和剩余风险；在不扩大 scope、不修改 spec、不破坏验收的前提下提升目标产物质量。
- Evaluator：独立证据裁判。输出裁决、阻塞问题、证据、复现方式、非阻塞建议和回归候选。阻塞问题必须具体、可复现、可定位、可由 Generator 修复；建议和个人偏好不得阻塞 PASS。

## 运行产物

Superpowers 长期产物：`docs/superpowers/specs/`、`docs/superpowers/plans/`。

Loop3E 运行态入口：

- `.loop3e/current_run.txt`：当前 `run_id`。
- `.loop3e/current_spec.txt` / `.loop3e/current_plan.txt`：兼容指针，只指向当前 Superpowers spec / plan。
- `.loop3e/runs/<run_id>/`：当前运行目录。Root、Generator、Evaluator 只能读写当前运行目录下的 package review、report、verdict 和 run_log。

每次 `$mloop` 启动都必须创建新的 `run_id`，不得复用上一次运行目录。当前运行目录默认只保留：`current_spec.txt`、`current_plan.txt`、`package_review.json`、`generator_report.md`、`verdict.json`、`evaluator_report.md`、`run_log.md`。

根目录旧 `verdict.json`、`generator_report.md`、`evaluator_report.md`、`package_review.json`、`run_log.md` 不得参与任何门禁判断；如果存在，只能视为历史兼容残留，不得读取为当前状态。

不要默认创建额外过程文件；spec/plan 细节属于 `docs/superpowers/`，经验、演进建议和回归候选写进最终回复。只有用户明确要求持久沉淀时，才另建文档。

Generator plan 必须以紧凑的 `Gate Summary` 开头，覆盖 scope、files、tests、risks 和 acceptance mapping。Root 先读 plan 前 80 行；只有 summary 缺失、自相矛盾或存在阻塞时才读完整 plan。

Superpowers skill 是工程纪律，不是官僚关卡。不要为了使用 skill 而使用 skill；TDD、debugging、code review、parallel agents、finishing branch 按触发条件使用，触发原因必须能服务当前目标产物质量。

plan 的结构、深度、任务颗粒度和执行顺序由 `superpowers:writing-plans` 统一决定。mloop 只要求 plan 顶部提供紧凑的 `Gate Summary`，用于 Root/Evaluator 快速定位 scope、files、tests、risks 和 acceptance mapping；不得为了 token budget 压缩必要计划内容。Evaluator 做 package review 时必须按需读取完整 plan。

IMPLEMENT_MODE 中，Generator 可在 approved package 内自主选择直接执行或并行执行。只有存在 2 个以上文件所有权清晰、可独立验证、不会编辑同一批文件的任务时才并行；满足并行条件时 Generator 默认并行；不并行必须在 generator_report 说明理由。并行前写紧凑 execution split，说明每个子任务的 files/checks/交付物，并由 Generator 负责最终集成和验证。

P0 需求包含外部系统、相邻仓库、第三方服务或生产配置时，必须把真实边界交付纳入 spec、package review、final evaluation 和 Root 产品验收。只写文档或替代验证不等于真实交付；除非 spec 明确记录用户接受降级，否则 package review 返回 `SPEC_ISSUE`，final evaluation 或 Root 产品验收返回 `FAIL`。

Root 产品验收检查原始用户目标、输出/UX/API 行为、范围边界和 human approval。Root 只做产品验收，不替代 Evaluator 的代码级证据裁判；若产品验收不通过，回 Generator 修复或 `ASK_USER`。

Evolution 默认只由 Root 聚合，不触发 subagent 并行验收，不阻塞完成；只有用户明确要求复盘、沉淀规则或生成回归资产时，才作为新任务处理。

## 停止和询问用户

本节不适用于 `superpowers:brainstorming`。brainstorming 的提问、方案比较、分段确认和 written spec review 节奏由 `superpowers:brainstorming` 自身决定。

其他 mloop 阶段只有遇到业务决策、范围变更、兼容性决策、破坏性迁移、API break、安全/权限/计费/数据一致性取舍、外部凭证、生产访问、循环次数超限或重复角色冲突时，才询问用户。

门禁含义：`APPROVED` 继续；`REQUEST_CHANGES` 回作者；`SPEC_ISSUE` 回 Root；`ASK_USER` 问用户；`STOP` 停止；`PASS` 进入汇总；`FAIL` 回 Generator 修阻塞问题。

## 常见失败

- 跳过 `brainstorming` 直接写 spec。
- 跳过 mloop preflight，直接把需求方案和后续实现承诺混进 brainstorming。
- Brainstorming 未按 `superpowers:brainstorming` 自身流程完成，就写 spec、创建 goal 或派发 Generator 写 plan。
- 用户只批准 design 后，Root 写完 spec 就继续创建 goal 或派发 Generator；必须先停下等待用户 review written spec。
- Root 抢写 implementation plan、实现代码或修复。
- 用户可见页面或流程变更时，Root 绕过 `superpowers:brainstorming` 的设计确认，只写行为合同。
- Generator 遇到后端、前端、配置/文档等清晰独立任务仍全部串行，且不说明不并行理由。
- 当前运行目录的 `package_review.json` 未 `APPROVED` 就加载执行类 skill。
- 复用旧 `.loop3e/verdict.json` 或根目录 report/package_review 作为当前运行证据。
- 把建议项、审美偏好或流程不完整当作目标产物质量阻塞项。
- 把 Agency 来源、长人设、固定技术栈或外部团队模板写进运行时提示。
- 自动 commit、push、PR、更新 `AGENTS.md`、更新 skills 或固化 evolution proposal。

## 最终回复

包含 summary、spec path、plan path、changed files、tests/checks run、evaluator verdict、Root 产品验收结论、remaining risks、evolution proposals、是否需要 human approval。除非 Evaluator 返回 fresh `PASS` 且 Root 产品验收通过，否则不得宣称成功。
