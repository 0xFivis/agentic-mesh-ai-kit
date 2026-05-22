<!-- REFERENCE ONLY: sanitized sample, not for production -->
# 04 · AI 编码工具全景（2026/Q2）

> **范围**：聚焦"会写代码"的 AI 工具，按交互形态分四象限。**不包含**仅做补全或问答的工具（Tabnine / Cody Chat 等纳入扩展阅读）。每条断言均带 2026 一手 URL。
> **目的**：给 <Platform> 选型提供事实底座，避免被自媒体"全家桶"误导。

---

## 0 · 一句话结论

> 2026/Q2 头部 AI 编码工具已分化为 **四个生态位**：(A) IDE 原生、(B) CLI Agent、(C) 云端长跑 Agent、(D) PR Review 专家。**没有一个工具同时占满四格**；理性团队是"组合拳"。<Platform> 推荐栈：**Claude Code（CLI 主力）+ Cursor 或 Copilot（IDE 协同）+ CodeRabbit（PR 守门）+ Codex Cloud / Devin（夜跑长任务，可选）**。

---

## 1 · 四象限分类

```
                  低自治                                            高自治
  ┌──────────────────────────────────────┬──────────────────────────────────────┐
  │ A · IDE 原生（你在驾驶）              │ C · 云端长跑 Agent（你下任务后离场）  │
  │ Cursor / Windsurf / Copilot Agent    │ Devin / Codex Cloud / Cursor Cloud /  │
  │ / Zed / JetBrains AI / Continue      │ Copilot Coding Agent / Manus          │
  ├──────────────────────────────────────┼──────────────────────────────────────┤
  │ B · CLI Agent（终端原生 + IDE 桥接）  │ D · PR Review 专家（被动守门）        │
  │ Claude Code / Codex CLI / Amp /      │ CodeRabbit / Greptile / Cursor       │
  │ Aider / Gemini CLI / Plandex /       │ Bugbot / Sourcegraph Amp Review      │
  │ OpenCode / Cline (VS Code 兼 CLI)    │                                       │
  └──────────────────────────────────────┴──────────────────────────────────────┘
```

> A 与 B 的边界在弱化（CLI 几乎都能 attach 到 IDE）；真正的差别是**默认交互面**与**心智模型**。

---

## 2 · 全景对照表（按象限分组）

| 工具 | 象限 | 入口文件 | Skills | Subagents | Hooks/Plugins | MCP | 沙箱/隔离 | 计价 | 一手 URL |
|------|------|---------|--------|-----------|---------------|-----|---------|------|---------|
| **Claude Code** | B | CLAUDE.md（+ `@AGENTS.md`） | ✅ `.claude/skills/SKILL.md` | ✅ `.claude/agents/` | ✅ Hooks | ✅ | git worktree 隔离 | 按订阅（Pro/Max） | [code.claude.com/docs](https://code.claude.com/docs/en) |
| **OpenAI Codex CLI** | B | AGENTS.md | ✅ | ✅ Subagents | ✅ Hooks | ✅ | 本地沙箱 + 审批模式 | ChatGPT Plus/Pro/Business/Edu/Ent 包含 | [developers.openai.com/codex/cli](https://developers.openai.com/codex/cli/) |
| **Amp (Sourcegraph)** | B+A | AGENTS.md（回退 AGENT.md / CLAUDE.md） | ✅ `.agents/skills/`（兼容 `.claude/skills/`） | ✅ Task 工具 | ✅ TS Plugins（`tool.call`/`agent.end`） | ✅（推荐打包到 Skill）| 工作区 MCP 需审批；默认无 tool 提示 | 按 token 透传（Free 段 + 付费）| [ampcode.com/manual](https://ampcode.com/manual) |
| **Aider** | B | `.aider.conf.yml` + CONVENTIONS.md | — | — | — | 实验性 | Git commit per change | OSS + 自带 API key | [aider.chat/docs](https://aider.chat/docs/) |
| **Gemini CLI** | B | GEMINI.md | — | — | — | ✅ | 本地 | Gemini Code Assist 免费层 + Vertex | [github.com/google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli) |
| **Plandex** | B | `.plandex/` 工作分支 | — | ✅ 多工程内置 | — | — | "Pending changes" 沙箱分支 | OSS + Hosted | [plandex.ai/docs](https://docs.plandex.ai/) |
| **OpenCode** | B | AGENTS.md | — | ✅ 实验 | — | ✅ | 本地 | OSS（自带 key 或订阅） | [opencode.ai](https://opencode.ai/docs/) |
| **Cursor** | A | AGENTS.md / `.cursor/rules/*.mdc` / `.cursor/skills/<n>/SKILL.md` | ✅ agentskills.io 原生（兼容 `.claude/skills/`、`.codex/skills/`、`.agents/skills/`；2.4 起 `/migrate-to-skills`） | ✅ `.cursor/agents/*.md`（本地，兼容 `.claude/agents/`、`.codex/agents/`；内置 Explore/Bash/Browser；`/name` 调用）+ **Cloud Agents**（云，含 Slack/GitHub/Linear/API 入口）| ✅ `.cursor/hooks.json`（4 级合并，含 `subagentStart/Stop` 等 18+ 事件，**兼容 Claude 退出码 2**）| ✅ | Checkpoints 本地快照 + Cloud Agent VM 隔离 | 订阅（Pro/Business） | [docs](https://cursor.com/docs) · [agents](https://cursor.com/docs/subagents) · [skills](https://cursor.com/docs/skills) · [hooks](https://cursor.com/docs/hooks) |
| **Windsurf (Cascade)** | A | AGENTS.md（同 Rules 引擎） + `.windsurf/rules/*.md` | ✅ Skills（独立条目） | — | — | ✅ | 本地 | 订阅 | [docs.windsurf.com](https://docs.windsurf.com/windsurf/cascade/memories) |
| **GitHub Copilot (VS Code Agent + Coding Agent)** | A + C | `.github/copilot-instructions.md` / `.github/instructions/*.instructions.md` / AGENTS.md（部分支持） | Prompt Files | Coding Agent（云端） | — | ✅ | 云端 GH Actions Runner | Copilot Pro/Pro+/Business/Enterprise | [docs.github.com/copilot](https://docs.github.com/copilot) |
| **Zed (Agent / ACP)** | A | AGENT.md（也读 AGENTS.md） | — | — | — | ✅ | 本地 | 自带 key 或 Zed AI | [zed.dev/docs](https://zed.dev/docs/ai) |
| **JetBrains AI Assistant / Junie** | A | `.junie/guidelines.md` | — | Junie（云端任务） | — | ✅ | 本地 + 云端 | JetBrains AI 订阅 | [jetbrains.com/junie](https://www.jetbrains.com/junie/) |
| **Continue.dev** | A | `.continue/rules/` | Prompts | — | — | ✅ | 本地 | OSS + Hub | [docs.continue.dev](https://docs.continue.dev/) |
| **Cline** | A+B | `.clinerules/` | — | — | — | ✅ | 本地 + 自带 key | OSS | [docs.cline.bot](https://docs.cline.bot/) |
| **Devin** | C | `.devin/`（知识库 + Playbooks） | Playbooks | 多并行会话 | — | ✅ | 完整云端 VM（Shell+IDE+Browser） | 按月席位 + ACU | [docs.devin.ai](https://docs.devin.ai/) |
| **Codex Cloud** | C | AGENTS.md（与 CLI 共用） | 同 Codex | ✅ | ✅ | ✅ | 隔离容器 | 含在 ChatGPT 套餐 | [openai.com/codex](https://openai.com/codex/) |
| **Cursor Cloud Agents**（旧称 Background Agents） | C | 复用 Cursor 配置 | 复用 Cursor Skills | — | 复用 Cursor Hooks | ✅ | 云端 VM + 远程桌面 | Cursor 订阅 | [cursor.com/docs/cloud-agents](https://cursor.com/docs/cloud-agents) |
| **Manus** | C | 自有配置 | — | 多 Agent | — | ✅ | 云端 VM | 信用点 | [manus.im](https://manus.im/) |
| **CodeRabbit** | D | `.coderabbit.yaml`（path+AST 规则、custom checks） | — | — | — | ✅（外部上下文）| GitHub/GitLab/Bitbucket Webhook | Free OSS / Pro / Enterprise（SOC2 Type II）| [coderabbit.ai](https://www.coderabbit.ai/) |
| **Greptile** | D | 自有配置 | — | — | — | — | PR Webhook | 按月订阅 | [greptile.com](https://www.greptile.com/) |
| **Sourcegraph Amp Review** | D | `.agents/checks/*.md`（含 severity / tools 白名单） | 复用 Amp Skills | ✅ 每个 check 一个 subagent | 复用 Amp Plugins | ✅ | 同 Amp | 同 Amp | [ampcode.com/manual#code-review](https://ampcode.com/manual#code-review) |

> **图例**：✅ 原生 / — 不支持或需第三方扩展。

---

## 3 · 各象限速写（关键差异）

### 3.1 IDE 原生（A）

**适用**：日常 80% 编辑、人在驾驶、需即时看 diff、需要 IDE 重构能力配合。

| 工具 | 杀手锏 | 死穴 |
|------|--------|------|
| **Cursor** | Plan Mode（Shift+Tab 5 步澄清→检索→出方案→Markdown 审阅→Build）、Checkpoints、Tab 模型、`.cursor/agents/*` 本地 Subagent + Cloud Agents、`.cursor/skills/` 原生 agentskills.io、`.cursor/hooks.json`（兼容 Claude 退出码 2）| 闭源订阅、模型权重在 Cursor 服务器 |
| **Windsurf** | Memories 自动持久化、Cascade Flows、Skills + Workflows 双轨、企业 System Rules | Codeium → Cognition 收购后路线不稳 |
| **Copilot (VS Code Agent)** | 与 GitHub Issues/Actions/PR 闭环、Coding Agent 云端跑 PR、Workspace 与企业治理成熟 | Agent 自主度仍低于 Cursor/Claude Code |
| **Zed** | 性能极快（Rust）、ACP（Agent Client Protocol）开放 | 生态最小 |
| **JetBrains AI / Junie** | JetBrains IDE 重度用户必需；Junie 提供云端长任务 | Plan/Skill 抽象较弱 |

### 3.2 CLI Agent（B）

**适用**：长任务、自动化脚本、夜跑、SSH 服务器、CI 集成。

| 工具 | 杀手锏 | 死穴 |
|------|--------|------|
| **Claude Code** | Skills/Subagents/Hooks/`/rewind`/Plan Mode 五件套最完整；CLAUDE.md `@import` 任意文件 | 仅 Anthropic 模型 |
| **Codex CLI** | OpenAI 模型自由度 + 全功能矩阵（AGENTS.md/Rules/Hooks/Skills/Subagents/Approvals/Non-interactive）；Rust 实现 | 生态略晚于 Claude Code 一拍 |
| **Amp** | "多模型自动调度"（GPT-5.5 / Opus 4.7 / fast 各取所长）、Oracle（GPT-5.4 second-opinion）、Librarian（跨仓 GitHub 搜索 subagent）、TypeScript Plugin API（`tool.call`/`tool.result`/`agent.end`） | 按 token 透传无包月，重度用户成本高 |
| **Aider** | OSS、Git-first（每次改动一个 commit）、最稳的"代码补丁"形态 | 无 Skills/Subagents 抽象 |
| **Gemini CLI** | Google 模型 + 100 万 ctx；个人 Code Assist 免费层 | 入口文件只认 GEMINI.md |
| **Plandex** | "Pending changes 工作分支"——AI 改在影分支，明确 review 后才 apply | 用户基数小 |
| **OpenCode** | OSS、UI 干净、AGENTS.md 原生 | 功能面窄 |

### 3.3 云端长跑 Agent（C）

**适用**：Linear/Jira 票自动认领、夜跑批量任务、跨仓重构、客户支持。

| 工具 | 杀手锏 | 死穴 |
|------|--------|------|
| **Devin** | 完整云 VM（Shell+IDE+Browser）、Slack/Teams 标记触发、`/handoff` CLI→Cloud 接力、Playbooks 沉淀 SOP | 按月席位+ACU 计费贵；事实自治度被独立测评质疑过 |
| **Codex Cloud** | 与 CLI 共用 AGENTS.md/Skills/Subagents；含在 ChatGPT 套餐 | UI 较新 |
| **Cursor Cloud Agents** | 复用 Cursor 全部配置，订阅内即得；多入口（cursor.com/agents + Slack/GitHub/Linear/API） | 自治深度浅于 Devin |
| **Copilot Coding Agent** | GH Actions Runner 跑、Issue→PR 全链路 | 仅 GitHub 生态 |
| **Manus** | 浏览器/电脑使用强、信用点计价 | 国内合规与稳定性需验证 |

### 3.4 PR Review 专家（D）

**适用**：PR 守门、与人审互补、强制规约落地。

| 工具 | 杀手锏 | 死穴 |
|------|--------|------|
| **CodeRabbit** | 3M 仓库装机量、`.coderabbit.yaml` 高可定制（path/AST 规则 + custom checks + Learnings）、40+ linter 整合、IDE/CLI 三栖、SOC2 Type II | 闭源，token 走云 |
| **Greptile** | 跨大仓代码理解强 | 功能面窄于 CodeRabbit |
| **Cursor Bugbot** | Cursor 用户零成本起步 | 仅 Cursor 生态 |
| **Sourcegraph Amp Review** | `.agents/checks/*.md` 每条 check 单独 subagent；与 Amp 主代理共享 Skills/Plugins/Permissions | 仍偏 Amp 生态 |

---

## 4 · 推荐组合（按团队规模）

| 场景 | 主力 (B) | IDE (A) | 长任务 (C) | 守门 (D) | 月成本档 |
|------|---------|---------|-----------|---------|---------|
| **单兵开发者** | Claude Code Pro **或** Codex CLI（含在 ChatGPT Plus） | Cursor Hobby **或** VS Code + Copilot Pro | — | CodeRabbit Free（OSS） | $20–40 |
| **小型团队 (≤10)** | Claude Code Max **或** Codex CLI Business | Cursor Pro / Copilot Business | Cursor Cloud Agents | CodeRabbit Pro | $30–60/人 |
| **中型团队 (10–50)** | Claude Code + Codex CLI 并存（按任务择优） | Cursor Business + Copilot Enterprise（按部门） | Codex Cloud + Devin（精挑 5–10 席位夜跑） | CodeRabbit Pro + Cursor Bugbot | $50–120/人 |
| **重型/受监管（金融/医疗）** | Claude Code Enterprise（Zero Retention）+ Codex Enterprise | Copilot Enterprise（GH 治理）+ Windsurf Enterprise（System Rules） | Devin Enterprise（VPC）+ Codex Cloud | CodeRabbit Enterprise（SOC2 + Trust Center） | $100–200/人 |

---

## 5 · 选型维度备查（给采购）

按重要性排序：

1. **入口文件中立性**：能不能只写一份 AGENTS.md / CLAUDE.md 喂所有工具？→ 见 [01_entry-file-support-matrix.md](01_entry-file-support-matrix.md)
2. **模型自由度**：能否切到 Anthropic / OpenAI / Google / 本地 OSS？→ Amp / Continue / Cline / Aider 强；Cursor / Windsurf / Claude Code 弱
3. **Skills/Subagents/Hooks 完整度**：Claude Code ≈ Cursor（2.4+）≈ Codex CLI ≈ Amp >> 其他（Cursor 自 2026-05 原生齐 SKILL.md / `.cursor/agents/` / `.cursor/hooks.json`，且兼容 Claude/Codex 格式）
4. **沙箱与权限模型**：Codex Approval Modes、Amp Plugins `tool.call`、Cursor Checkpoints、Devin 云 VM —— 形态各异，按"是否允许 Agent 直接写文件/跑命令"选
5. **隔私与合规**：CodeRabbit SOC2 Type II / Amp Enterprise Zero Retention / Copilot Enterprise GH 治理 —— <Platform> 受 CySEC/MAS 监管，**Zero Retention + 可审计日志**为硬门槛
6. **价格模型**：订阅（Claude Code/Cursor/Copilot）vs 透传（Amp）vs 席位+ACU（Devin）——透传对重度用户最贵但最透明
7. **生态锁定**：Cursor Bugbot 只在 Cursor 里、Copilot Coding Agent 只在 GitHub —— 评估"换工具的迁移成本"

---

## 6 · 给 <Platform> 的 8 条启示

1. **I-1 主力 = Claude Code + Codex CLI 双轨**。理由：两家把 Skills/Subagents/Hooks 做到了原生齐平（见 02 §2.6），SDD 工作流可移植；单押任何一家都形成生态锁定。
2. **I-2 IDE 选 Cursor（Plan Mode + Checkpoints）+ VS Code Copilot（仓库治理）双装**。Cursor 用于复杂功能开发（Plan Mode 强制澄清），Copilot 用于 PR/Issues 闭环。
3. **I-3 入口文件单源 `AGENTS.md`，CLAUDE.md `@AGENTS.md`**。Windsurf / Codex / Cursor / Amp / Aider / Zed 均原生认 AGENTS.md（已在 01 矩阵核实）。
4. **I-4 PR 守门用 CodeRabbit**。NVIDIA / Swiggy / Visma 均生产采用 + SOC2 Type II + 高度可定制 `.coderabbit.yaml`，与 <Platform> 多主体合规架构契合。
5. **I-5 云端长跑 Agent 先试 Codex Cloud（成本含在套餐），Devin 留作"高 ACU 任务"备选**。Devin 月成本结构对小团队不友好。
6. **I-6 强制 Hooks 落地"红线规约"**。Codex Hooks / Claude Code Hooks / Amp `tool.call` Plugins —— 用代码（非提示词）拦截"动钱包/动账本/动监管字段"的命令，杜绝 prompt-injection 绕过。
7. **I-7 拒绝"全家桶"心态**。每个象限选 1 个主力 + 1 个备用即可（5–6 个工具上限）。继续堆砌只会摊薄 CLAUDE.md / AGENTS.md 维护精力。
8. **I-8 设立"工具淘汰季评"**。AI 工具半年迭代一代（Plan Mode、Skills、Subagents 都是 2025/2026 才出的）；每季度复评一次"现栈是否还是最优"。

---

## 7 · 未尽事项

- [ ] Amp 的 "Oracle / Librarian / Painter" 三套内置 subagent 是否值得在 <Platform> 引入（vs 自建 subagent）？→ 留 06
- [ ] Devin Playbooks 与 Claude Code Skills、Codex Skills 的协议互通性 → 留 07
- [ ] CodeRabbit `.coderabbit.yaml` 与 Spec Kit `/speckit.constitution` 的"红线源"是否能合一 → 留 08
- [ ] 国内合规环境下（数据出境）哪些工具有"中国可用"路径（百度 Comate / 阿里通义 / 字节 Trae）→ 列入 09 业界 SOP 标杆

---

## 8 · 参考链接索引

| 工具 | 一手链接 |
|------|---------|
| Claude Code | <https://code.claude.com/docs/en> |
| OpenAI Codex CLI | <https://developers.openai.com/codex/cli/> |
| Amp (Sourcegraph) | <https://ampcode.com/manual> |
| Aider | <https://aider.chat/docs/> |
| Gemini CLI | <https://github.com/google-gemini/gemini-cli> |
| Plandex | <https://docs.plandex.ai/> |
| OpenCode | <https://opencode.ai/docs/> |
| Cursor | <https://cursor.com/docs> · <https://cursor.com/docs/agent/planning> · <https://cursor.com/docs/subagents> · <https://cursor.com/docs/skills> · <https://cursor.com/docs/hooks> · <https://cursor.com/docs/reference/third-party-hooks> |
| Windsurf | <https://docs.windsurf.com/windsurf/cascade/memories> |
| GitHub Copilot | <https://docs.github.com/copilot> |
| Zed Agent | <https://zed.dev/docs/ai> |
| JetBrains Junie | <https://www.jetbrains.com/junie/> |
| Continue.dev | <https://docs.continue.dev/> |
| Cline | <https://docs.cline.bot/> |
| Devin | <https://docs.devin.ai/> |
| Codex Cloud | <https://openai.com/codex/> |
| Cursor Cloud Agents（旧 Background Agents） | <https://cursor.com/docs/cloud-agents> |
| Manus | <https://manus.im/> |
| CodeRabbit | <https://www.coderabbit.ai/> · <https://docs.coderabbit.ai/> |
| Greptile | <https://www.greptile.com/> |
| Sourcegraph Amp Review | <https://ampcode.com/manual#code-review> |

---

> **本篇与 02、01 的衔接**：01 答"在哪写规则"，02 答"按什么范式写"，**04 答"用什么工具写"**。下一篇 [05 上下文工程](05_context-engineering.md) 把三者合成"一份 AGENTS.md + 多工具共用"的可落地方案。
