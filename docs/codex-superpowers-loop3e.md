# Loop3E 设计背景

本文只记录 Loop3E 的设计背景和关键决策，不再作为运行时规范。

运行时事实源：

- `$mloop` 工作流：`codex/skills/mloop/SKILL.md`
- Generator 角色：`codex/agents/loop_generator.toml`
- Evaluator 角色：`codex/agents/loop_evaluator.toml`
- 契约测试：`tests/test_mloop_contracts.sh`

更新 mloop 行为时，只维护这些运行资产和测试；不要把完整流程复制到本文。

## 为什么做 Loop3E

Loop3E 面向真实开发任务里的三角问题：

- **质量**：单模型既实现又自评，容易漏掉目标偏差。
- **效率**：复杂任务需要人反复澄清、评审和纠偏，人变成瓶颈。
- **成本**：高质量交付往往贵在返工、漏验和人工兜底。

Loop3E 不在质量、效率、成本之间做简单取舍，而是把一次任务拆成 Root / Generator / Evaluator 三角色闭环：

- Root 保留用户目标、产品判断、门禁和最终验收。
- Generator 负责 plan、实现、测试和修复。
- Evaluator 作为独立证据裁判，按 spec、diff、测试和运行证据验收。

## 为什么基于 Superpowers

Loop3E 不替代 Superpowers。Superpowers 负责工程纪律和长期资产：

- brainstorming 负责需求澄清、设计确认和 spec。
- writing-plans 负责 implementation plan。
- execution / TDD / debugging / verification 按触发条件提供工程纪律。

Loop3E 只增加三角色调度、门禁产物、独立验收和修复闭环。

## 关键设计决策

- Root 是 Planner，但不是实现者，也不写 implementation plan。
- Generator / Evaluator 必须通过 Codex custom agents 派发；显式 `$mloop` 不降级成 Root inline。
- spec / plan 属于 `docs/superpowers/`；`.loop3e/` 只保存运行态指针、review、report、verdict 和 run log。
- 每次 `$mloop` 创建新的 `.loop3e/runs/<run_id>/`，避免旧 verdict/report 污染当前门禁。
- Evaluator verdict 必须新鲜；Root 只信文件系统 mtime/ctime，不信模型生成 timestamp。
- Evaluator PASS 后，Root 仍需做产品验收，确认原始用户目标和 human approval。
- Evolution 默认只在最终回复中沉淀经验、风险和回归候选，不自动改规则、不自动提交。

## 角色来源

Loop3E 的角色边界参考了多角色协作方法，但只保留三个必要角色：

- Root = 产品 + 设计 + 项目编排
- Generator = 工程
- Evaluator = QA + 证据/现实校验

拒绝照搬长 persona、固定技术栈、大型组织流程或生产就绪表演。运行时契约以实际 skill 和 agent 模板为准。

## 不再放在本文里的内容

以下内容曾经放在本文中，但会造成第二事实源，已移出：

- 完整 `$mloop` 快速流程
- agent TOML 模板
- skill 模板
- package review / verdict JSON 细节
- 安装和 smoke test 步骤
- 运行时门禁规则

这些内容分别由 `codex/skills/`、`codex/agents/`、`scripts/`、`tests/` 和 README 承担。
