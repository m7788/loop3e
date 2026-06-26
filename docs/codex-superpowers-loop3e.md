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
- spec review
- plan review
- implementation evaluation
- repair loop
- evolution proposal

.loop3e 只保存运行态产物，不重复保存 spec / acceptance。
```

---

## 2. 一句话流程

```text
Root 按 mloop skill 写 spec；
Evaluator + Generator 评审 spec；
Generator 写 implementation plan；
Root + Evaluator 评审 plan；
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
Spec Review Gate
  ├─ Evaluator Review：可验收性 / 可验证性
  ├─ Generator Review：可实现性 / 技术风险
  └─ Root Codex 汇总
      ├─ APPROVED → 下一步
      ├─ REQUEST_CHANGES → Root 自动修改 spec
      ├─ ASK_USER → 用户裁决
      └─ STOP → 停止
  ↓
Generator 写 Superpowers implementation plan
  ↓
Dual Plan Review Gate
  ├─ Root Review：是否符合 spec / acceptance
  ├─ Evaluator Review：是否可验证 / 测试证据是否足够
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
  ├─ FAIL → Generator 自动修 blocking findings
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

### 4.1 Root Checkpoint Output

Root 在每个 gate 后输出短 checkpoint，让用户不打开文件也能掌握状态。

```text
<Phase>: <STATUS>
- artifact: <path>
- blocking: <none|count and short reason>
- next: <next action>
```

普通 checkpoint 不超过 6 行；只有 `ASK_USER`、`STOP`、`FAIL` 或用户要求详情时才展开。

### 4.2 Superpowers 6 Skill Map

Loop3E 不是替代 Superpowers，而是调度这些 Superpowers skill：

| 阶段 | Superpowers skill | 使用规则 |
| --- | --- | --- |
| 技能纪律 | `superpowers:using-superpowers` | mloop 启动时必须先调用；它负责技能调用纪律，但不替代下面的阶段门禁 |
| 需求澄清 | `superpowers:brainstorming` | 写 spec 前必须调用 |
| Plan 生成 | `superpowers:writing-plans` | Generator 写 implementation plan 前必须调用 |
| Plan 执行 | `superpowers:subagent-driven-development` / `superpowers:executing-plans` | approved plan 执行时二选一；按任务独立性和可用 subagent 选择 |
| 执行隔离 | `superpowers:using-git-worktrees` | 条件使用；只有需要隔离或执行 skill 要求时触发，不静默改环境 |
| 代码实现 | `superpowers:test-driven-development` | 条件使用；代码行为变更时由 `using-superpowers` 触发 |
| 实现评审 | `superpowers:requesting-code-review` | 条件使用；重大 code diff 或用户要求额外 review 时触发 |
| 评审反馈处理 | `superpowers:receiving-code-review` | 条件使用；处理 review / Evaluator findings 时触发 |
| 修复失败 | `superpowers:systematic-debugging` | 条件使用；bugfix、测试失败、异常行为或 Evaluator `FAIL` 时触发 |
| 完成声明 | `superpowers:verification-before-completion` | 任何完成声明前必须调用 |
| 收尾选择 | `superpowers:finishing-a-development-branch` | 用户要求 merge / PR / cleanup 时使用；mloop 默认只报告，不进入集成菜单 |
| 并行探索 | `superpowers:dispatching-parallel-agents` | 仅 2+ 独立问题域且不会编辑同一批文件时考虑 |

---

## 5. 角色职责

### 5.1 Root Codex / Orchestrator

职责：

* 接收用户需求。
* 判断是否需要 Loop3E。
* 启动 Superpowers 方法论。
* 按 mloop skill 承担 Planner 能力：澄清需求、写 spec、定义 acceptance。
* 调度 Generator / Evaluator。
* 维护 `.loop3e/` 运行态产物。
* 汇总 review / verdict。
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
* 定义 acceptance criteria。
* 根据 Spec Review 自动修改 spec。
* 评审 Generator 的 implementation plan 是否符合 spec。
* 处理 Evaluator 返回的 `SPEC_ISSUE`。
* PASS 后参与 Evolution Review。

不允许：

* 写业务代码。
* 写 implementation plan。
* 代替 Generator 选择具体实现步骤。
* 绕过 Evaluator + Generator 的 spec review。
* 降低 acceptance criteria。
* 在实现后随意扩大需求。

---

### 5.3 Generator

模型：

```text
MiniMax-M3
```

职责：

* 评审 spec 的技术可行性。
* 使用 Superpowers writing-plans 思路写 implementation plan。
* 根据 Plan Review 自动修改 plan。
* 按 approved plan 实现代码。
* 补测试、跑验证命令。
* 根据 Evaluator blocking findings 自动修复。
* 输出 generator report。

不允许：

* 修改 spec / acceptance。
* 绕过 plan review 直接实现。
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

职责：

* 评审 spec 是否可验收、可验证。
* 评审 plan 是否能产生足够验收证据。
* 独立检查 diff / tests / report。
* 根据 confirmed spec / acceptance 输出 PASS / FAIL。
* 发现 spec 问题时返回 `SPEC_ISSUE`。
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

  spec_review.json
  spec_review.md

  plan_review.json
  plan_review.md

  current_batch.md
  generator_report.md

  verdict.json
  evaluator_report.md

  lessons.md
  evolution_proposal.md
  rule_update_proposal.md
  regression_candidates.md

  run_log.md
```

| 文件                               | 作用                                 |
| -------------------------------- | ---------------------------------- |
| `.loop3e/current_spec.txt`         | 当前 Superpowers spec 路径             |
| `.loop3e/current_plan.txt`         | 当前 Superpowers plan 路径             |
| `.loop3e/spec_review.json`         | Evaluator + Generator 对 spec 的评审结果 |
| `.loop3e/spec_review.md`           | spec review 文字说明                   |
| `.loop3e/plan_review.json`         | Root + Evaluator 对 plan 的评审结果   |
| `.loop3e/plan_review.md`           | plan review 文字说明                   |
| `.loop3e/current_batch.md`         | Generator 本轮执行切片                   |
| `.loop3e/generator_report.md`      | Generator 实现和测试报告                  |
| `.loop3e/verdict.json`             | Evaluator 最终验收结论                   |
| `.loop3e/evaluator_report.md`      | Evaluator 详细验收报告                   |
| `.loop3e/lessons.md`               | 本次任务经验                             |
| `.loop3e/evolution_proposal.md`    | 演进建议                               |
| `.loop3e/rule_update_proposal.md`  | 规则更新建议                             |
| `.loop3e/regression_candidates.md` | 回归测试候选                             |
| `.loop3e/run_log.md`               | 调度记录                               |

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
| `FAIL`            | 实现未通过                 | Generator 修 blocking findings |

---

## 8. 自动闭环规则

### 8.1 默认自动修改

```text
Spec Review 不通过 → Root 自动修改 spec
Plan Review 不通过 → Generator 自动修改 plan
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
| Spec Review 修改         |       2 轮 |
| Plan Review 修改         |       2 轮 |
| Implementation 修复      |       3 轮 |
| 同一 blocking finding 重复 | 2 次后 STOP |

---

## 9. Spec Review Gate

### 9.1 目的

避免 Root 写 spec 后直接进入 plan。

Spec Review Gate 回答：

```text
这个 spec 是否可验收？
这个 spec 是否可实现？
这个 spec 是否需要用户裁决？
```

### 9.2 Evaluator 评审 spec

Evaluator 只看可验收性和可验证性。

检查项：

```text
1. Acceptance criteria 是否可验证
2. 是否有明确 PASS / FAIL 条件
3. 是否存在“尽快、良好、合理”等模糊词
4. 是否缺少关键边界条件
5. 验收项之间是否冲突
6. 是否能通过测试、日志、diff 或运行结果证明
```

Evaluator 不评审业务方向，不新增需求。

### 9.3 Generator 评审 spec

Generator 只看可实现性和技术风险。

检查项：

```text
1. 当前架构是否支持
2. 是否缺少关键输入信息
3. 是否需要高风险迁移
4. 技术约束是否冲突
5. 是否应该拆分阶段
6. 是否存在实现成本明显过高的点
```

Generator 不评审需求是否值得做。

### 9.4 spec_review.json 格式

通过示例：

```json
{
  "status": "APPROVED",
  "round": 1,
  "evaluator_review": {
    "status": "APPROVED",
    "verifiability_issues": [],
    "missing_acceptance_items": [],
    "ambiguous_items": [],
    "required_changes": []
  },
  "generator_review": {
    "status": "APPROVED",
    "feasibility_issues": [],
    "technical_risks": [],
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
    "verifiability_issues": [
      "A002 使用“快速恢复”作为验收标准，不可测量"
    ],
    "missing_acceptance_items": [],
    "ambiguous_items": [
      "A002"
    ],
    "required_changes": [
      {
        "id": "SR-E001",
        "problem": "验收标准不可验证",
        "required_fix": "将“快速恢复”改成可观察行为或明确时间阈值"
      }
    ]
  },
  "generator_review": {
    "status": "APPROVED",
    "feasibility_issues": [],
    "technical_risks": [],
    "required_changes": []
  },
  "root_decision": {
    "status": "REQUEST_CHANGES",
    "need_user_confirmation": false,
    "notes": [
      "该问题属于验收表达不清，可由 Root 自动修正"
    ]
  }
}
```

需要人工示例：

```json
{
  "status": "ASK_USER",
  "round": 1,
  "evaluator_review": {
    "status": "APPROVED",
    "verifiability_issues": [],
    "required_changes": []
  },
  "generator_review": {
    "status": "REQUEST_CHANGES",
    "feasibility_issues": [
      "保持旧接口完全兼容与字段全部重命名存在冲突"
    ],
    "technical_risks": [
      "可能需要破坏性 API 变更"
    ],
    "required_changes": [
      {
        "id": "SR-G001",
        "problem": "兼容性策略需要业务裁决",
        "required_fix": "确认是否允许破坏旧接口，或采用双字段兼容期"
      }
    ]
  },
  "root_decision": {
    "status": "ASK_USER",
    "need_user_confirmation": true,
    "notes": [
      "需要用户确认兼容策略"
    ]
  }
}
```

---

## 10. Dual Plan Review Gate

### 10.1 目的

避免 Generator 写完 plan 后直接实现。

Dual Plan Review Gate 回答：

```text
这个 plan 是否符合 spec？
这个 plan 将来是否能被证明完成？
```

### 10.2 Root 评审 plan

Root 只看需求一致性。

检查项：

```text
1. 是否覆盖所有 acceptance criteria
2. 是否漏掉用户明确要求
3. 是否范围漂移
4. 是否做了 non-goals
5. 是否过度设计
6. 是否违背用户约束
```

### 10.3 Evaluator 评审 plan

Evaluator 只看可验证性。

检查项：

```text
1. 每个 acceptance 是否有验证方式
2. 测试是否覆盖关键路径
3. 证据是否可采集
4. 是否有明显回归风险没有验证
5. 是否存在不可验收的模糊点
6. plan 是否会导致后续无法客观 PASS / FAIL
```

### 10.4 plan_review.json 格式

Generator 必须读取 `.loop3e/plan_review.json`。只有 `status=APPROVED` 才能进入实现；`REQUEST_CHANGES` 只能回到 plan 修订；`SPEC_ISSUE`、`ASK_USER`、`STOP` 必须停下交给 Root 路由。

通过示例：

```json
{
  "status": "APPROVED",
  "round": 1,
  "planner_review": {
    "status": "APPROVED",
    "focus": "spec_alignment",
    "missing_items": [],
    "scope_drift": [],
    "required_changes": []
  },
  "evaluator_review": {
    "status": "APPROVED",
    "focus": "verifiability",
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
  "planner_review": {
    "status": "APPROVED",
    "focus": "spec_alignment",
    "missing_items": [],
    "scope_drift": [],
    "required_changes": []
  },
  "evaluator_review": {
    "status": "REQUEST_CHANGES",
    "focus": "verifiability",
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
P4 plan_review.json
P5 current_batch.md
P6 generator_report.md
P7 git diff / changed files
P8 测试代码 / 测试日志 / CI 结果
P9 AGENTS.md / 项目约定
P10 Evaluator 独立代码审查
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

### 12.1 Spec Review 路由

| 状态                | 修改者     | 是否问用户 |
| ----------------- | ------- | ----: |
| `APPROVED`        | 无       |     否 |
| `REQUEST_CHANGES` | Root |     否 |
| `ASK_USER`        | 用户裁决    |     是 |
| `STOP`            | Root 汇总 |     是 |

### 12.2 Plan Review 路由

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
description = "Generator for Loop3E workflow. Reviews spec feasibility, writes Superpowers implementation plans, executes approved plans, implements code, tests, and fixes evaluator blocking findings."
model = "MiniMax-M3"
model_provider = "loop3e_generator"
model_context_window = 1000000
sandbox_mode = "workspace-write"

developer_instructions = """
你是 Loop3E 工作流中的 Generator。

核心职责：
1. 评审 spec 的技术可行性。
2. 读取 Root 确认后的 Superpowers spec。
3. 使用 Superpowers writing-plans 思路产出 implementation plan。
4. 根据 Plan Review 自动修改 plan。
5. 在 plan APPROVED 后执行实现。
6. 修改代码、补测试、运行验证。
7. 根据 Evaluator blocking findings 定向修复。
8. 输出 generator report。

你可以写入：
- docs/superpowers/plans/
- .loop3e/current_plan.txt
- .loop3e/current_batch.md
- .loop3e/generator_report.md
- 业务代码
- 测试代码
- 必要文档

你不允许：
- 修改 docs/superpowers/specs/ 中的 spec。
- 修改 acceptance criteria。
- 绕过 plan review 直接实现。
- 自行宣布验收通过。
- 在修复阶段扩大范围。
- 做无关重构。

模式一：SPEC_REVIEW_MODE

当 Root Codex 要求你评审 spec：
1. 读取 .loop3e/current_spec.txt。
2. 只评审技术可行性和技术风险。
3. 不修改 spec。
4. 输出 generator_review 部分。
5. 如果只是技术风险，写 technical_risks。
6. 如果需要用户裁决，标记 need_user_confirmation。
7. 不评审需求是否值得做。

模式二：PLAN_WRITE_MODE

当 Root Codex 要求你写 implementation plan：
1. 读取 .loop3e/current_spec.txt 指向的 spec。
2. 使用 Superpowers writing-plans 思路。
3. 产出 docs/superpowers/plans/YYYY-MM-DD-<feature>-implementation.md。
4. 不修改业务代码。
5. 不修改测试代码。
6. 写完 plan 后更新 .loop3e/current_plan.txt。

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

模式三：PLAN_REVISION_MODE

当 .loop3e/plan_review.json status 为 REQUEST_CHANGES：
1. 只修改 implementation plan。
2. 不写业务代码。
3. 逐条响应 required_changes。
4. 更新 plan 后等待 Root + Evaluator 复审。
5. 最多 2 轮。

模式四：IMPLEMENT_MODE

当 .loop3e/plan_review.json status 为 APPROVED：
1. 读取 approved plan。
2. 生成 .loop3e/current_batch.md，说明本轮要执行哪些 task。
3. 按 plan 最小范围实现。
4. 补充或更新测试。
5. 运行验证命令。
6. 输出 .loop3e/generator_report.md。

generator_report.md 必须包含：
- Summary
- Changed Files
- Acceptance Coverage
- Tests / Checks Run
- Results
- Evidence
- Known Risks
- Deviations From Plan

模式五：FIX_MODE

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
description = "Evaluator for Loop3E workflow. Reviews spec verifiability, reviews plan evidence quality, and independently verifies implementation against confirmed spec, acceptance criteria, approved plan, diff, tests, and reports."
model = "deepseek-v4-pro"
model_provider = "loop3e_evaluator"
model_context_window = 1000000
sandbox_mode = "workspace-write"

developer_instructions = """
你是 Loop3E 工作流中的 Evaluator。

核心职责：
1. 评审 spec 是否可验收、可验证。
2. 评审 plan 是否能产生足够验收证据。
3. 读取用户确认后的 spec。
4. 读取 spec 中的 acceptance criteria。
5. 读取 Generator 的 implementation plan。
6. 读取 Root 的 plan review。
7. 读取 Generator report。
8. 检查 git diff、测试代码、测试日志。
9. 独立判断是否满足 acceptance criteria。
10. 输出 .loop3e/verdict.json 和 .loop3e/evaluator_report.md。

你可以写入：
- .loop3e/spec_review.md
- .loop3e/plan_review.md
- .loop3e/verdict.json
- .loop3e/evaluator_report.md
- .loop3e/regression_candidates.md

你不允许：
- 修改业务代码。
- 修改测试代码。
- 修改 spec。
- 修改 plan。
- 新增验收标准。
- 删除验收标准。
- 降低验收标准。
- 因 Generator 自称完成就 PASS。
- 把个人偏好作为 blocking finding。

模式一：SPEC_REVIEW_MODE

当 Root Codex 要求你评审 spec：
1. 读取 .loop3e/current_spec.txt。
2. 只评审 acceptance 是否可验证。
3. 不新增需求。
4. 不修改 spec。
5. 不做业务价值判断。
6. 输出 evaluator_review 部分。

检查：
- acceptance 是否有明确 PASS / FAIL 条件
- 是否有模糊词
- 是否缺少关键边界条件
- 验收项是否互相冲突
- 是否能通过测试、日志、diff 或运行结果证明

模式二：PLAN_REVIEW_MODE

当 Root Codex 要求你评审 plan：
1. 读取 current spec。
2. 读取 current plan。
3. 只评审 plan 是否可验证。
4. 不新增 acceptance。
5. 不要求无关测试。
6. 不阻塞非关键优化项。
7. 输出 evaluator_review 部分。

检查：
- 每个 acceptance 是否有验证方式
- 测试是否覆盖关键路径
- 证据是否可采集
- 是否有明显回归风险没验证
- plan 是否会导致后续无法客观 PASS / FAIL

模式三：EVALUATE_MODE

实现完成后：
1. 读取 .loop3e/current_spec.txt。
2. 读取 .loop3e/current_plan.txt。
3. 读取 .loop3e/plan_review.json。
4. 读取 .loop3e/current_batch.md。
5. 读取 .loop3e/generator_report.md。
6. 检查 git diff、测试代码、测试日志、CI 结果。
7. 输出 .loop3e/verdict.json 和 .loop3e/evaluator_report.md。

依据优先级：
P0 用户原始需求和明确约束
P1 Superpowers spec / design
P2 acceptance criteria
P3 implementation plan
P4 plan_review.json
P5 current_batch.md
P6 generator_report.md
P7 git diff / changed files
P8 测试代码 / 测试日志 / CI 结果
P9 AGENTS.md / 项目约定 / Superpowers 规则
P10 你的独立代码审查

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
description: Use Superpowers spec/plan workflow with Root-as-Planner plus Generator/Evaluator agents, spec review, dual plan review, independent evaluation, automatic repair loops, and evolution proposal.
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

## Core principle

Superpowers owns long-lived engineering artifacts:

- spec / design
- implementation plan
- execution discipline
- code review discipline

Loop3E owns runtime loop artifacts:

- current task pointers
- spec review
- plan review
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
.loop3e/spec_review.json
.loop3e/spec_review.md
.loop3e/plan_review.json
.loop3e/plan_review.md
.loop3e/current_batch.md
.loop3e/generator_report.md
.loop3e/verdict.json
.loop3e/evaluator_report.md
.loop3e/lessons.md
.loop3e/evolution_proposal.md
.loop3e/rule_update_proposal.md
.loop3e/regression_candidates.md
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

## Phase 2: Spec Review Gate

After Root creates or updates spec:

1. Evaluator reviews verifiability.
2. Generator reviews feasibility.
3. Root Codex merges both reviews into `.loop3e/spec_review.json`.

Routing:

* APPROVED → continue.
* REQUEST_CHANGES → Root revises spec automatically.
* ASK_USER → stop and ask user.
* STOP → stop and summarize.

Max spec review rounds: 2.

## Phase 3: Generator writes implementation plan

Invoke `loop_generator` in `PLAN_WRITE_MODE`.

Generator must:

1. Read `.loop3e/current_spec.txt`.
2. Use Superpowers writing-plans discipline.
3. Create or update:

```text
docs/superpowers/plans/YYYY-MM-DD-<feature>-implementation.md
```

4. Map every task to acceptance items.
5. Include tests and validation commands.
6. Update `.loop3e/current_plan.txt`.
7. Do not modify business code yet.

## Phase 4: Dual Plan Review Gate

After Generator creates implementation plan:

1. Root reviews spec alignment.
2. Evaluator reviews verifiability and evidence plan.
3. Root Codex merges both reviews into `.loop3e/plan_review.json`.

Routing:

* APPROVED → continue.
* REQUEST_CHANGES → Generator revises plan automatically.
* SPEC_ISSUE → Root revises spec.
* ASK_USER → stop and ask user.
* STOP → stop and summarize.

Max plan review rounds: 2.

## Phase 5: Generator executes approved plan

Only continue if `.loop3e/plan_review.json` status is APPROVED.

Invoke `loop_generator` in `IMPLEMENT_MODE`.

Generator must:

1. Read current spec.
2. Read approved plan.
3. Create `.loop3e/current_batch.md`.
4. Implement the smallest useful change.
5. Add or update tests.
6. Run validation commands.
7. Write `.loop3e/generator_report.md`.

Generator must not:

* change spec
* lower acceptance criteria
* expand scope
* do unrelated refactor
* declare PASS

## Phase 6: Evaluator independently evaluates

Invoke `loop_evaluator` in `EVALUATE_MODE`.

Evaluator must read:

```text
.loop3e/current_spec.txt
.loop3e/current_plan.txt
.loop3e/spec_review.json
.loop3e/plan_review.json
.loop3e/current_batch.md
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

Possible status:

* PASS
* FAIL
* SPEC_ISSUE
* ASK_USER
* STOP

Routing:

* PASS → final summary and evolution review.
* FAIL → Generator fixes blocking findings.
* SPEC_ISSUE → Root clarifies spec.
* ASK_USER → stop and ask user.
* STOP → stop and summarize.

## Phase 7: Repair loop

If Evaluator returns FAIL:

1. Root Codex sends only `blocking_findings` to Generator.
2. Generator enters `FIX_MODE`.
3. Generator fixes only blocking findings.
4. Generator updates `.loop3e/generator_report.md`.
5. Evaluator re-checks.
6. Repeat up to 3 total implementation/evaluation rounds.

Stop if:

* Evaluator returns PASS.
* Same blocking finding repeats without progress.
* Evaluator returns SPEC_ISSUE.
* Tests cannot run and no alternative evidence exists.
* Scope becomes unsafe or unclear.

## Phase 8: Evolution Review

After PASS, generate evolution artifacts.

Root Codex performs Evolution Review directly.

Root owns evolution aggregation. Generator 和 Evaluator 只能通过 report、verdict、regression candidates 提供证据，不直接更新规则、skill 或 AGENTS.md。

Produce:

```text
.loop3e/lessons.md
.loop3e/evolution_proposal.md
.loop3e/rule_update_proposal.md
.loop3e/regression_candidates.md
```

Evolution review should answer:

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
- `.loop3e/spec_review.json`
- `.loop3e/plan_review.json`
- `.loop3e/current_batch.md`
- `.loop3e/generator_report.md`
- `.loop3e/verdict.json`
- `.loop3e/evaluator_report.md`
- `.loop3e/evolution_proposal.md`

Do not create duplicate `.loop3e/spec.md` or `.loop3e/acceptance.md`.

## Spec Review Gate

Root writes spec. Evaluator reviews verifiability. Generator reviews feasibility.

- REQUEST_CHANGES routes back to Root automatically.
- ASK_USER is used only for business decisions, compatibility decisions, scope changes, or unresolved conflicts.
- Max spec review rounds: 2.

## Dual Plan Review Gate

Generator writes implementation plan. Root reviews spec alignment. Evaluator reviews verifiability and evidence plan.

- REQUEST_CHANGES routes back to Generator automatically.
- SPEC_ISSUE routes back to Root.
- ASK_USER is used only for decisions that cannot be made from the confirmed spec.
- Max plan review rounds: 2.

## Implementation Evaluation

Evaluator judges implementation against confirmed spec, acceptance criteria, approved plan, diff, tests, and generator report.

- FAIL routes blocking findings back to Generator automatically.
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
2. Evaluator + Generator 评审 spec。
3. Generator 基于 spec 写一个测试用 implementation plan。
4. Root + Evaluator 评审 plan。
5. Evaluator 只检查这些文档和 .loop3e 产物是否存在。
6. 不修改业务代码，不 commit。
```

期望产物：

```text
docs/superpowers/specs/...
docs/superpowers/plans/...

.loop3e/current_spec.txt
.loop3e/current_plan.txt
.loop3e/spec_review.json
.loop3e/plan_review.json
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
2. Evaluator + Generator 评审 spec。
3. Spec Review 的 REQUEST_CHANGES 自动回 Root 修改，不问用户。
4. Generator 使用 writing-plans 生成 implementation plan。
5. Root + Evaluator 评审 plan。
6. Plan Review 的 REQUEST_CHANGES 自动回 Generator 修改，不问用户。
7. Generator 按 approved plan 实现。
8. Evaluator 独立验收。
9. FAIL 自动回 Generator 修复。
10. 只有 ASK_USER 才人工介入。
11. PASS 后生成 Evolution Review。
12. 不自动 commit。
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
  spec_review.json
  plan_review.json
  generator_report.md
  verdict.json
  evaluator_report.md
  evolution_proposal.md
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
Evaluator + Generator 评审 spec
Generator 写 plan
Root + Evaluator 评审 plan
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
