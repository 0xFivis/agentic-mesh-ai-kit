<!-- REFERENCE ONLY: sanitized sample, not for production -->
# 05 · 上下文工程（Context Engineering）2026/Q2

> **定位**：研究"如何在有限的注意力预算内，给 Agent 配置最优的 token 组合"。本篇依赖 [01 入口文件矩阵](01_entry-file-support-matrix.md) 与 [02 编程范式](02_coding-paradigms-2026.md)（§2.4 已点过题），落地为 <Platform> 可执行的上下文层级、记忆策略与 token 预算规则。
> **基准日期**：2026 年 5 月；所有断言均带 2026 年仍可访问的一手 URL。

---

## §0 一句话结论

> **Context Engineering 已取代 Prompt Engineering，成为 Agent 时代的主工程实践**[^1]。核心问题不是"写好一句话"，而是"在 n² 注意力衰减约束下，决定每一轮交互里**塞什么、不塞什么、何时换页**"。可落地的工具链 = **分层入口文件 + 路径作用域规则 + 按需 just-in-time 检索 + 三种长程对策（compaction / 结构化笔记 / 子代理）**。

<Platform> 建议的最小落地集：

1. **三层入口文件**：Managed Policy `CLAUDE.md` / `AGENTS.md`（组织级红线）→ Project `AGENTS.md`（团队共识，被 `CLAUDE.md` `@import`）→ User `~/.claude/CLAUDE.md`（个人偏好）。
2. **AGENTS.md ≤ 200 行**，超出部分一律拆到 `.claude/rules/*.md` 并加 `paths` frontmatter[^2]。
3. **长任务必须配 NOTES.md / TODO** 做结构化笔记，禁止依赖单一上下文窗口连贯性[^1]。
4. **复杂搜索/巨量探索路径必须 fan-out 给 Subagent**，主代理只接收 1–2k token 的摘要[^1][^3]。
5. **MCP 工具集做减法**：工具数量越多，主代理选错概率越高；优先 just-in-time 而非预加载[^1]。

---

## §1 为什么 Context 是稀缺资源（再次强调一次）

### 1.1 注意力衰减（context rot）

Anthropic 官方援引 Chroma 研究：**token 数量越多，模型对 context 内信息的精确召回越差**——所有模型都有这个特性，仅程度不同[^1]。原因：

- Transformer 注意力是 **n² pairwise** 关系，n 增大时注意力被稀释；
- 训练数据中长序列稀少，模型对超长上下文的位置编码经验不足；
- Position encoding interpolation 让模型能处理超训练长度，但精度有衰减。

**结论**：上下文是 finite resource with diminishing marginal returns。

### 1.2 三个常见反模式

| 反模式 | 症状 | 修复 |
|---|---|---|
| Brittle hardcoded prompts | system prompt 里写满 if/else 分支 | 改成简明原则 + few-shot 范例 |
| Vague high-level guidance | "请写出优雅的代码" | 给具体可验证的指标（如"2 空格缩进""提交前跑 `pnpm test`"）[^2] |
| Bloated tool set | 一次性挂 20+ MCP 工具 | 削减到必要工具；如果工程师都说不清何时用，Agent 也说不清[^1] |

---

## §2 三层心智模型：System / Project / Session

> 这是本篇核心抽象。把所有"上下文制品"按**生命周期 + 受众**归位，杜绝"哪个文件该写啥"的扯皮。

### 2.1 System 层（机器/组织级，长寿命）

| 制品 | 路径示例 | 何时写 | 谁能改 |
|---|---|---|---|
| Managed Policy CLAUDE.md | `/Library/Application Support/ClaudeCode/CLAUDE.md`（macOS）/ `/etc/claude-code/CLAUDE.md`（Linux）[^2] | 公司红线：禁止区域、合规要求、安全策略 | IT/DevOps，通过 MDM 推送 |
| User CLAUDE.md | `~/.claude/CLAUDE.md` 或 `~/.claude/rules/*.md`[^2] | 个人偏好：常用语言/编辑器/简称 | 本人 |
| Permissions/Hooks（settings.json） | `~/.claude/settings.json` + 项目 `.claude/settings.json` | 工具白名单、命令拒绝、PreToolUse 拦截 | IT + 项目维护者 |

**红线**：Managed Policy 用 **enforcement**（permissions.deny / sandbox）做硬约束；CLAUDE.md/AGENTS.md 用 **behavioral guidance** 做软引导。两者职责分离，不要互相替代[^2]。

### 2.2 Project 层（仓库级，团队共识）

| 制品 | 路径 | 用途 |
|---|---|---|
| `AGENTS.md` | 仓库根 | 跨工具单源（OpenAI Codex、Cursor、Aider、Gemini CLI、Amp、Windsurf 等原生读）[^4][^5][^6] |
| `CLAUDE.md` | 仓库根 | 首行 `@AGENTS.md` 引入团队共识，下方追加 Claude 专属指令[^2] |
| `.claude/rules/*.md` | 子目录 | 按 `paths` frontmatter 自动激活的局部规则[^2] |
| `.claude/skills/*/SKILL.md` | 子目录 | 可复用工作流，**按需触发**而非默认入栈（细节见 [07 Skills/Prompts](07_skills-and-prompts.md)） |
| `.claude/agents/*.md` | 子目录 | Subagent 定义（见 [06 子代理编排](06_subagent-orchestration.md)） |
| `.coderabbit.yaml` / `.agents/checks/*.md` | 仓库根 | PR Review 阶段的上下文（见 [08 质量/安全/评估](08_quality-safety-eval.md)） |

**单源原则**：项目级"团队共识"只写在 `AGENTS.md`，其他工具通过 `@import`、symlink、或自身 frontmatter `applyTo` 引用，避免 N 份副本漂移。详见 [01 入口文件矩阵 §3 推荐方案](01_entry-file-support-matrix.md)。

### 2.3 Session 层（一次性，短寿命）

| 制品 | 何时产生 | 何时丢弃 |
|---|---|---|
| Plan Mode 输出 | `/plan` 或 Cursor Shift+Tab 进入 Plan[^7] | 用户确认 → 转 Code 模式 |
| Auto Memory `~/.claude/projects/<proj>/memory/MEMORY.md` | Claude 主动写入（v2.1.59+）首 200 行/25 KB 进每次会话[^2] | 用户编辑/删除 |
| Compaction Summary | 接近 context window 阈值时由 Claude 自动生成[^1] | 下一轮 compaction 替换 |
| Structured Notes（NOTES.md / TODO） | Agent 长任务期间自维护 | 任务结束 |
| Subagent Working Set | Subagent fan-out 时各自独立 context | Subagent 返回摘要后销毁 |

---

## §3 长程任务的三种对策（必背）

Anthropic 官方[^1] 把长任务（数十分钟至数小时）的 context 管理收敛为三招。**<Platform> 必须把这三招写进 SOP**：

### 3.1 Compaction（压缩）

- **机制**：接近 context window → 让 LLM 把消息历史摘要 → 用摘要 + 最近 5 个文件重启新窗口[^1]。
- **Claude Code 默认行为**：保留架构决策、未解决 bug、实现细节；丢弃冗余工具输出和重复消息[^1]。
- **轻量变体**：Tool result clearing（清除深处的工具调用结果，因为不需要再看原始返回）已作为 Claude Developer Platform 的官方 feature 上线[^1]。
- **风险**：过度压缩会丢"当时不显眼、后来才关键"的上下文。
- **<Platform> 规则**：长任务先 `/compact`，再恢复必要细节；不要盲目相信压缩后的摘要是完备的。

### 3.2 Structured Note-Taking（结构化笔记 / Agentic Memory）

- **机制**：Agent 主动把进展/决策/未决事项写到上下文外的文件（`NOTES.md`、`TODO`、`MEMORY.md`），后续按需拉回[^1]。
- **代表实现**：
  - Claude Code Auto Memory：写到 `~/.claude/projects/<proj>/memory/MEMORY.md`，首 200 行/25 KB 每次会话自动加载，其余按需读[^2]；
  - Claude Developer Platform Memory Tool（Sonnet 4.5 同发，public beta）：基于文件系统的跨会话知识库[^1]；
  - 自定义 `NOTES.md`：所有工具都支持，最简实现。
- **类比**：Claude Plays Pokémon 用笔记跨数千步保持目标一致性[^1]。
- **<Platform> 规则**：任何 ACU > 1 万 token 或预计 > 30 分钟的任务，**必须**启用 NOTES.md。

### 3.3 Subagent Architecture（子代理隔离）

- **机制**：复杂搜索/探索任务 fan-out 给 subagent，每个 subagent 可用 N 万 token，**只返回 1–2k token 的摘要**给主代理[^1]。
- **效果**：主代理上下文保持干净，专注综合与决策；脏活留在 subagent 隔离窗口里[^3]。
- **典型场景**：跨仓库搜索、文档调研、并行候选方案探索。
- **细节**：见 [06 子代理编排](06_subagent-orchestration.md)。

### 3.4 三招的选择矩阵

| 任务特征 | 首选 |
|---|---|
| 需要大量来回对话、状态主要在脑子里 | Compaction |
| 有清晰里程碑、迭代式推进 | Note-taking |
| 需要并行探索 / 多个独立子问题 | Multi-agent |

> 三招**可以叠加**：典型大型重构 = subagent 做探索 + 主代理用 NOTES.md 记进度 + 接近窗口时 compaction。

---

## §4 检索策略：Just-In-Time vs Pre-Inference

Anthropic 明确指出业界正从"嵌入式预检索"转向"**just-in-time**"[^1]：

### 4.1 Pre-Inference（预加载）

- 启动时把所有可能相关的文件 / 嵌入向量塞进 context；
- 优点：快，无运行时探索成本；
- 缺点：浪费 token，污染注意力；嵌入索引会陈旧。

### 4.2 Just-In-Time（按需）

- Agent 只持有 lightweight identifier（文件路径、查询 ID、URL）；
- 用工具（`glob`/`grep`/`head`/`tail`/MCP 查询）按需拉数据进 context[^1]；
- 优点：上下文干净；自然支持 progressive disclosure；文件名/目录结构本身就携带语义信号（`test_utils.py` 在 `tests/` vs 在 `src/core_logic/` 含义不同）[^1]。
- 缺点：慢；需要好的 tool 设计与 navigation heuristic。

### 4.3 Claude Code 的 Hybrid 模型

- `CLAUDE.md` 在启动时被 **naively dropped into context**（pre-load）[^1]；
- 其他文件靠 `glob`/`grep` just-in-time 检索；
- 这是 "pre-load 团队共识 + JIT 具体文件" 的折中。

### 4.4 <Platform> 决策树

```
要进入 context 的信息？
├── 每次会话都需要 → CLAUDE.md / AGENTS.md（pre-load）
├── 只在某类文件出现时需要 → .claude/rules/*.md + paths frontmatter（JIT 加载）
├── 偶尔需要、有明确触发场景 → Skill（按需触发）
├── 需要从外部系统拉 → MCP tool（JIT，结果直接进 context）
├── 探索成本巨大、结论可压缩 → Subagent（fan-out，只回摘要）
└── 任务横跨多次会话 → Auto Memory / NOTES.md（持久化，按需拉回）
```

---

## §5 工具集设计：少而清晰

Anthropic 与多家厂商共识[^1]：

| 反模式 | 后果 | 修复 |
|---|---|---|
| 工具数量过多 | 主代理在工具选择上耗 token、出错 | 减到必要集；用 subagent 隔离专业工具 |
| 工具职责重叠 | 决策点模糊 | 合并或明确边界 |
| 工具输入参数模糊 | 调用失败、retry 浪费 token | 参数描述写得 LLM-friendly（清晰、不歧义） |
| 工具返回 verbose | 单次返回吃掉 context | 改成 token-efficient 输出 + reference ID |

**经验法则**：如果一个人类工程师都说不清"何时该用这个工具而不是另一个"，Agent 更说不清[^1]。

---

## §6 Memory 三层模型对照

> 不同工具对"memory"理解不同；统一到 **user / project / session** 三层方便对照。

| 层 | Claude Code | Cursor | Windsurf | Codex CLI | 通用 |
|---|---|---|---|---|---|
| **User**（全局个人偏好） | `~/.claude/CLAUDE.md` + `~/.claude/rules/*`[^2] | User Rules（settings）[^7] | `~/.codeium/windsurf/memories/global_rules.md`（6k 字符上限）[^8] | `~/.codex/AGENTS.md`（profile-level）[^5] | 个人 dotfile / 设置 |
| **Project**（仓库级团队共识） | `CLAUDE.md` + `.claude/rules/*` | `.cursor/rules/*.mdc` | `.windsurf/rules/*.md`（12k 上限，frontmatter `trigger`）[^8] | 仓库 `AGENTS.md` | 仓库根 `AGENTS.md` |
| **Session**（本次会话自学） | Auto Memory `MEMORY.md` + 长任务 `NOTES.md` | Cursor Memories（auto） | Windsurf Memories `~/.codeium/windsurf/memories/`（自动生成，不入仓）[^8] | 临时 plan / context cleared on exit | 任意 `NOTES.md` |

**<Platform> 共识**：仓库内只承认 **User 与 Project 层**，**Session 层一律 .gitignore**——避免个人会话状态污染仓库。

---

## §7 Token 预算：经验数字

> 以下数字来自 Anthropic 官方文档与社区共识，不是硬性规定，是 sanity check 起点。

| 项目 | 建议上限 | 出处 |
|---|---|---|
| 单个 `CLAUDE.md`/`AGENTS.md` 行数 | ≤ 200 行 | Claude Code 官方[^2] |
| `MEMORY.md` 首次加载 | 200 行 / 25 KB | Claude Code v2.1.59+[^2] |
| Global rules（Windsurf） | 6 000 字符 | Windsurf docs[^8] |
| Workspace rules per file（Windsurf） | 12 000 字符 | Windsurf docs[^8] |
| Subagent 返回摘要 | 1 000–2 000 token | Anthropic Engineering[^1] |
| `@import` 递归深度（Claude） | ≤ 5 hops | Claude Code 官方[^2] |
| Compaction 触发阈值（默认） | 接近 context window 上限 | Anthropic[^1] |

**<Platform> 工程规则**：任何 `AGENTS.md` PR 增加行数超 50 行 → review 时质询"是否该拆 Skill / Rule"。

---

## §8 决策清单：文件 vs Rule vs Skill vs Subagent vs MCP

这是本篇最实用的产物——把 [01 矩阵](01_entry-file-support-matrix.md) + [02 范式](02_coding-paradigms-2026.md) + [04 工具全景](04_tool-landscape-2026.md) 收敛为决策表：

| 需求形态 | 落地形式 | 理由 |
|---|---|---|
| 每次会话都要遵守的全仓库共识 | `AGENTS.md`（+ `CLAUDE.md @import`） | 必须 pre-load，跨工具单源 |
| 只对某类文件适用（如 `src/api/**/*.ts`） | `.claude/rules/*.md` + `paths` frontmatter[^2] | JIT 加载，省 context |
| 多步可复用工作流（如"发布前检查清单"） | Skill（`SKILL.md`） | 按需触发，progressive disclosure |
| 复杂探索任务、结论可压缩 | Subagent（`.claude/agents/*.md`） | 隔离 context，返回摘要 |
| 单次复杂指令、不需复用 | Slash Command 或 Prompt File | 一次性，无持久化 |
| 需要从外部系统读 / 写数据 | MCP server | 数据按需进 context |
| 必须在某事件强制执行（不能让 LLM 自由判断） | Hook（PreToolUse / PreCommit） | 硬约束，绕过 LLM 自由度 |
| 临时记一笔，下次会话可能还要 | Auto Memory（让 Agent 自己写） | 自动维护 MEMORY.md |
| 长任务中维持目标一致 | `NOTES.md`（结构化笔记） | 跨 compaction 边界存活 |

---

## §9 给 <Platform> 的启示（I-N）

- **I-1**：把 `tech-docs/AGENTS.md`（如有）/ `tech-standards/` 的核心红线**拷一份到仓库根 `AGENTS.md`**，让所有 AI 工具默认读到。避免靠每次 prompt 临时贴。
- **I-2**：`AGENTS.md` 严格控行（≤ 200 行）。任何"只对某个微服务/某种文件适用"的规则**必须**放 `.claude/rules/*.md` + `paths`。
- **I-3**：每个长开发任务（≥ 30 分钟或 ≥ 1 万 token）**必须**在 Agent 工作目录维护 `NOTES.md`；PR 模板里加一项 review checkpoint。
- **I-4**：跨仓库搜索 / 大型重构探索 **必须**走 subagent fan-out；主对话窗口禁止单线程啃巨型 codebase（context rot 风险）。
- **I-5**：MCP 工具集**做减法**——每个项目挂的 MCP server 不超过 5 个；新增 MCP 需走 PR review 与"为什么不能用现有工具替代"论证。
- **I-6**：组织级 enforcement（合规、安全、禁止操作）走 **Hook + Managed Settings**，不要靠 `AGENTS.md` 文字约束。文字约束是软引导，会被 LLM 自由解释。
- **I-7**：Session 层制品（Auto Memory、Plan 输出、临时 NOTES）**全部 .gitignore**。仓库只保留 User/Project 两层。
- **I-8**：建立 **季度 Context Audit**——抽样统计 `AGENTS.md` / `.claude/rules/` / Skills / Subagents 的命中率与失效率；过期的删，矛盾的合，未生效的下线（呼应 [02 §2.5 Verification-First](02_coding-paradigms-2026.md)）。

---

## §10 未尽事项（转下一篇）

1. **Subagent 的具体编排拓扑、隔离机制、错误恢复** → 转 [06 子代理编排](06_subagent-orchestration.md)。
2. **Skill 的 SKILL.md 格式、命名规范、progressive disclosure 实操** → 转 [07 Skills/Prompts](07_skills-and-prompts.md)。
3. **AGENTS.md 在大型 monorepo 的多层组织 + applyTo 详细方案** → 转 [03 大型项目工作流](03_large-project-workflows.md)。
4. **Hook / Permission / Sandbox 的具体配置 + secrets 检测 + 红线机制** → 转 [08 质量/安全/评估](08_quality-safety-eval.md)。

---

## §11 参考链接索引（2026 一手）

[^1]: Anthropic — *Effective Context Engineering for AI Agents*（Sep 29, 2025；2026 Q2 仍现行）：<https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents>
[^2]: Claude Code — *How Claude remembers your project*（含 CLAUDE.md 层级、`.claude/rules/` paths frontmatter、Auto Memory v2.1.59、@import 5-hop、Managed Policy 路径）：<https://code.claude.com/docs/en/memory>
[^3]: Anthropic — *How we built our multi-agent research system*：<https://www.anthropic.com/engineering/multi-agent-research-system>
[^4]: OpenAI Codex CLI — *AGENTS.md*：<https://developers.openai.com/codex/cli/agents-md/>
[^5]: OpenAI Codex CLI — Configuration & profile-level AGENTS.md：<https://developers.openai.com/codex/cli/configuration>
[^6]: Sourcegraph Amp — *AGENTS.md & instruction file fallback*：<https://ampcode.com/manual#agent-instructions>
[^7]: Cursor Docs — *Plan Mode（Shift+Tab）* + Rules：<https://cursor.com/docs/agent/planning>
[^8]: Windsurf Docs — *Memories & Rules*（三层 Global/Workspace/AGENTS，trigger frontmatter，6k/12k 字符上限）：<https://docs.windsurf.com/windsurf/cascade/memories>
[^9]: Chroma Research — *Context Rot*（n² 注意力衰减原始研究）：<https://research.trychroma.com/context-rot>
[^10]: Anthropic — *Memory & Context Management Cookbook*：<https://platform.claude.com/cookbook/tool-use-memory-cookbook>
[^11]: Karpathy on Context Engineering（X/Twitter）：<https://x.com/karpathy/status/1937902205765607626>
[^12]: Model Context Protocol（MCP）官方：<https://modelcontextprotocol.io/docs/getting-started/intro>

> 本篇基于 §11 全部 12 个一手链接撰写，未引入任何内部资料；I-1..I-8 是基于事实推导的 <Platform> 落地建议。
