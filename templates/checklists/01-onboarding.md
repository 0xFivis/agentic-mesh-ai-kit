<!-- REFERENCE ONLY: sanitized sample, not for production -->
<!--
来源：agentic-mesh-ai-kit/templates/checklists/01-onboarding.md
权威：agentic-mesh-ai-kit/playbook.md
触发：新仓启用 AI 协作工作流时
-->

# Checklist · 新仓启用 AI 协作

> 拷本 checklist 到新仓 `docs/checklists/` 或在首个 onboarding PR 里勾选。详细装配步骤见 [`../../playbook.md`](../../playbook.md)。

## 0. 必读

> 本 checklist 拷至新仓后相对路径会失效；下列均为 **agentic-mesh-ai-kit 根** 起算的稳定路径，按需打开。

- [ ] 通读 `playbook.md`
- [ ] 通读 `sop/`
- [ ] 通读上游平台的 `tech-standards/STD-05-security/`（红线源 · 如有）

## 1. L1 入口（根 AGENTS.md + CLAUDE.md symlink）

- [ ] 手写仓库根 `AGENTS.md`（仓库定位 / 上下游 / 命令速查 / 红线）— Cursor / Copilot / Codex 原生共读
- [ ] `cd <repo-root> && ln -s AGENTS.md CLAUDE.md` — Claude Code 读 CLAUDE.md，内容与 AGENTS.md 同源
- [ ] 如有 Codex 专属覆盖项（要求对其他家隐藏）：手写 `<dir>/AGENTS.override.md`，**不自动派生**

## 2. L2 共享（MCP + Skills）

- [ ] 拷 [`templates/mcp/.mcp.json.template`](../mcp/.mcp.json.template) → 仓库根 `.mcp.json`，按需启用 github / postgres / slack；Copilot 端 `ln -s ../.mcp.json .vscode/mcp.json`
- [ ] 环境变量在 `~/.zshrc` 或团队 secret manager 配齐（**禁** commit）
- [ ] Skills 真目录放 `shared/skills/<name>/SKILL.md`（拷 [`templates/skills/`](../skills/) 起步）；各家 `ln -s ../../shared/skills <agent-dir>/skills` 共享
- [ ] 第一次启用至少装：`data-redline`（横切必装）+ 当前阶段 skill（T0→`tech-intake` / T1→`bc-impact-map` / T2→`contract-first`）+ `gate-checklist`（T4 必备）

## 3. L3 原生（各家 settings · 互不派生）

- [ ] Claude：拷 [`templates/settings/claude/settings.json.template`](../settings/claude/settings.json.template) → `.claude/settings.json`（含 `data-redline` alwaysLoaded）
- [ ] Cursor：拷 [`templates/settings/cursor/hooks.json.template`](../settings/cursor/hooks.json.template) → `.cursor/hooks.json`
- [ ] Copilot：把 [`templates/settings/copilot/vscode-settings.snippet.json`](../settings/copilot/vscode-settings.snippet.json) 内容 merge 到 `.vscode/settings.json`（启用 `chat.useCustomAgentHooks` Preview）
- [ ] Codex：拷 [`templates/codex/config.toml.tmpl`](../codex/config.toml.tmpl) → `.codex/config.toml`（项目级，单一文件承载 settings + sandbox + MCP servers；机器级 key 仍放 `~/.codex/config.toml`）

## 4. Subagents（按需）

- [ ] 仅当需要 fan-out 或 Writer-Reviewer 隔离时装 `explorer` / `reviewer`
- [ ] 拷 [`templates/agents/<name>.md`](../agents/) → `.claude/agents/`（Cursor / Codex 各自 agents 目录复制）

## 5. 留痕模板

- [ ] 把 [`templates/docs/*.template`](../docs/) 按需拷到 `specs/<feature-id>/` 或 `docs/` 作为起始
- [ ] PR 模板引用 `gate-checklist` skill 输出格式

## 6. 验收

- [ ] 跑一个 dry-run feature（哪怕只到 T2），验证 5 件套能产出
- [ ] `retro-audit` skill 跑过一次 9 项 audit（即使全 N/A）
