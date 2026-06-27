# Codex + Superpowers + Loop3E Root-as-Planner 闭环落地方案 v0.5

## 1. 目标

在 Codex 中实现一套基于 Superpowers 的 Root-as-Planner 多模型开发闭环。

核心角色：

| 角色         | 模型         | 定位                             |
| ---------- | ---------- | ------------------------------ |
| Generator  | MiniMax-M3 | Implementation Plan、代码实现、测试、修复 |
| Evaluator  | DeepSeek   | 可验收性评审、独立验收、证据裁判               |
| Root Codex | 默认主模型      | 需求澄清、Spec、Acceptance、调度、门禁、汇总     |

核心原则：

```text
Superpowers 负责长期工程资产：
- spec
- implementation plan
- executing-plans
- code review discipline

Loop3E 负责 Root + 双 agent 闭环：
- generator plan/spec feasibility handoff
- spec+plan package review
- implementation evaluation
- repair loop
- evolution proposal

.loop3e 只保存运行态产物，不重复保存 spec / acceptance。
```

---

## 2. 一句话流程

```text
Root 按 mloop skill 写 spec；
Generator 读取 spec，返回 SPEC_ISSUE 或写 implementation plan；
Evaluator 一次性评审 spec+plan package；
Generator 实现；
Evaluator 验收；
REQUEST_CHANGES 自动回路；
ASK_USER 才人工介入；
PASS 后做 Evolution Review；
commit / push / PR / 固化规则必须人工确认。
```

---

## 3. 为什么是 Loop3E

Loop3E = Loop3 + Evolution。

Loop3 解决任务内闭环：

```text
需求 → Spec → Plan → 实现 → 验收 → 修复
```

Evolution 解决长期演进闭环：

```text
本次经验 → 规则提案 → 人工确认 → 固化到 AGENTS.md / Skill / 测试 / 模板
```

---

## 4. 总体流程

```text
用户需求
  ↓
Root Codex 启动 mloop
  ↓
Root 按 mloop skill 写 Superpowers spec
  ↓
Generator 读取 spec
  ├─ SPEC_ISSUE → Root 自动修正 spec 或问用户
  └─ APPROVED → 写 Superpowers implementation plan
  ↓
Package Review Gate
  ├─ Evaluator Review：spec 是否保留 P0 意图，plan 是否覆盖验收且可验证
  └─ Root Codex 汇总
      ├─ APPROVED → 下一步
      ├─ REQUEST_CHANGES → Generator 自动修改 plan
      ├─ SPEC_ISSUE → Root 自动修正 spec 或问用户
      ├─ ASK_USER → 用户裁决
      └─ STOP → 停止
  ↓
Generator 按 approved plan 实现
  ↓
Evaluator 独立验收
  ├─ PASS → Evolution Review
├─ FAIL → Generator 自动修阻塞问题
  ├─ SPEC_ISSUE → Root 修 spec
  ├─ ASK_USER → 用户裁决
  └─ STOP → 停止
  ↓
Evolution Review
  ↓
Root Codex 汇总
  ↓
人工确认是否 commit / push / PR / 固化规则
```

### 4.1 Root 检查点输出

Root 在每个 gate 后输出短 checkpoint，让用户不打开文件也能掌握状态。

```text
<Phase>: <STATUS>
- artifact: <path>
- blocking: <none|count and short reason>
- next: <next action>
```

普通 checkpoint 不超过 6 行；只有 `ASK_USER`、`STOP`、`FAIL` 或用户要求详情时才展开。

### 4.2 Root Token 预算

优先级：质量 > 效率 > 成本。

token / speed 优化不得删除必要 review、verification、Superpowers phase gate、Generator / Evaluator 调度或验收证据。

Root 的 token 目标不是“完全不消耗”，而是实现重活应主要消耗在 `loop_generator`，独立验收重活应主要消耗在 `loop_evaluator`。

Root 给 Generator / Evaluator 的 handoff 只传 artifact 路径和短 phase brief；不要粘贴完整 spec、plan、diff、report。子 agent 自己读取 artifact，并把结构化结论写回 `.loop3e/`。

Root 默认只读状态、required changes、阻塞问题和 artifact 路径；只有 gate 决策或冲突仲裁需要时才打开完整 artifact。

Root 只授权执行边界，不拆分实现子任务。是否并行、如何拆分和最终集成由 Generator 在 approved package 内决定，避免 Root 抢回工程执行上下文。

### 4.3 Goal Creation Gate

Goal mode 是 Codex runtime 的长任务控制面；`.loop3e/` 和 `docs/superpowers/` 仍然是证据源。

mloop 启动时不得立刻调用 `create_goal`。Root 必须先完成 `superpowers:brainstorming`、写出 spec，并更新 `.loop3e/current_spec.txt`。Root 写完 spec 并更新 `.loop3e/current_spec.txt` 后才创建或复用 goal。

Goal objective 只引用当前 spec 的绝对路径和完成标准，不写 spec 摘要，避免出现第二份需求事实源：

```text
Loop3E: complete <absolute spec path>. Done only after approved plan, Generator implementation, fresh Evaluator PASS, Root product acceptance, and recorded verification.
```

Root 先调用 `get_goal`：

* 没有 active goal：调用 `create_goal`。
* active goal 已包含当前 spec 绝对路径：复用并写入 `.loop3e/run_log.md`。
* active goal 与当前 spec 不匹配：返回 `ASK_USER`，不得覆盖或静默降级。
* goal 工具不可用或 goal feature 未开启时返回 `ASK_USER`，提示开启 goals 或明确接受 file-only loop 降级。

只有 Evaluator fresh `PASS`、Root 产品验收通过且验证证据已记录后，才调用 `update_goal(status="complete")`。同一阻塞条件连续 3 轮且无法继续推进时，才调用 `update_goal(status="blocked")`。

### 4.4 质量契约

质量指目标产物质量：最终代码、测试、文档、CLI 输出、API 行为、迁移结果，或用户真正要求交付的对象。流程完整性只是证据链，不等于质量本身。

硬边界、软判断：

参考 agency-agents 的可取部分：每个角色都要有身份、使命、交付物、成功指标；但 mloop 不照搬大量 persona，只保留 Root / Generator / Evaluator 三个必要角色。

角色定义：

Agency 对应关系：

* 用户 = 需求方/授权方
* Root = 产品 + 设计 + 项目编排
* Generator = 工程
* Evaluator = QA + 证据/现实校验

* Root 是编排者和冲突仲裁者：维护 P0 用户意图、需求澄清、门禁路由、冲突仲裁、用户可见状态和 Root 产品验收。Root 必须沉淀问题、用户结果、不做事项、质量标准、风险和变更控制决策。成功信号是共享意图清晰、角色冲突被解决、用户不打开产物也能掌控进度。
* Generator 是目标产物负责人：把已确认范围变成高质量目标产物，而不是机械满足弱检查。Generator 负责工程取舍：设计契合度、可维护性、可靠性、安全、性能和聚焦测试。成功信号是目标产物高于最低验收线，同时不扩大范围、不修改 spec、不破坏验收。
* Evaluator 是独立证据裁判：按 P0 原始需求、confirmed spec、acceptance、diff 和测试证据裁判目标产物质量。Evaluator 的证据包必须包含命令、输出、检查过的产物、复现步骤和严重级别。阻塞问题必须具体、可复现、可定位、可修复；建议项和个人偏好不能阻塞 PASS。

* Root 表达用户意图和可观察质量目标，不写死实现细节或精确输出文本，除非用户明确指定。
* Root spec 必须区分用户明确要求、Root 推断假设、待用户确认、用户已接受的降级；Root 不能把推断假设当作用户授权。
* Generator 在不扩大 scope、不修改 spec、不破坏验收的前提下，主动提升目标产物质量。
* Evaluator 可以按 P0 原始用户需求裁判目标产物质量；满足弱 spec 但明显低于原始质量意图时可以 `FAIL`。
* Evaluator PASS + Root Product Acceptance 才能宣称完成。Root 产品验收只检查原始用户目标、输出/UX/API 行为、范围边界和 human approval，不替代 Evaluator 的代码级证据裁判。
* P0 需求包含外部系统、相邻仓库、第三方服务或生产配置时，真实边界交付必须进入 spec、package review、final evaluation 和 Root 产品验收。只写文档或替代验证不等于真实交付；除非 spec 明确记录用户接受降级，否则 package review 返回 `SPEC_ISSUE`，final evaluation 或 Root 产品验收返回 `FAIL`。

如果 Root 无法表达质量目标而不替用户做产品取舍，必须在 brainstorming 阶段问一个简短澄清问题。

#### Agency 提取矩阵

这次只抽取 `agency-agents-zh` 中可迁移的角色方法，不复制长人设、固定技术栈或具体工具命令。

| mloop 角色 | Agency 来源 | 采纳精华 | 拒绝照搬 | mloop 落点 |
| --- | --- | --- | --- | --- |
| Root | `product-manager`, `product-sprint-prioritizer`, `design-ux-researcher`, `design-ui-designer`, `design-ux-architect`, `project-management-project-shepherd`, `project-manager-senior`, `agents-orchestrator` | 先确认问题而非方案；沉淀用户结果、不做事项、成功指标、质量标准；管理风险、变更、冲突和用户可见状态 | 大型 PRD/GTM/roadmap 模板、全量项目治理、固定设计系统输出 | spec 和 checkpoint 必须表达 P0 意图、不做事项、质量标准、未决问题、风险、角色交接、门禁决策 |
| Generator | `engineering-minimal-change-engineer`, `engineering-frontend-developer`, `engineering-backend-architect`, `engineering-senior-developer`, `engineering-code-reviewer` | 工程部负责目标产物；用最小有效 diff，但主动处理设计契合度、可维护性、可靠性、安全、性能和聚焦测试 | 固定技术栈、奢华默认、高端动效强制、提前抽象、顺手重构 | generator_report 必须包含实现决策、变更产物、质量提升、验证命令、剩余风险 |
| Evaluator | `testing-evidence-collector`, `testing-reality-checker`, `testing-test-results-analyzer`, `testing-api-tester`, `testing-accessibility-auditor`, `engineering-code-reviewer` | QA 负责独立证据；默认怀疑声明，按 P0 意图和实际产物判断；阻塞问题必须可复现、可定位、可修复 | 生产就绪表演、无证据评分、把建议/偏好当阻塞项、照搬 UI 截图流程到非 UI 任务 | verdict 必须包含裁决、阻塞问题、证据、复现方式、非阻塞建议、回归候选 |

拒绝照搬的 Agency 模式：长人设、固定技术栈、奢华默认、生产就绪表演、大型部门流水线和 mesh 协商。

### 4.5 产物读取预算

Generator plan 必须以 `Gate Summary` 开头，覆盖 scope、files、tests、risks 和 acceptance mapping。小任务 plan 目标不超过 100 行。

Root 默认只读 plan 前 80 行做 gate；只有 summary 缺失、自相矛盾或出现阻塞问题时才读完整 plan。

### 4.6 Evaluator 新鲜度守卫

Root 在派发 `loop_evaluator` 前必须覆盖 `.loop3e/verdict.json` 为 `PENDING`，并覆盖 `.loop3e/evaluator_report.md` 为 pending note，避免复用旧 run 的 PASS verdict。

Root 等待 Evaluator 必须使用显式有限 timeout。若 Evaluator 超时、未写 verdict、仍为 `PENDING`、JSON 不合法，或 verdict 早于本轮 evaluation start，Root 必须按 `FAIL` / `STOP` 处理，写入 timeout 或 stale-verdict finding，不得宣布完成。

Freshness 判断只能以 Root 写入 `PENDING` 后采集的文件系统 mtime / ctime 为准；不能信任 Evaluator 自己写入的 `evaluated_at`、`timestamp` 等模型生成字段。Evaluator 如需写时间，必须先通过命令读取当前时间，或省略该字段。

只有本轮新鲜的 Evaluator `PASS` verdict 才能进入 Evolution Review。

### 4.7 Superpowers 6 技能映射

Loop3E 不是替代 Superpowers，而是调度这些 Superpowers skill：

Superpowers skill 是工程纪律，不是官僚关卡。`using-superpowers` 负责发现和调用纪律；`brainstorming`、`writing-plans`、approved execution、`verification-before-completion` 构成 mloop 主链路；TDD、debugging、code review、parallel agents、finishing branch 按触发条件使用。不要为了使用 skill 而使用 skill，流程完整不能替代目标产物质量。

| 阶段 | Superpowers skill | 使用规则 |
| --- | --- | --- |
| 技能纪律 | `superpowers:using-superpowers` | mloop 启动时必须先调用；它负责技能调用纪律，但不替代下面的阶段门禁 |
| 需求澄清 | `superpowers:brainstorming` | 写 spec 前必须调用 |
| Plan 生成 | `superpowers:writing-plans` | `loop_generator` 写 implementation plan 前必须调用 |
| Plan 执行 | `superpowers:subagent-driven-development` / `superpowers:executing-plans` | `.loop3e/package_review.json` 为 `APPROVED` 之后二选一；`.loop3e/package_review.json` 为 `APPROVED` 之前不得加载执行类 skill |
| 执行隔离 | `superpowers:using-git-worktrees` | 条件使用；只有需要隔离或执行 skill 要求时触发，不静默改环境 |
| 代码实现 | `superpowers:test-driven-development` | 条件使用；代码行为变更时由 `using-superpowers` 触发 |
| 实现评审 | `superpowers:requesting-code-review` | 条件使用；重大 code diff 或用户要求额外 review 时触发 |
| 评审反馈处理 | `superpowers:receiving-code-review` | 条件使用；处理 review / Evaluator findings 时触发 |
| 修复失败 | `superpowers:systematic-debugging` | 条件使用；bugfix、测试失败、异常行为或 Evaluator `FAIL` 时触发 |
| 完成声明 | `superpowers:verification-before-completion` | 任何完成声明前必须调用 |
| 收尾选择 | `superpowers:finishing-a-development-branch` | 用户要求 merge / PR / cleanup 时使用；mloop 默认只报告，不进入集成菜单 |
| 并行探索 | `superpowers:dispatching-parallel-agents` | 仅 2+ 独立问题域且不会编辑同一批文件时考虑；Root 不用它拆实现任务 |

IMPLEMENT_MODE 的执行拆分由 Generator 决定。若 approved plan 中存在 2 个以上文件所有权清晰、可独立验证、不会编辑同一批文件的任务，Generator 可使用 `superpowers:subagent-driven-development` 并行；否则使用 `superpowers:executing-plans` 直接执行。并行前 Generator 必须写紧凑 execution split，列明每个子任务的 files/checks/交付物，并负责最终集成、冲突处理和验证。

mloop 固定使用 Root + `loop_generator` + `loop_evaluator` 三角色三模型；Root 必须用 Codex subagent spawn 机制启动 `loop_generator` 和 `loop_evaluator`；Root 不承担 Generator inline 工作。嫌重的任务应不使用 `$mloop`。

显式 `mloop` 请求等于用户已经选择 Generator / Evaluator 调度；项目或全局规则里的“审慎使用 subagent”只能约束交接压缩，不能取消三角色闭环。相关成本控制应体现在循环次数、artifact 路径交接和不可行时 `ASK_USER` / `STOP`。

当前 Codex surface 不能 spawn subagent 时必须 `STOP`，并说明 mloop 需要 Codex subagent spawning；不得由 Root 自己模拟 Generator / Evaluator 完成实现。

指定 `loop_generator` 或 `loop_evaluator` 这类 explicit agent type 时，Root 不得使用 full-history fork。只传递压缩后的任务上下文、artifact 路径和必要指令；full-history fork 会继承父 agent type/model，不能和显式角色 agent 混用。

### 4.8 Loop 根目录

Root 启动 mloop 时必须把当前工作目录绝对路径记录为 `loop_root`。`.loop3e/`、`docs/superpowers/specs/`、`docs/superpowers/plans/`、Evaluator freshness guard 和最终 artifact 读取都必须基于这个 `loop_root`。

不得用 git top-level 或父 workspace 替代 `loop_root`。当测试项目位于大仓库或 ignored workspace 的子目录时，mloop 的运行根仍然是用户启动 Codex 的当前项目目录。

Root 给 Generator / Evaluator 的 handoff 必须包含 `loop_root` 和该根下的绝对 artifact 路径。Generator / Evaluator 只能写入这个 `loop_root` 下的 `.loop3e/` 和 `docs/superpowers/`。

---

## 5. 角色职责

### 5.1 Root Codex / Orchestrator

身份：编排者和冲突仲裁者。

使命：维护 P0 用户意图、需求澄清、gate 路由、冲突仲裁和用户可见状态；沉淀问题、用户结果、不做事项、质量标准、风险和变更控制决策；Root 不做 Generator 的实现/plan 工作。

成功信号：共享意图清晰，角色冲突被显式解决，用户通过短 checkpoint 就能掌握当前状态。

职责：

* 接收用户需求。
* 判断是否需要 Loop3E。
* 启动 Superpowers 方法论。
* 按 mloop skill 承担 Planner 能力：澄清需求、写 spec、定义 acceptance。
* 调度 Generator / Evaluator。
* 维护 `.loop3e/` 运行态产物。
* 汇总 review / verdict。
* 在 Evaluator fresh PASS 后执行 Root 产品验收。
* 控制循环上限。
* 判断是否需要 `ASK_USER`。
* 输出最终报告。
* 控制人工门禁。

不允许：

* Evaluator `FAIL` 后强行宣布完成。
* 自动 commit / push / PR，除非用户明确要求。
* 自动固化 evolution proposal。
* 绕过 review gate 直接进入实现。

---

### 5.2 Root-as-Planner 能力

职责：

* 在写 spec 前必须调用 `superpowers:brainstorming` 进行需求澄清。
* 产出 Superpowers spec / design。
* Root spec 只写需求和验收，不写具体实现选择。具体库、API、算法、数据结构、测试实现由 `loop_generator` 在 plan 中提出。
* 定义 acceptance criteria。
* Root 不创建、不更新 `docs/superpowers/plans/` 或 `.loop3e/current_plan.txt`。
* Root 只能调度 `loop_generator` 进入 PLAN_WRITE_MODE，由 Generator 写 plan 或返回 SPEC_ISSUE。
* Root 不做 plan 细节评审，只路由 Evaluator 的 package review 结果。
* 根据 Generator / Evaluator 返回的 SPEC_ISSUE 自动修改 spec 或询问用户。
* 处理 Evaluator 返回的 `SPEC_ISSUE`。
* PASS 后参与 Evolution Review。

不允许：

* 以 Root gate 身份写业务代码。
* 以 Root gate 身份绕过 `writing-plans` 写 implementation plan。
* 绕过 `loop_generator` 选择具体实现步骤。
* 绕过 Generator 的 spec 可行性判断或 Evaluator 的 package review。
* 降低 acceptance criteria。
* 在实现后随意扩大需求。

---

### 5.3 Generator

模型：

```text
MiniMax-M3
```

身份：目标产物负责人。

使命：在 confirmed scope 内产出高质量目标产物，而不是机械满足最低验收；负责设计契合度、可维护性、可靠性、安全、性能和聚焦测试的工程取舍。

成功信号：目标产物高于最低验收线，关键取舍有证据，风险和置信度能交接给 Root / Evaluator。

职责：

* 读取 spec 并判断可行性；不可实现、不清楚或验收矛盾时返回 SPEC_ISSUE。
* 使用 Superpowers writing-plans 思路写 implementation plan。
* 根据 Package Review 自动修改 plan。
* 按 approved package 实现代码。
* 补测试、跑验证命令。
* 根据 Evaluator 阻塞问题自动修复。
* 输出 generator report。
* 在不扩大 scope、不修改 spec、不破坏验收的前提下，主动提升目标产物质量，并在 report 中说明关键质量判断。

不允许：

* 修改 spec / acceptance。
* 绕过 package review 直接实现。
* 自行宣布 PASS。
* 修复阶段扩大范围。
* 做无关重构。
* 为了实现方便降低验收标准。

---

### 5.4 Evaluator

模型：

```text
`deepseek-v4-pro`, provider `loop3e_evaluator`
```

身份：独立证据裁判。

使命：按 P0 用户意图、confirmed spec、acceptance、diff 和测试证据裁判目标产物质量；用命令、输出、检查过的产物、复现步骤和严重级别组成证据包。

成功信号：裁决有证据、可执行、指向 P0 意图；阻塞问题具体、可复现、可定位、可修复；建议项和个人偏好不阻塞 PASS。

职责：

* 评审 spec 是否可验收、可验证。
* 评审 plan 是否能产生足够验收证据。
* 独立检查 diff / tests / report。
* 根据 confirmed spec / acceptance 输出 PASS / FAIL。
* 发现 spec 问题时返回 `SPEC_ISSUE`。
* 按 P0 原始用户需求裁判目标产物质量；满足弱 spec 但明显低于原始质量意图时返回 `FAIL`。
* PASS 后提出 regression candidates。

不允许：

* 修改业务代码。
* 修改 spec。
* 修改 plan。
* 新增 blocking acceptance。
* 删除或降低 acceptance。
* 用个人偏好阻塞任务。
* 因 Generator 自称完成就 PASS。

---

## 6. 目录结构

### 6.1 用户级配置

```text
~/.codex/config.toml

~/.codex/agents/
  loop_generator.toml
  loop_evaluator.toml
```

### 6.2 项目级配置

```text
AGENTS.md

codex/
  agents/
    loop_generator.toml
    loop_evaluator.toml
  skills/
    mloop/
      SKILL.md

scripts/
  install-loop3e.sh
```

安装后目标：

```text
${CODEX_HOME:-~/.codex}/
  agents/
  loop_generator.toml
  loop_evaluator.toml
  skills/
    mloop/
      SKILL.md
```

### 6.3 Superpowers 长期工程资产

```text
docs/superpowers/
  specs/
    2026-06-26-<feature>-design.md
  plans/
    2026-06-26-<feature>-implementation.md
```

说明：

```text
spec / acceptance / implementation plan 都属于 Superpowers 长期资产。
```

不要创建：

```text
.loop3e/spec.md
.loop3e/acceptance.md
```

### 6.4 Loop3E 运行态产物

```text
.loop3e/
  current_spec.txt
  current_plan.txt
  package_review.json
  generator_report.md
  verdict.json
  evaluator_report.md
  run_log.md
```

| 文件                               | 作用                                 |
| -------------------------------- | ---------------------------------- |
| `.loop3e/current_spec.txt`         | 当前 Superpowers spec 路径             |
| `.loop3e/current_plan.txt`         | 当前 Superpowers plan 路径             |
| `.loop3e/package_review.json`      | Evaluator 对 spec+plan package 的评审结果 |
| `.loop3e/generator_report.md`      | Generator 实现和测试报告                  |
| `.loop3e/verdict.json`             | Evaluator 最终验收结论                   |
| `.loop3e/evaluator_report.md`      | Evaluator 详细验收报告                   |
| `.loop3e/run_log.md`               | 调度记录                               |

默认不要创建更多 `.loop3e` 过程文件。spec / acceptance / implementation plan 已由 `docs/superpowers/` 承载；经验、演进建议、规则更新建议和回归候选默认写进最终回复。只有用户明确要求持久沉淀时，才另建文档。

---

## 7. 状态机

所有 Gate 统一使用这些状态：

```text
APPROVED
REQUEST_CHANGES
SPEC_ISSUE
ASK_USER
STOP
PASS
FAIL
```

| 状态                | 含义                    | 下一步                           |
| ----------------- | --------------------- | ----------------------------- |
| `APPROVED`        | 当前阶段通过                | 进入下一阶段                        |
| `REQUEST_CHANGES` | 已有范围内可修正              | 自动回给对应角色修改                    |
| `SPEC_ISSUE`      | spec / acceptance 有问题 | 回 Root 修 spec                 |
| `ASK_USER`        | 需要用户裁决                | 停下问用户                         |
| `STOP`            | 风险过高或循环失败             | 停止并汇总                         |
| `PASS`            | 实现验收通过                | 进入 Evolution Review           |
| `FAIL`            | 实现未通过                 | Generator 修阻塞问题 |

---

## 8. 自动闭环规则

### 8.1 默认自动修改

```text
Generator 返回 SPEC_ISSUE → Root 自动修改 spec 或问用户
Package Review 不通过 → Generator 自动修改 plan，或 Root 修 spec
Implementation 验收不通过 → Generator 自动修代码 / 测试
```

### 8.2 不问用户的情况

以下属于普通 `REQUEST_CHANGES`，默认自动回路：

```text
- 验收标准表达不清
- acceptance 缺少可验证条件
- spec 漏掉用户已明确提出的边界
- plan 漏掉 acceptance item
- plan 缺少测试计划
- plan 没说明验证命令
- 实现漏掉某个验收项
- 实现缺少关键路径测试
- generator report 与 diff 不一致
- 代码存在明显 bug
```

### 8.3 需要 ASK_USER 的情况

以下情况必须停止自动闭环，问用户：

```text
1. 需求冲突
2. 业务策略取舍
3. 是否兼容旧版本
4. 是否允许破坏性 API 变更
5. 是否允许数据库迁移
6. 是否扩大范围
7. 涉及安全 / 权限 / 计费 / 数据一致性决策
8. 需要生产环境、密钥、人工操作
9. 自动修改超过循环上限
10. Generator 和 Evaluator 对同一问题重复冲突
11. Root Codex 判断继续自动修改风险过高
```

### 8.4 循环上限

| 闭环                     |      默认上限 |
| ---------------------- | --------: |
| Spec 修正         |       2 轮 |
| Package Review 修改      |       2 轮 |
| Implementation 修复      |       3 轮 |
| 同一阻塞问题重复 | 2 次后 STOP |

---

## 9. Generator Plan Handoff

### 9.1 目的

Generator 不再做独立 spec review gate。它在 `PLAN_WRITE_MODE` 内先读取 spec：

```text
spec 可实现且清楚 → 写 implementation plan
spec 不可实现 / 不清楚 / 验收矛盾 → 返回 SPEC_ISSUE，不写 plan
```

这样保留 Generator 的工程判断，同时避免 Root 和双 agent 在 plan 前制造一轮过程文件。

### 9.2 Generator 检查项

```text
1. 当前架构是否支持
2. 是否缺少关键输入信息
3. 是否需要高风险迁移
4. 技术约束是否冲突
5. 是否应该拆分阶段
6. 是否存在实现成本明显过高的点
```

Generator 不评审需求是否值得做，不修改 spec / acceptance。

---

## 10. Package Review Gate

### 10.1 目的

避免 Generator 写完 plan 后直接实现，同时避免 Root 抢 plan 细节评审。

Package Review Gate 由 Evaluator 一次性回答：

```text
spec 是否保留 P0 用户意图？
plan 是否覆盖 acceptance？
plan 是否有可执行验证方式和证据路径？
spec / plan 是否存在范围漂移、过度设计或验收矛盾？
```

Root 只做路由和用户交互，不做 plan 细节评审。

### 10.2 Evaluator 检查项

```text
1. Acceptance criteria 是否可验证
2. spec 是否弱化用户原始质量意图
3. plan 是否覆盖所有 acceptance criteria
4. 每个 acceptance 是否有验证方式
5. 测试是否覆盖关键路径
6. 证据是否可采集
7. 是否有明显回归风险没有验证
8. plan 是否会导致后续无法客观 PASS / FAIL
```

Evaluator 不新增需求。若发现 spec 弱化用户原始质量意图，返回 `SPEC_ISSUE`；若 plan 缺少验收覆盖或证据，返回 `REQUEST_CHANGES`。

### 10.3 package_review.json 格式

Generator 必须读取 `.loop3e/package_review.json`。只有 `status=APPROVED` 才能进入实现；`REQUEST_CHANGES` 只能回到 plan 修订；`SPEC_ISSUE`、`ASK_USER`、`STOP` 必须停下交给 Root 路由。

通过示例：

```json
{
  "status": "APPROVED",
  "round": 1,
  "evaluator_review": {
    "status": "APPROVED",
    "focus": "spec_plan_package",
    "spec_issues": [],
    "missing_items": [],
    "scope_drift": [],
    "test_gaps": [],
    "evidence_gaps": [],
    "risk_gaps": [],
    "required_changes": []
  },
  "root_decision": {
    "status": "APPROVED",
    "need_user_confirmation": false,
    "notes": []
  }
}
```

不通过示例：

```json
{
  "status": "REQUEST_CHANGES",
  "round": 1,
  "evaluator_review": {
    "status": "REQUEST_CHANGES",
    "focus": "spec_plan_package",
    "spec_issues": [],
    "missing_items": [],
    "scope_drift": [],
    "test_gaps": [
      "A002 缺少锁定过期后的自动恢复测试"
    ],
    "evidence_gaps": [
      "plan 没说明如何证明 5 分钟后账号恢复可登录"
    ],
    "risk_gaps": [],
    "required_changes": [
      {
        "id": "PR-E001",
        "problem": "A002 没有可执行验证方式",
        "required_fix": "在 implementation plan 中增加自动解锁逻辑的测试和验证命令"
      }
    ]
  },
  "root_decision": {
    "status": "REQUEST_CHANGES",
    "need_user_confirmation": false,
    "notes": [
      "该问题属于验证计划不足，可由 Generator 自动修改 plan"
    ]
  }
}
```

---

## 11. Implementation Evaluation

Evaluator 根据已确认的 spec / acceptance 和 approved plan 验收实现。

### 11.1 Evaluator 依据优先级

```text
P0 用户原始需求和明确约束
P1 Superpowers spec / design
P2 acceptance criteria
P3 implementation plan
P4 package_review.json
P5 generator_report.md
P6 git diff / changed files
P7 测试代码 / 测试日志 / CI 结果
P8 AGENTS.md / 项目约定
P9 Evaluator 独立代码审查
```

规则：

```text
Spec / Acceptance 高于 Plan
Diff 高于 Generator Report
没有证据不能 PASS
```

### 11.2 PASS 条件

必须同时满足：

```text
1. 所有 acceptance criteria 都有证据通过
2. 实现没有违背 spec
3. 没有 blocking bug
4. 没有明显范围漂移
5. 关键路径有测试或可接受替代验证
6. Generator report 与实际 diff 基本一致
7. 没有破坏项目约定或已有行为
```

### 11.3 FAIL 条件

任一命中即 FAIL：

```text
1. 漏掉任一 acceptance item
2. 实现与 spec 冲突
3. 测试缺失关键路径
4. Generator report 声称完成但 diff 无证据
5. 引入无关大改动
6. 有明显回归风险但无验证
7. plan 未经 APPROVED 就实现重大变更
8. 验收标准不可验证
9. 修改了不该修改的范围
```

### 11.4 verdict.json 格式

PASS 示例：

```json
{
  "status": "PASS",
  "confidence": "high",
  "required_next_action": "NONE",
  "spec_source": "docs/superpowers/specs/2026-06-26-login-lockout-design.md",
  "plan_source": "docs/superpowers/plans/2026-06-26-login-lockout-implementation.md",
  "acceptance_results": [
    {
      "id": "A001",
      "status": "PASS",
      "requirement": "登录失败 5 次后账号进入锁定状态",
      "evidence": [
        "auth/login.ts includes failed-attempt lockout logic",
        "auth/login.test.ts covers five failures",
        "npm test auth/login.test.ts passed"
      ]
    }
  ],
  "plan_compliance": {
    "status": "PASS",
    "notes": []
  },
  "scope_control": {
    "status": "PASS",
    "unexpected_changes": []
  },
  "test_evidence": {
    "status": "PASS",
    "commands": [
      {
        "command": "npm test auth/login.test.ts",
        "result": "PASS"
      }
    ]
  },
  "blocking_findings": [],
  "non_blocking_notes": []
}
```

FAIL 示例：

```json
{
  "status": "FAIL",
  "confidence": "medium",
  "required_next_action": "GENERATOR_FIX",
  "acceptance_results": [
    {
      "id": "A002",
      "status": "FAIL",
      "requirement": "锁定 5 分钟后自动恢复登录",
      "evidence": [
        "No test covers unlock-after-expiry behavior",
        "Implementation checks lock status but does not clear expired lock"
      ]
    }
  ],
  "blocking_findings": [
    {
      "id": "E001",
      "acceptance_item": "A002",
      "problem": "缺少锁定过期后的恢复逻辑和测试",
      "evidence": "diff 中未看到过期清理逻辑，测试也未覆盖",
      "required_fix": "补充 5 分钟后自动解锁逻辑，并增加对应测试"
    }
  ],
  "non_blocking_notes": []
}
```

SPEC_ISSUE 示例：

```json
{
  "status": "SPEC_ISSUE",
  "confidence": "medium",
  "required_next_action": "PLANNER_CLARIFY",
  "spec_issues": [
    {
      "id": "SI001",
      "acceptance_item": "A003",
      "problem": "A003 不可验证",
      "required_fix": "明确可观察行为或验收阈值"
    }
  ],
  "blocking_findings": [],
  "non_blocking_notes": []
}
```

---

## 12. 路由规则

### 12.1 Generator Plan Handoff 路由

| 状态                | 修改者     | 是否问用户 |
| ----------------- | ------- | ----: |
| `APPROVED`        | Generator 写 plan |     否 |
| `SPEC_ISSUE`      | Root 修 spec 或问用户 |   视情况 |
| `ASK_USER`        | 用户裁决    |     是 |
| `STOP`            | Root 汇总 |     是 |

### 12.2 Package Review 路由

| 状态                | 修改者       | 是否问用户 |
| ----------------- | --------- | ----: |
| `APPROVED`        | 无         |     否 |
| `REQUEST_CHANGES` | Generator |     否 |
| `SPEC_ISSUE`      | Root   |   通常否 |
| `ASK_USER`        | 用户裁决      |     是 |
| `STOP`            | Root 汇总   |     是 |

### 12.3 Implementation Evaluation 路由

| 状态           | 修改者       | 是否问用户 |
| ------------ | --------- | ----: |
| `PASS`       | 无         |     否 |
| `FAIL`       | Generator |     否 |
| `SPEC_ISSUE` | Root   |   视情况 |
| `ASK_USER`   | 用户裁决      |     是 |
| `STOP`       | Root 汇总   |     是 |

---

## 13. Provider 配置

项目内提供 `scripts/install-loop3e.sh`，默认 dry-run，不修改当前环境；传 `--apply` 后只安装 agents 和 skills 到 `${CODEX_HOME:-$HOME/.codex}`。

安装脚本不创建、不修改 `config.toml`，也不写入 `model_providers`。Provider 配置由用户按本节示例手工维护。

如果手工配置，可编辑：

```bash
mkdir -p ~/.codex
vi ~/.codex/config.toml
```

参考配置：

```toml
# ~/.codex/config.toml

[agents]
max_threads = 3
max_depth = 1

[model_providers.loop3e_generator]
name = "Loop3E Generator Provider"
base_url = "https://YOUR-GENERATOR-ENDPOINT/v1"
env_key = "LOOP3E_GENERATOR_API_KEY"
wire_api = "responses"

[model_providers.loop3e_evaluator]
name = "Loop3E Evaluator Provider"
base_url = "https://YOUR-EVALUATOR-ENDPOINT/v1"
env_key = "LOOP3E_EVALUATOR_API_KEY"
wire_api = "responses"
```

设置环境变量：

```bash
export LOOP3E_GENERATOR_API_KEY="your-generator-key"
export LOOP3E_EVALUATOR_API_KEY="your-evaluator-key"
```

写入 shell 配置：

```bash
echo 'export LOOP3E_GENERATOR_API_KEY="your-generator-key"' >> ~/.zshrc
echo 'export LOOP3E_EVALUATOR_API_KEY="your-evaluator-key"' >> ~/.zshrc
source ~/.zshrc
```

---

## 14. Custom Agents 配置

仓库内源文件：

```text
codex/agents/
  loop_generator.toml
  loop_evaluator.toml
```

执行 `scripts/install-loop3e.sh --apply` 后会复制到 `${CODEX_HOME:-$HOME/.codex}/agents/`。

---

### 14.1 Generator Agent

文件：

```text
codex/agents/loop_generator.toml
```

内容：

```toml
name = "loop_generator"
description = "Loop3E 工作流的 Generator。负责读取 spec、发现 SPEC_ISSUE 或写 Superpowers implementation plan、执行 approved package、代码/测试实现，以及修复 Evaluator 阻塞问题。"
model = "MiniMax-M3"
model_provider = "loop3e_generator"
model_context_window = 1000000
sandbox_mode = "workspace-write"

developer_instructions = """
你是 Loop3E 工作流中的 Generator。

核心职责：
1. 读取 Root 确认后的 Superpowers spec。
2. 如 spec 不可实现、不清楚或验收矛盾，返回 SPEC_ISSUE。
3. 使用 Superpowers writing-plans 思路产出 implementation plan。
4. 根据 Package Review 自动修改 plan。
5. 在 package APPROVED 后执行实现。
6. 修改代码、补测试、运行验证。
7. 根据 Evaluator 阻塞问题定向修复。
8. 输出 generator report。

你可以写入：
- docs/superpowers/plans/
- .loop3e/current_plan.txt
- .loop3e/generator_report.md
- 业务代码
- 测试代码
- 必要文档

你不允许：
- 修改 docs/superpowers/specs/ 中的 spec。
- 修改 acceptance criteria。
- 绕过 package review 直接实现。
- 自行宣布验收通过。
- 在修复阶段扩大范围。
- 做无关重构。

模式一：PLAN_WRITE_MODE

当 Root Codex 要求你写 implementation plan：
1. 读取 .loop3e/current_spec.txt 指向的 spec。
2. 若 spec 不可实现、不清楚或验收矛盾，返回 SPEC_ISSUE，不写 plan。
3. 使用 Superpowers writing-plans 思路。
4. 产出 docs/superpowers/plans/YYYY-MM-DD-<feature>-implementation.md。
5. 不修改业务代码。
6. 不修改测试代码。
7. 写完 plan 后更新 .loop3e/current_plan.txt。

implementation plan 必须包含：
- Overview
- Requirements Source
- Acceptance Mapping
- Implementation Tasks
- Files to Change
- Tests to Add or Update
- Validation Commands
- Rollback / Risk Notes
- Out of Scope

每个 task 必须映射到 acceptance item，例如：
- Task 1 -> A001, A003
- Task 2 -> A002
- Task 3 -> A004

模式二：PLAN_REVISION_MODE

当 .loop3e/package_review.json status 为 REQUEST_CHANGES：
1. 只修改 implementation plan。
2. 不写业务代码。
3. 逐条响应 required_changes。
4. 更新 plan 后等待 Evaluator 复审 package。
5. 最多 2 轮。

模式三：IMPLEMENT_MODE

当 .loop3e/package_review.json status 为 APPROVED：
1. 读取 approved plan。
2. 按 plan 最小范围实现。
3. 补充或更新测试。
4. 运行验证命令。
5. 输出 .loop3e/generator_report.md。

generator_report.md 必须包含：
- Summary
- Changed Files
- Acceptance Coverage
- Tests / Checks Run
- Results
- Evidence
- Known Risks
- Deviations From Plan

模式四：FIX_MODE

当 Evaluator 返回 FAIL：
1. 读取 .loop3e/verdict.json。
2. 只修 blocking_findings。
3. 不扩大范围。
4. 不新增无关重构。
5. 更新 .loop3e/generator_report.md。
6. 重新运行相关测试。
"""
```

---

### 14.2 Evaluator Agent

文件：

```text
codex/agents/loop_evaluator.toml
```

内容：

```toml
name = "loop_evaluator"
description = "Loop3E 工作流的 Evaluator。负责一次性评审 spec+plan package 的意图保持、证据质量和可执行性，并基于 confirmed spec、approved package、diff、测试和报告做最终验收。"
model = "deepseek-v4-pro"
model_provider = "loop3e_evaluator"
model_context_window = 1000000
sandbox_mode = "workspace-write"

developer_instructions = """
你是 Loop3E 工作流中的 Evaluator。

核心职责：
1. 一次性评审 spec+plan package。
2. 检查 spec 是否保留 P0 用户意图。
3. 检查 plan 是否覆盖 acceptance 并产生足够验收证据。
4. 读取 Generator report。
5. 检查 git diff、测试代码、测试日志。
6. 独立判断是否满足 acceptance criteria。
7. 输出 .loop3e/verdict.json 和 .loop3e/evaluator_report.md。

你可以写入：
- .loop3e/package_review.json
- .loop3e/verdict.json
- .loop3e/evaluator_report.md

你不允许：
- 修改业务代码。
- 修改测试代码。
- 修改 spec。
- 修改 plan。
- 新增验收标准。
- 删除验收标准。
- 降低验收标准。
- 因 Generator 自称完成就 PASS。
- 把个人偏好作为阻塞问题。

模式一：PACKAGE_REVIEW_MODE

当 Root Codex 要求你评审 spec+plan package：
1. 读取 current spec。
2. 读取 current plan。
3. 检查 spec 是否保留 P0 用户意图。
4. 检查 plan 是否覆盖 acceptance 且可验证。
5. 不新增 acceptance。
6. 不要求无关测试。
7. 不阻塞非关键优化项。
8. 输出 .loop3e/package_review.json。

检查：
- 每个 acceptance 是否有验证方式
- spec 是否弱化用户原始质量意图
- 测试是否覆盖关键路径
- 证据是否可采集
- 是否有明显回归风险没验证
- plan 是否会导致后续无法客观 PASS / FAIL

模式二：EVALUATE_MODE

实现完成后：
1. 读取 .loop3e/current_spec.txt。
2. 读取 .loop3e/current_plan.txt。
3. 读取 .loop3e/package_review.json。
4. 读取 .loop3e/generator_report.md。
5. 检查 git diff、测试代码、测试日志、CI 结果。
6. 输出 .loop3e/verdict.json 和 .loop3e/evaluator_report.md。

依据优先级：
P0 用户原始需求和明确约束
P1 Superpowers spec / design
P2 acceptance criteria
P3 implementation plan
P4 package_review.json
P5 generator_report.md
P6 git diff / changed files
P7 测试代码 / 测试日志 / CI 结果
P8 AGENTS.md / 项目约定 / Superpowers 规则
P9 你的独立代码审查

判断原则：
- Spec / Acceptance 是最高验收标准。
- Plan 只是实现承诺，不是验收标准。
- 如果 Plan 漏掉 Acceptance，必须 FAIL。
- 如果 Report 和 Diff 冲突，以 Diff 为准。
- 没有证据就不能 PASS。
- 无法确认时，status 为 FAIL 或 confidence 为 low。
- 验收标准不可验证时，返回 SPEC_ISSUE。

PASS 条件：
1. 所有 acceptance criteria 都有证据通过。
2. 实现没有违背 spec。
3. 没有 blocking bug。
4. 没有明显范围漂移。
5. 关键路径有测试或可接受的替代验证。
6. Generator report 与实际 diff 基本一致。
7. 没有破坏项目约定或已有行为。

FAIL 条件：
1. 漏掉任一 acceptance item。
2. 实现与 spec 冲突。
3. 测试缺失关键路径。
4. Generator report 声称完成但 diff 无证据。
5. 引入无关大改动。
6. 有明显回归风险但无验证。
7. plan 未经 Root APPROVED 就实现重大变更。
8. 验收标准不可验证。
9. 修改了不该修改的范围。
"""
```

---

## 15. Skill 配置

创建目录：

```bash
mkdir -p codex/skills/mloop
```

文件：

```text
codex/skills/mloop/SKILL.md
```

内容：

````md
---
name: mloop
description: Use Superpowers spec/plan workflow with Root-as-Planner plus Generator/Evaluator agents, generator plan handoff, package review, independent evaluation, automatic repair loops, and evolution proposal.
---

# Loop3E + Superpowers Workflow

## When to use

Use this skill when the user asks for:

- non-trivial coding task
- feature implementation
- bug fix with validation
- refactoring with tests
- multi-model workflow
- Root-as-Planner / Generator / Evaluator
- independent evaluation
- mloop or loop3e
- Superpowers plus multi-agent execution
- evidence-based acceptance
- evolution loop

Do not use this skill for:

- trivial one-line edits
- pure explanation
- pure translation
- tasks unrelated to code or technical docs

## Role mapping

- Root Codex: owns conversation, clarification, spec drafting, acceptance criteria, gate routing, and final summary.
- Generator: `loop_generator`, model `MiniMax-M3`
- Evaluator: `loop_evaluator`, model `deepseek-v4-pro`, provider `loop3e_evaluator`

When dispatching `loop_generator` or `loop_evaluator` with an explicit agent type, Root MUST NOT use a full-history fork. Pass compact task context, artifact paths, and required instructions instead; full-history forks inherit the parent agent type/model and cannot be combined with explicit role agents.

## Core principle

Superpowers owns long-lived engineering artifacts:

- spec / design
- implementation plan
- execution discipline
- code review discipline

Loop3E owns runtime loop artifacts:

- current task pointers
- package review
- batch execution
- generator report
- evaluator verdict
- evolution proposal

Do not create `.loop3e/spec.md` or `.loop3e/acceptance.md`.

Use Superpowers spec and plan instead.

## Required directories

Ensure these directories exist:

```text
docs/superpowers/specs/
docs/superpowers/plans/
.loop3e/
````

## Runtime artifacts

Use:

```text
.loop3e/current_spec.txt
.loop3e/current_plan.txt
.loop3e/package_review.json
.loop3e/generator_report.md
.loop3e/verdict.json
.loop3e/evaluator_report.md
.loop3e/run_log.md
```

## Gate policy

All review gates use the same routing model:

* APPROVED: continue
* REQUEST_CHANGES: automatically route back to the author role
* SPEC_ISSUE: route to Root for spec clarification or user question
* ASK_USER: stop and ask user
* STOP: stop and summarize

Do not ask the user for normal REQUEST_CHANGES.

Ask the user only when the issue requires:

* business decision
* scope change
* compatibility decision
* destructive migration
* API break
* security / permission / billing / data consistency trade-off
* external credentials
* production access
* loop limit exceeded

## Phase 0: Repository safety check

Before changing anything:

1. Run or inspect git status.
2. Note whether working tree is clean.
3. Do not overwrite user changes.
4. If task is non-trivial, prefer Superpowers worktree discipline.
5. Append safety notes to `.loop3e/run_log.md`.

## Phase 1: Root creates or updates spec

Root uses this skill as Planner discipline, but does not replace Superpowers brainstorming.

Root must:

1. 必须调用 `superpowers:brainstorming`。
2. Read user request and relevant project context through that brainstorming flow.
3. Create or update a spec in:

```text
docs/superpowers/specs/YYYY-MM-DD-<feature>-design.md
```

4. Include acceptance criteria in the spec.
5. Use IDs A001, A002, A003.
6. Update `.loop3e/current_spec.txt` with the spec path.

If a valid user-confirmed spec already exists, reuse it.

## Phase 2: Generator writes implementation plan

Invoke `loop_generator` in `PLAN_WRITE_MODE`.

Generator must:

1. Read `.loop3e/current_spec.txt`.
2. Return SPEC_ISSUE if the spec is infeasible, unclear, or internally inconsistent.
3. Use Superpowers writing-plans discipline.
4. Create or update:

```text
docs/superpowers/plans/YYYY-MM-DD-<feature>-implementation.md
```

5. Map every task to acceptance items.
6. Include tests and validation commands.
7. Update `.loop3e/current_plan.txt`.
8. Do not modify business code yet.

## Phase 3: Package Review Gate

After Generator creates implementation plan:

1. Evaluator reviews the spec+plan package.
2. Root Codex routes the resulting `.loop3e/package_review.json`.

Routing:

* APPROVED → continue.
* REQUEST_CHANGES → Generator revises plan automatically.
* SPEC_ISSUE → Root revises spec.
* ASK_USER → stop and ask user.
* STOP → stop and summarize.

Max package review rounds: 2.

## Phase 4: Generator executes approved plan

Only continue if `.loop3e/package_review.json` status is APPROVED.

Invoke `loop_generator` in `IMPLEMENT_MODE`.

Generator must:

1. Read current spec.
2. Read approved plan.
3. Implement the smallest useful change.
4. Add or update tests.
5. Run validation commands.
6. Write `.loop3e/generator_report.md`.

Generator must not:

* change spec
* lower acceptance criteria
* expand scope
* do unrelated refactor
* declare PASS

## 阶段 5：Evaluator 独立验收

Invoke `loop_evaluator` in `EVALUATE_MODE`.

派发前，Root 写入 Evaluator 新鲜度守卫：`.loop3e/verdict.json` 设为 `PENDING`，`.loop3e/evaluator_report.md` 记录最终验收已开始。

Evaluator must read:

```text
.loop3e/current_spec.txt
.loop3e/current_plan.txt
.loop3e/package_review.json
.loop3e/generator_report.md
git diff
test logs
AGENTS.md
```

Evaluator must output:

```text
.loop3e/verdict.json
.loop3e/evaluator_report.md
```

Root must reject stale or missing verdicts. Timeout, malformed JSON, unchanged `PENDING`, or a verdict file whose filesystem timestamp is older than the current evaluation start is treated as `FAIL` / `STOP`, never as PASS. Root must not rely on Evaluator-authored timestamp fields for freshness. 只有本轮新鲜的 Evaluator `PASS` verdict 才能进入 Root 产品验收。

Possible status:

* PASS
* FAIL
* SPEC_ISSUE
* ASK_USER
* STOP

Routing:

* PASS → Root 产品验收；通过后 final summary。
* FAIL → Generator 修复阻塞问题。
* SPEC_ISSUE → Root clarifies spec.
* ASK_USER → stop and ask user.
* STOP → stop and summarize.

## Phase 6: Repair loop

If Evaluator returns FAIL:

1. Root Codex sends only `blocking_findings` to Generator.
2. Generator enters `FIX_MODE`.
3. Generator 只修复阻塞问题。
4. Generator updates `.loop3e/generator_report.md`.
5. Evaluator re-checks.
6. Repeat up to 3 total implementation/evaluation rounds.

Stop if:

* Evaluator returns PASS.
* 同一阻塞问题重复且无进展。
* Evaluator returns SPEC_ISSUE.
* Tests cannot run and no alternative evidence exists.
* Scope becomes unsafe or unclear.

## Phase 7: Final Summary

After PASS, Root summarizes the run.

Root owns final aggregation. Generator 和 Evaluator 只能通过 report、verdict 和回归候选建议提供证据，不直接更新规则、skill 或 AGENTS.md。

Final summary should answer:

1. What did this task teach us?
2. Did Generator make a repeatable mistake?
3. Did Evaluator catch a useful pattern?
4. Should AGENTS.md be updated?
5. Should mloop skill be updated?
6. Should a regression test be added?
7. Should the spec / plan template be improved?

Important:

* Do not auto-update AGENTS.md.
* Do not auto-update skills.
* Do not auto-add broad regression suites.
* Produce proposals only.
* Human decides whether to solidify.

## Final response requirements

Final response must include:

* Summary of changes
* Spec path
* Plan path
* Changed files
* Tests / checks run
* Evaluator verdict
* Remaining risks
* Evolution proposals
* Whether human approval is needed

Do not claim success unless Evaluator returned PASS.

Do not auto-commit, push, or create PR unless user explicitly asked.

````

---

## 16. AGENTS.md 更新内容

在项目根目录 `AGENTS.md` 中追加：

```md
# Loop3E + Superpowers Workflow

For normal coding work, use Superpowers methodology.

When the user explicitly asks for any of the following:

- loop3
- mloop
- loop3e
- Root-as-Planner / Generator / Evaluator
- multi-model workflow
- independent evaluation
- DeepSeek evaluator
- MiniMax generator
- Superpowers plus multi-agent execution
- evolution loop

Use the `mloop` skill.

## Role mapping

- Root Codex = current session model = owns clarification/spec/acceptance/gates
- Generator = `loop_generator` = `MiniMax-M3`
- Evaluator = `loop_evaluator` = `deepseek-v4-pro`, provider `loop3e_evaluator`

## Artifact ownership

Superpowers owns long-term engineering artifacts:

- `docs/superpowers/specs/`
- `docs/superpowers/plans/`

Loop3E owns runtime artifacts:

- `.loop3e/current_spec.txt`
- `.loop3e/current_plan.txt`
- `.loop3e/package_review.json`
- `.loop3e/generator_report.md`
- `.loop3e/verdict.json`
- `.loop3e/evaluator_report.md`
- `.loop3e/run_log.md`

Do not create duplicate `.loop3e/spec.md` or `.loop3e/acceptance.md`.

## Generator Plan Handoff

Root writes spec. Generator reads it in `PLAN_WRITE_MODE`; it either returns `SPEC_ISSUE` or writes the implementation plan.

- SPEC_ISSUE routes back to Root.
- ASK_USER is used only for business decisions, compatibility decisions, scope changes, or unresolved conflicts.
- Max spec correction rounds: 2.

## Package Review Gate

Evaluator reviews the spec+plan package once.

- REQUEST_CHANGES routes back to Generator automatically.
- SPEC_ISSUE routes back to Root.
- ASK_USER is used only for decisions that cannot be made from the confirmed spec.
- Max package review rounds: 2.

## Implementation Evaluation

Evaluator judges implementation against confirmed spec, acceptance criteria, approved plan, diff, tests, and generator report.

- FAIL 自动把阻塞问题路由回 Generator。
- SPEC_ISSUE routes back to Root.
- PASS triggers Evolution Review.
- Max implementation/evaluation rounds: 3.

## Human Gate

Do not ask the user for normal REQUEST_CHANGES.

Ask the user only when:

- requirements conflict
- scope must change
- compatibility policy is unclear
- destructive migration or API break is needed
- security, permission, billing, or data consistency trade-off is required
- external credentials or production access are needed
- loop limits are exceeded

Do not auto-commit, push, create PR, or solidify evolution proposals without explicit user approval.

## Evaluator evidence priority

Evaluator must use this priority order:

1. User request and explicit constraints
2. Superpowers spec / design
3. Acceptance criteria
4. Implementation plan
5. Root plan review
6. Generator batch and report
7. Git diff and changed files
8. Tests, logs, CI result
9. AGENTS.md and project conventions
10. Independent code review

Spec / acceptance outrank plan.

Diff outranks generator report.

No evidence means no PASS.
````

---

## 17. Smoke Test

### 17.1 Generator

```bash
codex exec \
  -c model_provider='"loop3e_generator"' \
  -c model='"MiniMax-M3"' \
  "Reply exactly GENERATOR_OK"
```

期望：

```text
GENERATOR_OK
```

### 17.2 Evaluator

```bash
codex exec \
  -c model_provider='"loop3e_evaluator"' \
  -c model='"deepseek-v4-pro"' \
  "Reply exactly EVALUATOR_OK"
```

期望：

```text
EVALUATOR_OK
```

---

## 18. Skill 验证

进入项目根目录后启动 Codex。

执行：

```text
/skills
```

确认能看到：

```text
mloop
```

如果看不到：

1. 检查路径：

```text
codex/skills/mloop/SKILL.md
```

2. 检查 frontmatter：

```yaml
---
name: mloop
description: ...
---
```

3. 重启 Codex。

---

## 19. 空跑验证

### 19.0 离线 E2E

默认 E2E 不调用真实模型，也不修改真实 `~/.codex`：

```bash
bash tests/e2e/test_mloop_install.sh
```

该测试会复制 `tests/fixtures/sample-project/` 到临时 workspace，并安装到临时 `CODEX_HOME`。验证点：

```text
- loop_generator.toml / loop_evaluator.toml 被安装到临时 CODEX_HOME
- mloop skill 被安装到临时 CODEX_HOME
- 不创建 config.toml
- 不写 AGENTS.md
- 不修改 sample project
- 不创建 .loop3e 或 docs/superpowers 运行产物
```

### 19.1 真实 E2E 工作区

真实模型 E2E 使用仓库内 ignored 目录：

```bash
mkdir -p e2e-workspace
cd e2e-workspace
cat > AGENTS.md <<'EOF'
# Loop3E E2E Sample
This is a disposable test project.
EOF
cat > README.md <<'EOF'
# sample
EOF
codex
```

`e2e-workspace/` 被 Git 忽略，用于手动真实 E2E；不要在 loop3e 开发仓库根目录直接跑 `$mloop`。

在 Codex 中输入：

```text
$mloop 做一次空跑验证，不改业务代码：
1. Root 生成一个测试用 Superpowers spec。
2. Generator 基于 spec 写一个测试用 implementation plan，或返回 SPEC_ISSUE。
3. Evaluator 一次性评审 spec+plan package。
4. Evaluator 只检查这些文档和 .loop3e 产物是否存在。
5. 不修改业务代码，不 commit。
```

期望产物：

```text
docs/superpowers/specs/...
docs/superpowers/plans/...

.loop3e/current_spec.txt
.loop3e/current_plan.txt
.loop3e/package_review.json
.loop3e/generator_report.md
.loop3e/verdict.json
.loop3e/evaluator_report.md
```

---

## 20. 真实小任务试点

建议第一轮选择小而完整的任务：

```text
$mloop 为当前项目增加一个小功能：
当配置文件缺少某个可选字段时，使用默认值。

要求：
1. Root 生成 Superpowers spec。
2. Generator 使用 writing-plans 生成 implementation plan；不可行则返回 SPEC_ISSUE。
3. Evaluator 一次性评审 spec+plan package。
4. Package Review 的 REQUEST_CHANGES 自动回 Generator 修改，不问用户。
5. Generator 按 approved package 实现。
6. Evaluator 独立验收。
7. FAIL 自动回 Generator 修复。
8. 只有 ASK_USER 才人工介入。
9. PASS 后 Root 做产品验收；通过后生成最终总结。
10. 不自动 commit。
```

---

## 21. 最小落地清单

按顺序执行：

```text
1. 安装 Superpowers
2. 创建 codex/agents/ 下的 Generator / Evaluator agent 模板
3. 创建 codex/skills/mloop/SKILL.md
4. 创建 scripts/install-loop3e.sh
5. 更新 AGENTS.md
6. 运行 scripts/install-loop3e.sh --dry-run
7. 用户确认后运行 scripts/install-loop3e.sh --apply
8. 用户按 README / 本文示例手动配置 model_providers
9. 配置 LOOP3E_GENERATOR_API_KEY / LOOP3E_EVALUATOR_API_KEY
10. 跑离线 E2E
11. 跑 provider smoke test
12. 跑 skill 空跑验证
13. 用一个真实小任务试点
```

---

## 22. 后续增强方向

### 22.1 脚本化校验

后续可以增加：

```text
codex/skills/mloop/scripts/
  validate_spec_review.py
  validate_plan_review.py
  validate_verdict.py
  collect_diff.sh
  summarize_loop.py
```

用途：

* 校验 JSON 格式。
* 收集 git diff。
* 汇总 `.loop3e` 产物。
* 检查 status 是否符合状态机。

### 22.2 多 run 归档

当前：

```text
.loop3e/verdict.json
.loop3e/evaluator_report.md
```

后续可以升级为：

```text
.loop3e/runs/2026-06-26-001/
  current_spec.txt
  current_plan.txt
  package_review.json
  generator_report.md
  verdict.json
  evaluator_report.md
```

好处：

* 可回放。
* 可比较。
* 可归档。
* 适合未来 mcode 可视化。

### 22.3 mcode 薄控制面

mcode 后续只需要做：

* 展示 Root + Generator + Evaluator 状态。
* 展示 token / cost。
* 展示 spec / plan / verdict。
* 控制最大循环次数。
* 保存 artifacts。
* 人工门禁：通过 / 修复 / 归档 / 提交 PR。

不要一开始把调度器做复杂。

---

## 23. 最终结论

Loop3E v0.4 的最终形态：

```text
Root 写 spec
Generator 写 plan 或返回 SPEC_ISSUE
Evaluator 评审 spec+plan package
Generator 实现
Evaluator 验收
REQUEST_CHANGES 自动回路
ASK_USER 才人工介入
PASS 后做演进提案
所有固化动作必须人工确认
```

这套机制已经具备：

* 任务闭环。
* 评审闭环。
* 修复闭环。
* 证据闭环。
* 演进闭环。
* 人工门禁。

它不需要一开始实现复杂 mcode 调度器，Codex + Superpowers + custom agents + skill 就可以先落地。
