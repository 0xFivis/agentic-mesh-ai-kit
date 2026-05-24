# Installing agentic-mesh-ai-kit

> 把 AI 协作矩阵注入到一个已 scaffold 过的项目仓。**先 arch-kit/scaffold.sh，再本步**。

## 前置

- target 仓已通过 `agentic-mesh-arch-kit/scripts/scaffold.sh` 生成基线结构
- 本仓 (`agentic-mesh-ai-kit`) 已 clone 到本地

## 命令

```bash
cd /path/to/target-repo
bash /path/to/agentic-mesh-ai-kit/scripts/install.sh \
  --vendor all \
  [--codex-override] \
  [--no-spec-kit] \
  [--skip-agent-check] \
  [--dry-run]
```

## 参数

| 参数 | 默认 | 说明 |
|---|---|---|
| `--vendor` | 必填 | `claude` / `cursor` / `copilot` / `codex` / `all` |
| `--codex-override` | false | 落地 `.codex/AGENTS.override.md`（少数 Codex 团队需要） |
| `--no-spec-kit` | false | 跳过 spec-kit 集成步骤 |
| `--skip-agent-check` | false | 跳过 vendor CLI 探测（CI / 多家场景） |
| `--dry-run` | false | 只打印将做什么，不写盘 |
| `--target` | `$PWD` | target 仓路径 |

## 10 步流程概览

1. 根 AGENTS.md（L1）
2. 子目录 AGENTS.md（apps/contracts/docs/ops/packages/specs/testing）
3. spec-kit（除非 --no-spec-kit）
4. skills（复制到 `.claude/skills`、`.cursor/skills`、`.codex/skills`、`.github/skills`）
5. rules（按厂商分发到各自规则文件）
6. agents（4 角色：researcher / planner / implementer / reviewer · Claude 完整；其余 v0.1 仅 reviewer）
7. hooks（`_shared/*.sh` + 各厂商封装；Codex 走 `.codex/hooks.json` 或 inline）
8. settings（Claude / Cursor / Copilot / **Codex 单文件 SSOT** = settings + sandbox + mcp + skills/agents）
9. ci-prompts（`.github/ci-prompts/review.md`）
10. 写 `.ai-kit-version`

## 升级

后续 kit 升级用 `scripts/upgrade.sh`（三方合并，保护本地修改）。

## 故障排查

- `--vendor codex` 后 `.codex/config.toml` 未生效 → 该项目尚未被 `codex` 标记为 trusted
- 机器级 key (`openai_base_url` 等) 项目级不生效 → 手放 `~/.codex/config.toml`
- `.mcp.json` 不读取 → 重启 Claude Code 或检查 schema
