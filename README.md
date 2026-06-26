# loop3e

`loop3e` 是一套面向 Codex + Superpowers 的轻量多模型开发闭环。

它把一次开发请求拆成：

- Root-as-Planner：澄清需求、写 spec / acceptance、控制门禁
- Generator：写 plan / 实现 / 测试
- Evaluator：评审可验收性 / 独立验收
- Evolution：沉淀经验和规则提案

日常使用：

```text
$mloop <你的开发任务>
```

## 仓库结构

- `codex/skills/mloop/`：Loop3E skill 源文件。
- `codex/agents/`：Generator / Evaluator 的 Codex agent 模板。
- `docs/superpowers/specs/`：长期 spec 资产。
- `docs/superpowers/plans/`：长期 implementation plan 资产。
- `.loop3e/`：运行态产物目录，由任务运行时创建并被 Git 忽略。

## 安装到 Codex 环境

默认只预览，不修改当前环境：

```bash
scripts/install-loop3e.sh
```

显式安装到当前 Codex home：

```bash
scripts/install-loop3e.sh --apply
```

安装到临时或指定目录：

```bash
scripts/install-loop3e.sh --apply --codex-home /tmp/codex-home
```

脚本只安装 `codex/agents/` 和 `codex/skills/mloop/`；不会创建或修改 `config.toml`，也不会写入 `model_providers`。

需要模型 provider 时，手动把类似配置加入 `${CODEX_HOME:-$HOME/.codex}/config.toml`：

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

真实 provider smoke test 还需要先配置：

```bash
export LOOP3E_GENERATOR_API_KEY="..."
export LOOP3E_EVALUATOR_API_KEY="..."
```

## 测试

离线测试不调用真实模型，也不修改真实 `~/.codex`：

```bash
bash tests/test_install-loop3e.sh
bash tests/e2e/test_mloop_install.sh
```

`tests/e2e/test_mloop_install.sh` 会复制 `tests/fixtures/sample-project/` 到临时 workspace，再安装到临时 `CODEX_HOME`，验证安装不会修改目标项目、不会创建 `config.toml`、不会写 `AGENTS.md`。

真实 E2E 使用仓库内 ignored 目录：

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

在打开的 Codex 会话里执行 `$mloop` 空跑验证。`e2e-workspace/` 已被 Git 忽略，可以反复清空重建。
