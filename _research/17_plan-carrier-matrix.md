<!-- REFERENCE ONLY: sanitized sample, not for production -->
# 17 · "Plan" 在四家工具里的载体矩阵

> 调研时间：2026-05-20 · 60 天未复核即视为待校
> 修订：v3.6。上版删 Workspace 但留了 Coding Agent，用户点名：Coding Agent 同样是云端独立产品（GitHub.com 侧的 issue→PR 服务），**不是 Copilot IDE 本体的 Plan 载体**，与 Workspace 同理不应计入。本版 Copilot App/Cloud 列清零。v3.4 补回的 IDE 内置 `Plan` agent（[code.visualstudio.com/docs/copilot/agents/overview](https://code.visualstudio.com/docs/copilot/agents/overview) “VS Code has three built-in agents: Agent / Plan / Ask”）保留。本版只回答“有没有”。

---

## 1. 核心结论

`Plan` 是 4-Phase（Explore→Plan→Code→Commit）里的**一个方法论阶段**（产物：可审阅的实施方案，不动文件）。每家工具把这同一个阶段实现到 0/1/N 个载体上，**名字、形态都不一样**——不能跨工具类比。

---

## 2. 四家 × 四载体 · 有没有 Plan 载体（仅"有/无 + 名字"）

| 工具 \ 载体 | 独立 App / 云端 surface | IDE 扩展 | CLI | Built-in subagent |
|---|---|---|---|---|
| **Claude Code** | 无独立 App | 通过 IDE 终端调用 CLI | **有**：`plan` permission mode（read-only） | **有**：`Plan` 内置 subagent（与 `Explore` / `general-purpose` 并列） |
| **Codex (OpenAI)** | **有**：`plan` mode | **有**：`Chat` mode（与 `Agent` / `Agent (Full Access)` 并列） | **有**：`Read-only` approval mode | **无内置 planner**（内置只有 `default` / `worker` / `explorer`）；可装实验性 skill `$create-plan` 或自定义 read-only agent |
| **Cursor** | 无独立 App | **有**：Plan 模式（与 Agent / Chat 并列；产物是 markdown 计划文件，可 Save to workspace） | `cursor-agent` CLI 默认 agent 模式；CLI 是否有独立 Plan 入口本次未直接核到 | **有**：内置 `Explore` / `Bash` / `Browser`（来源 [_research/01](01_entry-file-support-matrix.md) / [_research/06](06_subagent-orchestration.md)）；`Explore` 是 read-only 探索 agent，**承载 Plan 阶段的探索动作**（不是严格 planner） |
| **GitHub Copilot** | 无（Copilot Workspace / Coding Agent 均为 GitHub 云端独立产品，不是 Copilot IDE 本体的 Plan 载体） | **有**：内置 `Plan` agent（与 `Agent` / `Ask` 并列为 VS Code 三大 built-in agents），产出 structured implementation plan 后 hand off 给 implementation agent | `gh copilot` CLI 主要 suggest/explain，不承载 Plan 阶段 | **有**：`Explore`（**preview**，扩展 bundled `.agent.md` 而非 hardcoded）——read-only 探索 agent，承载 Plan 阶段探索（留底 [playbook](../ai-agent-playbook.md) L397+L430） |

### 一行读法

- **Claude**：Plan 同时是 *permission mode* **和** 内置 subagent（**双形态**）
- **Codex**：Plan 在 3 个 surface 都有，名字三样（plan / Chat / Read-only）；subagent 形态缺
- **Cursor**：IDE 有显式 Plan 模式；subagent 层有内置 `Explore`（read-only）承载 Plan 阶段的探索
- **Copilot**：IDE 层**有内置 `Plan` agent**（与 Agent / Ask 并列）；subagent 层有内置 `Explore`（preview）；App/云端无本体载体（Workspace / Coding Agent 均为 GitHub 独立产品）

---

## 3. 命名歧义（playbook 必须括号标工具名）

| 词 | Codex 指 | Claude 指 | Cursor 指 | Copilot 指 |
|---|---|---|---|---|
| **Plan** | App 的 plan mode | permission mode + 内置 subagent（双形态） | IDE 的 Plan 模式 | **三大 built-in agent 之一**（与 Agent / Ask 并列） |
| **Chat** | IDE 的 Chat mode（≈Plan，read-only） | claude.ai 网页对话 | Cursor 侧栏对话（read-only） | Copilot Chat 普通 ask |
| **Agent** | IDE 的 Agent mode（有写权限） | Claude Code 默认行为 | Cursor Agent 模式（含写） | VS Code Agent mode（有写） |
| **Read-only** | CLI approval mode 名（≈Plan） | Plan mode 本质即 read-only | — | — |
| **Explore** | 内置 subagent 名 | 内置 subagent 名 | 内置 agent 名（与 Bash / Browser 并列） | 内置 subagent 名（**preview** · 扩展 bundled） |

---

## 4. 与 spec-kit（[§18](18_spec-driven-support-matrix.md)）的边界

一句话：spec-kit 的 `/speckit.plan` 产出**项目级** `plan.md`；本篇说的 Plan 是**单 task 级** mode 切换。两者粒度差一个数量级，互不替代，可嵌套。

---

## 5. playbook §3.1 修订要点

1. "Plan 入口动作" 列**只写"有无 + 名字"**，删除任何快捷键/命令/触发方式描述。
2. 4-Phase 必须前缀"Anthropic 风格"，与 spec-kit 的 4-phase 区分。
3. Codex 行不能写"无 Plan"——改为 "App=plan / IDE=Chat / CLI=Read-only / Subagent=无内置（`$create-plan` 或自写）"。
4. Cursor 行：IDE 有 Plan 模式；subagent 列写内置 `Explore`（read-only 探索，归入 Plan 阶段载体）。
5. Copilot 行：IDE 层**有内置 `Plan` agent**（三大 built-in 之一，不需自写）；subagent 列内置 `Explore`（preview）；**App/云端列写“无”**（Workspace / Coding Agent 均为 GitHub 独立产品、不纳入 Copilot 本体）。

---

## 6. 引用源

| # | URL | 用于核实 |
|---|---|---|
| 1 | <https://developers.openai.com/codex/changelog> | Codex App `plan` mode（26.210 / 26.317）|
| 2 | <https://developers.openai.com/codex/ide/features> | Codex IDE `Agent` / `Chat` / `Agent (Full Access)` 三档 |
| 3 | <https://developers.openai.com/codex/cli/features> | Codex CLI Auto / Read-only / Full Access 三档 |
| 4 | <https://developers.openai.com/codex/subagents> | Codex 内置 `default` / `worker` / `explorer`；TOML schema |
| 5 | <https://code.claude.com/docs/en/subagents> | Claude 内置 `Explore` / `Plan` / `general-purpose`；`permissionMode: plan` |
| 6 | <https://code.claude.com/docs/en/common-workflows> | Claude `--permission-mode plan` |
| 7 | <https://cursor.com/docs/agent/plan-mode> | Cursor IDE Plan 模式 + Save to workspace |
| 8 | <https://code.visualstudio.com/docs/copilot/agents/overview> | **VS Code 三大 built-in agents：Agent / Plan / Ask**；handoff 机制 |
| 9 | <https://code.visualstudio.com/docs/copilot/customization/custom-agents> | Copilot `.agent.md`（前 `.chatmode.md`）custom agent 体系 |
