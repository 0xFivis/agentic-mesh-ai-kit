<!-- REFERENCE ONLY: sanitized sample, not for production -->
# 10 · 大厂 Agent 工具 3 个月增量调研（2026.02.18 – 05.18）

> **范围**：只覆盖**使用层**（用大厂 agent，不自建 agent）。聚焦近 3 个月一手变更，作为 `01–09` 之上的"增量补丁"。
> **不重复**：模型对比、工具全景、Skill/Subagent 写法已在 [04_tool-landscape-2026.md](04_tool-landscape-2026.md) / [06_subagent-orchestration.md](06_subagent-orchestration.md) / [07_skills-and-prompts.md](07_skills-and-prompts.md) 给过；本篇只追"3 月窗口里**变了什么** + **应该怎样回写主文档**"。
> **产出去向**：§9 把全部发现映射成对 [ai-collab-workflow.md](../ai-collab-workflow.md) 的 patch 清单。本仓库是**项目无关方法论**，不在此处做任何项目级落地决策。
> **每条断言**都带 2026 一手 URL，方便 6 个月后再 audit。

---

## 0 · TL;DR（10 句话）

1. 「**Harness**」从黑话变成 Anthropic 官方术语；5 件套（CLAUDE.md / hooks / skills / plugins / MCP）+ LSP + subagents 是事实标准。
2. 主力模型在 3 个月内**换了两代**：Sonnet 4.6 / Opus 4.6 / **Opus 4.7（新 `xhigh` effort）**；GPT-5.2 系列已宣布弃用 → GPT-5.3 / 5.3-Codex / 5.4。
3. Claude Code 把"会话"提升为**一等公民**：`claude agents` 仪表盘 + `/goal` + `/loop` + 后台 session。"一次只跟一个 chat 对话"的心智已过时。
4. 异步云 agent **变主流**：Copilot Cloud Agent（REST API 启动）/ Claude Cowork / ChatGPT Codex 全部进入生产。
5. **Agent PR Review 成独立技能**：GitHub 官方发布 5 类红旗 + 10 分钟分级 review SOP；GitHub Copilot 单月处理了 60M+ reviews，已 1/5 涉及 agent。
6. **Token 成本工程化**：GitHub 公开了 `Effective Tokens` 公式 + 自动 Auditor/Optimizer，单 workflow 优化 19%–62%。
7. **1M context** 在 Opus 4.6 / Sonnet 4.6 GA（Max/Team/Enterprise 默认开启）。
8. **AGENTS.md 成跨厂标准**：[agents.md](https://agents.md/) 由 OpenAI / Cursor / Factory / Amp / Google Jules 联合维护，现交 Linux Foundation 旗下 Agentic AI Foundation 托管，**60k+ OSS 项目**已采用。
9. **Plugin 市场成熟**：Claude Code 引入插件依赖管理 + 企业 marketplace 治理；Copilot CLI 企业 plugin 进入 public preview。
10. **组织角色出现**：「Agent Manager / DRI」从最佳实践写进 Anthropic 客户成功手册——10 人以上团队需指派一名负责人。

---

## 1 · 时间轴（按厂商分线，3 月内重大节点）

### 1.1 Anthropic / Claude Code

| 日期 | 事件 | 一手 URL |
|---|---|---|
| 2.5 | Opus 4.6 公开发布，财金行业试点 | [Advancing finance with Claude Opus 4.6](https://claude.com/blog/opus-4-6-finance) |
| 2.5 | Claude Code 2.1.32 上 Opus 4.6 + **Agent Teams 实验**（多 agent 协作，需 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`） | [Claude Code Changelog 2.1.32](https://code.claude.com/docs/en/changelog) |
| 2.12 | Claude **Enterprise** 开放自助购买 | [Self-serve Enterprise](https://claude.com/blog/self-serve-enterprise) |
| 2.24 | **Cowork** 与 plugins 正式发布（多人协作 + 团队插件市场） | [Cowork and plugins across enterprise](https://claude.com/blog/cowork-plugins-across-enterprise) |
| 2.25 | Claude Code 2.1.63：`/copy` 对所有人开放 + 跨 worktree 共享 project config | Changelog |
| 3.13 | **1M context GA**（Opus 4.6 + Sonnet 4.6）；Claude Code 默认对 Max/Team/Ent 启用 | [1M context is now GA](https://claude.com/blog/1m-context-ga) |
| 4.7 | **Project Glasswing** 启动（AWS / Apple / Google / Cisco / MS / NVIDIA / 摩根大通 等联合做关键软件安全） | [Project Glasswing](https://www.anthropic.com/glasswing) |
| 4.16 | **Opus 4.7** 发布 + 新 `xhigh` effort 档；Auto Mode 对 Max 默认开启 | [Introducing Claude Opus 4.7](https://www.anthropic.com/news/claude-opus-4-7) |
| 4.16 | Claude Code 2.1.111：`/ultrareview`（云端并行多 agent code review）+ `/less-permission-prompts` 技能 | Changelog 2.1.111 |
| 4.22 | LSP tool（go-to-def / find references / hover）内置；C/C++/Java 大代码库可用 | Changelog 2.1.117 |
| 4.28 | "Claude for Creative Work" + plan 模式细化 | [Claude for Creative Work](https://www.anthropic.com/news/claude-for-creative-work) |
| 5.11 | **`/goal`**（设完成条件持续跨轮工作）+ **`claude agents`** 会话仪表盘 + `/scroll-speed` | Changelog 2.1.139 |
| 5.13 | 2.1.141：rewind 增加 "Summarize up to here"；hook 增加 `terminalSequence`（桌面通知） | Changelog 2.1.141 |
| 5.14 | **官方权威指南**：[How Claude Code works in large codebases](https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start) ——首次把 "Harness" 写进官方文档 |
| 5.15 | 2.1.143：plugin 依赖强制 + projected context cost 显示 | Changelog 2.1.143 |

### 1.2 GitHub Copilot

| 日期 | 事件 | URL |
|---|---|---|
| 3.9 | 公开 Agentic Workflows 安全架构（隔离 / 受限输出 / 全量日志） | [Security architecture of GitHub Agentic Workflows](https://github.blog/ai-and-ml/generative-ai/under-the-hood-security-architecture-of-github-agentic-workflows/) |
| 3.10 | "Execution is the new interface"（Copilot SDK 主张：agent 是可调用的执行单元，不是文本接口） | [The era of "AI as text" is over](https://github.blog/ai-and-ml/github-copilot/the-era-of-ai-as-text-is-over-execution-is-the-new-interface/) |
| 4.1 | Copilot CLI **`/fleet`**：并行派发多 agent，prompt 声明依赖 | [Run multiple agents at once with /fleet](https://github.blog/ai-and-ml/github-copilot/run-multiple-agents-at-once-with-fleet-in-copilot-cli/) |
| 4.6 | Copilot CLI 多模型族（Rubber Duck 二次意见） | [Combines model families for a second opinion](https://github.blog/ai-and-ml/github-copilot/github-copilot-cli-combines-model-families-for-a-second-opinion/) |
| 5.6 | **企业管理 plugins** 进入 public preview | [Enterprise-managed plugins in Copilot CLI](https://github.blog/changelog/2026-05-06-enterprise-managed-plugins-in-github-copilot-cli-are-now-in-public-preview) |
| 5.6 | "Validating agentic behavior when correct isn't deterministic"（Trust Layer，使用 dominatory analysis 替代脆弱断言） | [Validating agentic behavior](https://github.blog/ai-and-ml/generative-ai/validating-agentic-behavior-when-correct-isnt-deterministic/) |
| 5.7 | **Agent PR Review 红旗手册**（5 类红旗 + 10 分钟分级 review） | [Agent pull requests are everywhere](https://github.blog/ai-and-ml/generative-ai/agent-pull-requests-are-everywhere-heres-how-to-review-them/) |
| 5.7 | **Token 效率工程**（`Effective Tokens` 公式 + Auditor/Optimizer workflow） | [Improving token efficiency](https://github.blog/ai-and-ml/github-copilot/improving-token-efficiency-in-github-agentic-workflows/) |
| 5.7 | Sonnet 4 / GPT-4.1 标记 deprecated（Copilot 中） | Copilot Changelog |
| 5.13 | **REST API 启动 Copilot Cloud Agent 任务**；JetBrains 引入 Copilot CLI + unified sessions | Copilot Changelog 5.13 |
| 5.14 | Cloud Agent 支持 **auto model selection** | Copilot Changelog 5.14 |
| 5.15 | Copilot Memory 支持 Pro/Pro+ 用户偏好（持久记忆） | Copilot Changelog 5.15 |

### 1.3 OpenAI Codex

| 日期 | 事件 | URL |
|---|---|---|
| 持续 | **GPT-5.3 / 5.3-Codex / 5.3-Instant / 5.4** 上线 | [openai.com/research](https://openai.com/research/index/?tags=codex) |
| 5.1 | Copilot 标记 GPT-5.2 / GPT-5.2-Codex 即将弃用 | Copilot Changelog 5.1 |
| 全期 | ChatGPT Codex（云端 sandbox agent）按任务调度，1–30 分钟出 PR；新增任务中途互联网访问 | [Introducing Codex](https://openai.com/index/introducing-codex/) |
| 全期 | **AGENTS.md** 成为 Codex 系统提示官方推荐配置文件（见 Codex System Message 附录） | 同上 |

### 1.4 Cursor

| 日期 | 事件 | URL |
|---|---|---|
| 2026/Q1 | **Background Agents 正式改名 Cloud Agents**；多入口接入（cursor.com/agents + Slack + GitHub + Linear + REST API）；自带 VM + 远程桌面 | [Cloud Agents](https://cursor.com/docs/cloud-agents) |
| Cursor 2.x | **原生 Subagents**：`.cursor/agents/*.md`（同时识别 `.claude/agents/`、`.codex/agents/`，含 user/project 两级）；frontmatter `name / description / model(inherit|id) / readonly / is_background`；内置 Explore/Bash/Browser；`/name` 调用；前台 + 后台两种模式 | [Subagents](https://cursor.com/docs/subagents) |
| Cursor 2.x | **原生 Hooks**：`.cursor/hooks.json`（Enterprise / Team / Project / User **四级合并**）；事件含 `subagentStart/Stop / beforeShellExecution / beforeMCPExecution / beforeReadFile / afterFileEdit / beforeSubmitPrompt / preCompact / stop` 等 18+ 种；**原生兼容 Claude Code hook 格式**（退出码 2 = deny；`CLAUDE_PROJECT_DIR` env） | [Hooks](https://cursor.com/docs/hooks) · [Third-party Hooks](https://cursor.com/docs/reference/third-party-hooks) |
| **Cursor 2.4**（2026-05） | **原生 Skills（agentskills.io）**：`.cursor/skills/<n>/SKILL.md`（兼容 `.claude/skills`、`.codex/skills`、`.agents/skills`）；`paths` + `disable-model-invocation` + `scripts/references/assets` 三件套；GitHub remote 安装；内置 **`/migrate-to-skills`** 一键从旧 rules 迁移 | [Skills](https://cursor.com/docs/skills) |

> **意义**：Cursor 2.x 发布后，Subagents / Skills / Hooks 三件套已与 Claude Code / Codex CLI 达成事实标准一致，且是唯一**同时读 Claude、Codex、Agentic 三套目录**的客户端——生态兼容性最广。本仓库只需写一份 `.claude/skills/qx-*/`，即可被 Claude Code / Cursor / Codex 三家同时识别。

### 1.5 跨厂标准

| 日期 | 事件 | URL |
|---|---|---|
| 全期 | **agents.md** 移交 Linux Foundation 下 **Agentic AI Foundation** 托管；OpenAI Codex / Cursor / Amp / Google Jules / Factory 联合维护 | [agents.md About](https://agents.md/) |
| — | OSS 采用量：**60,000+** 项目根目录已有 `AGENTS.md` | [GitHub search](https://github.com/search?q=path%3AAGENTS.md+NOT+is%3Afork+NOT+is%3Aarchived&type=code) |
| — | 嵌套生效：OpenAI 主仓库已有 **88 个** AGENTS.md（按目录就近覆盖） | agents.md FAQ |

---

## 2 · 概念升级：Harness 取代 Prompt

### 2.1 官方定义（5.14 Anthropic 客户成功团队首发）

> **The harness matters as much as the model.** It's built from five extension points—CLAUDE.md / hooks / skills / plugins / MCP servers—plus two capabilities: LSP integrations and subagents.

| 组件 | 作用 | 加载时机 | 最常见错误 |
|---|---|---|---|
| **CLAUDE.md** | Claude 自动读取的上下文 | 每个 session | 当 "可复用专长" 仓库——这些应该走 skill |
| **Hooks** | 关键时刻触发的脚本 | 事件触发 | 用 prompt 实现本该自动跑的事 |
| **Skills** | 特定任务类型的封装指令 | 按需触发 | 把所有专长塞进 CLAUDE.md |
| **Plugins** | 打包 skills + hooks + MCP | 一次配置始终可用 | 让好实践留在个人作品集（tribal） |
| **MCP servers** | 接外部工具 / 数据 / API | 一次配置始终可用 | 在基础没跑通前就先建 MCP |
| **LSP**（plugin 形式接） | 符号级代码导航 | 一次配置始终可用 | 以为它"自动可用" |
| **Subagents**（委派能力，非配置点）| 独立 context window 干一件事 | 显式调用 | 把探索和编辑放同一 session |

### 2.2 对主文档的隐含 patch

现行 [ai-collab-workflow.md](../ai-collab-workflow.md) §1.4「三种装配」只列 4 档（入口规则 / 路径规则 / Skill / Subagent），缺第二层（Hooks）/ 第四层（Plugins）/ 横切层（LSP）。本节意味着主文档需要：

- §1.4 装配表升级为 **5+2 件套**
- 新增独立章节展开 **Hooks / Plugins / LSP** 三件（详见 §9）
- 装配顺序约定加一句：「能用 hook 自动做的，不要用 prompt 重复触发」
- §5 Subagents 首段加一句：「Subagent 是**委派能力**，不是**配置点**」——5 件套是配置，subagent 是动作

具体 patch 行见 §9。

---

## 3 · 工作流迁移：从"对话"到"会话舰队"

3 个月窗口里冒出来的、必须知道的新动词：

| 命令 / 概念 | 厂商 | 时间 | 含义 | 替代了什么 |
|---|---|---|---|---|
| `/goal "完成 X 直到 Y"` | Claude Code | 2026-05-11 | 跨轮持续工作，直到完成条件达成 | 反复手动"continue" |
| `/loop 5m <cmd>` | Claude Code | 2026-03-07 | 定时循环触发（每 5min 检查部署） | 外部 cron + 手动检查 |
| `claude agents` | Claude Code | 2026-05-11 | 会话仪表盘：跑中 / 待审 / 已完成 | 反复 `claude --resume` |
| `claude --bg` / `claude -p` | Claude Code | 全期 | 后台 session 异步执行 | 占用一个终端等结果 |
| `/ultrareview [PR#]` | Claude Code | 2026-04-16 | 云端并行多 agent 做 PR 复审 | 单一 model 复审 |
| `/ultraplan` | Claude Code | 全期 | plan 上云用更强模型 refine | 直接进 implement |
| `/fleet` | Copilot CLI | 2026-04-01 | 并行派发多 agent；prompt 声明依赖 | 一个个发 |
| Cowork | Anthropic 产品 | 2026-02-24 | 多人 + 多 agent 共同工作区 | Slack 转发 prompt |
| Copilot Cloud Agent + REST API | GitHub | 2026-05-13 | CI / 外部触发器派任务给云 agent | GitHub Actions 里跑 prompt |
| ChatGPT Codex（async） | OpenAI | 全期 | sandbox 跑 1–30min 出 PR | 本地阻塞式跑 |

**心智模型变化**：
- ❌ 旧：「我打开 chat，跟它对话」
- ✅ 新：「我有 3–5 个 session 在跑，仪表盘看进度，到点回来 review」

---

## 4 · Agent PR Review：独立的新技能

数据先行（[GitHub 5.7 文章](https://github.blog/ai-and-ml/generative-ai/agent-pull-requests-are-everywhere-heres-how-to-review-them/)）：

- Copilot code review 已处理 **60M+** PR review，**一年 10x** 增长
- **20%+** GitHub PR review 涉及 agent
- 学术研究（[arXiv 2601.21276 "More Code, Less Reuse"](https://arxiv.org/abs/2601.21276)）发现：agent 生成代码引入**更多冗余**和**更多技术债**，且 reviewer **主观上更容易批准**

### 4.1 5 类必查红旗

| # | 红旗 | 你必须做的检查 |
|---|---|---|
| 1 | **CI Gaming**——agent 跑不过 CI 时会绕过：删测试 / skip / `\|\| true` | `.github/workflows/` 任何修改、coverage 阈值变化、被 skip 的测试，都需要显式 justification |
| 2 | **代码复用盲区**——agent 用模式匹配复制现有逻辑，造成多套相似 utility | 对每个新 helper 在仓库搜一次，发现等价物 → 强制合并，不只是评论 |
| 3 | **幻觉性正确**——编译通过、所有测试通过，但逻辑错（off-by-one、缺权限检查、边界条件未考虑）| 跟踪最关键路径 input → transforms → output；要求一个**在改动前会失败的新测试** |
| 4 | **Agentic Ghosting**——大 PR 没 implementation plan，多轮 review 后 agent 鬼打墙 | PR 超 5 个无关文件 / 无法一句话说清目的 / body 空 → 直接退回拆分 |
| 5 | **CI 中的非可信输入**——agent workflow 读取 PR body / issue / commit message → 拼 prompt → 把 model 输出 pipe 到 shell（带 `GITHUB_TOKEN`） | 输入消毒、最小权限 `permissions: read-all`、分离 analysis / execution、人工 gate、绝不 `eval` model 输出 |

### 4.2 10 分钟分级 Review SOP

| 时段 | 步骤 | 内容 |
|---|---|---|
| 1–2 min | **扫描 + 分类** | 文件列表、diff 大小；窄任务（文档/CI/小改）vs 复杂（多文件/逻辑/性能/测试） |
| 2–3 min | **CI 优先** | 先看 `.github/workflows/`、test config、coverage、build script。任何削弱 CI 的改动 = 停止信号 |
| 3–5 min | **扫新 utility** | 找新增 function / helper / module，每个仓库搜重复 |
| 5–8 min | **追一条关键路径** | 选最重要的逻辑改动，从 input 追到 output，检查边界 / 权限 / 意外分支 |
| 8–9 min | **安全边界** | 若改了任何调 LLM 的 workflow，跑 §4.1 红旗 5 |
| 9–10 min | **要求证据** | 非平凡逻辑改动 → 要求新测试（改动前会失败的）；高风险改动 → 要 rollback plan |

### 4.3 对主文档的隐含 patch

[ai-collab-workflow.md](../ai-collab-workflow.md) §11「T5 实施→审查→验收（G1~G6）」当前没有 agent-PR 专门章节。本节意味着主文档需要：

- §11 内插入 §11.x **Agent PR Review**：直接搬入 §4.1（5 类红旗）+ §4.2（10 分钟分级 SOP）
- 4-Phase 的 Commit 阶段加注脚：「若 PR 主要作者为 agent，必须先经一次 LLM PR review 作为人审 prerequisite，而非 replacement」

具体 patch 行见 §9。

---

## 5 · Token 经济：从无感成本到可观测

### 5.1 GitHub 公开的 Effective Tokens 公式

$$ ET = m \times (1.0 \times I + 0.1 \times C + 4.0 \times O) $$

| 符号 | 含义 |
|---|---|
| $m$ | 模型成本乘子（Haiku = 0.25× / Sonnet = 1.0× / Opus = 5.0×） |
| $I$ | 新处理的 input tokens |
| $C$ | cache-read tokens（约 1/10 价） |
| $O$ | output tokens（约 4× 价） |

**用途**：让"换模型导致 raw token 数不变但成本骤降"这件事**变成可对账数字**。

### 5.2 GitHub 实测优化结果（[5.7 文章](https://github.blog/ai-and-ml/github-copilot/improving-token-efficiency-in-github-agentic-workflows/)）

| Workflow | 优化后 ET 降幅 | 主要手段 |
|---|---|---|
| Auto-Triage Issues | **−62%** | 把元数据 fetch 从 LLM turn 挪到 pre-agentic CLI step |
| Daily Compiler Quality | −19% | MCP 工具裁剪 |
| Daily Community Attribution | −37% | 同上 |
| Security Guard | −43% | 加 relevance gate：不涉安全文件直接 skip LLM |
| Smoke Claude | −59% | MCP 裁剪 + 模型降级到 Haiku |

### 5.3 三条普适规律（GitHub Microsoft Research 总结）

1. **很多 agent turn 是确定性数据拉取**——这些应该用 `gh` / CLI 在 LLM 之前跑完，把结果写文件给 agent 读
2. **未用 MCP 工具的成本很高**——40 个 GitHub MCP tools 的 schema = 每次 call 多 10–15KB context，若只用 2 个则 38 个是纯开销
3. **一条错配规则可能引发失控循环**——一例：sandbox bash allowlist 不匹配 → agent 进入 **64 turn fallback 循环** 自己重建编译器输出

### 5.4 对主文档的隐含 patch

[ai-collab-workflow.md](../ai-collab-workflow.md) 全文未提 token 经济。本节意味着主文档需要：

- 新增**附录 E · 季度 Audit + Token 经济**：含 ET 公式、5 个实测案例、3 条普适规律、9 项 audit checklist
- §4 Skills 末加一条：「skill 描述超 250 字符 / 系统 prompt 整体超阈值的，先跑 `/context` 估算再合入」
- §1.4 装配表 MCP 列加一句：「默认裁剪原则——过去 90 天未调用的 MCP tool 必须移除」

具体 patch 行见 §9。

---

## 6 · AGENTS.md 跨厂标准

### 6.1 现状

- 主页 [agents.md](https://agents.md/) 列出兼容工具：**OpenAI Codex / Cursor / Amp / Jules / Factory / Aider / Gemini CLI / Warp / Phoenix / Zed / Windsurf / Kilo Code / RooCode / Semgrep / VS Code / Ona**
- 已交 Linux Foundation 旗下 **Agentic AI Foundation** 治理
- GitHub 搜索：**60k+** OSS 项目根目录有 `AGENTS.md`

### 6.2 关键设计原则（来自 spec / FAQ）

1. **没有必填字段**——纯 Markdown，agent 自己 parse
2. **冲突解决**：最靠近被改文件的 AGENTS.md 优先；用户 prompt 覆盖一切
3. **嵌套**——大 monorepo 用嵌套 AGENTS.md，agent 自动读最近一个
4. **跟 README.md 分离**——README 给人看，AGENTS.md 给 agent 看
5. **可执行检查**——若文件里列了测试命令，agent **会自动跑并修到通过**

### 6.3 对主文档的隐含 patch

[ai-collab-workflow.md](../ai-collab-workflow.md) §2「仓库入口装配」当前只讲单仓 AGENTS.md。本节意味着主文档需要：

- §2.1 数据点刷新：兼容工具列表、60k+ OSS 采用、Linux Foundation / Agentic AI Foundation 治理
- 新增 §2.6 **AGENTS.md 嵌套与冲突解决**：5 条设计原则；monorepo / 子模块下「占位 AGENTS.md 仅 import CLAUDE.md」不是合规做法——子目录有独立约定时必须写实质性嵌套 AGENTS.md

具体 patch 行见 §9。

---

## 7 · 组织变化：Agent Manager 角色

[Anthropic 5.14 文章](https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start)直接定义：

> The rollouts that spread fastest had a dedicated infrastructure investment **before broad access**. A small team, sometimes even just one person, wired up the tooling so Claude already fit developer workflows when they first touched it.
>
> An emerging role in several organizations is an **agent manager**: a hybrid PM/engineer function dedicated to managing the Claude Code ecosystem.
>
> For organizations without a dedicated team, the minimum viable version is a **DRI**: one person with ownership over Claude Code configuration, plugin marketplace, and CLAUDE.md conventions.

> Bottoms-up adoption generates enthusiasm but can **fragment without someone to centralize what works**. Without that work, knowledge will **stay tribal** and adoption will plateau.

### 7.1 对主文档的隐含 patch

[ai-collab-workflow.md](../ai-collab-workflow.md) 当前未定义「谁维护这套方法论」。本节意味着主文档需要：

- 在附录 B（Onboarding）或新增附录 F「角色与治理」中定义 **DRI** 的最小职责：
  - 维护仓库根 `CLAUDE.md` / `AGENTS.md` 一致性
  - 维护 plugin / skill marketplace 准入
  - 主持季度 audit（附录 E）
  - 决定团队 prompt → skill → plugin 的升级路径
- 明确建议：「团队规模 ≥ 10 人时必须指派 DRI，否则知识会 stay tribal」

具体 patch 行见 §9。

---

## 8 · 季度 Audit 节奏（强烈建议落地）

Anthropic 自己说的：

> Teams should expect to do a **meaningful configuration review every 3 to 6 months**, but it's also worth doing one whenever performance feels like it's plateaued after major model releases. CLAUDE.md files that guided Claude through patterns it used to struggle with **may become unnecessary or actively constraining** when the next model ships.

### Audit Checklist（建议每季度初执行）

- [ ] **模型层**：当前主力模型是否仍为 latest stable？effort 档位是否还合理？
- [ ] **CLAUDE.md / AGENTS.md**：每条规则问"如果这条不在，新模型会做错吗？"，否则删
- [ ] **Skills**：跑 `/skills` 看 token 估算；超 250 字符的 description 必砍
- [ ] **Hooks**：每个 hook 问"模型已经能自己做这件事吗？"；是 → 删
- [ ] **MCP servers**：每个 tool 在过去 90 天被调用了吗？没有 → 删（按 §5.3 规律 2）
- [ ] **Plugins**：marketplace 上的 plugin 还在维护吗？没有 → 替换或自封
- [ ] **LSP**：所有主力语言的 language server 都跑通了吗？
- [ ] **PR review checklist**：§4 的 5 类红旗是否纳入团队 PR template？
- [ ] **Token spending**：跑一次 ET 公式估算近 30 天用量（粗算即可）

---

## 9 · 对 [ai-collab-workflow.md](../ai-collab-workflow.md) 主文档的 patch 清单

> **本节定位**：本调研的产出去向是更新主文档。下表把 §1–§8 的发现映射到主文档具体章节，标出 **新增 / 修改 / 删除** 三类动作。任何项目级落地（哪个团队装 LSP、谁当 DRI、PR template 抄到哪里）**不属于本仓库**——它们应该由各自的项目仓（例如 team-operating-model）按本主文档为依据，自行决定。

### 9.1 主文档章节 × 调研发现 映射表

| 主文档章节 | 动作 | 内容来源 | 摘要 |
|---|---|---|---|
| **§1.4 三种装配** | 🔧 **改** | §2 Harness | 当前是 4 档（入口/路径规则/Skill/Subagent）；升级为 **5+2 件套**（CLAUDE.md / Hooks / Skills / Plugins / MCP + LSP + Subagents），并保留"能用上一档就不用下一档"的顺序约定 |
| **§1.2 4-Phase 循环** | ➕ **加** | §3 会话舰队 | 在 4-Phase 图后加一段 "**会话维度**"：单 session 之外，新增 `claude agents` 仪表盘 / `/goal` 长任务 / 后台 session / 异步云 agent；心智从「一次跟一个 chat 对话」→「3–5 个 session 并行 + 仪表盘 review」 |
| **§2.1 为什么以 AGENTS.md 为单源** | 🔧 **改** | §6.1 | 兼容工具列表刷新；OSS 采用量 60k+；治理转入 Linux Foundation / Agentic AI Foundation |
| **§2 新增 §2.6 AGENTS.md 嵌套与冲突解决** | ➕ **加** | §6.2 | 5 条设计原则（无必填 / 就近优先 / 嵌套 / 与 README 分离 / 可执行检查）；monorepo 多 AGENTS.md 套用规则 |
| **新增第 4.5 章 Hooks** | ➕ **加** | §2 Harness | 当前主文档完全缺第二层。需补：事件类型 / 何时用 hook 而非 skill / `terminalSequence` 桌面通知（2.1.141）/ 与 lint/format 的关系 |
| **新增第 4.6 章 Plugins & 企业 Marketplace** | ➕ **加** | §2 Harness + 1.1 时间轴 | Claude Code 2.24 plugin GA；2.1.143 引入插件依赖；Copilot CLI 企业 plugin 进入 public preview（5.6）；如何把"已验证 skill 集"打包成 plugin |
| **新增第 4.7 章 LSP 集成** | ➕ **加** | §2 Harness | Claude Code 内置 LSP tool（2.1.117 起）；以 plugin 形式接入；建议每个主力语言配 1 个 language server |
| **§11 (T5 实施→审查→验收) 新增 §11.x Agent PR Review** | ➕ **加** | §4 全节 | 60M+ / 一年 10x / 20%+ 涉 agent 三个数据点；**5 红旗** + **10 分钟分级 SOP** 直接搬过去；标注"Let Copilot review it first" 设为 prerequisite |
| **附录 C 跨工具兼容矩阵** | 🔧 **改** | §1 时间轴 | 模型刷新（Sonnet 4.6 / Opus 4.6 / Opus 4.7 + `xhigh`；GPT-5.3 系列；Sonnet 4 / GPT-4.1 deprecated）；1M context GA；新增 Copilot Cloud Agent REST API、Cowork、`/fleet`、`/goal`、`claude agents`、ChatGPT Codex 行 |
| **新增附录 E · 季度 Audit + Token 经济** | ➕ **加** | §5 + §8 | ET 公式 $ET = m \times (1.0 I + 0.1 C + 4.0 O)$；3 条普适规律（CLI 替 MCP / MCP 工具裁剪 / sandbox allowlist）；9 项 audit checklist；GitHub 19%–62% 实测案例作为锚 |
| **§5 Subagents** | 🔧 **改** | §2 Harness | 现有章节有"独立 context window"；建议加一段 "subagent ≠ 配置点 而是委派动作"——只有 5 件套是配置，subagent 是能力 |
| **散落各处的"chat 心智"措辞** | 🗑️ **删/改** | §3 + §10 | 全文搜 "对话 / chat" 与 "单 session" 假设；改为 "session（可能是后台/云端）"。`/research` `/explore` 等已被 `/goal`+`claude agents` 取代的措辞按 §10 表清理 |
| **任何引用 METR 19% / 12-factor / Superpowers / Opus 4.x 默认 的位置** | 🗑️ **删/标过时** | §10 全节 | 按 §10 表清理；保留 12-factor / Superpowers 的提及（仍正确）但加注 "**对'只用大厂 agent'的团队无关**，本主文档不再展开" |

### 9.2 Patch 实施顺序建议（写主文档时的依赖关系）

1. 先动 **§1.4 三种装配 → 升级为 5+2**（这是后续所有章节的语义底座）
2. 再补 **§4.5 Hooks / §4.6 Plugins / §4.7 LSP** 三新章（5+2 升级后的具体展开）
3. 然后 **§1.2 加会话舰队** + **附录 C 矩阵刷新**（让心智模型和事实矩阵同步）
4. 再做 **§11.x Agent PR Review**（独立性最强，可任何时候插入）
5. 最后做 **附录 E** 与 **§10 散落措辞清理**（收尾）

### 9.3 与 _research/ 其他篇的协同

| 触发本次 patch 的发现 | 同时需要 patch 哪些 _research 文档 |
|---|---|
| Harness 5+2（§2） | [04_tool-landscape-2026.md](04_tool-landscape-2026.md) 矩阵列要加 Hooks / Plugins / LSP 三列 |
| 会话舰队（§3） | [02_coding-paradigms-2026.md](02_coding-paradigms-2026.md) 加"会话维度"范式 |
| Agent PR Review（§4） | [08_quality-security-evaluation.md](08_quality-security-evaluation.md) 加 §4.1 红旗 5 |
| Token 经济（§5） | [05_context-engineering.md](05_context-engineering.md) 加 ET 公式 + 3 规律 |
| AGENTS.md 60k+ + 嵌套（§6） | [01_entry-file-support-matrix.md](01_entry-file-support-matrix.md) 数据刷新 |

> **不动**：[06_subagent-orchestration.md](06_subagent-orchestration.md) / [07_skills-and-prompts.md](07_skills-and-prompts.md) / [09_industry-sop-benchmarks.md](09_industry-sop-benchmarks.md) 三篇在 3 月窗口内核心结论未变，**不要为了刷新而刷新**——按 §8 audit 原则，"不在新模型下出错的规则就不动"。

---

## 10 · 已过时（请从原报告中删除/标注）

| 出处 | 内容 | 状态 |
|---|---|---|
| 引用 [METR 19% slowdown 研究](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/) | "AI 让有经验 dev 慢 19%" | ❌ **作者已撤回**（2.24）；不要再引 |
| 12-factor agents 详细规范 | "构建 agent 的 12 条" | ⚠ 仍正确，但对「只用大厂 agent」的团队**无关**——主文档可提及不展开 |
| Superpowers 插件 SOP（195k stars） | 7 步流程 | ⚠ 仍有效但**已被各家 harness 内化**；不需要单独装 |
| 「单 chat 心智」相关章节 | "一次跟一个 chat 对话" | ❌ 被会话舰队取代（见 §3） |
| "skills 是新概念，等待成熟" | — | ❌ 已合并入 slash command（Claude Code 2.1.3）|
| Opus 4 / 4.1 默认 | — | ❌ 已从 Claude Code 第一方 API 移除（2.1.69）|

---

## 11 · 推荐阅读（按性价比排）

1. ⭐ [How Claude Code works in large codebases](https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start) — Anthropic 5.14，**3 月内最重要的一篇**
2. ⭐ [Agent pull requests are everywhere](https://github.blog/ai-and-ml/generative-ai/agent-pull-requests-are-everywhere-heres-how-to-review-them/) — GitHub 5.7，PR review SOP 直接抄
3. ⭐ [Improving token efficiency in GitHub Agentic Workflows](https://github.blog/ai-and-ml/github-copilot/improving-token-efficiency-in-github-agentic-workflows/) — GitHub 5.7，ET 公式 + 实测数据
4. [Validating agentic behavior when correct isn't deterministic](https://github.blog/ai-and-ml/generative-ai/validating-agentic-behavior-when-correct-isnt-deterministic/) — GitHub 5.6，未来一年 agent eval 方法
5. [Under the hood: Security architecture of GitHub Agentic Workflows](https://github.blog/ai-and-ml/generative-ai/under-the-hood-security-architecture-of-github-agentic-workflows/) — GitHub 3.9
6. [agents.md](https://agents.md/) — 跨厂标准官网
7. [Claude Code Changelog](https://code.claude.com/docs/en/changelog) — 每两周扫一次

---

## Changelog

| 日期 | 变更 |
|---|---|
| 2026-05-18 | 首版（覆盖 2026.02.18–05.18 三个月增量） |
