---
name: bc-impact-map
description: T1 阶段限界上下文 / 服务影响地图 skill。对照基线架构图，输出本 feature 触达的 BC + 服务 + 契约 + 数据表清单，标注 delta 类型（新增 / 修改 / 废弃）。仅在 T1 影响分析阶段调用，推荐配合 explorer subagent fan-out 并行。
disable-model-invocation: false
allowed-tools: ["Read", "Grep", "Glob", "Write"]
argument-hint: "<feature-id>"
arguments:
  - name: feature-id
    required: true
context: fork
paths:
  - "specs/<feature-id>/impact-map.md"
---

# BC Impact Map Skill

> **何时调用**：T1 影响分析 · 须先有 Approved 的 `spec.md`（DoR）。
> **权威**：playbook。
> **前置**：架构基线 ready；涉及契约/标准变更时**并行启动 R 横切**。

## 输入
1. `specs/<feature-id>/spec.md`（Approved）
2. `tech-docs/01_业务上下文与限界上下文.md`（BC 基线）
3. `tech-docs/03_微服务拆分原则与服务清单.md`（服务基线）

## 步骤
1. **抽业务动作**：从 spec.md `## 业务规则` 抽出 N 个动作（动词起头）
2. **映射 BC**：每个动作落在哪个 BC（→ 给出基线引用行号）
3. **映射服务**：每个 BC 下涉及哪些服务（→ tech-docs 引用）
4. **映射契约**：每个服务的哪些 API / 事件需要 new/modify/deprecate
5. **映射数据**：涉及哪些表 / 字段，是否触红线
6. **风险标签**：每行打 `low / medium / high`（基于变更范围 + 数据敏感度）

## 输出格式
`specs/<feature-id>/impact-map.md`：

```markdown
| 业务动作 | BC | 服务 | 契约 delta | 数据 delta | 风险 |
|---|---|---|---|---|---|
| 调整业务规则 | <bounded-context> | <service-name> | PATCH /<entity>/:id/<attribute> (modify) | <entity>.<attribute> (modify) | high |
| ... | ... | ... | ... | ... | ... |
```
末尾附 **候选清单依据**：对每个 high 风险项给 ≥2 个候选方案，供 T2 详设 / ADR 决策。

## Gate（进 T2 · DoR）

- 所有动作均映射到 ≥1 个 BC
- 所有 high 风险项 ≥2 个候选
- 涉及 R 横切（新 STD / ADR）的项已建关联 issue

## Worked Example

> 占位示例 · 待 v0.2+ 填充真实业务场景。

**Input**：
```
specs/FEAT-042/spec.md            # Approved
tech-docs/01_业务上下文与限界上下文.md
tech-docs/03_微服务拆分原则与服务清单.md
```

**调用**：
```bash
claude skill bc-impact-map FEAT-042
```

**Output**：`specs/FEAT-042/impact-map.md`
```markdown
| 业务动作 | BC | 服务 | 契约 delta | 数据 delta | 风险 |
|---|---|---|---|---|---|
| 创建 <entity> | <bounded-context> | <service-name> | POST /<entity> (new) | <entity>.<attribute> (new) | medium |
| 调整 <attribute> | <bounded-context> | <service-name> | PATCH /<entity>/:id (modify) | <entity>.<attribute> (modify) | high |

## 候选清单依据
- 高风险项 1：方案 A（同步改契约）vs 方案 B（事件 outbox 异步），见 ADR-NNN 草稿
```
