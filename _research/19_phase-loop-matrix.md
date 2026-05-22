<!-- REFERENCE ONLY: sanitized sample, not for production -->
# 19 · Anthropic 4-Phase 的性质 & 其他三家的认可/采纳度

> 调研时间：2026-05-20 · 60 天未复核即视为待校
> 范围：回答两个问题——
> 1. **4-Phase（Explore→Plan→Code→Commit）是通用方法论理论，还是深度绑定 Claude 工具内部逻辑？**
> 2. **其他三家（Codex / Cursor / Copilot）官方有没有承认、采纳、或借鉴 4-Phase？认可度是哪一级？**
> 与 [_research/11](11_spec-driven-development-and-4phase.md) 的关系：11 详写了 Anthropic 4-Phase 与 Spec-Kit 4-Phase 的对照，但未拆解"理论 vs 工具绑定"维度，也没量化其他厂商的态度。本篇补这一层。
> 与 [_research/17](17_plan-carrier-matrix.md) 的区分：17 是横向"Plan 阶段载体"，本篇是纵向"4-Phase 整体被各家承认到什么程度"。

---

## 1. 核心结论（三句话）

1. **4 步本身是通用编程认知顺序**（先看、再想、再做、再交付）——任何工程师本能就这么干，**不专属于 Claude**。并且任务按需选子集（review 只走 Explore+Plan、问答只走 Explore、hotfix 可跳 Plan）。
2. **Anthropic 是唯一把它命名、文档化、并且在工具内做物理强约束的厂商**——`plan mode` 是 hardcoded 状态（Shift+Tab 切换、物理 read-only、`Ctrl+G` 编辑 plan 都是硬编码快捷键，不是 prompt 约定）。
3. **其他三家：能力上 4 步全部能跑**（详见 §2.5 逐步支持矩阵），**但没人在官方文档里引用过"4-Phase"这个命名**（也没说"我们参考 Anthropic"）——都只独立把 **Plan 阶段抽出来做载体**（Codex `plan` mode / Cursor `Plan` 模式 / Copilot 内置 `Plan` agent），事实上证实 Plan 是当前主流。

---

## 2. 4-Phase 性质拆解：理论 vs 工具绑定

把 Anthropic 的 4-Phase 拆成两层看：

| 层次 | 内容 | 是否绑定 Claude 工具 | 可迁移度 |
|---|---|---|---|
| **L1 方法论层**（认知顺序） | "先 Explore 充分理解上下文，再 Plan 产出可审阅方案，再 Code 实现，再 Commit 收尾" | ❌ **不绑定**——本质是通用工程经验的总结，任何工具/任何人都可以遵守 | ✅ 完全可迁移（甚至不用工具，靠习惯就能跑） |
| **L2 工具实现层**（强约束） | `plan mode` 是 hardcoded UI 模式 / 物理 read-only / `Ctrl+G` 硬编码快捷键 / 内置 plan subagent / `--permission-mode plan` CLI flag | ✅ **重度绑定 Claude Code / Codex CLI**——离开 Anthropic 工具链就只剩 prompt 提醒 | ❌ 难迁移（其他工具没有"物理 read-only 状态"对应物） |

**结论**：4-Phase = **L1 通用方法论 + L2 Anthropic 工具强约束**双层叠加。
- 你说"4-Phase 是理论指导"——对一半（L1 层成立）。
- 你说"4-Phase 深度绑定 Claude 工具内部"——也对一半（L2 层成立）。
- 完整答案是**两层都有**，且 Anthropic 的独特价值在于**把 L1 用 L2 的物理约束兜底**（用户在 plan mode 下哪怕想让 Claude 改文件也改不了，这是其他三家都没有的硬约束）。

---

## 2.5  4 步×4 工具 · 逐步支持矩阵

4-Phase **还是 4 步**，不需要变抽象。重点是：每家工具**全部 4 步是否都能跑**，以及跑的强度（有独立成态 / 只能 prompt 提示 / 能力完备但未命名）。

| 阶段 | 本质动作 | Claude Code | Codex CLI | Cursor | Copilot |
|---|---|---|---|---|---|
| **Explore** | 读文件/grep/glob/上下文汇总 | ✅ plan mode 状态 + `Explore` subagent | ✅ Read-only 权限档 + 内置 `explorer` subagent | ✅ Ask 模式 + 内置 `Explore` subagent | ✅ `Ask` agent（built-in）+ `Explore` subagent（preview）|
| **Plan** | 产出可审阅方案 | ✅ plan mode + `Plan` subagent（双形态） | ✅ App `plan` mode / IDE `Chat` mode / CLI Read-only | ✅ `Plan` 模式（产物 plan.md） | ✅ **内置 `Plan` agent**（VS Code 三大 built-in 之一）|
| **Code** | 改文件 + 跑命令 | ✅ default mode | ✅ Auto / Full Access | ✅ Agent 模式 | ✅ `Agent` agent（built-in）|
| **Commit** | `git add` / `git commit` / `gh pr create` | ✅ 官方推荐动作（best-practices 第四步）| ✅ 能起 bash、能力完备（未命名为阶段）| ✅ 能起 bash、能力完备（未命名为阶段）| ✅ 能起 bash、能力完备（未命名为阶段）|

**读法**：

- **能力层：4 步四家全能跑**——没有哪个阶段是某家工具物理跑不了的。
- **命名层：只 Claude 把 4 步都当一等公民**——其他三家都只命名了 Plan（间接含 Explore/Code），Commit 从未被命名为独立阶段。
- **约束层：只 Claude / Codex 在 Plan 阶段有物理 read-only 强约束**（permission/plan mode）；Cursor Plan 模式 / Copilot Plan agent 是 UI/角色层软约束，不阻止写入。

---

## 2.6  任务×4-Phase · 按需选子集

4-Phase 不是“每个任务都走完 4 步”，是“**完整任务最多 4 步**”。常见任务类型取子集：

| 任务类型 | Explore | Plan | Code | Commit | 说明 |
|---|---|---|---|---|---|
| **代码讲解 / 问答** | ✅ | — | — | — | 只用一步；Claude Ask 模式 / Copilot Ask agent / Codex Chat / Cursor Ask 都是这个场景 |
| **代码 review** | ✅ | ✅ | — | — | 要 Explore 上下文 + Plan 产出审阅意见；不动文件不提交 |
| **架构设计** | ✅ | ✅ | — | — | 产出 ADR/设计文档；不进入实现 |
| **小 hotfix（同于照现成 plan）** | — | — | ✅ | ✅ | 跳过前两步，直接改+提交 |
| **中小 feature（默认）** | ✅ | ✅ | ✅ | ✅ | 标准完整 4 步 |
| **大型 feature / 不熟代码库** | ✅ | ✅ | ✅ | ✅ | 4 步 + 可以中间复返 Explore/Plan |
| **debug 复现徧疾** | ✅ | — | ✅ | — | Explore 找根因 → Code 补丁；补丁是否提交覗是否需 PR |
| **写文档 / PRD** | ✅ | ✅ | ✅ | ✅ | 文档也是产出物，Code = 写 md，Commit = git 入库 |

**关键读法：Plan 是当前业界主流阶段**——除了“问答”和“hotfix”这两个极端场景，其他任务几乎都要走 Plan。这是为什么四家都独立把 Plan 抽出来做独立载体（详见 §3 评级表及 [_research/17](17_plan-carrier-matrix.md)）。

---

## 3. 其他三家的认可度：四档评级

> 评级维度：①命名采纳 ②文档引用 ③功能对应 ④物理强约束。从弱到强递进——纯命名认可（最弱）到工具内强约束（最强）。

| 工具 | ①命名采纳"4-Phase" | ②文档引用 Anthropic | ③功能对应物（Plan 阶段是否独立成态） | ④物理强约束（read-only 等硬约束） | 综合认可度 |
|---|---|---|---|---|---|
| **Claude Code**（自家） | ✅ 官方命名 | — | ✅ plan mode + Plan subagent | ✅ 物理 read-only + `Ctrl+G` hardcoded | **★★★★★** 全栈强绑定 |
| **Codex CLI**（OpenAI） | ❌ 不用此名 | ❌ 从不引用 | ✅ 有 `plan` 模式（Auto / Read-only / Full Access 三档之一）+ `$skill` 语法 | ⚠ 部分（Read-only 是权限层，不是 phase 状态） | **★★★☆☆** 功能层默认采纳，命名层完全独立 |
| **Cursor** | ❌ 不用此名 | ❌ 从不引用 | ✅ `Plan` 模式（与 Agent / Chat 并列；产物 plan.md 可 Save to workspace） | ❌ 无物理强约束（Plan 模式只是 UI 模式，不阻止文件写入） | **★★★☆☆** 功能层采纳，约束最弱 |
| **GitHub Copilot** | ❌ 不用此名 | ❌ 从不引用 | ✅ **内置 `Plan` agent**（VS Code 三大 built-in 之一，与 `Agent` / `Ask` 并列）+ handoff 机制 | ⚠ 角色分工层（Plan agent 设计上"先产 plan、再 hand off"，但没硬阻止边写边改） | **★★★★☆** 角色分工最清晰，约束次于 Anthropic |

**横向观察**：

- **没有一家官方说过"我们采用 / 借鉴 Anthropic 的 4-Phase"**——这个命名是 Claude 独占的。
- **但三家都独立地把 "Plan 阶段必须独立成态" 实现到产品里**——这反向证明 L1 方法论是**业界共识级别的认知**，不是 Anthropic 独有洞察。
- **物理强约束（L2）只有 Anthropic 做到了**——Codex Read-only 是权限层（不是 phase 概念）、Cursor Plan 模式只是 UI 模式、Copilot Plan agent 是角色分工。**这是 Anthropic 的护城河**。
- **没有任何一家实现完整 4 阶段**（Explore / Plan / Code / Commit 全部独立成态）——其他三家普遍只把 Plan 单独抽出来，Explore 和 Commit 都融在 Code 里。Anthropic 是唯一把 4 阶段都视作一等公民的厂商。

---

## 4. 业界态度可总结成一句话

> **4 步全部四家能跑**（能力层齐平）**、Plan 是全员独立载体的主流阶段**（命名层共识）**、但只有 Anthropic 把 4 步都当一等公民并在 Plan 阶段用物理 read-only 强约束兜底**（约束层独占）**。任务按需选阶段子集（review 只需 Explore+Plan、hotfix 可跳 Plan、问答只需 Explore）。**

playbook 提及 4-Phase 时建议措辞：

- ✅ "Anthropic 4-Phase 工作流（Explore→Plan→Code→Commit）是 Claude Code 官方推荐流程；业界其他三家未采纳此命名，但都内置了 Plan 阶段载体（详见 _research/17）。"
- ❌ 不要写"4-Phase 是业界通用方法论"——它的 L1 是通用的，但**命名和完整 4 段框架**没被任何其他厂商承认。
- ❌ 不要写"四家工具都支持 4-Phase"——只有 Anthropic 完整支持，其他三家只支持其中的 P 阶段。

---

## 5. 已知未解决 / 待二次核验

- **Codex `plan` 模式与 Anthropic plan mode 的实现差异未深挖**：Codex 是 permission mode，物理上是否阻止写入文件还是仅 prompt 约束，需读 [_research/01](01_entry-file-support-matrix.md) / [_research/06](06_subagent-orchestration.md) 验证。
- **Cursor 是否在 changelog/blog 里隐性引用过 Anthropic 工作流**：本次只查了 docs/learn，未穷尽 forum.cursor.com 与官方 blog。
- **Copilot `Plan` agent handoff 是否真有"产完 plan 才能 hand off"的强约束**：官方 overview 描述为"creates a plan ... hands off when it looks right"，措辞偏意图、未明确说强约束，需读 `agents/local-agents` 子页确认。

---

## 6. 引用源

| # | URL / 文件 | 用于核实 |
|---|---|---|
| 1 | <https://code.claude.com/docs/en/best-practices> | Anthropic 4-Phase 原文 "The recommended workflow has four phases: Explore, Plan, Code, Commit" |
| 2 | <https://code.visualstudio.com/docs/copilot/agents/overview> | Copilot **`Plan` agent built-in**；未引用 Anthropic |
| 3 | <https://cursor.com/docs/agent/plan-mode> | Cursor **`Plan` 模式**；未引用 Anthropic |
| 4 | <https://cursor.com/learn/agents> | Cursor 把 agent 描述为"工具在循环中运行"通用模型，无 4-Phase 命名 |
| 5 | <https://developers.openai.com/codex/cli/features> | Codex `plan` 模式 + Read-only / Auto / Full Access 三档 |
| 6 | [_research/11](11_spec-driven-development-and-4phase.md) | Anthropic 4-Phase 与 Spec-Kit 4-Phase 详细对照 |
| 7 | [_research/17](17_plan-carrier-matrix.md) v3.5 | Plan 阶段在四家载体的"有没有"矩阵（与本篇互补）|
