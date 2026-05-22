---
name: contract-first
description: T2 阶段服务详设 skill。基于 spec.md + impact-map，按 playbook 5 步 prompt 链顺序生成规格五件套（spec → plan → data-model → contracts → quickstart）。前一步未 Approve 时拒绝继续。
disable-model-invocation: false
allowed-tools: ["Read", "Write", "Edit", "Bash"]
argument-hint: "<feature-id> [--step=1|2|3|4|5]"
arguments:
  - name: feature-id
    required: true
  - name: step
    required: false
    description: "指定从第几步开始（默认从未 Approve 的最早一步）"
context: fork
hooks:
  before: "scripts/check-spec-approved.sh"
paths:
  - "specs/<feature-id>/**"
---

# Contract First Skill

> **何时调用**：T2 详设 · spec.md 已 Approve 后启动。
> **权威**：playbook（spec 生成方法 · 5 步 prompt 链 + 五件套定义）。

## 五件套

| # | 件套 | 输入 | 核心约束 |
|---|---|---|---|
| 1 | `spec.md` | PRD + `memory/constitution.md` | 只写 WHAT/WHY，发现 HOW → `[REJECT-HOW]` |
| 2 | `plan.md` | Approved spec.md + 相邻 ADR | ≥ 2 HOW 候选 + 对比矩阵，新决策点标 `adrs: [TBD]` |
| 3 | `data-model.md` | spec + plan | 实体 / 字段约束 / 状态机，遵循 STD-03 |
| 4 | `contracts/*.yaml` | data-model + STD-02 | OpenAPI / AsyncAPI · schema lint 必须通过 |
| 5 | `quickstart.md` | 前 4 件套 | ≥ 3 条人类可读场景 + 可执行 CI 命令 |

## 硬约束

- **顺序固定**：1 → 2 → 3 → 4 → 5，前一步未 Approve **拒绝**继续
- **每步生成后 PM-Tech 必须 Approve** 才能进下一步
- 缺一不可入 T4.2（DoR · playbook）

## 输出落点
```
specs/<feature-id>/
├── spec.md             ← step 1（如已存在则跳过）
├── plan.md             ← step 2
├── data-model.md       ← step 3
├── contracts/*.yaml    ← step 4
└── quickstart.md       ← step 5
```

## 与 Context Bundle 对应

| 件套 | Bundle 顺位 |
|---|---|
| `spec.md` | ③ |
| `plan.md` | ④ |
| `data-model.md` | ⑥ |
| `contracts/*` | ⑦ |
| `quickstart.md` | ⑨ |

## Gate（进 T3）
五件套齐全 + 每件套有 PM-Tech Approve 留痕 + `contracts/` lint 全绿。

## Worked Example

**Input**
```
/contract-first 042-<feature> --step=4
prerequisites: specs/042-<feature>/{spec.md,plan.md,data-model.md} all Approved
```

**Output** (`specs/042-<feature>/contracts/<bctx>.openapi.yaml` 片段)
```yaml
openapi: 3.1.0
info: { title: <bctx>-api, version: 0.1.0 }
paths:
  /<entities>:
    get:
      operationId: list<Entities>
      responses: { "200": { $ref: "#/components/responses/PageOfEntity" } }
components:
  schemas:
    Entity: { type: object, required: [id], properties: { id: {type: string} } }
```
