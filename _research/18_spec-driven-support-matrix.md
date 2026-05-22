<!-- REFERENCE ONLY: sanitized sample, not for production -->
# 18 · Spec-Driven Development（SDD）四家工具支持矩阵

> 调研时间：2026-05-20 · 60 天未复核即视为待校
> 目的：澄清 spec-kit（Specify CLI）在 Claude Code / Cursor / Codex / Copilot 四家的**实际安装方式、命令前缀、目录结构**，给 playbook §3.3 提供可操作依据。
> 配套：[§17 Plan 载体矩阵](17_plan-carrier-matrix.md)。
>
> **v1.1 校正**：
> - Codex 用 `$speckit-<cmd>` **不是 spec-kit 独有**，而是 Codex 全平台 skills 调用语法（`$<skill-name>`，2025-12 引入）。spec-kit 在 Codex 上以 skills 形式安装，所以沿用 `$` 前缀。
> - Codex 也有一个**实验性** `$create-plan` skill（不属于 spec-kit，是 OpenAI 自家的轻量 plan 工具），与 spec-kit `/speckit.plan` 不要混。

---

## 1. SDD 是什么（一句话校准）

**Spec-Driven Development = "intent is the source of truth"**：spec 不是文档，是可执行的产物，直接驱动 AI 生成 plan / tasks / code。

GitHub 博客原文："**It works in four phases with clear checkpoints**：Specify → Plan → Tasks → Implement"。每阶段一个 explicit checkpoint，**未验证不进下一阶段**。

| 阶段 | 命令 | 输出 | 用户的角色 |
|---|---|---|---|
| 1. Specify | `/speckit.specify` | `spec.md`（user journey · 体验 · what/why · **不含技术栈**）| 提供高层描述 |
| 2. Plan | `/speckit.plan` | `plan.md`（技术栈 · 架构 · 约束 · 合规要求）| 提供 stack / 架构方向 |
| 3. Tasks | `/speckit.tasks` | `tasks.md`（可独立实现+测试的小任务清单）| 审阅+裁剪 |
| 4. Implement | `/speckit.implement` | 代码 + tests | review focused changes，不再看千行 dump |

**辅助命令**（optional，按需用）：

| 命令 | 用途 | 建议时机 |
|---|---|---|
| `/speckit.constitution` | 项目级 governing principles | 项目初始化第一步 |
| `/speckit.clarify` | 揪出 spec 中的歧义（旧名 `/quizme`）| `/specify` 之后，`/plan` 之前 |
| `/speckit.analyze` | 跨工件一致性 + 覆盖度分析 | `/tasks` 之后，`/implement` 之前 |
| `/speckit.checklist` | 给 spec / plan 生成质量 checklist（"unit tests for English"）| 任意阶段 |
| `/speckit.taskstoissues` | 把 tasks 转成 GitHub Issues | tasks 评审过后 |

---

## 2. 四家 spec-kit 集成对照表

> 一手源：<https://github.github.io/spec-kit/reference/integrations.html>（spec-kit ≥ 0.8.5）

| 项 | Claude Code | Cursor | OpenAI Codex CLI | GitHub Copilot |
|---|---|---|---|---|
| **integration key** | `claude` | `cursor-agent` | `codex` | `copilot` |
| **安装命令** | `specify init my-proj --integration claude` | `specify init my-proj --integration cursor-agent` | `specify init my-proj --integration codex` | `specify init my-proj --integration copilot` |
| **命令调用语法** | `/speckit.<cmd>` slash | `/speckit.<cmd>` slash | **`$speckit-<cmd>`**（dollar 前缀 · hyphen 不是 dot）| `/speckit.<cmd>` slash |
| **示例** | `/speckit.specify` | `/speckit.specify` | `$speckit-specify` | `/speckit.specify` |
| **集成模式** | **Skills-based**（默认）| **Skills-based**（默认）| **Skills-only**（无 prompts 模式）| 普通 commands / prompts（默认）|
| **安装目录** | `.claude/skills/` | `.cursor/skills/` + `.cursor/rules/specify-rules.mdc` | `.agents/skills/` + `AGENTS.md` | `.github/prompts/`（或对应 Copilot 目录）|
| **multi-install safe** | ✅ | ✅ | ✅ | ❌（未在白名单） |
| **context file** | `CLAUDE.md` | `.cursor/rules/specify-rules.mdc` | `AGENTS.md` | `.github/copilot-instructions.md` |

### 关键差异

1. **Codex 用 `$speckit-<cmd>`**：因为 Codex CLI 的官方 spec-kit 集成**只支持 skills 模式**（无 prompts 模式可选），而 Codex skill 的原生触发符就是 `$<skill-name>`。其他三家走标准 `/speckit.*` slash。
2. **Claude / Cursor 默认 skills 模式**：spec-kit 不下发 prompt 文件，而是安装为 agent skills（可被 model 主动召回）。Copilot 默认走 prompts 文件。Codex 是 skills-only（强制）。
3. **Cursor 的 context file 是 `.mdc`**：rules 体系（不是 markdown），格式不同于其他三家的 markdown context。
4. **Copilot 不在 multi-install safe 名单**：与其他集成共存时需 `--force`，因为 Copilot 的 prompt 路径与 GitHub 仓库其他 agent 路径有冲突风险。

---

## 3. SDD 4-Phase（L1）vs Anthropic 4-Phase（L2）的边界

**这是 playbook §3.1 与 §3.3 衔接处的核心问题**。两个流程都叫 "4-phase"，但粒度完全不同：

| 维度 | L1 · Spec-Kit SDD | L2 · Anthropic 执行循环 |
|---|---|---|
| **阶段** | Specify → Plan → Tasks → Implement | Explore → Plan → Code → Commit |
| **粒度** | 项目级 / 大需求级（**周/月**）| 单任务级（**小时**）|
| **产物** | `spec.md` + `plan.md` + `tasks.md` + code | working code + commit |
| **回答的问题** | WHAT 要做 · WHY 要做 · HOW（架构层）· 拆成什么 task | HOW 写这个 task · 怎么验证 |
| **来源** | GitHub Spec-Kit（2025-09 开源）| Anthropic Claude Code Best Practices |
| **触发命令** | `/speckit.*` 或 `$speckit-*` | 各家 mode 切换（见 [§17](17_plan-mode-vs-execution-loop-matrix.md)）|

**正确嵌套方式**：

```
L1 spec-kit:  Specify → Plan → Tasks → Implement
                                        │
                                        └─ 对 tasks.md 的每一个 task：
                                           L2 Anthropic: Explore → Plan → Code → Commit
                                                         └─ Explore + Plan 用 L3 只读模式
                                                         └─ Code + Commit 用 L3 写模式
```

**playbook 不能再把这两个 4-phase 当成一个东西**。

---

## 4. Extensions & Presets · 二级定制机制

spec-kit 允许按"叠加优先级"自定义：

```
1 (最高) Project-Local Overrides  .specify/templates/overrides/
2        Presets                  .specify/presets/templates/
3        Extensions               .specify/extensions/templates/
4 (最低) Spec Kit Core            .specify/templates/
```

| 机制 | 定位 | 何时用 |
|---|---|---|
| **Extensions** | 加**新**命令 / 新模板 / 新阶段 | 引入 Jira 集成、合规审阅 gate、V-Model 测试追溯 |
| **Presets** | 改**已有**命令 / 模板的格式 / 措辞 | 监管 traceability spec 格式、领域术语、本地化语言 |
| **Project-Local Overrides** | 一次性微调 | 单项目特殊要求，不值得做 preset |

**对本仓库的指导**：<Platform> 的 `tech-standards/` 红线（命名/格式/合规）应该做成 **Preset**，而 `templates/skills/` 中的 `contract-first` / `data-redline` / `release-canary` 这些**新工序**应该做成 **Extension**。

---

## 5. 红线（playbook 必须遵守）

1. ❌ 不要写 `--ai <agent>`（旧 flag，已废弃）→ ✅ 用 `--integration <key>`
2. ❌ 不要假设 Codex 也是 `/speckit.*` → ✅ Codex 用 `$speckit-<cmd>`
3. ❌ 不要把 SDD 4-phase 和 Anthropic 4-phase 混为一谈 → ✅ 显式标 L1/L2 层
4. ❌ 不要在 `/specify` 里写技术栈 → ✅ 技术栈只能进 `/plan`
5. ❌ 不要跳过 `/speckit.clarify`（如有 `[NEEDS CLARIFICATION]` 残留）→ ✅ Specify→Plan 中间必跑
6. ⚠️ Copilot 与其他集成同 repo 共存需 `--force`（不在 multi-install safe 名单）

---

## 6. 与本仓库现有产物的映射

| 本仓库现状 | spec-kit 等价 | 建议做法 |
|---|---|---|
| `tech-docs/` 顶层 8 篇 | 项目级 spec + 大 plan | 不动；保留为人类阅读，spec-kit 引用 |
| `tech-standards/` STD-01 ~ STD-08 | **Preset**（合规 + 命名 + 红线）| 做一个 `<platform>-preset`，可 `specify preset add` |
| `templates/skills/contract-first` 等 11 个 | **Extension**（新工序）| 重构为 `<platform>-extension` |
| `tech-docs/adr/*.md` | ADR（属于 L1 plan 阶段的衍生物）| 关联 `/speckit.plan` 输出，做 cross-ref |

---

## 7. 引用源（按重要性）

1. <https://github.github.io/spec-kit/reference/integrations.html>（30+ agents 表 · Codex `$speckit-*` 特例 · multi-install safe 名单）
2. <https://github.com/github/spec-kit>（README 主流程 · 7 步上手 · `--integration` 替代 `--ai`）
3. <https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/>（4-phase with checkpoints 原话 · "intent is source of truth" 论述）
4. spec-kit `spec-driven.md` 长文档（深度方法论；本仓库未直接引用，需要时 fetch）
