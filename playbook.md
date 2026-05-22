<!-- REFERENCE ONLY: sanitized sample, not for production -->
# AI Agent Playbook · 战术手册

> **本文为唯一事实源**。`ai-agent-playbook.html` 是渲染产物，最后从本文同步。
> 与 [`sop/tech-delivery-sop.md`](sop/tech-delivery-sop.md) 配套：SOP 定义"做什么 / 谁做 / Gate 在哪"（宏观工序），本手册定义"用哪家 vendor agent 怎么熟练操作"（微观协作单元）。两者分层不重叠，删本手册全部内容后 SOP 仍可执行（C1 降级）。
> 适用：Claude Code / Cursor / GitHub Copilot / OpenAI Codex 四家主流 agent · 基于 2026/5 vendor 官方文档。
> 视觉派生：[`diagrams/output/02-ai-collab-playbook.html`](diagrams/output/02-ai-collab-playbook.html)（**以本文为准**）。

---

## 目录

**Part 1 · 组织原则**
- [1.1 两层关系：宏观工序 × 微观协作](#11-两层关系宏观工序--微观协作)
- [1.2 4-Phase 通用循环](#12-4-phase-通用循环)
- [1.3 AI 能力分级](#13-ai-能力分级)
- [1.4 装配优先级](#14-装配优先级)
- [1.5 Feature / Task 两层结构](#15-feature--task-两层结构)

**Part 2 · 配置组件全集**（每节固定 4 段：用途 / 文件位置 / 配置示例 / 跨工具对照）
- [2.1 仓库入口文件](#21-仓库入口文件)
- [2.2 路径作用域规则](#22-路径作用域规则)
- [2.3 Agent Skills](#23-agent-skills)
- [2.4 Subagents](#24-subagents)
- [2.5 Hooks](#25-hooks)
- [2.6 MCP Servers](#26-mcp-servers)
- [2.7 Memory](#27-memory)
- [2.8 CI 集成 & Plugins](#28-ci-集成--plugins)

**Part 3 · 流程落地**
- [3.1 4-Phase 落地](#31-4-phase-落地)
- [3.2 Context Bundle 契约](#32-context-bundle-契约)
- [3.3 Spec 链式生成五件套](#33-spec-链式生成五件套)
- [3.4 Implementer ↔ Reviewer 隔离模式](#34-implementer--reviewer-隔离模式)
- [3.5 AI 草稿留痕硬约束](#35-ai-草稿留痕硬约束)
- [3.6 SOP 步骤 ↔ 装配速查表](#36-sop-步骤--装配速查表)

**附录**
- [A. 跨工具兼容矩阵（合并所有跨工具表）](#附录-a--跨工具兼容矩阵)
- [B. 资料红线](#附录-b--资料红线)
- [C. Onboarding 6 阶段](#附录-c--onboarding-6-阶段)

---

## Part 1 · 组织原则

### 1.1 两层关系：宏观工序 × 微观协作

| 层级 | 单位 | 回答 | 由谁定 |
|---|---|---|---|
| **宏观 · SOP T0–T7+R** | 一次项目交付 | 做哪些工作 / 谁做 / Gate 在哪 | [tech-delivery-sop](sop/tech-delivery-sop.md) |
| **微观 · 4-Phase（Explore → Plan → Implement → Commit）** | 一次 AI 协作单元 | 每个起草活动 AI 如何辅助、人如何审 | 本手册 |

**嵌套关系**：4-Phase 是"一次 AI 起草 → 人审"的最小循环单元；一个 SOP 步骤内部通常包含 0 / 1 / N 个这种单元（如 T4 coding 每子任务一次）。

**裁剪规则**：纯审查 / 决策类活动（Gate review、T7 retro）可只跑 Explore + Commit；纯探索类活动可只跑 Explore + Plan。

### 1.2 4-Phase 通用循环

```
┌───────────────────────────────────────────────────────────────┐
│              一次 AI 协作单元（按需裁剪 / 重复 N 次）         │
│                                                                │
│   ① Explore  ── Plan Mode（只读）/ explorer subagent fan-out  │
│        ↓                                                       │
│   ② Plan     ── Plan Mode + AskUserQuestion / *-spec skill     │
│        ↓                                                       │
│   ③ Implement── 退出 Plan Mode / implementer subagent          │
│                  + PostToolUse hook 强制 lint/format            │
│        ↓                                                       │
│   ④ Commit   ── git hook / auto memory 沉淀 / claude -p CI     │
└───────────────────────────────────────────────────────────────┘
```

权威来源：Anthropic Claude Code Best Practices（`code.claude.com/docs/en/best-practices`）。Cursor Plan Mode、GitHub Copilot 内置 `Plan` agent（IDE built-in，与 `Agent` / `Ask` 并列）同义，仅命名不同。详细落地见 [§3.1](#31-4-phase-落地)。

### 1.3 AI 能力分级

本手册用 4 色标记 AI 在每个工作项里的产出权重（审批人永远是人，由 SOP §3.5 矩阵指定）：

| 标记 | 含义 | 典型 |
|---|---|---|
| 🟢 全自动 | AI 主导草稿，人审批复核即过 | Lint / 自检 checklist / Issue 拆分 |
| 🟡 半自动 | AI 起草，人审批实质评审拍板 | 架构方案 / 契约 / Code Review |
| 🟠 辅助 | AI 仅给候选与对比，人决策 | ADR 候选分析 |
| 🔴 不可用 | 必须真人起草 | 业务验收 / 合规签字 |
| 🟢(CI) 附加 | CI 自动化兜底（AI 主动产出 + CI 强制校验，失败即拒入合并）| 编码阶段 lint / 单测 / 契约 lint |

> **复合标记规则**：基础色 = AI 草稿权重；附加 `🟢(CI)` = 该步另有 CI 自动门禁（如 T4.2 = 🟡（CI 🟢））。

### 1.4 装配优先级

**同样能解决，下层不上**：

1. **入口规则**（[§2.1](#21-仓库入口文件) AGENTS.md + [§2.2](#22-路径作用域规则) 路径规则）能解决 → 不上 Skill
2. **Skill**（[§2.3](#23-agent-skills)）能解决 → 不上 Subagent
3. **Subagent**（[§2.4](#24-subagents)）仅在需要独立 context window 时启用（reviewer ↔ implementer 隔离 / 并行 fan-out）
4. **Hook**（[§2.5](#25-hooks)）仅用于不可漏的强约束（lint / 安全扫描 / 留痕）

### 1.5 Feature / Task 两层结构

> **与 SOP 的映射**：SOP §3.1 抽象为「需求规格（feature spec）· 任务包（task package）· 跟踪条目（Issue）」三层，不锁定具体工具。本节是 HOW 层落地：选 **GitHub Spec-Kit** 作为规格包载体，下列 `specs/` 路径与 `/speckit.*` 命令均为其约定。不用 Spec-Kit 的项目可插换同等载体。

**层级关系**：一个 feature = 一个 `specs/NNN-<slug>/` 目录 = 一份共享 spec；T3 在其内拆出 N 个 task，每 task 镜像一个 Issue / 对应一个 PR。

| 层级 | 载体 | 内容 | 数量关系 |
|---|---|---|---|
| **Feature（共享）** | `specs/NNN-<slug>/` 目录（+ 仓库根 `memory/constitution.md` 单例）| `spec.md` + `plan.md` + `research.md` + `data-model.md` + `contracts/` + `quickstart.md` | 1 个 feature |
| **Task（独立）** | `tasks.md` 一行 + Issue Tracker 一个 Issue | SOP §3.1 的 11 字段 + 该 task 的 `verification:` | N 个 task / feature |
| **PR** | 一个 task 一个 PR | commit `Closes #N` | 1 PR : 1 Issue : 1 task |

镜像约定：
- T2 先建 feature 目录（spec / plan / contracts / data-model / quickstart）
- T3 在该目录内拆 `tasks.md` → `/speckit.taskstoissues` 一次派生 N 个 Issue
- commit message 必带 `Closes #N`；PR merge 自动闭单 Issue
- 任何 spec / contract 变更**只改目录**，不在单 task 内私改；Issue body 通过 sync hook 重生（不双写）

> 调研出处与 9 条 Article 详见 [`_research/11_spec-driven-development-and-4phase.md`](_research/11_spec-driven-development-and-4phase.md)。Context Bundle 契约见 [§3.2](#32-context-bundle-契约)。

---

## Part 2 · 配置组件全集

> 每节固定 4 段：**用途 / 文件位置 / 配置示例 / 跨工具对照**。
> 完整跨工具兼容大表见 [附录 A](#附录-a--跨工具兼容矩阵)；本部分每节只放该组件的迷你定位行。

**跨家分发策略（SSOT 三层）** — 经 `_research/14-18` 五个矩阵证实，**没有任何一类配置能"一份 4 家自动同步"**。所以策略不是"如何派生"，而是"**按通用性分 3 层，每层用最简方法**"：

| 层 | 判定标准 | 类别 | 落地方式 |
|---|---|---|---|
| **L1 真通用** | 一份文件 4 家共读 | 仓库入口（[§2.1](#21-仓库入口文件)）| 根 `AGENTS.md` 单源 · `CLAUDE.md` symlink · 4 家全读 |
| **L2 准通用** | 统一标准、可统一安装 | **Skills**（[§2.3](#23-agent-skills) · `agentskills.io` 同形 frontmatter）| 一条命令 `npx skills add` 安装到 4 家原生路径；可选**全装 copy**或**单源 + symlink** |
| **L3 各家原生** | 格式异构需翻译，或概念各家独有 | 路径作用域（[§2.2](#22-路径作用域规则)）· Subagents（[§2.4](#24-subagents)）· Hooks（[§2.5](#25-hooks)）· MCP（[§2.6](#26-mcp-servers)）· Memory（[§2.7](#27-memory)）· 命令 · 沙箱 · env | `.claude/` `.cursor/` `.github/` `.codex/` 各自原生目录维护，**互不派生、互不翻译** |

**Codex-only 物理隔离机制**：`AGENTS.override.md` 是 Codex 官方支持的专属文件名（Codex 每目录优先级 `AGENTS.override.md` > `AGENTS.md`；Cursor/Copilot auto-discover 只认 `AGENTS.md` 字面名，**不读 `.override.md`**；Claude Code 不原生读 `AGENTS.*`（需 symlink/import））。**仅手写、不自动派生**。来源：[developers.openai.com/codex/guides/agents-md](https://developers.openai.com/codex/guides/agents-md)「How Codex discovers guidance」。

**Skills 跨家共享（L2 落地范式）**：走 [`agentskills.io`](https://agentskills.io/) 通用 `SKILL.md` frontmatter 格式，4 家落地路径 `.claude/skills/<x>/` `.cursor/skills/<x>/` `.github/skills/<x>/` `.codex/skills/<x>/` 全部指向同一物理文件（symlink）；CLI 已成型——`npx skills add <repo-url> -a claude-code -a cursor -a github-copilot -a codex` 自动检测已装 IDE 并一次性 symlink 进 4 家原生路径（vercel-labs/skills，实测）。不复制不派生。

**反模式**（红线）：

- ❌ 中立 schema 抽象 + 跨家翻译器（4 家原生格式差异是 vendor 决定，不是工程问题）
- ❌ gitignored 派生物（静默腐烂风险）
- ❌ 把 Claude 当"特权源"再向其他家派生
- ❌ 工程化自动生成 `AGENTS.override.md`（仅手写）

**onboarding & 守门**：

- ✅ 一次性脚本：`scripts/agent-init.sh`（建 symlink + 拉共享 skill）
- ✅ CI 守门：仅校验 `AGENTS.md` 存在 + `CLAUDE.md` 是 symlink；**L3 各家原生不强制校验**

事实源：[`_research/14`](_research/14_hooks-support-matrix.md) · [`_research/15`](_research/15_mcp-support-matrix.md) · [`_research/16`](_research/16_memory-support-matrix.md) · [`_research/17`](_research/17_plan-carrier-matrix.md) · [`_research/18`](_research/18_spec-driven-support-matrix.md)。60 天未复核即视为待校。

---

### 2.1 仓库入口文件

**用途**：永远在 agent 上下文中的"全员永久规则"。覆盖 Setup / Code style / Testing / PR / Security 5 大类。

**文件位置**：以 `AGENTS.md` 为团队共享主入口（**根 + 任意子目录嵌套就近继承**，四家原生入口都支持嵌套，只是文件名不同），各 vendor 按下表叠加可选适配文件。

| 工具 | 共享主入口（提交进 git）| Vendor 适配（可选）| 个人级（不进 git）|
|---|---|---|---|
| Claude Code | `CLAUDE.md` | 同时维护 `AGENTS.md` 时：首行 `@AGENTS.md` 或 `ln -s AGENTS.md CLAUDE.md` | `CLAUDE.local.md` · `~/.claude/CLAUDE.md` |
| Cursor | `AGENTS.md` | `.cursor/rules/*.mdc`（路径作用域 · [§2.2](#22-路径作用域规则)）| — |
| GitHub Copilot | `AGENTS.md`（亦读根 `CLAUDE.md` / `GEMINI.md`）| `.github/copilot-instructions.md`（使用约束见下方 prose）· `.github/instructions/*.instructions.md`（`applyTo` · [§2.2](#22-路径作用域规则)）| — |
| OpenAI Codex | `AGENTS.md` | `AGENTS.override.md`（路径作用域 · [§2.2](#22-路径作用域规则)）| `~/.codex/AGENTS.md` |

> 嵌套与替代源细节据 [`_research/01_entry-file-support-matrix.md`](_research/01_entry-file-support-matrix.md) · 60 天未复核即视为待校。

**配置示例**（`AGENTS.md` 推荐 5 节结构，控制在 2 页内）：

```markdown
# Project AGENTS

## Setup commands
- Install:  `<package-manager> install`
- Dev:      `<dev-server-cmd>`
- Test:     `<test-cmd>`

## Code style
- Language:  <language + version>
- Formatter: <prettier/black/gofmt/...>
- Linter:    <eslint/ruff/golangci-lint/...>

## Testing
- Framework: <jest/pytest/go test/...>
- Coverage threshold: <NN>%

## Pull requests
- Title format: `<type>(<scope>): <subject>`
- Required reviewers: <团队>

## Security
- Never commit secrets to repo
- Refer to `.claude/skills/data-redline/SKILL.md` for data classification
```

Claude Code 专属补充（`CLAUDE.md`）：

```markdown
@AGENTS.md

## Claude Code 专属补充
- 默认进入 Plan Mode（Shift+Tab 切换）
- 路径作用域规则：见 `.claude/rules/`
- Skills：见 `.claude/skills/`
- Subagents：见 `.claude/agents/`
- 项目级偏好（不进 git）：`CLAUDE.local.md`
```

Copilot 入口（`.github/copilot-instructions.md`）：保持 <2 页，**只**写 Copilot 独有偏好（Coding Agent 云端配置 / PR 模板特殊约定 / `@workspace` 风格）。通用 Setup / Style / Test / PR / Security 已被 AGENTS.md 自动累加，不要重复。模板见 [`templates/entry/copilot/copilot-instructions.md.template`](templates/entry/copilot/copilot-instructions.md.template)。

**跨工具同步原则**：一份内容多处出现 = 维护噩梦。**只在工具语义独有时才进专属文件**。

### 2.2 路径作用域规则

**用途**：入口文件太长会稀释模型注意力。路径作用域规则只在上下文中存在匹配文件时才注入。

**文件位置**：

| 工具 | 文件路径 | 作用域字段 | 触发时机 |
|---|---|---|---|
| Claude Code | `.claude/rules/<topic>.md` | `paths:` frontmatter | 上下文含匹配文件 |
| Cursor | `.cursor/rules/<topic>.mdc` | `globs:` frontmatter | 上下文含匹配文件 |
| GitHub Copilot | `.github/instructions/<topic>.instructions.md` | `applyTo:` frontmatter | 编辑 / 讨论匹配文件时 |
| OpenAI Codex | 仅 `<dir>/AGENTS.md`（或 `<dir>/AGENTS.override.md`）| 无 frontmatter glob · 唯一靠物理位置 | 进入匹配目录时合并（nearest-wins）|

> **关于 Codex 的「两个 `rules`」（易混淆）**：
> - **本节说的 rules** = 提示词规则。Codex 靠 `AGENTS.md`（根 + 嵌套）+ `AGENTS.override.md`，**没有**同类 `.codex/rules/*.md` 提示词目录。
> - `.codex/rules/*.rules`（Starlark 语言）是**沙箱命令准入策略**（execpolicy），属 [§2.5 Hooks](#25-hooks) 范畴，与本节无关。

**配置示例**（同一规则四家写法对照 · 目标：服务 A 的接口层禁止写业务逻辑，必须用 DTO）：

Claude Code（`.claude/rules/api-layer.md`）：
```markdown
---
paths:
  - "services/*/api/**/*.ts"
  - "services/*/handlers/**/*.ts"
---
# API 层规则
- 禁止在 handler 里写业务逻辑
- 必须用 DTO 转换 request/response
```

Cursor（`.cursor/rules/api-layer.mdc`）：
```markdown
---
description: API 层规则
globs:
  - "services/*/api/**/*.ts"
  - "services/*/handlers/**/*.ts"
alwaysApply: false
---
（正文同上）
```

GitHub Copilot（`.github/instructions/api-layer.instructions.md`）：
```markdown
---
applyTo:
  - "services/*/api/**/*.ts"
  - "services/*/handlers/**/*.ts"
---
（正文同上）
```

OpenAI Codex（手写 `<prefix>/AGENTS.override.md` · Codex-only 物理隔离 · 详见下文）：
```markdown
<!-- services/<svc>/api/AGENTS.override.md · 手写 · Cursor/Copilot 不读 .override.md -->
# API 层规则
- 禁止在 handler 里写业务逻辑
- 必须用 DTO 转换 request/response
```

**写在哪**：可 glob 表达 → 各家原生 frontmatter（仅该家）；目录物理契约（glob 表达不了）→ 通用 `<dir>/AGENTS.md`（Cursor/Copilot/Codex 原生共读 · Claude 需 symlink）；Codex 独有且需对其他家隐藏 → `<dir>/AGENTS.override.md`（仅 Codex）。

**四种触发模式（四家都有，载体不同）**：

| 模式 | Cursor（同一 `.mdc` 切档）| Claude / Copilot / Codex（按文件类型分散）|
|---|---|---|
| Always | `alwaysApply: true` | 入口文件本身（`CLAUDE.md` / `copilot-instructions.md` / `AGENTS.md`，永远 auto-load）|
| Auto Attached | `globs:` | 路径作用域规则（见 §2.2 主表）· Codex 无 glob 字段，仅靠目录嵌套近似 |
| Agent Requested | `description:` | Agent Skills 的 `description` 字段（见 [§2.3](#23-agent-skills)）|
| Manual | 裸文件 + `@RuleName` | Slash commands（`.claude/commands/` · `.github/prompts/` · `.codex/commands/`）|

Cursor 真正独有的是**单文件家族 + frontmatter 切档**；其他三家把四种模式分散到不同文件类型（rules / skills / commands / 入口文件）。

### 2.3 Agent Skills

**用途**：可复用工作流。模型按 `description` 自动召回或用户手动调用。[agentskills.io](https://agentskills.io) 开放标准。

**文件位置**：一个 Skill = 一个目录 + 一个 `SKILL.md` + 可选辅助文件。

```
.claude/skills/<skill-name>/
├── SKILL.md          ← 入口（必有）
├── prompts/          ← 子提示词（可选）
├── scripts/          ← 辅助脚本（可选）
└── templates/        ← 输出模板（可选）
```

跨工具同构（agentskills.io 标准）：`.cursor/skills/<x>/SKILL.md`（Cursor 2.4 原生 · 兼容 `.claude/skills` / `.codex/skills`）· `.github/skills/<x>/SKILL.md`（Copilot Agent Skills · VS Code `/create-skill` · 自动召回）· `.codex/skills/<x>/SKILL.md`（Codex 2026/Q1 起声明兼容）。

**配置示例**（SKILL.md frontmatter · agentskills.io 标准）：

```yaml
---
name: contract-first
description: 从需求或 SPEC 生成 OpenAPI / 事件 / 数据三件套
disable-model-invocation: false   # 允许模型主动调用
allowed-tools: ["Read", "Write", "Edit", "Bash"]
argument-hint: "<service-name> [--from-spec=path]"
arguments:
  - name: service-name
    required: true
context: fork                      # 或 inherit / new
hooks:
  before: ".claude/skills/contract-first/scripts/check-spec.sh"
paths:                             # 限定生效范围（可选）
  - "services/<service-name>/**"
---

# Contract First Skill
（正文 < 500 行）
```

**命名约定**：
- 一个 skill 一个职责（动词起头：`tech-intake` / `contract-first` / `gate-checklist`）
- SKILL.md 控制 < 500 行，复杂逻辑外推到 `scripts/`
- `description` 写清"什么时候该被调用"——这是模型自动召回的依据

**本工作流提供的 12 个 Skill（权威索引）**：

> 本表为 Skill ↔ SOP 步骤的**唯一权威绑定源**。[§3.6](#36-sop-步骤--装配速查表) 速查表只引用、不重定义。

| Skill | 对应 SOP | 用途 |
|---|---|---|
| `tech-intake` | T0 | AskUserQuestion 访谈，输出 SPEC.md |
| `bc-impact-map` | T1 | 限界上下文 / 服务影响地图 |
| `contract-first` | T2 | 生成 OpenAPI / 事件 schema / 数据迁移（详见 [§3.3](#33-spec-链式生成五件套)）|
| `task-decomp-fanout` | T3 | 在 feature 目录内生成 `tasks.md` + `/speckit.taskstoissues` 派生 Issue |
| `gate-checklist` | T4.1 + T4.3（单 skill 两处复用）| Plan 自评 5 条 + Code Review 5 条红旗 |
| `qa-cases` | T4.4 | 测试用例生成 + 探索性 mutation 测试 |
| `release-canary` | T5 | 灰度方案 + 回滚剧本（AI 无 prod 写权限）|
| `retro-audit` | T7 | 9 项 audit checklist + auto memory 沉淀 |
| `adr-writing` | R（横切）| ADR 模板 + ≥2 候选决策矩阵 |
| `std-writing` | R（横切）| STD-NN 标准草稿模板填充 |
| `data-redline` | 横切（始终在 context）| 资料 4 级 + 8 红线 |
| `scaffold-agents-md` | 横切（按需调用）| 业务子域 AGENTS.md 生成（服务/特定模块红线占位填充）|

**跨工具对照**：Cursor 2.4+ / Copilot Agent Skills / Codex 均认 agentskills.io字段同形，可软链或脚本同步一份 SKILL.md。

### 2.4 Subagents

**用途**：仅在三种情况启用——
1. **隔离 context window**（reviewer 不能看到 implementer 的草稿历史，否则会带偏见）
2. **并行 fan-out**（同时探索 5 个服务的 BC 影响）
3. **不同模型 / 权限**（security-auditor 用 Opus，implementer 用 Sonnet）

否则用 Skill 即可（见 [§1.4 装配优先级](#14-装配优先级)）。

**文件位置**：`.claude/agents/<name>.md`。跨工具同构但格式不同：`.cursor/agents/*.md`（同时识别 `.claude/agents/` / `.codex/agents/`）· `.github/agents/*.agent.md`（兼容 `.claude/agents/*.md`）· **`.codex/agents/*.toml`**（[Codex 用 TOML 而非 Markdown](https://developers.openai.com/codex/subagents)）。

**配置示例**（只读 reviewer，无需 worktree）：

```yaml
---
name: reviewer
description: 隔离上下文的代码 / 文档审查代理；Writer-Reviewer 模式中的 Reviewer 角色
model: sonnet
tools: ["Read", "Grep", "Glob"]   # 白名单即达成只读
maxTurns: 20
skills:                            # preload
  - gate-checklist
  - data-redline
mcpServers:                        # 此 subagent 可用的 MCP
  - github
memory: false                      # 不写 auto memory
background: false
effort: medium
color: blue
initialPrompt: |
  你是隔离的 Reviewer。只能 Read/Grep/Glob。
  按 gate-checklist skill 的 T4.3 代码评审段执行，输出 REVIEW.md。
---

# Reviewer Subagent
（正文）
```

> **字段红线**：Claude Code 的 `permissionMode` 合法值只有 `default / acceptEdits / auto / dontAsk / bypassPermissions / plan`——**无 `read-only`**（[官方文档](https://code.claude.com/docs/en/sub-agents)）。只读需求用 `tools` 白名单表达即可。`isolation: worktree` 是文件系统写隔离，只读 subagent 不需要（官方说明：适用于“大型重构 / 危险实验”）。

**本工作流使用的 2 个 Subagent**：

| Subagent | 四家原生 preset | 用途 |
|---|---|---|
| `explorer` | ✅ Claude `Explore` / Cursor `Explore` / Codex `explorer` / Copilot `Explore`（preview）—— 四家均内置，无需自建 | 只读 fan-out 研究（T1 影响分析）|
| `reviewer` | ⚠️ 四家均需自建（Codex 官文有 [`reviewer.toml` 示例](https://developers.openai.com/codex/subagents)）| Writer-Reviewer 模式中的 Reviewer（T4.3 代码评审 / T4.4 QA 辅助 · 详见 [§3.4](#34-implementer--reviewer-隔离模式)）|

未启用候选（保留供未来扩展）：

> ⚠️ 当前 SOP 未引用，仅作为模式示例保留。新增引用前请先在 [§3.6](#36-sop-步骤--装配速查表) 落到具体步骤。

| Subagent | 模型 | 隔离 | 设想用途 |
|---|---|---|---|
| `security-auditor` | Opus | 默认（只读）| 高风险审查（T4.3 安全红旗 / T5 上线前）|
| `doc-writer` | Sonnet | 默认 | 文档生成（README / Changelog / ADR 起草）|

**调用方式**：

```bash
# CLI 直接以 subagent 模式启动
claude --agent reviewer

# 主代理内 fan-out
for svc in $(cat services.txt); do
  claude -p "use explorer subagent to analyze $svc" \
    --allowedTools "Read,Grep,Glob" &
done
wait
```

**跨工具对照**：

| 工具 | 内置 explore preset | 配置位置 | 一手文档 |
|---|---|---|---|
| Claude Code | ✅ `Explore`（Haiku，只读）/ `Plan` / `General-purpose` | `.claude/agents/*.md` | [`code.claude.com/docs/en/sub-agents`](https://code.claude.com/docs/en/sub-agents) |
| Cursor | ✅ `Explore` / `Bash` / `Browser` | `.cursor/agents/*.md`（兼读 `.claude/` / `.codex/`） | [`cursor.com/docs/subagents`](https://cursor.com/docs/subagents) |
| OpenAI Codex | ✅ `default` / `worker` / `explorer` | `.codex/agents/*.toml` 或 `~/.codex/agents/` | [`developers.openai.com/codex/subagents`](https://developers.openai.com/codex/subagents) |
| GitHub Copilot | ✅ `Explore`（preview，扩展 bundled `.agent.md` 而非 hardcoded） | 扩展 `globalStorage/.../explore-agent/Explore.agent.md`；用户自定义放 `.github/agents/*.agent.md` | [`docs.github.com/copilot/cloud-agent`](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-cloud-agent) |

### 2.5 Hooks

**用途**：关键事件触发的强约束（lint / 安全扫描 / 留痕 / 沙箱准入）。

**文件位置**：

| 工具 | 配置文件 | 备注 |
|---|---|---|
| Claude Code | `.claude/settings.json` 全局 + skill/subagent frontmatter 局部 | 28+ 事件（PreToolUse / PostToolUse / SubagentStart / SubagentStop / PreCompact / TaskCreated / WorktreeCreate / FileChanged / …）·5 种 handler：`command` / `http` / `mcp_tool` / `prompt` / `agent`（[官文](https://code.claude.com/docs/en/hooks)）|
| Cursor | `.cursor/hooks.json`（以及 `~/.cursor/hooks.json`）| **Enterprise / Team / Project / User 四级合并** · 21 个事件（agent 18 + Tab 2 + workspace 1）· 原生兼容 Claude Code：退出码 2 = deny，提供 `CLAUDE_PROJECT_DIR` 别名（[官文](https://cursor.com/docs/hooks)）。**配套 shell 脚本可与 Claude 复用同一份**（属 OS 级工具，不算红线"翻译派生"——派生指 `hooks.json` / `settings.json` **配置文件**派生）|
| GitHub Copilot | agent frontmatter `hooks` 字段（**Preview**，需 `chat.useCustomAgentHooks` setting）| 仅在该 custom agent 激活时生效（[官文](https://code.visualstudio.com/docs/copilot/customization/custom-agents)）。与 GitHub Actions / `.github/workflows/` **不是同一个东西**，不要混淆 |
| OpenAI Codex | `~/.codex/hooks.json` / `<repo>/.codex/hooks.json`，也可在 `config.toml` 内嵌 `[hooks]` | 6 个事件（SessionStart / PreToolUse / PermissionRequest / PostToolUse / UserPromptSubmit / Stop）· 仅 `type: command` 处理器生效（[官文](https://developers.openai.com/codex/hooks)）。沙箱（Seatbelt/landlock）与 execpolicy（`.codex/rules/*.rules`）是**与 hooks 配合使用的独立机制**，不要当 hooks |

**配置示例**（`.claude/settings.json`）：

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "command": ".claude/hooks/check-no-secrets.sh" }
    ],
    "PostToolUse": [
      { "matcher": "Edit|Write", "command": ".claude/hooks/lint-format.sh" }
    ]
  },
  "permissions": {
    "allow": ["Read", "Grep", "Glob", "Edit"],
    "deny": ["Bash(rm -rf*)", "Read(.env)", "Read(secrets/**)"]
  },
  "autoMemoryEnabled": true
}
```

### 2.6 MCP Servers

**用途**：用 Model Context Protocol 标准把外部工具（GitHub / Postgres / Notion / Figma / 浏览器 等）暴露给 agent。四家原生支持，但**配置文件位置和格式各不相同**，不能一份配置走天下。

> **分层定位**：MCP 属 [L3 各家原生](#)（见 §2 头表注）——只有 Claude ↔ Cursor 这一对同 schema 可仓内 symlink，Copilot 顶层 key `servers` 与 Codex TOML 都需要翻译，不是"单源分发"。本节按各家原生格式描述。

| 工具 | 配置位置 | 格式 / 顶层键 | 备注 |
|---|---|---|---|
| Claude Code | 项目 `.mcp.json` · 用户/本地 `~/.claude.json` · 企业 `managed-mcp.json`（allowlist/denylist） | JSON · `mcpServers` | 3 传输：HTTP / SSE(已弃用) / stdio · OAuth 走 `/mcp` · plugin 可在 `plugin.json` inline 声明 · `MAX_MCP_OUTPUT_TOKENS` 控制大输出 |
| Cursor | 项目 `.cursor/mcp.json` · 全局 `~/.cursor/mcp.json` | JSON · `mcpServers` | 3 传输：stdio / SSE / Streamable HTTP · OAuth 固定回调 `cursor://anysphere.cursor-mcp/oauth/callback` · stdio 独有 `envFile` |
| OpenAI Codex | 全局 `~/.codex/config.toml` · 项目 `.codex/config.toml`（trusted 项目） | **TOML** · `[mcp_servers.<name>]` | 2 传输：STDIO / Streamable HTTP · `codex mcp login <name>` 走 OAuth · 独有 `enabled_tools` / `disabled_tools` / `default_tools_approval_mode` 工具级管控 |
| GitHub Copilot | 工作区 `.vscode/mcp.json` · 用户 profile（`MCP: Open User Configuration`）· custom agent frontmatter `mcp-servers:`（仅 `target: github-copilot` cloud agents） | JSON · **`servers`**（不是 `mcpServers`） | 可从 Extensions 视图按 `@mcp` 装；首次启动需 trust；独有 `sandboxEnabled: true`（macOS/Linux 沙箱）+ Settings Sync |

**模板**：[`templates/mcp/.mcp.json.template`](templates/mcp/.mcp.json.template) 直接可用于 Claude / Cursor（驼峰键 + 项目根放置）；Copilot 需另存为 `.vscode/mcp.json` 并把顶层 `mcpServers` 改成 `servers`；Codex 需翻译为 TOML 写入 `~/.codex/config.toml`。详细对照见 [`_research/15_mcp-support-matrix.md`](_research/15_mcp-support-matrix.md)。

### 2.7 Memory

**用途**：让 agent **自己**在会话里学到的偏好跨会话持久化（人写指令是另一条线，归 [§2.1 入口文件](#21-仓库入口文件) 与 [§2.2 路径作用域规则](#22-路径作用域规则) 管）。

**截至 2026-05，四家全部已有 auto memory**（Codex 自 2026-04-15 起新增，最后一家上车）。

| 工具 | auto memory | 写到哪 | 启动加载 | 开关 / 控制 |
|---|---|---|---|---|
| Claude Code | ✅ 默认开（v2.1.59+） | **本地** `~/.claude/projects/<project>/memory/MEMORY.md` + 同目录 topic 文件 · machine-local，不跨机 | MEMORY.md 前 200 行 / 25 KB（topic 文件按需读） | `/memory` 面板 · `autoMemoryEnabled: false` · `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` · `autoMemoryDirectory` 改路径（仅 user/policy/`--settings` 可设）<br>·· **subagent 独立 memory**：frontmatter `memory: user\|project\|local` → `~/.claude/agent-memory/<name>/` · `.claude/agent-memory/<name>/` · `.claude/agent-memory-local/<name>/`（与 `CLAUDE.md` 的 4 层 scope 是**两套机制**，别混） |
| Cursor | ✅ Memories（默认开） | **云端**用户账户，跨项目跨机；磁盘无文件 | 由 Cursor 后台自动注入 | Settings → Memories review/编辑/删除 |
| GitHub Copilot | ✅ Copilot Memory（**public preview**，非 GA） | **云端** GitHub 账户；repo-level facts（带 citation，按 branch 校验）+ user-level preferences | 仅在 Copilot **coding agent / code review / CLI** 注入；**IDE Chat 当前不消费 Memory** | `github.com/settings/copilot/memory` review/删除<br>·· **Pro/Pro+** 默认开；**Business/Enterprise** 默认关，admin 在 org/enterprise 启用<br>·· 未使用 fact **28 天自动删**（用一次重置计时器）<br>·· code review 只读 repo-level，不读 user prefs<br>·· 与 Personal Context 是两个独立机制 |
| OpenAI Codex | ✅ Memories（**默认关**，2026-04-15+） | **本地** `~/.codex/memories/`（受 `CODEX_HOME` 控制） · 含 summaries / durable entries / recent inputs / supporting evidence · secrets 自动 redact | 由 Codex 后台异步生成并注入（避开活跃 thread 与速率限制接近时） | `config.toml` 加 `[features] memories = true` 或 app Settings 开<br>·· per-thread 用 `/memories` 控制当前会话是否使用/生成<br>·· 细粒度：`memories.generate_memories` / `memories.use_memories` / `memories.disable_on_external_context` / `memories.min_rate_limit_remaining_percent`<br>·· **EEA / UK / CH launch 时不可用** |

**红线（关键 4 条；完整 14 条对照见 [`_research/16_memory-support-matrix.md`](_research/16_memory-support-matrix.md)）**：

1. **存储位置二分**：Claude / Codex 在**本地磁盘**（可 grep、可手编但 Codex 不建议）；Cursor / Copilot 在**云端**（只能 UI review）。不要把 4 家写成同一种形态。
2. **Claude 的两个 `user|project|local` 是不同概念**：`CLAUDE.md` 4 层 scope（managed/user/project/local，路径分散）vs subagent frontmatter `memory:` 3 层 scope（user/project/local，路径固定在 `agent-memory*/` 下）。
3. **Copilot Memory 不是 GA**：是 public preview；不是「所有 Copilot 场景都用」（IDE Chat 当前不用）；不是「永久」（28 天 TTL）；不是「只 Pro/Pro+」（4 plans 都可用，但默认开关与 admin 控制不同）。
4. **Codex Memory 不是云端**：是本地文件；默认**关**；EEA/UK/CH 不可用——别按 Cursor/Copilot 的「云上自动」模板描述它。

### 2.8 CI 集成 & Plugins

#### 2.8.1 CI 非交互模式（四工具对照）

| 工具 | 非交互入口 | 输出捕获 | 沙箱/权限旗 | CI 推荐组合 |
|---|---|---|---|---|
| Claude Code | `claude -p "<prompt>"` | stdout（`>` / `\| tee`）；`--output-format json/stream-json`；`--json-schema` 结构化 | `--permission-mode dontAsk` + `--allowedTools "Read,Grep"` | `--bare`（跳过 hook/skill/MCP 自动发现，Anthropic 明确推荐用于 CI，未来将成 `-p` 默认）|
| Codex | `codex exec "<prompt>"` | stdout（final message）；`-o <path>`；`--json`（JSONL）；`--output-schema schema.json` | `--sandbox workspace-write \| read-only \| danger-full-access` | `--ignore-user-config --ignore-rules`（隔离个人配置）；`--skip-git-repo-check` 用于非仓库环境 |
| Cursor CLI | `agent -p "<prompt>"` | `--output-format text/json` | `--sandbox enabled/disabled` | 也支持 `@cursor` 在 PR / Issue / Slack 触发 Cloud Agent |
| Copilot CLI | `copilot -p "<prompt>"` | stdout | `--allow-all` / `--yolo`（全权限，慎用）；按需 `--agent <name>` 指定 custom agent | 也支持 `@copilot` 在 Issue / PR 触发 Copilot cloud agent |

> 来源：[Claude headless](https://code.claude.com/docs/en/headless)、[Codex noninteractive](https://developers.openai.com/codex/noninteractive)、[Cursor CLI overview](https://cursor.com/docs/cli/overview)、[GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli)。

**Claude Code CI 示例**（修正版，pipe diff 进去避免给 Bash 权限）：

```yaml
# .github/workflows/ai-review.yml
- name: AI pre-review (Claude)
  env: { ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }} }
  run: |
    gh pr diff "${{ github.event.pull_request.number }}" \
      | claude --bare -p \
          --append-system-prompt "你是 reviewer subagent，按 5 红旗规则审 diff，无问题输出 LGTM。" \
          --allowedTools "Read,Grep" \
          --output-format json \
          | tee review.json
- uses: actions/upload-artifact@v4
  with: { name: ai-review, path: review.json }
```

**Codex CI 示例**（官方 action）：

```yaml
- uses: openai/codex-action@v1
  with:
    openai-api-key: ${{ secrets.OPENAI_API_KEY }}
    prompt-file: .github/ci-prompts/review.md   # SSOT · 4 家 workflow 共指同一份
    output-file: codex-review.md
    safety-strategy: drop-sudo          # 默认；剥离 sudo
    sandbox: workspace-write
    codex-args: '["--json"]'            # 需要 JSONL 时
```

**关键纪律**（跨工具通用）：

- **流水线必带显式 sandbox**：从未传 sandbox = 任何工具都默认拿到读写权限。Claude `--permission-mode dontAsk`、Codex `--sandbox workspace-write`、Cursor `--sandbox enabled`，三选一不可省。
- **AI 输出永远是 advisory**：CI 把结果作为 PR comment 或 artifact 上传，**不允许直接挂在 required check 上**（reviewer 与 implementer 不能同一 actor —— §2.6 5 红旗第 5 条）。
- **secret 不进 prompt**：所有工具都把 prompt 发回云端模型；OWASP A02 角度，CI prompt 用 `prompt-file` 引用仓内静态文件，禁拼接 issue body / PR title 等用户可控字段（防 prompt injection）。

#### 2.8.2 Plugins / Marketplace 生态

四家工具都已有"打包分发可复用单元"的机制，但**形态各异**：

| 工具 | 名词 | 单元清单 | 安装入口 | 现状 |
|---|---|---|---|---|
| Claude Code | Plugin + Marketplace | skills / agents / hooks / MCP / LSP / monitors / bin / settings | `claude plugin install <name>@<marketplace>`；marketplace = git repo 含 `.claude-plugin/marketplace.json` | GA；官方 `claude-plugins-official` + 社区 `claude-community` 两个公共市场 |
| Codex | Plugin | skills / `.app.json`（连接器）/ `.mcp.json` | per-user `~/.codex/plugins/` 或 per-repo `.agents/plugins/marketplace.json`；内置 `@plugin-creator` 脚手架 | 2026-03 GA；curated 公开目录 |
| Copilot CLI | Plugin | agents / skills / hooks / MCP / 集成 | enterprise 可下发 plugin standards 策略 | 已有概念页与企业管理；安装 UI 通过 `/plugin` |
| Cursor | 无 "plugin" 名词；走 **rules + hooks + MCP** 组合 | `.cursor/rules/*.mdc` + `.cursor/hooks.json` + MCP servers | 仓内 commit 即生效；MCP 经 `cursor.com/agents` UI 装 | 等效能力齐全，但不像前三家可一键 install 一个打包单元 |

> 重要边界：**plugin / marketplace 是分发机制，不是 memory**。三家 plugin 装进去的是「可复用 prompt + 脚本 + MCP 配置」，跟 §2.7 讨论的 auto memory（云端 user/repo 偏好）完全不同——请勿混为一谈。

**本仓库的对应**：

- 我们的 `.github/skills/*` 与 `ai-workflow/sop.md` 当前以 **standalone**（仓内 commit）形态分发，不打 plugin 包——理由是只在一个 monorepo 内使用，不需要跨项目分发。
- 如果未来要给外部团队复用，**Claude 路径**：把 `.github/skills/` + `ai-workflow/` 包成 `.claude-plugin/plugin.json` + `marketplace.json`，发到内部私有 GitHub repo；**Codex 路径**：等价物为 `.codex-plugin/plugin.json` + `.agents/plugins/marketplace.json`。两路径产物可并存（不同目录名互不冲突）。

---

## Part 3 · 流程落地

### 3.1 4-Phase 落地

> 权威来源：Anthropic Claude Code Best Practices —— "Give Claude a way to verify its work ... the single highest-leverage thing you can do"。
> 适用：SOP 中**任何**带 AI 草稿的步骤（T1 / T2 / T4.1 / T4.2 / T4.3 / T7 / R），不止 T4.2 编码。

**四阶段定义表**：

| Phase | 工具状态 | 入口动作 | 输入工件 | 产出工件 | Verification（强制）|
|---|---|---|---|---|---|
| **① Explore** | Plan Mode（只读 · `permissionMode: plan`）| `claude --permission-mode plan` / Cursor `Shift+Tab` | AGENTS.md + `specs/NNN-feature/` 全量（[§3.2](#32-context-bundle-契约)）| 内部记忆 + 问题清单 | — |
| **② Plan** | Plan Mode | 同上；可 `Ctrl+G` 编辑 plan | Explore 阶段问答结果 | `specs/NNN-feature/plan.md`（草稿）+ 每任务 `verification:` 字段 | plan lint：每任务必有可执行验证命令 |
| **③ Implement** | 默认 mode | 退出 Plan Mode；按 `tasks.md` 单条执行 | plan.md + contracts/ + tasks.md | 代码 + 测试 + 本地 CI 通过 | 跑 `verification:` 命令必绿 |
| **④ Commit** | 默认 mode | git commit + open PR | 通过验证的 diff | commit message `Closes #N` + PR | PR CI 全绿 + reviewer subagent 5 红旗通过 |

**阶段切换硬规则**：

1. **Explore → Plan**：未问完澄清问题不进 Plan。`spec.md` 中 `[NEEDS CLARIFICATION]` 必须清零。
2. **Plan → Implement**：`plan.md` 中**每条任务**必带 `verification:` 字段。缺一条退回。
3. **Implement → Commit**：本地 verification 不绿不 commit。`--no-verify` 永远禁用。
4. **Commit → 下一任务**：commit 必引用 Issue `Closes #N`（关 Issue 状态机），否则 hook 拦截。

**反例（hook 应直接拦截）**：

- `spec.md` 写"使用 Redis 实现幂等" → HOW 泄漏，hook 报错
- `tasks.md` 某条无 `verification:` → plan lint fail
- commit 缺 `Closes #N` → pre-commit hook reject
- PR 由 implementer subagent 自己 review → CODEOWNERS 强制 reviewer 隔离

**Codex 降级方案（hook 事件子集）**：Codex 仅 6 事件（`SessionStart / PreToolUse / PermissionRequest / PostToolUse / UserPromptSubmit / Stop`）且仅 `type: command` handler 生效（[§2.5](#25-hooks)）。能在 hooks 覆盖的（`UserPromptSubmit` 扫 `[NEEDS CLARIFICATION]` / `PreToolUse` 拦 `--no-verify` + secret）就在 hooks；不能覆盖的 4-Phase 拦截（`plan.md` verification 行级校验、commit-message `Closes #N`）由 **CI 兜底**——repo 必须配 `.github/workflows/entry-lint.yml`（校 spec/plan/tasks 形态）+ commit-msg lint + PR check，禁止以"Codex 当前未拦下"为理由跳过该拦截。

**跨工具映射**：见 [附录 A](#附录-a--跨工具兼容矩阵) "Plan / Approval 模式"行。

### 3.2 Context Bundle 契约

> **名词互通**：T2 产出的「**规格五件套**」（`spec / plan / contracts / data-model / quickstart`）即下表第 3–7、9 项的 feature 级共享部分；生成方法见 [§3.3](#33-spec-链式生成五件套)。

AI 接手某个 task 时，按其所属 feature **整目录**入 context（顺序即权重；feature 级 6 件套被同 feature 下所有 task 共享）：

```
1. AGENTS.md                            ← 仓库入口规则
2. memory/constitution.md               ← 仓库级不变原则（≤9 条，单例）
3. specs/NNN-<slug>/spec.md             ← WHAT / WHY（feature 共享 · 禁 HOW）
4. specs/NNN-<slug>/plan.md             ← HOW 高层（feature 共享）
5. specs/NNN-<slug>/research.md         ← 技术选型对比（feature 共享）
6. specs/NNN-<slug>/data-model.md       ← 实体 schema（feature 共享）
7. specs/NNN-<slug>/contracts/*         ← API / 事件契约（feature 共享 · 机读）
8. specs/NNN-<slug>/tasks.md  §T-NNN-XX ← 当前 task 行（task 独有）
9. specs/NNN-<slug>/quickstart.md       ← 自验收场景（feature 共享）
```

**硬约束**：

- 缺任何一项 → DoR 不达 → 不进 T4.2 编码
- `spec.md` 出现 HOW 描述（库名 / 框架 / 数据结构）→ 退回 T2 重写
- 每条 `tasks.md` 项必带 `verification:` 字段（CI 命令 / 测试名 / 期望输出）—— Claude Code "single highest-leverage" 原则的落地

### 3.3 Spec 链式生成五件套

T2 产出的「规格五件套」是后续所有步骤的事实源。本节统一走 **GitHub Spec-Kit** 的 `/speckit.*` 命令链产出五件套，弃自造路径（参 [§2.3](#23-agent-skills) + 决策矩阵 D8）。

**Spec-Kit 名词锚定**

`/speckit.specify` / `/speckit.plan` / `/speckit.tasks` / `/speckit.taskstoissues` 等命令出自 [GitHub Spec-Kit](https://github.com/github/spec-kit)，通过 9 条 Article（见 [`_research/11_spec-driven-development-and-4phase.md`](_research/11_spec-driven-development-and-4phase.md)）约束 spec-first 节奏。**本项目强制安装**：

```bash
uvx --from git+https://github.com/github/spec-kit.git \
  specify init . --integration <vendor> --here
# vendor ∈ {claude, cursor, copilot, codex}；详见 _research/18_spec-driven-support-matrix.md
```

**(a) /speckit.* 5 步链 ↔ 5 件套**（顺序固定 · 每步产出后 PM-Tech 必须 Approve 才进下一步）：

| # | 件套 | Spec-Kit 命令 + 核心约束 | 输入 | 输出落点 |
|---|---|---|---|---|
| 1 | `spec.md` | `/speckit.specify`：读 PRD §X 与 `memory/constitution.md`；只写 WHAT/WHY，发现任何 HOW 描述立即标 `[REJECT-HOW]`；按章节锚填写；存疑列入 `## 5. 待澄清`。| PRD 节选 + `memory/constitution.md` | `specs/<id>/spec.md` |
| 2 | `plan.md` | `/speckit.plan`：读 Approved 的 `spec.md`；列 ≥ 2 个 HOW 候选 + 对比矩阵；选定方案，未选项给排除理由；标注需要新 ADR 的决策点写入 `adrs: [TBD]`。| `spec.md`（Approved）+ 相邻已 Approve 的 ADR | `specs/<id>/plan.md` |
| 3 | `data-model.md` | `/speckit.plan` 续：按选定方案抽实体、关键字段约束、状态机；字段类型与命名遵循 STD-03 数据规范。| `spec.md` + `plan.md` | `specs/<id>/data-model.md` |
| 4 | `contracts/*` | `/speckit.plan` 续：按 `data-model.md` 生成 OpenAPI / AsyncAPI；遵循 STD-02 API 规范；schema lint 必须通过。| `data-model.md` + STD-02 | `specs/<id>/contracts/*.yaml` |
| 5 | `quickstart.md` | `/speckit.plan` 续：写人类可读的自验收场景（≥ 3 条），每条配可执行 CI 命令；命令必须能映射到 `/speckit.plan` 阶段产出的 `contracts/` lint + 单测 + 集成测试。| 前 4 件套 | `specs/<id>/quickstart.md` |

**(b) 五件套 ↔ Context Bundle 对应**：

| 五件套文件 | Bundle 顺位（[§3.2](#32-context-bundle-契约)）| 共享粒度 |
|---|---|---|
| `spec.md` | ③ | feature 共享 |
| `plan.md` | ④ | feature 共享 |
| `data-model.md` | ⑥ | feature 共享 |
| `contracts/*` | ⑦ | feature 共享（机读）|
| `quickstart.md` | ⑨ | feature 共享 |

> 缺一不可入 T4.2（DoR 硬约束）；Spec-Kit 默认产出 `research.md`，对应 Bundle ⑤。

### 3.4 Implementer ↔ Reviewer 隔离模式

T4.3 代码评审 **强烈推荐**用 reviewer subagent 在独立 context 跑，避免审批人看到 implementer 的草稿过程被带偏见：

```bash
# Implementer（起草）
claude --agent implementer -p "执行任务 task-A，写到 feat/task-a 分支"

# Reviewer（独立 context window；不见 implementer 的对话历史）
claude --agent reviewer -p "审 feat/task-a 的 diff，按 5 条红旗 checklist 出 REVIEW.md"
```

Subagent 定义见 [§2.4](#24-subagents)。

### 3.5 AI 草稿留痕硬约束

AI 起草的任何工件都必须**自动生成给审批人的结构化检查记录**（呼应 SOP §3.3 审批通用约束），否则审批人无法签字：

| 工件类型 | 留痕最小内容 |
|---|---|
| 自检 / Review checklist | 每条 ✅/❌ + 异常项备注 |
| 方案 / 详设 | 候选讨论摘要 + 选定理由 + 排除项原因 |
| 代码 / 测试 PR | commit message 必带 Issue id + 关联契约版本号 |
| 复盘 | 全程工件链接 + 数据指标快照 |

### 3.6 SOP 步骤 ↔ 装配速查表

> 本表只回答"每步用什么装配"，所有装配的定义全部在 Part 2，不重复。
> Gate 定义、审批人矩阵、判据规则全部在 [SOP](sop/tech-delivery-sop.md)。
> **R 横切仪式不占主序号**，可在任意步触发（详见 SOP §1.1）；表末单列以便查阅，**不构成序列位置**。

| SOP 步 | AI 能力分级（[§1.3](#13-ai-能力分级)）| AI 装配（草稿生产）| 关键产出（给审批人）|
|---|---|---|---|
| **T0** Intake | 🟢 | `tech-intake` skill + `AskUserQuestion` 多轮访谈 | 8 项自检报告（含原始问答留痕）|
| **T1** 影响分析 | 🟡 | **前置 · 架构基线 ready**（涉契约 / 标准变更时并行启动 R 横切）· `explorer` subagent fan-out + `bc-impact-map` skill | 影响地图草稿（vs 基线 delta）+ 候选清单依据 |
| **T2** 详设 + 契约 | 🟡 | `contract-first` skill 生成规格五件套（[§3.3](#33-spec-链式生成五件套)）| 规格五件套：`spec.md` / `plan.md` / `contracts/` / `data-model.md` / `quickstart.md` + lint 通过证据 |
| **T3** 任务包拆分 | 🟢 | `task-decomp-fanout` skill 生成 `tasks.md` → `/speckit.taskstoissues` 一次派生 N 个 Issue（[§1.5](#15-feature--task-两层结构)）| `tasks.md`（N 行）+ N 个镜像 Issue + 依赖图 |
| **T4.1** 写方案 | 🟡 | 主代理 Plan Mode + `gate-checklist` skill；**消费**该 feature 的 `spec.md` + `plan.md` + `contracts/`，输出落该 task 的 Issue body / `tasks.md` 行展开（**不改 feature 级 spec**，缺漏回流 T2）| 单 task 方案 1 页 + 5 条 checklist 自评 |
| **T4.2** 编码 | 🟡（CI 🟢）| **内部循环：4-Phase（[§3.1](#31-4-phase-落地)）** · `implementer` subagent + `worktree` 隔离 + PostToolUse hook 强制 lint/test · Context Bundle 见 [§3.2](#32-context-bundle-契约) · Gate：CI 全绿 + `quickstart.md` 场景通过 | 代码 + 测试 + commit `Closes #N` + CI 报告 |
| **T4.3** 代码评审 | 🟡 | **`reviewer` subagent**（隔离 context · [§3.4](#34-implementer--reviewer-隔离模式)）+ `gate-checklist` skill 跑 5 条红旗 | PR Review 记录（checklist 打勾 + 备注）|
| **T4.4** QA 验收 | 🟡 | `qa-cases` skill 生成测试用例 + 探索性 mutation 测试 | 测试报告 + 缺陷登记 |
| **T4.5** 业务验收 | 🔴 | AI 仅生成 demo 脚本；**不参与决策** | 验收对照表（PRD 标准逐条 vs 实现）|
| **T5** 部署 | 🟡 | `release-canary` skill 出灰度方案 + 回滚剧本 · **AI 无 prod 写权限**，只产出草稿 / 观察 / 建议 | 发布单草稿 + canary 指标解读 |
| **T6** 观测窗 | 🟢 | 定时聚合告警与指标的 cron prompt | 观测报告草稿 |
| **T7** 复盘 | 🟡 | `retro-audit` skill 跑 9 项 audit checklist + auto memory 沉淀 | 复盘文档草稿 + Action Items 候选 |
| **R · 横切** | 🟠 | `adr-writing` / `std-writing` skill 列 ≥ 2 候选 + 对比矩阵 | ADR / STD 草稿（决策由人做）|

---

## 附录 A · 跨工具兼容矩阵

> 60 天未复核即视为待校。

| 能力 | Claude Code | Cursor | GitHub Copilot | OpenAI Codex |
|---|---|---|---|---|
| 主入口文件 | `CLAUDE.md`（根 + 嵌套）| `AGENTS.md`（根 + 嵌套）+ `.cursor/rules/*.mdc` | `.github/copilot-instructions.md` + `AGENTS.md`（根 + 嵌套）；亦读根 `CLAUDE.md` / `GEMINI.md`（替代源）| `AGENTS.md`（根 + 嵌套）|
| `AGENTS.md` 直读 | ⚠️ 需 `@AGENTS.md` 或 `ln -s` | ✅ | ✅（累加进 instructions）| ✅ |
| 路径作用域规则 | `.claude/rules/*.md` + `paths:` | `.cursor/rules/*.mdc` + `globs:` / skill `paths:` | `.github/instructions/*.instructions.md` + `applyTo:` | `AGENTS.md` 嵌套（就近覆盖）· Codex-only 隔离写 `<dir>/AGENTS.override.md`（手写）|
| Plan / Approval 模式 | ✅ Plan Mode（Shift+Tab · `permissionMode: plan`）| ✅ Plan Mode（Shift+Tab · 方案 Markdown 可编辑 · save to workspace）| ✅ mode dropdown · Plan agent + "Start Implementation" 一键 hand-off | ✅ 3 档 approval（`Read-only` / `Auto` / `Full Access` · CLI 现行）|
| Custom Subagent | ✅ `.claude/agents/*.md` + `/agents` 向导；frontmatter `tools / permissionMode / isolation:worktree / memory / mcpServers / skills / hooks / model` | ✅ `.cursor/agents/*.md`（同识 `.claude/agents/` / `.codex/agents/` · user/project 两级）；frontmatter `name / description / model(inherit\|id) / readonly / is_background`；内置 Explore / Bash / Browser；`/name` 调用；前台 + 后台两种 | ✅ `.github/agents/*.agent.md`（兼容 `.claude/agents/*.md`）；`tools / model / handoffs / mcp-servers / hooks(Preview) / user-invocable / disable-model-invocation / target` | ✅ 官方 `/docs/codex/subagents` → `.codex/agents/*.md`（Cursor 2.4 互识）+ ChatGPT Codex 异步云 |
| Agent Handoff（链式）| ⚠️ 手动 prompt 链 + Agent tool 调度 | ⚠️ 无显式 `handoffs` 字段，以 orchestrator 子代理模式手动链 | ✅ frontmatter `handoffs:`（label / agent / prompt / send / model · 按钮 + 可 auto-submit）| ⚠️ subagent orchestrator 模式手动链 |
| Skills | ✅ agentskills.io 原生 · 可在 subagent `skills:` 预加载 | ✅ agentskills.io 原生：`.cursor/skills/<n>/SKILL.md`（兼容 `.claude/skills` / `.codex/skills` / `.agents/skills`）；`paths` 限定 + `disable-model-invocation`；`scripts / references / assets` 三件套；GitHub remote 安装；内置 `/migrate-to-skills`（2.4）| ✅ Agent Skills + `/create-skill` 内置创建器 · 自动召回 · 另可附 `.github/prompts/<x>.prompt.md`（独立机制 · `/<x>` 手动 slash）| ✅ 官方 `/docs/codex/skills` → `.codex/skills/<n>/SKILL.md` |
| Hooks | ✅ `.claude/settings.json` 全局 + subagent frontmatter 局部（PreToolUse / PostToolUse / SubagentStart / SubagentStop 等）| ✅ `.cursor/hooks.json`（Enterprise / Team / Project / User 四级合并 · 18+ 事件 · 原生兼容 Claude 退出码 2 = deny）| ⚠️ Preview（agent frontmatter `hooks` 需 `chat.useCustomAgentHooks`）+ `.github/workflows/` | ✅ 官方 `/docs/codex/hooks` + `~/.codex/config.toml` sandbox/approval + OS 级 Seatbelt / landlock / Windows sandbox |
| Cloud / Background Agent | ✅ Background subagent + Agent View · Web / iOS 联动 | ✅ Cloud Agents（旧 Background · cursor.com/agents + Slack / GitHub / Linear / API · 自带 VM + 远程桌面）| ✅ Cloud Agent（REST API + auto model + custom agent profile）| ✅ ChatGPT Codex（云端 sandbox · 任务 1-30 分钟出 PR · 支持中途联网）|
| Auto Memory | ✅ v2.1.59+ · `CLAUDE.md` 自动写回 + per-subagent `memory: user\|project\|local` | ✅ Memories（自动 + 可编辑）| ✅ Copilot Memory（2026/5/15 GA · 用户偏好）+ Personal Context | ⚠️ 仅静态 `AGENTS.md` + `~/.codex/AGENTS.md`（profile · 无自动写回）|
| MCP | ✅ `.mcp.json` + per-subagent inline | ✅ MCP servers（OAuth · Cloud 共用）| ✅ GA（含 `mcp-servers` agent 字段）| ✅ 原生 |
| Spec-Kit 集成 | ✅ Skills-based · `.claude/skills/` · `/speckit.*` | ✅ Skills-based · `.cursor/skills/` · `/speckit.*` | ✅ Prompts · `.github/prompts/` · `/speckit.*`（非 multi-install safe）| ✅ Skills-only · `.agents/skills/` · `$speckit-*` |

> 各 SOP 步具体 prompt 模板、skill frontmatter、subagent 配置详见 [`templates/`](templates/) 与 [`_refs/`](_refs/)。

---

## 附录 B · 资料红线

参见 [`templates/skills/data-redline/SKILL.md`](templates/skills/data-redline/SKILL.md) 与 [`templates/checklists/05-data-redline.md`](templates/checklists/05-data-redline.md)。

**4 级数据分类**：Public / Internal / Confidential / Restricted

**8 条红线**（generic 化自 v11 第 7 章）：

1. 不向 AI 工具传 Restricted 数据
2. 不在 prompt 中粘贴生产凭证
3. 不让 AI 直接连生产数据库
4. AI 生成代码须走人审才能合并到 main
5. AI 不可访问 `.env` `secrets/` 等目录（hook 拦截）
6. 跨租户数据查询须脱敏
7. 客户数据导出须审批 + 审计
8. 违规事件按 warn → record → revoke 三级处置

数据红线 skill 始终在 context（通过 `disable-model-invocation: false` + 入口规则 import）。

---

## 附录 C · Onboarding 6 阶段

参见 [`templates/checklists/01-onboarding.md`](templates/checklists/01-onboarding.md)。

| 阶段 | 时间 | 目标 | 关键 check |
|---|---|---|---|
| D1 环境 | Day 1 | 装工具 / clone 仓 | Claude / Cursor / Copilot CLI 可跑 |
| D1 验证 | Day 1 | 跑通示例 | `claude` `cursor` `gh copilot` 能输出 |
| W1 阅读 | Week 1 | 读完本工作流 + 入口模板 | AGENTS.md 4 家入口理解（含嵌套发现）|
| W2 影子 | Week 2 | 跟一次完整 SOP T0~T6 | 观察 Writer-Reviewer 模式 |
| W2 小任务 | Week 2 | 独立完成一个 worktree 任务 | PLAN.md 拆解 + 自测 |
| M1 完整 sprint | Month 1 | 主导一个完整 SPEC → 上线 | 双签字（导师 + 架构师）|

---

> 最后更新：2026/5 · 与 22-tech-cycle-sop 流程图同步维护
