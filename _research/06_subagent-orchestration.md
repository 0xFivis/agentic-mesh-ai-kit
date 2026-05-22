<!-- REFERENCE ONLY: sanitized sample, not for production -->
# 06 · 子代理编排（Subagent Orchestration）2026/Q2

> **定位**：研究"如何把任务拆给多个并行/串行 AI 代理跑、它们各自隔离上下文、最后回汇主代理"。本篇承接 [05 §3.3 Subagent Architecture](05_context-engineering.md)，把它从抽象概念落到具体的 frontmatter 字段、隔离机制、与典型拓扑。依赖 [02 §2.3 多代理共识](02_coding-paradigms-2026.md) 与 [04 §2 工具矩阵](04_tool-landscape-2026.md)。
> **基准日期**：2026 年 5 月。

---

## §0 一句话结论

> **Subagent 是 2026 年 AI Coding 工程化的核心抽象之一**——它解决的是“主对话上下文不能被无关探索/工具输出污染”的问题。Anthropic Claude Code 已把它做成一等公民（YAML 定义 + 隔离 context + 工具白名单 + worktree 隔离 + 持久 memory + 三种调用方式），Sourcegraph Amp / OpenAI Codex / Cursor（本地 `.cursor/agents/` + Cloud Agents，旧称 Background Agents）/ Devin 等纷纷跟进。<Platform> 必须立 5 条规则：**显式定义**、**最小工具集**、**摘要返回**、**禁止嵌套**、**默认 worktree 隔离**[^1]。

<Platform> 推荐的 6 种典型 subagent（建在 `.claude/agents/`）：

1. **explorer**（read-only，Haiku）— 大型 codebase 探索
2. **reviewer**（read-only，Sonnet）— 代码审查、不动文件
3. **debugger**（Edit 允许，Sonnet）— 错误分析与最小修复
4. **test-runner**（Bash 允许，Haiku）— 跑测试、只回失败摘要
5. **migration-worker**（worktree 隔离，Sonnet）— 大型重构、不污染主分支
6. **doc-writer**（Edit 限定 `docs/**`，Haiku）— 文档撰写

---

## §1 为什么需要 Subagent（三大动因）

| 动因 | 没有 subagent 的痛 | Subagent 的解 |
|---|---|---|
| **Context 隔离** | 探索/测试/搜索的 verbose 输出污染主对话，触发 context rot | 子代理独立 context window，只回 1–2k token 摘要[^2] |
| **能力约束** | 主代理拿着所有工具，容易越权（误删、误写、调错 MCP） | YAML `tools` 白名单 / `disallowedTools` 黑名单 / `permissionMode` / 子代理专属 hooks[^1] |
| **成本与速度** | 用 Opus 跑探索浪费钱、慢 | 子代理可指定 Haiku，主代理用 Sonnet/Opus 综合[^1] |

补充："子代理永远会自动写 NOTES.md"——这一点 Claude Code 已经做了：子代理可配 `memory: project | user | local`，自动维护 `MEMORY.md`，跨会话持久化[^1]。

---

## §2 Claude Code Subagent 完整定义（事实清单）

> 这是 2026/Q2 业界最完整的 subagent 规范，其他工具是其子集或变体。

### 2.1 文件格式

```markdown
---
name: code-reviewer                    # 必填，小写连字符
description: ...                       # 必填，告诉主代理何时委派
tools: Read, Grep, Glob, Bash         # 可选，白名单（不写则继承全部）
disallowedTools: Write, Edit          # 可选，黑名单（先于 tools 应用）
model: sonnet                          # 可选，sonnet/opus/haiku/full-id/inherit
permissionMode: plan                   # 可选，default/acceptEdits/auto/dontAsk/bypassPermissions/plan
maxTurns: 50                           # 可选，agentic turn 上限
skills: [api-conventions, error-patterns]  # 可选，启动即注入 skill 全文
mcpServers: [playwright, github]       # 可选，子代理专属 MCP
hooks:                                 # 可选，子代理生命周期 hook
  PreToolUse: ...
memory: project                        # 可选，user/project/local 持久 memory
background: false                      # 可选，是否始终后台运行
effort: medium                         # 可选，low/medium/high/xhigh/max
isolation: worktree                    # 可选，独立 git worktree 隔离
color: blue                            # 可选，UI 区分
initialPrompt: ...                     # 可选，主-session 模式下自动首条 user 消息
---

You are a senior code reviewer...     # 系统 prompt（markdown 正文）
```

### 2.2 加载位置与优先级（高 → 低）

| 优先级 | 位置 | 寿命 |
|---|---|---|
| 1 | Managed settings 下的 `.claude/agents/` | 组织级，强制 |
| 2 | `--agents` CLI flag（JSON 内联） | 仅本次会话 |
| 3 | `.claude/agents/`（项目） | 项目级，入 VCS |
| 4 | `~/.claude/agents/`（用户） | 跨项目 |
| 5 | Plugin 的 `agents/` 目录 | 插件域 |

> **关键事实**：项目目录子文件夹（如 `agents/review/security.md`）**不影响 identifier**——身份只来自 frontmatter `name`。两个文件 name 撞，Claude Code 静默丢一个。**<Platform> 规则：name 全仓库唯一，建议加前缀如 `qx-reviewer`、`qx-debugger`。**

### 2.3 内置 subagent（Anthropic 已预制）

| 名字 | 模型 | 工具 | 用途 |
|---|---|---|---|
| **Explore** | Haiku | read-only（Write/Edit deny） | 快速 codebase 探索，支持 quick/medium/very thorough 三档[^1] |
| **Plan** | inherit | 视情况 | Plan mode 输出 |
| **General-purpose** | inherit | 全部 | 通用回退 |

### 2.4 隔离机制：三层

| 隔离层 | 机制 | 何时用 |
|---|---|---|
| **Context 隔离**（默认） | 独立 context window，新 system prompt | 一切 subagent 默认开启 |
| **Tool 隔离** | `tools` 白名单 + `disallowedTools` 黑名单 + `permissionMode` | 想让子代理只读 / 只 Bash / 只跑特定 MCP |
| **Filesystem 隔离** | `isolation: worktree` — 临时 git worktree 副本；无修改则自动清理[^1] | 大型重构、危险实验、想保留多个候选方案 |

> **<Platform> 默认**：`migration-worker` / `experimentation-worker` 必须 `isolation: worktree`；其他默认共享主 cwd。

### 2.5 调用方式（三档）

| 强度 | 语法 | 行为 |
|---|---|---|
| 自然语言提示 | `Use the code-reviewer subagent to ...` | 主代理决定是否委派 |
| @-mention | `@"code-reviewer (agent)" look at ...` | 保证委派给指定子代理 |
| 全会话 | `claude --agent code-reviewer` 或 `.claude/settings.json` 设 `agent` | 整个 session 用该子代理的 system prompt+工具+模型 |

### 2.6 前后台与并行

- **Foreground**：阻塞主对话，permission prompt 透传给用户。
- **Background**：并发跑，用已授予的 permission，会 auto-deny 任何会触发 prompt 的调用。
- 触发方式：让 Claude 自己判断 / 显式说"run in background" / 按 `Ctrl+B` / 子代理 frontmatter `background: true`。
- 全禁：环境变量 `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`。

### 2.7 关键限制（必知）

| 限制 | 影响 |
|---|---|
| **子代理不能 spawn 其他子代理** | 嵌套委派必须由主代理串接，或用 Skills/Plugins 替代[^1] |
| **子代理摘要回传仍占主 context** | 并行多个 subagent 时摘要叠加会显著吃 context（Anthropic 官方 warn）[^1] |
| **每次调用都是 fresh instance** | 想"接着上次的"必须显式 resume（需开启 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`） |
| **Auto-compaction 默认 95%** | 子代理也压缩；可用 `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=50` 提前 |

### 2.8 Fork mode（实验，v2.1.117+）

`CLAUDE_CODE_FORK_SUBAGENT=1` 开启后：

- `/fork <directive>` 创建 **fork**——继承全部主会话历史（system prompt / tools / model / message history）；
- 与命名 subagent 区别：fork 不重新初始化 context，**省一次 cache rebuild**；
- 适合"已经聊了半天，需要分支去试一个想法"；
- fork 不能再 fork；fork 与命名 subagent 都强制后台。

---

## §3 其他工具的等价物（横向对照）

| 工具 | 等价物 | 隔离强度 | 备注 |
|---|---|---|---|
| **Sourcegraph Amp** | Subagent 通过 Task tool 启动 + 内置 **Oracle**（GPT-5.4 二次意见）、**Librarian**（跨仓 GitHub 搜索）、**Painter**（Gemini 3 Pro Image） | Context 独立 + Plugin TS hook 可拦 | `.agents/checks/*.md` 每条 check 一个 subagent 跑[^3] |
| **OpenAI Codex CLI** | Profile / Workspace 切换 + 多 session 编排（无原生 subagent 概念，但 AGENTS.md 可分 scope） | Context 独立（session 级） | 走 Skills/Subagents 兼容 Claude 生态[^4] |
| **Cursor**（2.4+） | **本地** `.cursor/agents/*.md`（兼容 `.claude/agents/`、`.codex/agents/`）+ **Cloud Agents**（旧称 Background Agents · cursor.com/agents + Slack/GitHub/Linear/API 入口）；内置 Explore / Bash / Browser | 本地：context 独立 + `readonly` 字段；云端：完整 VM 隔离 + 远程桌面 | 本地适合即时探索 / 审查；云端适合长任务、需 IDE 自动操作；`/name` 调用 |
| **Roo Code Orchestrator Mode** | Mode 切换（Code/Architect/Debug/Orchestrator） | Context 切换（同 conversation） | 自由度高、隔离弱 |
| **Devin** | Cloud VM (Shell+IDE+Browser) + Playbooks | 完整 VM 隔离 | `/handoff` 把本地 CLI 任务转给云端 Devin 接力[^5] |
| **Manus** | "主-辅" agent 架构（Planner + Executor） | Context 独立 | 闭源，细节有限 |
| **Aider** | 单代理，无 subagent | — | 用 `/architect` 模式做轻度规划-实现分离 |

> **核心趋势**：所有工具最终都要解决"main context 不能被工具输出/探索污染"的问题；**Claude Code 的 YAML + 隔离 + worktree 是当前最完整的 reference 实现**。

---

## §4 五种典型 Subagent 拓扑

> 这是本篇最实用的产物——把抽象的"subagent"映射到具体的工程场景。

### 4.1 拓扑 A · Single Worker（最简）

```
[Main] ──delegate──▶ [Worker] ──summary──▶ [Main]
```

- 用例：跑测试、查日志、生成单文件代码。
- 时机：任务有明确边界、能 1 次完成。

### 4.2 拓扑 B · Parallel Researchers（并行调研）

```
            ┌──▶ [Researcher A: auth] ──┐
[Main] ─────┼──▶ [Researcher B: db]  ───┼──▶ summaries ──▶ [Main]
            └──▶ [Researcher C: api] ───┘
```

- 用例：跨模块平行探索、候选方案对比。
- 风险：子代理摘要叠加吃 context，Anthropic 官方 warn[^1]。
- **<Platform> 规则**：并行 ≤ 3 个；超出走 [agent teams](https://code.claude.com/docs/en/agent-teams) 或拆两轮串行。

### 4.3 拓扑 C · Pipeline（流水线）

```
[Main] ──▶ [Reviewer] ──findings──▶ [Main] ──▶ [Fixer] ──diff──▶ [Main] ──▶ [Tester]
```

- 用例：审 → 改 → 测；spec → 实现 → review。
- **关键**：每段必须回到 Main 才能再 spawn 下一个（子代理不能 spawn 子代理）。

### 4.4 拓扑 D · Worktree Sandbox（重构 / 危险实验）

```
[Main] ──▶ [Migration-Worker, isolation: worktree]
              │
              ├── tmp worktree at /tmp/xxx
              ├── 大量 edit/test/iterate
              └──▶ 把 diff 摘要 + worktree 路径回 Main
[Main] ──▶ 决定 cherry-pick / apply / 丢弃
```

- 用例：跨多文件大型重构、依赖升级、风险高的修改。
- 优势：不污染主 checkout，可保留多个候选 worktree 对比。

### 4.5 拓扑 E · Fork-Then-Diverge（实验性，v2.1.117+）

```
[Main, 已聊 100 turns] ──/fork "试试 approach A"──▶ [Fork A]
                       └──/fork "试试 approach B"──▶ [Fork B]
[Main] ◀──── 两个 fork 各自跑完回汇结果 ────
```

- 用例：在已建立大量上下文后，平行试多种方案。
- 优势：复用 prompt cache，比从头 spawn 命名 subagent 便宜。
- 限制：fork 不能再 fork。

---

## §5 反模式（必避）

| 反模式 | 症状 | 修复 |
|---|---|---|
| **过度 fan-out** | 一次性 spawn 10+ subagent，摘要回汇直接撑爆主 context | 限并发 ≤ 3；走 agent teams 或串行 |
| **Subagent 拿全工具** | 不写 `tools` 字段，子代理继承全部，越权风险大 | 总是显式写 `tools` 白名单 |
| **Subagent 拒绝写 NOTES** | 长任务 subagent 不维护 memory，下次重启从零 | frontmatter 写 `memory: project` + system prompt 显式要求"任务结束写 MEMORY.md" |
| **嵌套 subagent 期待** | 写 "subagent A 完成后让 subagent B 接手" 给子代理 | 子代理不能 spawn 子代理；由主代理 pipeline 串接 |
| **Permission bypass 滥用** | 给 subagent 设 `bypassPermissions` 求方便 | 只在受控 sandbox/worktree 用；其他场景禁止 |
| **Background subagent 卡在 prompt** | 子代理在后台跑、需要 permission 时直接 auto-deny | 提前在 settings.json 把必要工具 allow；或让其前台跑 |
| **name 冲突** | 两个 .md 同 name，被静默丢一个 | 命名规范 `qx-<role>-<scope>` |

---

## §6 给 <Platform> 的启示（I-N）

- **I-1**：在 `<backend-repo>/.claude/agents/` 沉淀 6 个标准 subagent（§0 列表），name 加 `qx-` 前缀；写入 SOP 的"第一周"checklist。
- **I-2**：`qx-migration-worker` 与 `qx-experimenter` **强制** `isolation: worktree`；CI 校验任何带 `isolation:` 关键字外的 worktree-类 subagent。
- **I-3**：所有 subagent **必须**写 `tools` 白名单——禁止依赖默认继承。PR review 时把 frontmatter diff 单独列检查项。
- **I-4**：并行 fan-out 上限 **3 个**；超出必须走 [agent teams](https://code.claude.com/docs/en/agent-teams) 或拆成两轮串行（避免主 context 摘要堆叠）。
- **I-5**：每个 subagent 的 `description` 必须含"何时用 / 何时不用"两段；触发词加"use proactively"提高自动委派命中率（Anthropic 官方推荐）[^1]。
- **I-6**：危险操作（`bypassPermissions`、`Bash` 写操作、`Write` 到 `.git/.claude/`）一律加 **PreToolUse hook 校验脚本**——硬约束，绕过 LLM 自由度（见 [05 §8 决策清单](05_context-engineering.md)）。
- **I-7**：子代理 `memory: project` 默认开启；提交时 `.claude/agent-memory/<name>/MEMORY.md` 一起入仓，作为团队知识资产。
- **I-8**：Hooks 配 `SubagentStart`/`SubagentStop`，往可观测系统上报子代理生命周期事件——这是 AI 用量审计的最小可行实现（呼应 [02 §2.5 Verification-First](02_coding-paradigms-2026.md)）。

---

## §7 未尽事项（转下一篇）

1. **Skill 与 Subagent 的取舍：何时建哪一个** → 转 [07 Skills/Prompts](07_skills-and-prompts.md)；本篇只点了"frontmatter `skills:` 字段会注入全文"这一事实。
2. **大型重构的 worktree 流水线 + cherry-pick 操作手册** → 转 [03 大项目工作流](03_large-project-workflows.md)。
3. **Hooks 完整事件列表、Permission 系统、Sandbox 设置** → 转 [08 质量/安全/评估](08_quality-safety-eval.md)。
4. **agent teams 实验功能（CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS）的拓扑与同步原语** → 待 Anthropic 正式 GA 后单独立题。

---

## §8 参考链接索引（2026 一手）

[^1]: Claude Code — *Create custom subagents*（含 frontmatter 完整字段、isolation: worktree、Fork mode v2.1.117+、SubagentStart/Stop hooks、Agent tool rename from Task v2.1.63）：<https://code.claude.com/docs/en/sub-agents>
[^2]: Anthropic — *Effective Context Engineering for AI Agents*（subagent 摘要 1–2k token、与 compaction/note-taking 三招对比）：<https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents>
[^3]: Sourcegraph Amp — *Manual: Subagents (Oracle/Librarian/Painter) + .agents/checks/*：<https://ampcode.com/manual#subagents>
[^4]: OpenAI Codex CLI — Skills + Subagents + Hooks：<https://developers.openai.com/codex/cli/configuration>
[^5]: Devin Docs — *Cloud VM + /handoff + Playbooks*：<https://docs.devin.ai/>
[^6]: Claude Code — *Agent teams*（实验性多代理协作）：<https://code.claude.com/docs/en/agent-teams>
[^7]: Anthropic — *How we built our multi-agent research system*（拓扑设计原理）：<https://www.anthropic.com/engineering/multi-agent-research-system>
[^8]: Claude Code — *Hooks*（SubagentStart/Stop 事件 + PreToolUse exit code 2 拦截）：<https://code.claude.com/docs/en/hooks>

> 本篇基于 §8 全部 8 个一手链接撰写；§4 五种拓扑与 §6 八条启示是基于事实推导的 <Platform> 落地建议。
