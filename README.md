# Loop3E

> 给 Codex + Superpowers 增加一个三角色、多模型、可验收的开发闭环。

Loop3E 面向中大型开发任务：需求先被澄清成 spec，再由独立工程角色实现，最后由独立验收角色按证据判断是否通过。

## 为什么需要 Loop3E

普通 Codex 会话里，需求澄清、方案设计、实现、测试和验收都容易混在同一个上下文里。任务变大后，常见问题是：

- Root 写了实现细节，工程角色失去独立判断。
- 实现完成后只看测试绿了，没有独立检查目标产物质量。
- 多模型能力没有形成闭环，只是换了一个模型继续单线程工作。

Loop3E 把职责拆开：

- Root：产品 / 设计 / 项目编排，负责澄清需求、写 spec、控制门禁、最终产品验收。
- Generator：工程负责人，负责 plan、实现、测试、修复和实现期组织。
- Evaluator：测试 / 证据裁判，负责评审 spec+plan package，并做最终独立验收。

## Loop 是什么

Loop3E = Loop3 + Evolution。

Loop3 是任务内闭环：

```text
需求澄清 → Spec → Plan → 实现 → 验收 → 修复
```

Evaluator 不通过时，问题回到 Generator 修复；如果发现 spec 本身有问题，则回到 Root 澄清或修正。只有 Evaluator 给出 fresh PASS，并且 Root 产品验收通过，任务才算完成。

Evolution 是任务后的轻量演进：Root 在最终回复里沉淀经验、风险和回归候选；默认不自动改规则、不自动提交、不把复盘变成第四个固定 agent。

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

这种分工的目标是提高中大型任务的质量：实现者和验收者彼此独立，Root 不抢工程细节，Evaluator 不被 Generator 的自述说服。代价是更慢、更贵，所以 `$mloop` 更适合重要或不确定的开发任务。

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

```bash
scripts/install-loop3e.sh --apply
```

安装到指定 Codex home：

```bash
scripts/install-loop3e.sh --apply --codex-home /tmp/codex-home
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

## License

[MIT](LICENSE)
