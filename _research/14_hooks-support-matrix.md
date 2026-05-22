<!-- REFERENCE ONLY: sanitized sample, not for production -->
# 14 · 四家 AI Agent Hooks 能力对照表

> 调研日期：2026-05-20
> 一手来源：
> - Claude Code：https://code.claude.com/docs/en/hooks
> - Cursor：https://cursor.com/docs/hooks
> - OpenAI Codex：https://developers.openai.com/codex/hooks
> - GitHub Copilot：https://code.visualstudio.com/docs/copilot/customization/custom-agents（`hooks` 字段段落）

---

## 0. 通用模型（四家共识）

Hooks = agent 在**生命周期事件**触发时调用外部脚本/命令，通过 **stdin JSON + stdout JSON / 退出码** 通信。

- **退出码约定（四家共用）**：`0` = 成功放行；`2` = **阻断**当前动作（deny / block）；其他非零 = 非阻断错误
- **stdin**：JSON，包含事件类型、工具名、工具参数、cwd、session_id 等上下文
- **stdout**：可选 JSON 决策对象，可改写参数、附加 system message、显式 allow/deny

---

## 1. 总体能力对比

| 维度 | Claude Code | Cursor | OpenAI Codex | GitHub Copilot |
|---|---|---|---|---|
| **官方文档** | code.claude.com/docs/en/hooks | cursor.com/docs/hooks | developers.openai.com/codex/hooks | code.visualstudio.com/docs/copilot/customization/custom-agents |
| **稳定性** | GA | GA | GA | **Preview**（需 `chat.useCustomAgentHooks` setting）|
| **事件总数** | 28+ | 21（agent 18 + Tab 2 + workspace 1）| **6** | 沿用 Claude 格式 |
| **Handler 类型** | 5：`command` / `http` / `mcp_tool` / `prompt` / `agent` | 同 Claude（兼容）| **只有 `command` 生效**，`prompt`/`agent` 解析但跳过 | 沿用 Claude 格式 |
| **配置文件** | `.claude/settings.json`（全局）+ skill/subagent frontmatter（局部）| `.cursor/hooks.json`、`~/.cursor/hooks.json` | `~/.codex/hooks.json` / `<repo>/.codex/hooks.json`，或 `config.toml` 内嵌 `[hooks]` | agent frontmatter `hooks:` 字段（`.agent.md` / `.claude/agents/*.md`）|
| **配置合并层级** | 用户 + 项目 | **4 级**：Enterprise → Team → Project → User | 全局 + 仓库 | 仅 agent 文件级（scope = 该 agent 激活时）|
| **配置格式** | JSON | JSON | JSON **或** TOML | YAML frontmatter（hooks 子项是 JSON-like 结构）|
| **跨家兼容声明** | — | **原生兼容 Claude 格式**：识别 `CLAUDE_PROJECT_DIR`，退出 2 = deny | — | 与 Claude 格式同构（Preview 阶段）|
| **Matcher（事件过滤）** | `matcher` 字符串/正则，按工具名过滤 | 同 Claude | 同 Claude | 同 Claude |
| **超时与失败处理** | 超时默认 60s 可调，失败不阻断除非 exit 2 | 同 Claude | 同 Claude | 同 Claude |

---

## 2. 事件清单逐家对照

### 2.1 Claude Code（28+ 事件）

| 类别 | 事件 |
|---|---|
| 会话生命周期 | `SessionStart`、`Setup`、`InstructionsLoaded`、`SessionEnd` |
| 用户输入 | `UserPromptSubmit`、`UserPromptExpansion`、`Elicitation`、`ElicitationResult` |
| 工具调用 | `PreToolUse`、`PostToolUse`、`PostToolUseFailure`、`PostToolBatch` |
| 权限 | `PermissionRequest`、`PermissionDenied` |
| 子代理 | `SubagentStart`、`SubagentStop`、`TaskCreated`、`TaskCompleted` |
| 停止 | `Stop`、`StopFailure`、`TeammateIdle` |
| 文件 / 工作树 | `FileChanged`、`CwdChanged`、`WorktreeCreate`、`WorktreeRemove` |
| 上下文压缩 | `PreCompact`、`PostCompact` |
| 配置 | `ConfigChange` |
| 其他 | `Notification` |

**5 种 handler**：
- `command`：执行 shell 命令（最常用）
- `http`：POST 到 URL
- `mcp_tool`：调用 MCP 服务器上的工具
- `prompt`：插入一段 prompt 到模型上下文
- `agent`：触发另一个 subagent

### 2.2 Cursor（21 个事件）

**Agent hooks（18 个）**：
`sessionStart` · `sessionEnd` · `preToolUse` · `postToolUse` · `postToolUseFailure` · `subagentStart` · `subagentStop` · `beforeShellExecution` · `afterShellExecution` · `beforeMCPExecution` · `afterMCPExecution` · `beforeReadFile` · `afterFileEdit` · `beforeSubmitPrompt` · `preCompact` · `stop` · `afterAgentResponse` · `afterAgentThought`

**Tab hooks（2 个）**：
`beforeTabFileRead` · `afterTabFileEdit`

**Workspace hooks（1 个）**：
`workspaceOpen`

**Cursor 独有亮点**：
- 四级配置合并（Enterprise/Team/Project/User），冲突时高优先级覆盖
- 原生 Claude 兼容：脚本读 `CLAUDE_PROJECT_DIR` 也能跑；`exit 2` 同义 deny

### 2.3 OpenAI Codex（仅 6 个事件）

| 事件 | 说明 |
|---|---|
| `SessionStart` | 会话开始 |
| `UserPromptSubmit` | 用户提交 prompt |
| `PreToolUse` | 工具调用前 |
| `PermissionRequest` | 权限审批请求 |
| `PostToolUse` | 工具调用后 |
| `Stop` | 会话结束 |

**Codex 特殊点**：
- 配置格式两种：`hooks.json` 或在 `config.toml` 内嵌 `[hooks.<event_name>]`
- **只有 `type: "command"` 真正会执行**；解析器认识 `prompt`/`agent`/`http`/`mcp_tool` 但跳过不跑
- 与 hooks **不同概念但常配合**：
  - 沙箱：`~/.codex/config.toml` 的 `sandbox` / `approval_policy`（OS 级 Seatbelt/landlock/Windows sandbox）
  - execpolicy：`.codex/rules/*.rules`（Starlark `prefix_rule()` + `allow|prompt|forbidden`）

### 2.4 GitHub Copilot（Preview）

**位置**：custom agent 文件（`.agent.md` / `.github/agents/*.md` / `.claude/agents/*.md`）的 frontmatter `hooks` 字段

**前置条件**：
- VS Code setting `chat.useCustomAgentHooks` = `true`
- 仅在该 custom agent **激活时**生效（被用户选中，或被作为 subagent 调用）

**事件 / handler / 格式**：与 Claude Code 同构（官方原文：*Uses the same format as hook configuration files*）

**与 Copilot 相邻易混概念（不是 hooks）**：
- `.github/workflows/`：GitHub Actions CI，跑在远端 runner，不属于 agent hooks
- `.github/copilot-instructions.md`：永久 system instruction，不是事件回调
- Custom agent `handoffs` 字段：会话结束后弹按钮让用户切换 agent，是 UI 流转不是脚本回调

---

## 3. 典型场景配方

| 场景 | 用哪个事件 | 备注 |
|---|---|---|
| 拒绝写入 `.env` / 生产配置 | `PreToolUse` (Write/Edit) | exit 2 阻断；matcher 过滤工具名 |
| 写入后自动 `prettier` / `ruff` | `PostToolUse` (Write/Edit) | 直接 shell 执行 |
| 提交前跑测试套件 | `Stop` 或 `PreToolUse` (Bash:git commit) | Claude/Cursor 都支持 |
| 把团队红线注入每一轮 prompt | `UserPromptSubmit` | stdout 返回 `additionalContext` JSON |
| 子代理启动通知 | `SubagentStart` | Claude/Cursor 都有；Codex 无 |
| 大文件读取前拦截 | `beforeReadFile`（Cursor 独有）| Claude 走 `PreToolUse` (Read) 替代 |
| 会话结束发 Slack | `SessionEnd` / `Stop` | 四家都行（Copilot 需在该 agent frontmatter 内）|
| 危险命令二次确认 | `PermissionRequest` | Claude/Codex 有专门事件；Cursor 走 `preToolUse` |

---

## 4. <platform> 适用性建议（基于现仓状况）

| 需求 | 推荐方案 |
|---|---|
| 保护 `.env`、`tech-docs/_audits/`、`tech-docs-v1-archive/`（只读） | Claude `PreToolUse` + 路径匹配；Cursor 同等 |
| Docsify 站点改动后自动跑 `build_sidebars.py --check` | `PostToolUse` (Edit) matcher = `**/*.md` |
| 阻止 agent 直接 `git push --force` / 改已发布 commit | `PreToolUse` (Bash) 拦 `git push.*--force\|git reset --hard` |
| 跨仓库引用红线（PRD 反向引用 tech-docs 等）自动检查 | `PostToolUse` (Edit) 调一段 grep 规则 |
| 多 agent 协作时记录哪个 subagent 改了什么 | `SubagentStart` / `SubagentStop` 写审计日志（Claude/Cursor）|

---

## 5. 红线 / 易踩坑

1. **不要把 GitHub Actions 当 hooks**：CI workflow ≠ agent 生命周期回调
2. **不要把沙箱/execpolicy 当 hooks**：Codex 的 sandbox 与 `.codex/rules/*.rules` 是 OS / 应用层访问控制，与 hooks 配合但独立
3. **Copilot hooks 还在 Preview**：不要在生产关键路径上依赖；用户需自行打开 `chat.useCustomAgentHooks`
4. **Codex handler 类型只 `command` 生效**：从 Claude 迁移过来的 `prompt`/`agent` hook 会被静默跳过
5. **退出码 1 ≠ 阻断**：四家都规定 `exit 2` 才是阻断，`exit 1` 会被视为脚本失败但放行
6. **stdin 是 JSON 流，不是 argv**：忘了 `cat` 或读 stdin 会拿到空字符串

---

## 6. 参考链接

- Claude Code Hooks：https://code.claude.com/docs/en/hooks
- Cursor Hooks：https://cursor.com/docs/hooks
- OpenAI Codex Hooks：https://developers.openai.com/codex/hooks
- VS Code Copilot Custom Agents（含 `hooks` 字段）：https://code.visualstudio.com/docs/copilot/customization/custom-agents
- 本仓库现有交叉资料：
  - [_research/01_entry-file-support-matrix.md](01_entry-file-support-matrix.md)（Cursor 4 级合并、18 事件清单）
  - [ai-agent-playbook.md §2.5](../ai-agent-playbook.md)（playbook 简表版）
