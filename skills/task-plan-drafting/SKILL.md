---
name: task-plan-drafting
description: T4.1 阶段单 task 实施方案起草 skill。读 Approved 的 spec / plan / impact-analysis / contracts，按固定 5 段（方案 / 步骤 / 自测 / 风险 / 候选选定排除）起草 task 级 plan section，写入 issue body（不修 feature 级 spec.md）。起草后必须由 `gate-checklist plan` 跑 5 条 checklist 才进 T4.2。触发词：写 T4.1 方案 / task plan / 起草实施方案 / draft task plan。
disable-model-invocation: false
allowed-tools: ["Read", "Grep", "Glob", "Write"]
argument-hint: "<feature-id> <task-id>"
arguments:
  - name: feature-id
    required: true
    description: "feature 编号（如 042）"
  - name: task-id
    required: true
    description: "task 编号（如 T-042-03）"
context: fork
paths:
  - "specs/<feature-id>/**"
  - "docs/reviews/<feature-id>/**"
---

# Task Plan Drafting Skill

> **何时调用**：T3 拆完 tasks.md / 派生 Issue 后，单 task 进入 T4.1 起草阶段。
> **权威**：playbook §T4.1（SOP 表）+ `gate-checklist` plan 模式 5 条门。
> **硬约束**：本 skill **只写 task 内 plan section**（落 issue body 或 task 单独的 plan 段），**禁修 feature 级 `spec.md`**（违反则回流 T2）。

## 输入

1. `specs/<feature-id>/spec.md`（Approved · Bundle ③）
2. `specs/<feature-id>/plan.md`（Approved · Bundle ⑤）
3. `specs/<feature-id>/impact-analysis.md`（Bundle ④）
4. `specs/<feature-id>/contracts/*`（Bundle ⑧）
5. `specs/<feature-id>/tasks.md` 中 `<task-id>` 那一行（含 verification 字段）

## 步骤

1. **读 Bundle**：把上述 5 源全部读入 context（顺序即权重）
2. **抽该 task 的范围**：从 tasks.md 行中识别 task 触及的服务 / 契约 / 数据
3. **校验 DoR**：5 件套齐全 + impact-analysis 已 sign-off；缺则停，提示先回 T1/T2
4. **起草 5 段**：按下方"输出格式"逐段填，禁省略
5. **挂自检**：在 plan section 末尾追加 `gate-checklist plan <output-path>` 调用提示

## 输出格式（强制 5 段）

落点：issue body（GitHub Issue）或 `specs/<feature-id>/tasks/<task-id>-plan.md`

```markdown
# T4.1 Plan · <task-id>

> Feature: <feature-id> · Task: <task-id>
> 起草：<AI tool> + task-plan-drafting skill
> Bundle 引用：spec.md#L<line> · plan.md#L<line> · impact-analysis.md#L<line> · contracts/<file>#L<line>

## 1. 方案（HOW · 高层 → 落地）

- 技术路径：<引 plan.md 选定方案 + 本 task 的具体化>
- 复用的既有组件 / 服务：<列表 + 路径>
- 新增 / 改造的模块：<文件路径 + 简述>

## 2. 实施步骤（≤7 步 · 可独立 commit）

| # | 步骤 | 涉及文件 | 预计 LOC |
|---|---|---|---|
| 1 | ... | apps/<svc>/... | <n> |
| 2 | ... | ... | ... |

## 3. 自测策略（DoD ≤3 条 · 全部可机检）

- [ ] DoD-1：<quickstart 场景 N · CI 命令 `pnpm test ...`>
- [ ] DoD-2：<契约 lint · CI 命令 `spectral lint contracts/...`>
- [ ] DoD-3：<集成测试 · CI 命令 `make e2e-...`>

> 与 `tasks.md` 该行 `verification:` 字段必须一致。

## 4. 风险（≥1 + fallback）

| 风险 | 等级 | 触发条件 | 降级 | 责任人 |
|---|---|---|---|---|
| <描述> | low/medium/high | <场景> | <fallback> | <name> |

## 5. 候选 / 选定 / 排除（仅当涉及选型时必填）

- 候选 A：<方案> · 优点 / 缺点
- 候选 B：<方案> · 优点 / 缺点
- **选定**：候选 <X> · 理由：<...>
- **排除**：候选 <Y> · 理由：<...>
- 若决策升级到架构层 → 标 `adrs: [ADR-NNNN-draft]` 触发 R 横切

---

## 自检入口

```bash
gate-checklist plan specs/<feature-id>/tasks/<task-id>-plan.md
```

5 条全 ✅ → 提请 TL approve 进 T4.2；任一 ❌ → 改方案或回 T2/T3。
```

## Gate（skill 自身 DoD）

- 5 段全填（涉选型才必填第 5 段，但需显式写「本 task 无选型」）
- 所有引用带 `file#Lnnn` 锚点
- DoD ≤3 条 + 全部可机检（无 `verification:` 命令则 fail）
- 不修 feature 级 `spec.md`（grep diff 校验）

## 与其他 skill 协同

- 前置：`task-decomp-fanout`（T3 拆出 tasks.md）/ `bc-impact-map`（T1）/ `/speckit.plan`（T2）
- 后置：`gate-checklist plan`（强制 5 条门）→ TL approve → `contract-first`（若涉契约）→ 编码进 T4.2
- 互斥：本 skill 单次只起草一个 task 的 plan；批量请并行调多个实例

## 红线

- ❌ 修 `spec.md` / `plan.md` / `data-model.md` / `contracts/*` —— 这些是 feature 级 SSOT，T4.1 只读不写
- ❌ 写 HOW 之外的 WHAT/WHY —— 业务规则已在 spec.md 锁定
- ❌ DoD 含 "目视确认 / 人工 review"（不可机检）

## Worked Example

**Input**
```
/task-plan-drafting 042 T-042-03
```

**Output**（`specs/042-order-cancel/tasks/T-042-03-plan.md`）
```markdown
# T4.1 Plan · T-042-03

> Feature: 042-order-cancel · Task: T-042-03（订单取消的补偿事件发布）
> Bundle 引用：spec.md#L18 · plan.md#L42 · impact-analysis.md#L67 · contracts/order/asyncapi/order-cancelled-v1.yaml#L1

## 1. 方案
- 复用 outbox pattern（plan.md 选定方案 B）
- 改造：apps/svc-12-order-api/internal/event/publisher.go 加 cancel 主题

## 2. 实施步骤
| # | 步骤 | 文件 | LOC |
|---|---|---|---|
| 1 | 加 OrderCancelled event struct | apps/svc-12-order-api/internal/event/types.go | 20 |
| 2 | publisher 注册 cancel topic | .../publisher.go | 15 |
| 3 | 单测 | .../publisher_test.go | 50 |

## 3. 自测
- [ ] DoD-1: `make test PKG=event/` 绿
- [ ] DoD-2: `spectral lint contracts/order/asyncapi/order-cancelled-v1.yaml`
- [ ] DoD-3: `make e2e-order-cancel` 绿

## 4. 风险
| 风险 | 等级 | fallback |
|---|---|---|
| outbox 投递延迟 > SLO | medium | 加 retry + dead-letter |

## 5. 候选 / 选定 / 排除
本 task 无新选型（已由 plan.md 锁定 outbox）。

gate-checklist plan specs/042-order-cancel/tasks/T-042-03-plan.md
```
