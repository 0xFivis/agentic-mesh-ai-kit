---
name: adr-writing
description: R 横切 · ADR（架构决策记录）起草 skill。强制给出 ≥ 2 个候选方案 + 对比矩阵 + 选定理由 + 排除项原因。决策由人做，AI 只产草稿。
disable-model-invocation: false
allowed-tools: ["Read", "Write"]
argument-hint: "<adr-id> <title>"
arguments:
  - name: adr-id
    required: true
    description: "ADR 编号，例 ADR-042"
  - name: title
    required: true
context: fork
paths:
  - "docs/adr/**"
  - "tech-docs/adr/**"
---

# ADR Writing Skill

> **何时调用**：R 横切 · 任何 plan.md 标了 `adrs: [TBD]` 的决策点。
> **权威**：playbook) Step 2。

## 5 段结构（硬模板 · 见 `../../docs/ADR.md.template`）
1. **Context**：触发 ADR 的业务/技术背景（链到 spec.md）
2. **Candidates**（≥ 2 个）：每个候选给「概述 / 优点 / 缺点 / 成本」
3. **Decision Matrix**：横轴候选 / 纵轴评判维度（性能 / 维护 / 成本 / 风险 / 一致性 / ...），打分加权
4. **Decision**：选定方案 + 关键理由
5. **Excluded Reasons**：每个未选候选给排除理由（不可省 · playbook 留痕硬约束）

## 硬约束

- **拒绝单候选**：只给出 1 个方案 → 自动拒绝并要求补候选
- **禁 HOW 泄露到 spec.md**：ADR 是 HOW 决策的归宿，spec.md 只能引用 ADR-ID
- **状态机**：`draft → review → accepted / rejected / superseded`，转换需人工审批

## 输出落点
`tech-docs/adr/<adr-id>-<slug>.md` 或仓库本地 `docs/adr/<adr-id>-<slug>.md`。

## Gate

- 候选 ≥ 2 + 决策矩阵齐全 + 排除理由齐全 → Arch Lead Approve → `accepted`

## Worked Example

**Input**
```
/adr-writing ADR-042 "<decision-title>"
spec.md ref: specs/<feature-id>/spec.md#L40-L80
```

**Output** (`docs/adr/ADR-042-<slug>.md`)
```markdown
# ADR-042 · <decision-title>
Status: draft
## 1. Context
参 spec.md#L40-L80 …
## 2. Candidates
### A. <option-a>  优点/缺点/成本
### B. <option-b>  优点/缺点/成本
## 3. Decision Matrix
| 维度 | 权重 | A | B |
|------|------|---|---|
| 性能 | 0.3  | 4 | 3 |
| 维护 | 0.3  | 3 | 4 |
## 4. Decision
选 A，理由 …
## 5. Excluded Reasons
B 落选：<reason>
```
