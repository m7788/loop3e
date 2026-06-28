# Loop3E

> 超轻量 Codex-native Loop Engineering：用 Codex skills、custom agents 和 Superpowers，把一次开发任务变成 Root / Generator / Evaluator 三角色、多模型、可验收闭环。

[快速开始](#快速开始) · [工作方式](#工作方式) · [多模型配置](#4-配置模型-provider) · [设计背景](docs/codex-superpowers-loop3e.md)

Loop3E 解决传统 AI 编程里的三角不可能：

- **质量**：实现者不再自己当裁判，Evaluator 独立验收，Root 做最终产品验收。
- **效率**：需求说明、计划、评审、实现、验收、修复闭环自动推进，减少人工反复介入。
- **成本**：高 token 的实现交给 Generator，可路由到更快、更便宜或额度更充足的模型；Evaluator 只在关键门禁裁判。

```text
用户需求 → Root 需求说明 → Generator 计划/实现 → Evaluator 评审 → Root 产品验收
```

安装不需要服务端、数据库、队列或控制台；只复制 skill 和 agent 模板。使用时：

```text
$mloop <你的开发任务>
```

Loop3E = Loop3 + Evolution。Evolution 是任务后的轻量沉淀，由 Root 在最终回复里整理经验、风险和回归候选，不默认改规则、不自动提交。

## 为什么是 Loop Engineering

传统 AI 编程容易陷入质量、效率、成本的三角不可能：

- **质量**：一个模型既写代码又评审自己，容易漏掉目标偏差。
- **效率**：复杂任务需要人反复澄清、评审、纠偏，人变成瓶颈。
- **成本**：高质量任务需要多轮返工和人工兜底，真实交付成本不低。

Loop3E 不是在质量、效率、成本之间做取舍，而是用三角色、多模型闭环改变约束。

### 质量：实现者不再自己当裁判

- **Root**：澄清用户目标，写 spec，控制门禁，做最终产品验收。
- **Generator**：写 plan，完成实现，补测试，修复问题。
- **Evaluator**：评审 spec+plan，按 diff、测试和运行证据独立验收。

完成条件：

- Generator 自测通过。
- Evaluator 给出 fresh PASS。
- Root 从产品角度确认目标达成。

### 效率：人不再卡在每个中间环节

Loop3E 把开发任务拆成自动推进的闭环：

```text
需求说明 → 计划 → 包评审 → 实现 → 验收 → 修复闭环
```

人的介入集中在真正需要判断的地方：

- 业务决策。
- 范围变化。
- 权限或外部系统授权。
- 验收分歧。

大型任务里，Generator 还可以：

- 使用更快、更便宜或额度更充足的模型。
- 在文件边界清晰时并行实现。
- 最后统一集成和验证。

### 成本：多模型分工降低真实交付成本

Loop3E 不把所有 token 都压在一个模型上：

- Root 保留用户上下文和产品判断。
- Generator 承担高 token 的实现和修复，可路由到低成本快速模型。
- Evaluator 只在关键门禁上做独立裁判。

它优化的不是最低单次调用成本，而是同等质量要求下的真实交付成本：

- 更少返工。
- 更少漏验。
- 更少人工兜底。
- 更好利用不同模型和订阅额度。

## Goal 怎么参与

Loop3E 会使用 Codex Goal mode 承载长任务的 runtime objective，但不会在 `$mloop` 启动时立刻创建 goal。Root 先澄清需求并写出 spec，等 spec 稳定后才把 goal 指向当前 spec。

goal 只负责长任务持续性和完成/阻塞状态；spec、plan、package review、verdict 和验证证据仍然落在 `docs/superpowers/` 与 `.loop3e/`。

目标格式保持短：

```text
Loop3E: complete <absolute spec path>. Done only after approved plan, Generator implementation, fresh Evaluator PASS, Root product acceptance, and recorded verification.
```

## 多模型怎么用

Loop3E 不是把同一个任务随机丢给多个模型，而是让不同模型承担不同责任：

- Root 使用主 Codex 模型，保留用户上下文、产品判断和最终验收权。
- Generator 使用工程模型，主要消耗在 plan、实现、测试和修复。
- Evaluator 使用独立评审模型，按 spec、diff、测试和证据做验收裁判。

这种分工同时服务质量、效率和成本：

- **质量隔离**：实现者和裁判彼此独立，Root 不抢工程细节，Evaluator 不被 Generator 的自述说服。
- **效率提升**：高 token 的实现和修复集中给 Generator；大型任务边界清晰时可并行实现、统一集成。
- **成本路由**：Generator 可接更快、更便宜或额度更充足的模型；Evaluator 只在关键门禁上做独立裁判。

Loop3E 不追求最低单次调用成本，而是面向同等质量要求下更低的真实交付成本。

## 工作方式

```text
用户需求
  │
  ▼
Root 澄清需求并写 spec
  │
  ▼
Generator 写 plan
  │
  ▼
Evaluator 评审 spec+plan package
  │
  ▼
Generator 实现并验证
  │
  ▼
Evaluator 独立验收
  │
  ▼
Root 产品验收并回复用户
```

日常使用：

```text
$mloop <你的开发任务>
```

## 快速开始

### 1. 进入仓库

```bash
cd loop3e
```

### 2. 预览安装内容

```bash
scripts/install-loop3e.sh
```

### 3. 安装到 Codex

macOS / Linux / WSL / Git Bash：

```bash
scripts/install-loop3e.sh --apply
```

安装到指定 Codex home：

```bash
scripts/install-loop3e.sh --apply --codex-home /tmp/codex-home
```

Windows PowerShell 不直接运行这个 Bash 脚本。可以用 Git Bash / WSL 执行，或手动复制：

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.codex\agents" | Out-Null
New-Item -ItemType Directory -Force "$env:USERPROFILE\.codex\skills" | Out-Null
Copy-Item ".\codex\agents\loop_generator.toml" "$env:USERPROFILE\.codex\agents\loop_generator.toml" -Force
Copy-Item ".\codex\agents\loop_evaluator.toml" "$env:USERPROFILE\.codex\agents\loop_evaluator.toml" -Force
Copy-Item ".\codex\skills\mloop" "$env:USERPROFILE\.codex\skills\mloop" -Recurse -Force
```

安装脚本只复制 `codex/agents/` 和 `codex/skills/mloop/`，不会创建或修改 `config.toml`，也不会写入 `model_providers`。

### 4. 配置模型 provider

Loop3E 使用中性的 provider 名称，具体供应商由你自己决定：

```toml
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

然后确保启动 Codex 的进程环境能稳定提供对应变量：

```bash
export LOOP3E_GENERATOR_API_KEY="..."
export LOOP3E_EVALUATOR_API_KEY="..."
```

### 5. 在 Codex 中使用

```text
$mloop 帮我给这个 CLI 增加一个导出 JSON 的能力，保持原来的文本输出不变
```

## DeepSeek 接入

DeepSeek 原生是 Chat Completions API，Codex 使用 Responses API。Evaluator 如果使用 DeepSeek，推荐通过本地协议翻译代理接入：

- <https://github.com/zhonghexing/codex-deepseek>

配置思路是：让 `loop3e_evaluator` 的 `base_url` 指向本地代理地址，并保持：

```toml
wire_api = "responses"
```

端口、模型名和 API key 以 codex-deepseek 的 README 为准。

## 常见问题

### 安装会修改 `~/.codex/config.toml` 吗？

不会。provider、API key、模型路由都由用户自己配置。

### 为什么 provider 名字不叫 deepseek 或 minimax？

`loop3e_generator` / `loop3e_evaluator` 表示角色，不绑定供应商。你可以把它们接到 MiniMax、DeepSeek、OpenAI 兼容代理或其他 Responses API provider。

### MiniMax 做 Generator 有什么坑？

如果 `env_key` 方式下 Generator 拿不到 key，通常是 Codex 启动进程或 subagent 没有继承你临时 export 的环境变量。可以改用 Codex 的 command-backed auth，例如从 macOS Keychain 读取 MiniMax key：

```toml
[model_providers.loop3e_generator]
name = "MiniMax"
base_url = "https://api.minimaxi.com/v1"
wire_api = "responses"

[model_providers.loop3e_generator.auth]
command = "/usr/bin/security"
args = ["find-generic-password", "-a", "YOUR_ACCOUNT", "-s", "codex.MINIMAX_API_KEY", "-w"]
```

`auth` 和 `env_key` 不要同时配置在同一个 provider 上。确认 auth command 能直接输出 API key；否则 Generator 阶段会失败，Root 不应降级成 inline 实现。

Windows 也可以用 command-backed auth，但命令应换成你自己的凭据读取方式，例如调用 PowerShell 脚本从 Windows Credential Manager 或其他密钥管理器输出 token；要求同样是 stdout 只输出 token。

### DeepSeek 做 Evaluator 有什么坑？

DeepSeek 原生不是 Responses API。通过代理接入时，必须确认代理能把 `reasoning_content` 转成 Codex 可见的 `output_text`；否则 Evaluator 可能显示 completed，但没有可用消息，也不会写 `.loop3e/package_review.json` 或 `.loop3e/verdict.json`。推荐使用上面提到的 `codex-deepseek`，并先做一次真实 `$mloop` package review / final evaluation smoke。

### `$mloop` 适合所有任务吗？

不适合。很小的修改直接让 Codex 做通常更快。`$mloop` 更适合需求不完全明确、实现影响较大、需要独立验收或需要多模型交叉判断的任务。

### 运行产物放在哪里？

实际运行会在目标项目里创建 `.loop3e/`，用于保存当前 spec、plan 指针、package review、Generator report、Evaluator verdict 和运行日志。它是运行态目录，不是本仓库源码目录。

## 文件说明

```text
loop3e/
├── codex/
│   ├── agents/          # loop_generator / loop_evaluator agent 模板
│   └── skills/mloop/    # $mloop skill
├── docs/                # 设计说明和对比 benchmark 说明
├── scripts/             # 安装和辅助脚本
└── tests/               # 仓库契约测试
```

更完整的设计背景见 [docs/codex-superpowers-loop3e.md](docs/codex-superpowers-loop3e.md)。

## 致谢

- [codex-deepseek](https://github.com/zhonghexing/codex-deepseek)：DeepSeek 接入 Codex Responses API 的协议代理参考。
- [superpowers](https://github.com/obra/superpowers)：Loop3E 的 spec、plan、执行和验证纪律主要参考 Superpowers 的技能体系。
- [agency-agents](https://github.com/msitarzewski/agency-agents)：Root / Generator / Evaluator 的角色边界参考了其中的多角色协作思想。
- [agency-agents-zh](https://github.com/jnMetaCode/agency-agents-zh)：角色定义和中文语境参考来源之一。

## License

[MIT](LICENSE)
