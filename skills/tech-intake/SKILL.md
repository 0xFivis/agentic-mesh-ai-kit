---
name: tech-intake
description: T0 阶段的需求 / 技术访谈 skill。用 AskUserQuestion 式多轮提问，对照 8 项自检逐项过堂，输出 SPEC.md 草稿与原始问答留痕。仅在 T0 Intake 阶段或新需求评审时调用。
disable-model-invocation: false
allowed-tools: ["Read", "Write", "AskUserQuestion"]
argument-hint: "<feature-id> [--prd=path]"
arguments:
  - name: feature-id
    required: true
    description: "feature 短 ID，例 042-<feature-slug>-v2"
  - name: prd
    required: false
    description: "PRD 章节路径，例 docs/prd/<area>/<feature>.md#L120-L240"
context: fork
paths:
  - "specs/<feature-id>/**"
---

# Tech Intake Skill

> **何时调用**：T0 Intake · 新 feature 启动 · 仅在主代理 Plan Mode 下运行。
> **权威**：playbook) Step 1 spec.md prompt。

## 输入
1. PRD 节选（`--prd` 指向章节）
2. `memory/constitution.md`（项目硬约束）
3. 相邻已 Approve 的 ADR 列表

## 8 项自检（逐项过堂 · 不可跳）
1. **用户故事**：As who · I want · So that — 三段齐全
2. **业务规则**：枚举所有 WHAT/WHY，禁 HOW（库名 / 框架 / 数据结构 → 标 `[REJECT-HOW]`）
3. **验收标准**：≥ 3 条 Given-When-Then，可机检
4. **NFR**：性能 / 可用性 / 安全 / 合规 4 类有数值或 N/A 说明
5. **上下游**：依赖谁 / 谁依赖你 → BC 名清单
6. **数据**：涉及哪些实体 / 是否触红线（参 `data-redline` skill）
7. **风险**：列 ≥ 2 个风险点 + 缓解候选
8. **待澄清**：所有存疑写入 `## 5. 待澄清`，标 `[BLOCK-T1]` 阻塞下一步

## 输出
落到 `specs/<feature-id>/spec.md`，模板见 [`../../docs/SPEC.md.template`](../../docs/SPEC.md.template)。
同步落 `specs/<feature-id>/_intake-qa.md`（原始问答留痕）。

## Gate
8 项全过且 `[BLOCK-T1]` 为空 → PM-Tech Approve → 进 T1。
任意一项 ❌ → 回访谈，**不允许跳过**。

## Worked Example

**Input**
```
/tech-intake 042-<feature> --prd=docs/prd/<area>/<feature>.md#L120-L240
```

**Output** (`specs/042-<feature>/spec.md` 片段)
```markdown
# Spec · 042-<feature>
## 1. User Story
As <role>, I want <capability>, so that <value>.
## 2. Business Rules (WHAT only)
- R1: <rule>
## 3. Acceptance
- Given <ctx> When <action> Then <expect>
## 4. NFR
- p95 latency ≤ 200ms; availability 99.9%
## 5. 待澄清
- [BLOCK-T1] <question>  ← T1 启动前必须清空
```
