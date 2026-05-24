# templates/

> 按"资产类型"组织的 AI 协作模板。`scripts/install.sh` 按厂商分发到 target 仓的对应位置。

## 目录布局（按类型，不按厂商）

```
templates/
├── agents-md/         L1 入口：根 AGENTS.md + 子目录 AGENTS.md（apps/contracts/...）
├── rules/             L3 规则：claude / codex / copilot / cursor
├── agents/            L3 角色化子代理：4 角色（researcher / planner / implementer / reviewer）
├── hooks/             L3 钩子：_shared/ 公共 .sh + 各厂商封装
├── mcp/               L3 MCP 服务定义：claude / cursor / copilot / codex (pointer)
├── settings/          L3 设置：claude / copilot / cursor / codex (SSOT for Codex)
├── ci-prompts/        L3 CI 提示词：review.md.tmpl + overrides/
├── checklists/        通用清单：01-05 阶段
└── (no top-level codex/ — Codex 配置全部在 settings/codex/config.toml.tmpl)
```

## 厂商支持矩阵

| 厂商 | rules | agents | hooks | mcp | settings |
|---|---|---|---|---|---|
| Claude | ✓ | ✓ (4 角色) | ✓ | ✓ | ✓ |
| Cursor | ✓ | ✓ (v0.1: reviewer 1 角色) | ✓ | ✓ | ✓ |
| Copilot | ✓ | ✓ (v0.1: reviewer 1 角色) | (CI Actions) | ✓ | ✓ |
| Codex | ✓ | ✓ (v0.1: reviewer 1 角色) | ✓ | → settings/codex/config.toml | ✓ (SSOT 单文件) |

## 设计原则

- **类型优先于厂商**：所有同类资产汇聚在同一目录，便于跨厂商对照
- **Codex 单文件例外**：Codex 的 settings + sandbox + mcp + skills/agents 共享 `.codex/config.toml`，唯一 SSOT 落 `settings/codex/`
- **占位符约定**：`<project-name>`、`<owner>` 等由 install.sh 的 `render_tmpl` 替换
- **REFERENCE ONLY 头**：所有模板顶部带 `<!-- REFERENCE ONLY: sanitized template -->`，与 retro-audit 第 11 条对齐
