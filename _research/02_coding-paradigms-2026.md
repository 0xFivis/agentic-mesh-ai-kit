<!-- REFERENCE ONLY: sanitized sample, not for production -->
# 02 · AI 编程范式调研（2026/Q2）

> **目的**：梳理 2025 H2 – 2026 H1 真正在头部团队落地的"用 AI 写代码"的工作范式，区分**炒作词** vs **可执行模式**，为后续 SOP / 模板/ 子代理设计提供地基。
>
> **方法**：每条结论必须来自厂商一手文档或一手工程博客；不引用二手"X 大佬观点"。
>
> **调研时间**：2026-05-18

---

## 0 · 一句话结论

> 2026 年的主流范式不是"vibe coding（凭感觉提示）"，也不是"全自动 Agent 替我写完所有代码"，而是 **"规格驱动 + 计划-执行分段 + 子代理委派 + 检查点回退"** 的人机协作回路。所有头部供应商的官方最佳实践都指向同一个内核：**显式分阶段、显式验证、显式上下文管理**。

---

## 1 · 六种公认范式（按抽象度从低到高）

| # | 范式 | 一句话 | 代表化身 | 适用 |
|---|------|--------|---------|------|
| P1 | **Inline Completion** | 光标处下一个 token 补全 | Copilot 经典模式 / Cursor Tab | 单行/局部 |
| P2 | **Chat-in-IDE** | 选段对话、解释、改写 | Copilot Chat / Cursor Chat | 函数级 |
| P3 | **Edit Mode（多文件编辑）** | 一次任务跨多文件结构化 diff | Copilot Edits / Cursor Composer | 小特性 |
| P4 | **Agentic Loop（自主回路）** | Agent 自己 read/write/exec/verify 循环 | Claude Code / Codex CLI / Cursor Agent | 中等任务 |
| P5 | **Plan-then-Code（计划-执行分段）** | 先 plan mode → 经人审批 → 再 implement | Claude Code Plan Mode / Spec Kit `/plan` | 复杂特性 |
| P6 | **Spec-Driven / Multi-Agent Orchestration** | 规格→计划→任务→执行四件套 + 子代理委派 | GitHub Spec Kit / Anthropic Multi-Agent Research | 大型工程 |

> **关键观察**：P1–P3 是**工具能力**，P4–P6 是**工作流**。当前误区是用 P4 工具按 P1 习惯使用，结果就是"AI 给出能跑但不对的代码"。

---

## 2 · 六大共识原则 + 跨厂商验证

### 2.1 "Explore → Plan → Code → Commit" 四段法

**来源**：Claude Code Best Practices · "Explore first, then plan, then code" 段。

> "Letting Claude jump straight to coding can produce code that solves the wrong problem. Use plan mode to separate exploration from execution."
> — <https://code.claude.com/docs/en/best-practices>

四阶段：
1. **Explore**（Plan Mode 只读）：读文件、回答问题，不写
2. **Plan**：要求生成详细实现计划，可手动编辑
3. **Implement**：退出 Plan Mode，按计划编码并验证
4. **Commit**：生成提交信息并开 PR

**适用判据**（Claude 官方）：
- ✅ 跨多文件改 / 自己不熟的代码区域 / 拿不准方向
- ❌ 一行 typo、加一行 log、重命名——直接做

### 2.2 Spec-Driven Development（SDD）

**来源**：GitHub Spec Kit（开源，101k★，2026/05 仍活跃）

> "Spec-Driven Development flips the script... specifications become executable, directly generating working implementations rather than just guiding them."
> — <https://github.com/github/spec-kit>

七步标准管线（slash commands 形态）：

```
/speckit.constitution → 项目级原则（=<Platform> 的 STD-* 标准）
/speckit.specify      → 写"做什么/为什么"（=PRD L1）
/speckit.clarify      → 澄清未定项（可选但推荐）
/speckit.plan         → 技术栈与实现计划（=ADR + 详设）
/speckit.tasks        → 拆为可执行任务清单
/speckit.analyze      → 跨工件一致性检查（任务 vs 计划 vs 规格）
/speckit.implement    → 执行所有任务
```

> 已支持 **30+ 主流 AI 编程 Agent**（Claude Code/Codex/Copilot/Cursor/Cline/Windsurf/Gemini CLI/...）；同一套 Markdown 模板可跨 Agent 复用。

**核心哲学**：
- Intent-driven：规格定义 "what" 先于 "how"
- Multi-step refinement，**反对一次性 prompt 生成代码**
- 重模型规格解读能力，轻提示词技巧

### 2.3 Multi-Agent Orchestration（Orchestrator-Worker）

**来源**：Anthropic 工程博客 *How we built our multi-agent research system*（2025-06）

> "A multi-agent system with Claude Opus 4 as the lead agent and Claude Sonnet 4 subagents outperformed single-agent Claude Opus 4 by **90.2%** on our internal research eval."
> — <https://www.anthropic.com/engineering/built-multi-agent-research-system>

模式：
- **LeadAgent**：分解任务、生成计划、协调
- **Subagents**：独立上下文窗口并行探索、压缩信息回传
- **CitationAgent**：终段处理引用/校对
- **MemoryAgent**：将关键计划写持久化外存，防止 200k token 截断丢失

**适用边界**（Anthropic 自己强调）：
> "Most coding tasks involve fewer truly parallelizable tasks than research... Multi-agent systems excel at valuable tasks that involve heavy parallelization, information that exceeds single context windows, and interfacing with numerous complex tools."

→ **编码场景不是天然 fit**：用于"读 200 个文件做调研""跨服务一致性审查"等，而非"一起写同一个函数"。

**经济性现实**：
- 多代理系统比单次 chat 用 **~15× token**
- 必须任务价值 > 增量 token 成本，否则不划算

### 2.4 Context Engineering（上下文工程）

> "Context is the most important resource to manage."
> — Claude Code Best Practices

四把斧子（所有主流 Agent 都暴露的能力）：

| 武器 | 机制 | 何时用 |
|------|------|--------|
| **入口文件**（AGENTS.md / CLAUDE.md） | 每次会话开头注入 | 工程级常驻规则 |
| **Subagents** | 独立 context window 并行 | 调研/审查 → 报回摘要 |
| **Skills**（按需加载） | model 决定相关时才注入 | 领域知识/模板（不污染主对话） |
| **Compaction / Rewind** | `/clear` `/compact` `/rewind` `Esc+Esc` | 长会话清理 / 错误回退 |

> 反模式（Claude 官方点名）：
> - **The kitchen sink session**：不相关任务堆同一会话
> - **The over-specified CLAUDE.md**：写太长导致 Claude 反而忽略
> - **The infinite exploration**：让 Agent "investigate X" 不限定范围 → context 爆掉

### 2.5 Verification-First（让 Agent 能自验）

> "Include tests, screenshots, or expected outputs so Claude can check itself. **This is the single highest-leverage thing you can do.**"
> — Claude Code Best Practices

落地：
- 让 Agent 自己 `pytest` / `cargo test` / `npm test` 后看结果
- UI 改动 → 截图比对（Claude in Chrome / Playwright MCP）
- Hooks 强制：每次写文件后跑 lint（区别于"建议写在 CLAUDE.md"——hooks 是确定性的）

> <Platform> 启示：T29 编码规范、T07/T08 验收标准本质上都是给 Agent 的自验脚本/checklist；要从"人审"改成"机审 + 人复核"。

### 2.6 跨厂商对照：Plan-then-Code 不是 Anthropic 独家

> **目的**：验证 §2.1 / §2.2 不是 Anthropic / GitHub 的孤例。截至 2026/05，至少 OpenAI Codex 与 Cursor 都把"先计划再写代码"做成了**官方默认能力**。

#### 2.6.1 Cursor Plan Mode（官方原生）

**来源**：<https://cursor.com/docs/agent/planning>（"Plan 模式"页）

> Plan 模式会在你编写任何代码之前先生成详细的实现方案。Agent 会分析你的代码库、提出澄清性问题，并生成一个可审阅的计划，你可以在开始实现前对其进行编辑。
> 在聊天输入框中按 **Shift+Tab** 可切换到 Plan 模式。

官方五步：
1. Agent 提澄清性问题
2. 检索代码库收集上下文
3. 制定完整实现方案
4. 通过对话或 **Markdown 文件**审阅/编辑（默认存主目录，可 Save to workspace 入仓）
5. 点击"开始构建方案"才落代码

官方适用边界（原文）：
- ✅ 多种可行方案的复杂功能 / 涉及大量文件 / 需求不清需先探索 / 需先审整体架构
- ❌ 简单修改、做过很多次的任务 → 直接 Agent 模式

> **关键金句**（官方原话）：
> "有时 Agent 生成的结果与你的预期不符。与其用后续提示一点点修修补补，**不如回到最初的计划。撤销这些更改，把计划写得更具体、更清晰，然后再重新运行**。这样通常比修复一个进行中的 Agent 更快，输出也更干净利落。"

→ 与 Claude Code 的 "After two failed corrections, `/clear` and write a better initial prompt" 在精神上完全一致。**两家头部 IDE/Agent 工具独立得出同一结论**。

#### 2.6.2 OpenAI Codex CLI（官方功能矩阵）

**来源**：<https://developers.openai.com/codex/cli/>（Codex CLI 总览页）

Codex CLI 官方功能侧栏，明确列出与 Claude Code **几乎一对一对齐**的能力：

| 能力 | Codex CLI 官方路径 |
|------|---------------------|
| 入口文件 | [AGENTS.md](https://developers.openai.com/codex/guides/agents-md) |
| 规则 | [Rules](https://developers.openai.com/codex/rules) |
| 钩子 | [Hooks](https://developers.openai.com/codex/hooks) |
| 技能 | [Skills](https://developers.openai.com/codex/skills) |
| 子代理 | [Subagents](https://developers.openai.com/codex/subagents) |
| MCP | [MCP](https://developers.openai.com/codex/mcp) |
| 审批模式 | [Approval modes](https://developers.openai.com/codex/cli/features#approval-modes) |
| 非交互模式 | [Non-interactive Mode](https://developers.openai.com/codex/noninteractive) |
| Slash 命令 | [Slash commands](https://developers.openai.com/codex/cli/slash-commands) |

> **观察**：Codex CLI 与 Claude Code 在能力面上**功能等价**（入口文件 / Rules / Hooks / Skills / Subagents / MCP / 非交互模式），命名上前者用 `AGENTS.md`，后者用 `CLAUDE.md`。这是 §1 P4–P6 范式跨厂商可移植的强证据。

#### 2.6.3 GitHub Spec Kit "30+ Agent 共用同一套指令"

**来源**：<https://github.com/github/spec-kit>（README · Supported AI Coding Agent Integrations）

> "Spec Kit works with **30+ AI coding agents** — both CLI tools and IDE-based assistants."

Spec Kit 把 `/speckit.constitution → /specify → /clarify → /plan → /tasks → /analyze → /implement` 七步**编译成不同 Agent 各自的命令格式**（Claude Code 的 commands、Cursor 的 commands、Copilot 的 prompts、Codex 的 skills…）。这意味着 **Spec-Driven Development 已成为跨厂商可执行的共同基线**，不依赖任何一家。

#### 2.6.4 三方对照表

| 维度 | Claude Code | Cursor | Codex CLI | 共识 |
|------|-------------|--------|-----------|------|
| Plan-then-Code | Plan Mode（permission-mode） | Plan 模式（Shift+Tab） | 通过 Skills/Subagents 自定义 | ✅ 三家都支持 |
| 计划落盘为 Markdown | `Ctrl+G` 打开编辑 | 默认存主目录，可 Save to workspace | AGENTS.md / Skills 文件 | ✅ |
| 澄清问题先于计划 | `AskUserQuestion` tool + "Let Claude interview you" | Plan Mode 第 1 步即"澄清性问题" | （SDD 通过 `/speckit.clarify`） | ✅ |
| 检查点/回退 | `/rewind`、`Esc+Esc`、`/btw` | 自动检查点 + Restore Checkpoint | （依赖 git） | ⚠️ Codex 弱 |
| 失败 → 回到改计划重跑（非堆 prompt） | "After 2 corrections → `/clear` + 重写 prompt" | "回到最初的计划，撤销更改，把计划写得更具体" | （惯例） | ✅ 两家明文 |
| Hooks 确定性强制 | `.claude/settings.json` Hooks | `.cursor/hooks.json`（4 级 · 兼容 Claude 退出码 2，Cursor 2.x 原生） | Hooks（官方） | ✅ 三家都支持 |
| Skills 按需加载 | `.claude/skills/SKILL.md` | `.cursor/skills/<n>/SKILL.md`（agentskills.io 原生，Cursor 2.4 起 + `/migrate-to-skills`） | Skills（官方） | ✅ 三家都支持（同一 SKILL.md 格式） |
| Subagents | `.claude/agents/*.md` | `.cursor/agents/*.md` 本地（兼容 `.claude/agents/`）+ Cloud Agents | Subagents（官方） | ✅ 三家都支持 |

> **结论**：Plan-then-Code、Skills、Subagents、Hooks、MCP 这五件套已成 2026 头部 Agent 工具的**事实标准能力清单**。SDD 七步管线是跨厂商可移植的工作流标准。这彻底打消了"是否只是 Anthropic 一家之言"的疑虑。

---

### 2.7 Tight Feedback Loop（小步快错快回退）

**来源**：Claude Code Best Practices · "Course-correct early and often"

> "If you've corrected Claude more than twice on the same issue in one session, the context is cluttered with failed approaches. Run `/clear` and start fresh."

工具配套：
- `Esc` 中断保留上下文
- `Esc+Esc` / `/rewind` 检查点回退（每个 prompt 自动快照）
- "Undo that" 让 Agent 反向回滚

> 这是对"完美 prompt 一次成"幻想的根本否定——**回退是一等公民**，不是失败信号。

---

## 3 · 三条已被官方"打脸"的旧实践

### 3.1 ❌ "把所有规范塞进 CLAUDE.md/AGENTS.md"

**官方原话**：
> "Bloated CLAUDE.md files cause Claude to ignore your actual instructions! ... Treat CLAUDE.md like code: review it when things go wrong, prune it regularly."
> — <https://code.claude.com/docs/en/best-practices#write-an-effective-claudemd>

**正解**：常驻规则进入口文件；按需知识 → **Skills**（model 自主调用），结构化检查 → **Hooks**（确定性）。

### 3.2 ❌ "靠 prompt 工程 = 一次 prompt 解决一切"

**官方原话**（GitHub Spec Kit）：
> Core philosophy 第三条："**Multi-step refinement rather than one-shot code generation from prompts**"

**正解**：用 SDD 七步管线把单次 prompt 拆成 spec→plan→tasks→implement→analyze 五个可审查节点。

### 3.3 ❌ "Multi-Agent 对编码万能"

**官方原话**（Anthropic）：
> "**Most coding tasks involve fewer truly parallelizable tasks than research**, and LLM agents are not yet great at coordinating and delegating to other agents in real time."

**正解**：编码场景里 Multi-Agent 主用于（a）调研/审查（独立 context 必要）、（b）跨独立模块的扇出（如批量迁移 2000 个文件用 `claude -p` 循环）；同模块同函数协作仍单 Agent + 子任务委派最稳。

---

## 4 · 范式与项目阶段映射（给 <Platform> 用）

| <Platform> 阶段 | 推荐范式组合 | 关键工具 |
|--------------|------------|---------|
| **文档/调研期**（当前 ai-workflow / tech-docs Phase C 收尾） | P5 Plan-then-Code + P6 Multi-Agent 调研 | Subagent + Skills + Spec Kit `/specify` `/clarify` |
| **Phase 1 平台基线**（IaC、CI/CD、骨架代码） | P5 + P6 SDD 全套 | `/speckit.plan` → `/speckit.tasks` → Hooks 强制 lint |
| **Phase 2 服务编码**（核心微服务实现） | P4 Agentic Loop + P5 Plan Mode + Verification-First | Plan Mode + 子代理 review + 单测自验 |
| **Phase 2 大批量迁移/合规审查** | P6 Multi-Agent 扇出 | `claude -p` 批跑 + LLM-as-judge |
| **Phase 3 监管准入** | Hooks + Sandbox + 严格 Permissions | `.claude/settings.json` + auto mode classifier |

---

## 5 · 不需要追的"概念碎纸"

调研中频繁出现，但**没有厂商一手文档定义、或与上述六范式重叠**的术语，本调研不予采用：

| 术语 | 现状 | 实际指代 |
|------|------|---------|
| "Vibe Coding" | Karpathy 2025 推文造词，**反讽用法** | 等同 P2 Chat-in-IDE 但无规格无验证 |
| "Cursor Rules Engineering" | 营销词 | = Cursor 版的 .cursor/rules / AGENTS.md |
| "Prompt Stack" | 自媒体词 | = Skills + Subagents + 入口文件 已覆盖 |
| "Agent OS" | 部分创业公司话术 | = Agentic Loop（P4）+ Hooks + MCP |
| "Self-Healing Code" | 多为 demo 视频 | = Verification-First + 自动重试 |

---

## 6 · 给 <Platform> 的 8 条启示（→ 直接喂入后续 SOP）

| # | 启示 | 落点 |
|---|------|------|
| **I-1** | 把 SDD 七步直接复用到我们的"PRD L1/L2/L3 → tech-docs 详设 → 服务实现"管线上 | SOP 第 X 节 / `_analysis/A1` |
| **I-2** | "Explore→Plan→Code→Commit" 应作为**所有非小修小补任务的默认工作模式**写入 ai-collab-workflow | ai-collab-workflow.md 主流程 |
| **I-3** | 把 PRD/ADR/STD 三类文档显式映射为：constitution=STD、specify=PRD、plan=ADR+详设、tasks=Issue | A1 SOP 重审 |
| **I-4** | 入口文件（AGENTS.md）只放"广义规则 + 必跑命令 + 红线"；领域知识全部下沉到 Skills | 模板 `templates/entry/` 重写 |
| **I-5** | Hooks 强制 = 红线（不可绕过）；CLAUDE.md/AGENTS.md = 建议（可忽略） → 安全/合规相关一律走 Hooks | 04 工具全景 / 08 质量安全 |
| **I-6** | 子代理用于"独立 context window"必要时——调研、跨服务一致性审查；不要为"显得多代理"而强行拆 | 06 子代理编排 |
| **I-7** | Multi-Agent 经济性：~15× token，仅用于高价值任务（如跨服务架构审查、批量迁移） | 06 + 08 |
| **I-8** | 把 "/clear"、"/rewind"、checkpoint 写入团队工作习惯 ≥ 把"完美 prompt"写入 → 教会"快错快回退" | 03 大项目工作流 + ai-collab-workflow |

---

## 7 · 未尽事项

- [x] ~~Cursor Agent / Composer 的 plan-then-code 是否官方支持~~ → **已答**（§2.6.1：Cursor Plan Mode，Shift+Tab，官方原生五步流）
- [x] ~~OpenAI Codex CLI 是否有 plan/skills 等价物~~ → **已答**（§2.6.2：AGENTS.md / Rules / Hooks / Skills / Subagents 官方俱全）
- [ ] Spec Kit 30+ 集成中是否含 Copilot；命令是否真正跨 Agent 一致？（留 09 业界 SOP 标杆核实）
- [x] ~~Hooks 在 Cursor 中的等价物~~ → **已答**：`.cursor/hooks.json`（Enterprise / Team / Project / User 四级合并，事件含 `subagentStart/Stop / beforeShellExecution / beforeMCPExecution / beforeReadFile / afterFileEdit / beforeSubmitPrompt / preCompact / stop` 等；**原生兼容 Claude Code hook 格式**，退出码 2 = deny；<https://cursor.com/docs/hooks>）
- [ ] "Skills" 这一抽象在 Codex 与 Claude Code 的实现差异（文件协议是否互通）→ 留 07 专题

---

## 8 · 参考链接索引

| 主题 | 链接 | 一手性 |
|------|------|--------|
| Claude Code Best Practices | <https://code.claude.com/docs/en/best-practices> | 一手（Anthropic） |
| Multi-Agent Research System | <https://www.anthropic.com/engineering/built-multi-agent-research-system> | 一手 |
| GitHub Spec Kit | <https://github.com/github/spec-kit> | 一手（GitHub） |
| Spec-Driven 方法论 | <https://github.com/github/spec-kit/blob/main/spec-driven.md> | 一手 |
| Claude Code Memory（CLAUDE.md） | <https://code.claude.com/docs/en/memory> | 一手 |
| Plan Mode | <https://code.claude.com/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode> | 一手 |
| Cursor Plan Mode | <https://cursor.com/docs/agent/planning> | 一手（Cursor） |
| Cursor Agent overview（Checkpoints） | <https://cursor.com/docs/agent/overview> | 一手 |
| OpenAI Codex CLI 总览 | <https://developers.openai.com/codex/cli/> | 一手（OpenAI） |
| Codex AGENTS.md 指南 | <https://developers.openai.com/codex/guides/agents-md> | 一手 |
| Codex Skills / Subagents / Hooks | <https://developers.openai.com/codex/skills> · <https://developers.openai.com/codex/subagents> · <https://developers.openai.com/codex/hooks> | 一手 |

---

> **本篇与 01 的衔接**：01 解决"在哪写规则"（入口文件支持矩阵），02 解决"按什么节奏写代码"（六范式 + Explore-Plan-Code-Commit）。
> **下一篇**：`04_tool-landscape-2026.md`（按用户优先级：先工具全景，再上下文工程，再子代理编排）
