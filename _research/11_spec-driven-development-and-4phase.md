<!-- REFERENCE ONLY: sanitized sample, not for production -->
# 11 · Spec-Driven Development（SDD）与 4-Phase 工作流

> 调研日期：2026-05
> 来源：GitHub Spec-Kit 官方仓库 + Anthropic Claude Code 官方文档
> 用途：回答"任务包给 AI 是什么形态最合理 / 怎么给 AI 才能写出最优代码"

---

## 0 · TL;DR（一句话）

- **任务包给人**：Issue（11 字段，进 Issue Tracker，状态机驱动）OK
- **任务包给 AI**：单 Issue body 不够，**业界事实标准是一个入仓的目录** `specs/NNN-feature/`，含 `spec.md / plan.md / contracts/ / data-model.md / tasks.md / quickstart.md / memory/constitution.md`
- **两者关系**：单一事实源是 `specs/NNN-feature/`（入 git，可 diff/回滚/分支并行），Issue 是它在 tracker 里的**投影**（用于人协作仪表与 PR 闭环）

---

## 1 · 一手来源

| 来源 | URL | 关键性 |
|---|---|---|
| GitHub Spec-Kit | https://github.com/github/spec-kit | 101k★ · MIT · 30+ AI 工具适配 |
| Spec-Driven 方法论 | https://github.com/github/spec-kit/blob/main/spec-driven.md | 完整哲学+工件清单 |
| Claude Code Best Practices | https://code.claude.com/docs/en/best-practices | Anthropic 官方 4-Phase 出处 |

---

## 2 · Spec-Driven Development（SDD）

### 2.1 核心反转

> "For decades, code has been king—specifications served code...SDD inverts this: code serves specifications."

- 传统：PRD → 写代码 → 代码是事实 → spec 被丢弃
- SDD：PRD = 可执行 spec → AI 从 spec 生成 code → spec 是事实
- 维护软件 = 演化 spec；refactor = 重构 spec
- 这是 0→1, (1', ...), 2, 3, N 的迭代演化模型

### 2.2 七命令工作流（slash command · AI 工具原生）

| # | 命令 | 输入 | 产出 |
|---|---|---|---|
| 1 | `/speckit.constitution` | 项目治理原则 | `memory/constitution.md` |
| 2 | `/speckit.specify` | "我想做 X" | `specs/NNN-feature/spec.md`（仅 WHAT/WHY） |
| 3 | `/speckit.clarify` | spec.md | 标 `[NEEDS CLARIFICATION]` 反逼澄清 |
| 4 | `/speckit.plan` | spec.md + 技术栈选择 | `plan.md + data-model.md + contracts/ + research.md` |
| 5 | `/speckit.tasks` | plan.md + contracts | `tasks.md`（每条带 `[P]` 并行标） |
| 6 | `/speckit.analyze` | 全套工件 | 跨工件一致性检查报告 |
| 7 | `/speckit.implement` | tasks.md | AI 按任务一条条执行 |

辅助：`/speckit.taskstoissues` 将 tasks.md 镜像到 GitHub Issues（用于 tracker 闭环）。

### 2.3 标准目录（给 AI 的最佳 context bundle）

```
<repo-root>/
├── memory/
│   └── constitution.md       ← 仓库级单例（不在 specs/ 下）
└── specs/
    └── NNN-feature/
        ├── spec.md           ← WHAT/WHY（业务意图，禁 HOW）
        ├── plan.md           ← HOW 高层（技术架构）
        ├── research.md       ← 技术选型对比 / 库调研
        ├── data-model.md     ← 实体 schema
        ├── contracts/        ← API / 事件契约（机读，*.yaml / *.json）
        │   ├── rest.yaml
        │   └── events.yaml
        ├── tasks.md          ← 任务列表（每条反链 contract）
        └── quickstart.md     ← 验证场景（让 AI 自检）
```

**给 AI 时一次 `cd specs/NNN-feature/` 全部入 context**。

### 2.4 Constitution · 九条不变原则（节选）

| 条 | 名 | 关键约束 |
|---|---|---|
| I | Library-First | 每 feature 必先是独立 library |
| II | CLI Interface Mandate | 所有库必须有 stdin/stdout/JSON CLI |
| III | Test-First | **NON-NEGOTIABLE**：tests 必先于 code，先 Red |
| VII | Simplicity | ≤3 projects，禁 future-proofing |
| VIII | Anti-Abstraction | 直用框架，单 model representation |
| IX | Integration-First Testing | 真 DB > mock，contract test mandatory |

### 2.5 模板约束 LLM 的 7 个机制（spec-driven.md 原话）

1. **Preventing Premature Implementation**（spec 禁 HOW）
2. **Forcing Explicit Uncertainty Markers**（`[NEEDS CLARIFICATION]`）
3. **Structured Thinking Through Checklists**（spec 自带"unit tests for English"）
4. **Constitutional Compliance Through Gates**（Phase -1 Gates）
5. **Hierarchical Detail Management**（高层 plan + 低层 implementation-details/）
6. **Test-First Thinking**（contracts → tests → source 顺序）
7. **Preventing Speculative Features**（禁"might need"）

---

## 3 · Claude Code 4-Phase（Anthropic 官方）

### 3.1 4 个阶段

| Phase | 工具状态 | 动作 | 工件 |
|---|---|---|---|
| **① Explore** | Plan Mode（只读） | `claude` 读 src/auth，问问题不动文件 | 内部记忆 |
| **② Plan** | Plan Mode | 出实现计划，可 `Ctrl+G` 编辑 | 一份 implementation plan |
| **③ Implement** | 默认 mode | 按 plan 写代码 + 跑测试 | 代码 + 测试 + commit |
| **④ Commit** | 默认 mode | descriptive commit + 开 PR | PR |

### 3.2 最高杠杆原话

> "Give Claude a way to verify its work ... This is **the single highest-leverage thing you can do**."

→ 每条任务必带可验证手段（tests / screenshots / expected output / lint / typecheck）。

### 3.3 其他关键原则

- **CLAUDE.md ≤2 页**：超过则规则被忽略；"Would removing this cause mistakes? If not, cut it."
- **Skill 优于 CLAUDE.md**：domain knowledge 放 `.claude/skills/<x>/SKILL.md`，按需触发
- **Hook 是唯一确定性约束**：CLAUDE.md 是 advisory，hook 才 guarantee
- **Subagent 用于隔离 context**（reviewer 独立 session 不见 writer 历史）
- **`/clear` 在不相关任务间**：避免 kitchen sink session
- **Auto Mode + 验证**：classifier 拦危险动作，例行通过
- **Writer/Reviewer 双 session**：实现和评审隔离，避免 AI 自我偏见

---

## 4 · 业界共识 6 铁律（spec-kit + Claude Code + 09_industry-sop-benchmarks）

| # | 铁律 | 原句出处 |
|---|---|---|
| 1 | **Spec-First** · 写代码前必有 spec + contracts | Spec-Kit Article III |
| 2 | **Verification 强制** · 每 task 自带验证手段 | Claude Code "single highest-leverage" |
| 3 | **Constitution 单文件** · immutable 原则永远在 context | Spec-Kit `memory/constitution.md` |
| 4 | **Plan Mode 分离** · Explore/Plan 只读 → Implement 才动文件 | Claude Code 4-Phase |
| 5 | **Writer/Reviewer 双 session** · 隔离 context 避免偏见 | Anthropic Engineering Blog |
| 6 | **Test/Contract-First** · contracts + tests 先于 implementation | Spec-Kit Article IX |

---

## 5 · 任务包形态对比 · 人 vs AI（核心结论）

| 维度 | 人协作形态 | AI 实施形态 |
|---|---|---|
| **载体** | Issue（GitHub/Jira/Linear） | `specs/NNN-feature/` 目录（入 git） |
| **字段** | 11 字段（id/title/context_links/inputs/outputs/dor/dod/estimate/owner/dependencies/status） | spec.md + plan.md + contracts/ + tasks.md + quickstart.md + constitution |
| **状态机** | Backlog → Ready → In Progress → In Review → Done | git 分支 + commit + PR |
| **强项** | 通知 / 权限 / 跟踪 / 状态机 / 关 PR 闭环 | 一次性入 context · diff/回滚 · 跨工具一致 |
| **弱项** | 单 body 装不下 spec/契约/验证；不可 diff | 不适合人协作仪表盘 |

**关系**：

```
T3 拆分（一次拆，两处落地）：
  ├─ specs/NNN-feature/tasks.md   ← 单一事实源（入 git）
  └─ GitHub Issue #N               ← tasks.md 中每条任务的镜像

T4 实施：
  人  → 看 Issue 认领 / 改状态 / 关 PR
  AI  → cd specs/NNN-feature/ 跑 4-Phase
        commit message: "Closes #N" → Issue 状态机闭环
```

**单一事实源 = `specs/NNN-feature/`（入 git）**。
Issue 是它的派生投影。这是 Spec-Kit `/speckit.taskstoissues` 命令在做的事——tasks.md 是源，Issue 是导出。

---

## 6 · 三种落地策略（不含 <Platform> 具体细节）

| 策略 | 描述 | 优 | 劣 |
|---|---|---|---|
| **A · 仅 Issue** | 维持 SOP 原状，把 spec/contract 塞 Issue body | 简单 | AI 上下文炸 · 不可 diff · 跨 session 不稳 |
| **B · 双轨镜像** | Issue（人）+ `specs/NNN-feature/`（AI），tasks.md ↔ Issue 一对一 | 人 AI 都满意 · 单源在 git · 兼容现有 SOP 状态机 | 需建镜像约定 |
| **C · 纯目录** | 抛 Issue，全用 `specs/NNN-feature/`，PR 闭环 | 极简 | 失去 Issue 的 tracker/通知/权限能力，团队协作弱 |

业界推荐 **B**（Spec-Kit 自带 `/speckit.taskstoissues` 印证）。

---

## 7 · 七文件逐个解释（内容 / 来源 / 人 AI 分工）

> 后续实际项目架构对应 specs/ 工程时直接对照本节。

### 7.1 生成顺序（强制 · 任一前置缺失则 slash 命令拒绝执行）

```
constitution（一次性 · 仓库级单例）
   ↓
spec ──[/clarify 循环]──→ DoR
   ↓
plan ──┬─→ research
       ├─→ data-model
       ├─→ contracts/
       └─→ quickstart
   ↓
tasks ──[/speckit.taskstoissues]──→ GitHub Issue #N
```

### 7.2 每文件详解

#### ① `memory/constitution.md`（仓库级单例 · 全仓 1 份）

| 维度 | 说明 |
|---|---|
| **内容** | 9 条左右不可违背的工程原则（Library-First / Test-First NON-NEGOTIABLE / Simplicity ≤3 projects / Anti-Abstraction / Integration-First …）|
| **来源** | 团队架构决策；可引用 STD-* 红线、AGENTS.md 摘要 |
| **谁写** | **人主笔**（架构师 + Tech Lead）；`/speckit.constitution` 辅助起草 |
| **AI 角色** | 永远在 context；每个新 feature 自检"我有没有违背"。AI 不可修改 |
| **变更频率** | 极低（季度级）。改它 = 改架构 DNA |
| **类比 SOP** | ≈ T0 之前的常设前提；属 R 横切 |

#### ② `spec.md`（WHAT / WHY · 业务意图）

| 维度 | 说明 |
|---|---|
| **内容** | 用户故事、业务规则、验收准则、`[NEEDS CLARIFICATION]` 标记。**禁出现库名 / 框架 / 表结构 / API 路径** |
| **来源** | PRD + 业务方访谈 |
| **谁写** | **人主笔（PM / BA）**；`/speckit.specify` 把粗 PRD 段落转成结构化 spec |
| **AI 角色** | 起草后跑 `/speckit.clarify` 自动标出歧义 → 反逼人澄清 |
| **类比 SOP** | T0 Intake 产出（PRD Signed → spec.md 转写） |
| **典型反例** | "使用 Redis 存幂等键" ← HOW 泄漏，hook 拦截 |

#### ③ `plan.md`（HOW 高层 · 技术架构）

| 维度 | 说明 |
|---|---|
| **内容** | 模块拆分、技术栈选择、关键决策、Phase Gates、跨服务交互高层视图 |
| **来源** | spec.md + constitution.md + research.md |
| **谁写** | **人 + AI 双签**。Tech Lead 决策；AI 起草并列候选 |
| **AI 角色** | Plan Mode（只读）下 `/speckit.plan` 一次产出 plan + data-model + contracts + research + quickstart 五件套 |
| **类比 SOP** | T2 详设的核心产出 |
| **关键约束** | 每条任务必带 `verification:` 字段（怎么证明做完了）|

#### ④ `research.md`（技术选型对比）

| 维度 | 说明 |
|---|---|
| **内容** | 候选库 / 框架 / 模式的对比矩阵 + 选定理由 + 排除原因 |
| **来源** | AI 上网搜（vendor 官网 / GitHub / benchmark）+ 人补充内部约束 |
| **谁写** | **AI 主笔**（`/speckit.plan` 副产出），人审 |
| **AI 角色** | 🟢 全自动起草 → 🟡 人删除不靠谱候选 |
| **类比 SOP** | T2 内部"为什么选 X"留痕 / ADR 候选材料 |
| **价值** | 给后续 AI 实施提供"为什么这样选"上下文，避免无脑改回别的库 |

#### ⑤ `data-model.md`（实体 schema）

| 维度 | 说明 |
|---|---|
| **内容** | 领域实体、字段、关系、约束、状态机。**不写存储引擎**（那是实施细节）|
| **来源** | spec.md 抽出业务实体 + plan.md 技术约束 |
| **谁写** | **AI 起草**（`/speckit.plan` 副产出），架构师审 |
| **AI 角色** | 🟡 半自动；人改字段命名 / 关系 / 状态转移 |
| **类比 SOP** | T2 数据契约的一半（另一半是 contracts/）|

#### ⑥ `contracts/`（API / 事件契约 · 机读）

| 维度 | 说明 |
|---|---|
| **内容** | OpenAPI YAML / AsyncAPI / Protobuf / JSON Schema。机器可 lint、可生成 client/server stub、可生成 contract test |
| **来源** | data-model.md + plan.md 的服务边界 |
| **谁写** | **AI 起草**，跨服务 owner 审签 |
| **AI 角色** | 🟢 schema 生成 / 🟡 命名风格修正 |
| **类比 SOP** | T2 契约的另一半（**SOP 中契约 Approve 是 Gate**）|
| **硬约束** | semver 必带；breaking 变更回 T2 走完整 Approve |

#### ⑦ `tasks.md`（任务列表 · 实施清单）

| 维度 | 说明 |
|---|---|
| **内容** | 每条一行：`id / title / inputs / outputs / verification / [P] 并行标 / dependencies` |
| **来源** | plan.md + contracts/ 自动拆 |
| **谁写** | **AI 主笔**（`/speckit.tasks`），Tech Lead 审依赖图 |
| **AI 角色** | 🟢 拆分 → `/speckit.taskstoissues` 镜像到 GitHub Issue（每条任务 ↔ 一个 Issue #N）|
| **类比 SOP** | T3 任务包拆分的**单一事实源** |
| **关键点** | Issue 是它的派生投影；人改 Issue body 不算数，要改 tasks.md 重镜像 |

#### ⑧ `quickstart.md`（验证场景 · AI 自检手册）

| 维度 | 说明 |
|---|---|
| **内容** | 跑通 feature 的最短脚本：起服务 / 调 API / 看预期输出 / 关停 |
| **来源** | spec.md 验收准则 + contracts/ 端点 |
| **谁写** | **AI 主笔**，QA 审 |
| **AI 角色** | 🟢 起草脚本；AI 在 4-Phase Implement 阶段**自动跑一遍**自验 |
| **类比 SOP** | T4.4 QA 用例的种子 + T4.2 内部自验 |
| **价值** | 体现 Claude Code "single highest-leverage" 原则——给 AI 一个验证它自己工作的方法 |

### 7.3 自动化 vs 人协作总览

| 文件 | 谁主笔 | AI 自动化程度 | 人介入时机 | SOP 步骤 |
|---|---|---|---|---|
| `constitution.md` | 人 | 🔴 AI 只读 | 一次性写好 + 季度评审 | R / T0 前置 |
| `spec.md` | 人（PM）| 🟡 起草后 AI 标歧义 | DoR 前澄清 | T0 → T1 |
| `plan.md` | 人决策 + AI 起草 | 🟡 | Tech Lead Approve | T2 |
| `research.md` | AI | 🟢 | 审候选合理性 | T2 |
| `data-model.md` | AI 起草 | 🟡 | 架构师审字段 | T2 |
| `contracts/` | AI 起草 | 🟢 schema · 🟡 命名 | 跨服务 owner Approve（Gate）| T2 |
| `tasks.md` | AI | 🟢 | Tech Lead 审依赖图 | T3 |
| `quickstart.md` | AI | 🟢 | QA 审场景覆盖 | T2 → T4.2/4.4 |

🟢 全自动（AI 主导、人复核即过）· 🟡 半自动（AI 起草、人实质评审）· 🔴 AI 只读 / 不可生成

---

## 8 · Spec 自动装配方案（<Platform> 落地路径 · 待实施）

> 用途：项目实施时，把 <Platform> 已有资产（tech-docs / tech-standards / contracts / ADR）**自动注入** spec 生成过程，让人或 AI agent 接手时拿到的是预填上下文的 `specs/NNN-feature/`，而非空模板。
> 状态：**方案备查**，未实施。

### 8.1 三档可选方案

| 档 | 做法 | 投入 | 自动化度 |
|---|---|---|---|
| **L1 · 提示词驱动** | `/speckit.specify` 前用 prompt 告诉 AI 去读 `tech-docs/services/<svc>/` + `tech-standards/STD-*/` | 0 | AI 每次自己读 |
| **L2 · 自定义 prompt + 装配脚本**（推荐）| 写 `.github/prompts/quantix-specify.prompt.md` 固化装配规则 + `scripts/gen_task_spec.py` 做硬性数据拉取 | 1–2 天 | 半自动（人触发 slash 命令）|
| **L3 · MCP server** | 把"读 BC / 读 STD / 读契约 / 读 ADR"做成 MCP tool，AI 自动调用 | 1 周 | 全自动 |

**推荐 L2** —— 脚本做确定性装配（路径解析 / 文件复制 / frontmatter 注入），AI 做判断性生成（哪段相关 / 怎么裁剪）。

### 8.2 信息源映射（<Platform> 资产 → spec 文件）

```
任务输入（来自 T3 任务卡）
├─ 任务标题 + 所属 BC + 影响服务列表
└─ Issue id（来自 T3 拆分）
                                  ↓
                        scripts/gen_task_spec.py
                                  ↓
tech-docs/
├── 01_业务上下文与限界上下文.md       → spec.md 的"BC 定位"段
├── services/<svc>/
│   ├── detail.md §interfaces        → plan.md 的"服务现状 + 接口"
│   ├── detail.md §domain            → data-model.md 种子
│   └── contracts/*.yaml             → contracts/ 的"已有接口"基线
├── 08_技术选型与ADR索引.md            → research.md 的"技术栈"
└── adr/ADR-*.md（按 BC 过滤）         → research.md 的"已决决策"

tech-standards/
├── STD-02-api/（摘要节）              → contracts/ lint 规则
├── STD-03-data/（摘要节）             → data-model.md 命名规则
├── STD-04-events/（摘要节）           → events.yaml 规范
└── STD-05-security/（摘要节）         → spec.md 安全要求

memory/constitution.md（仓库根 · 单例） → 永远在 context
                                  ↓
                  specs/NNN-<slug>/ 预填 5 件套
                                  ↓
              人开发者 / AI Agent 接手实施
```

### 8.3 落地步骤

**Step A · 自定义 slash 命令**（30 行）

```yaml
# .github/prompts/quantix-specify.prompt.md
---
description: 从 <Platform> 任务包生成 specs/NNN/ 并预填充上下文
mode: agent
---
输入：任务标题 + 所属 BC + 影响服务列表
步骤：
1. 读 tech-docs/01_业务上下文.md 抽该 BC 段 → spec.md
2. 读 tech-docs/services/<svc>/detail.md 抽 §interfaces / §domain → plan.md / data-model.md
3. 读 tech-docs/services/<svc>/contracts/* 列已有接口 → 避免重复
4. 读 tech-standards/STD-02/03/04/05 摘要节 → plan.md constraints
5. 读 tech-docs/adr/ 匹配相关 ADR → research.md
6. 落盘 specs/NNN-<slug>/ 按 spec-kit 标准结构
```

**Step B · 装配脚本**（150 行内）

```bash
scripts/gen_task_spec.py \
  --task-id 042 \
  --slug wallet-withdraw-v2 \
  --bc wallet \
  --services wallet,risk,notify
# → specs/042-wallet-withdraw-v2/ 含预填 5 件套（spec/plan/data-model/contracts/quickstart）
# → tasks.md 由后续 /speckit.tasks 生成
# → Issue 由 /speckit.taskstoissues 镜像
```

**Step C · 人或 AI 接手**

```
人开发者：    git checkout -b feat/042 → 看 specs/042/ 直接干活
Copilot Agent: cd specs/042/ → /speckit.implement
Claude Code:  cd specs/042/ → 4-Phase
```

两者拿到的 context 完全一致。

### 8.4 关键设计原则

1. **脚本只装配，不生成**：拉数据靠 path 约定，写 spec 靠 AI
2. **路径约定稳定**：`tech-docs/services/<svc>/{detail.md, contracts/}` 这种格式不变，脚本逻辑就不变
3. **STD 只注摘要节**（前 50 行 + 红线清单），不灌全文，防 context 爆
4. **生成的 spec.md 仍要人 review**：AI 装配 ≠ AI 决策
5. **不放 T4 各步**：spec 是 feature 级，T2 一次产出；T4.1 是单 task 消费 spec，不是生产 spec

### 8.5 时序在 SOP 中的位置

| SOP 步 | Spec-Kit 工件 | 谁产出 | Gate |
|---|---|---|---|
| **T2 详设+契约** | spec.md / plan.md / research.md / data-model.md / contracts/ / quickstart.md **整套一次性出**（由 8.3 自动装配 + 人审）| AI 装配 + Tech Lead | 架构师 Approve（SOP §3.5 已有 Gate）|
| **T3 任务包拆分** | tasks.md + `/speckit.taskstoissues` 镜像 Issue | AI 拆 + Tech Lead | Tech Lead |
| **T4.1 写方案** | tasks.md 中**单条任务**的实施细节展开（消费 spec，不修 spec）| 实施者（人或 AI）| 同行轻评 |
| **T4.2 编码** | 按 spec 实施，跑 quickstart 自验 | 实施者 | CI |

### 8.6 反向回流（罕见）

T4.1 / T4.2 若发现 spec 缺字段 / 契约不可行：
- **回流 T2** 修 `plan.md` / `contracts/` / `data-model.md`
- 重新过 T2 Gate
- 不允许在 T4 内私改 spec（破坏 spec 单一事实源）

### 8.7 实施时的 Checklist（实施前查阅）

- [ ] `tech-docs/services/<svc>/` 目录结构稳定 · 章节命名一致（§interfaces / §domain）
- [ ] `tech-standards/STD-*/` 每个标准文件有可机读的"摘要节"或 frontmatter 摘要字段
- [ ] `tech-docs/adr/` ADR 文件名带 BC 标签（便于按 BC 过滤）
- [ ] 仓库根 `memory/constitution.md` 已写好（≤9 条）
- [ ] `specs/` 已在 `.gitignore` 之外（必入 git）
- [ ] Issue 模板含 `BC / services / task-id` 三字段（喂给装配脚本）


