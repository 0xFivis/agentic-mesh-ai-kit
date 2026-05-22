---
name: gate-checklist
description: T4.1 Plan 自评 + T4.3 Code Review 红旗 checklist 双用 skill。单 skill 两处复用。输出结构化打勾记录给审批人。
disable-model-invocation: false
allowed-tools: ["Read", "Grep", "Write"]
argument-hint: "<mode: plan|review> <target-path>"
arguments:
  - name: mode
    required: true
    description: "plan = T4.1 方案自评；review = T4.3 代码评审"
  - name: target-path
    required: true
    description: "plan 模式 = 方案 md 路径；review 模式 = PR diff 或 branch"
context: fork
paths:
  - "specs/**"
  - "docs/reviews/**"
---

# Gate Checklist Skill

> **何时调用**：T4.1 写方案完成时（plan 模式）/ T4.3 代码评审时（review 模式）。
> **权威**：playbook。

## Mode: `plan`（T4.1 方案自评 · 5 条）

| # | 条目 | 判据 |
|---|---|---|
| 1 | 消费 spec / plan / contracts 完整 | 方案显式引用 `spec.md` + `plan.md` + 具体 contract 锚点（无 → ❌）|
| 2 | 不修 feature 级 spec | 方案只在 issue body / tasks.md 行展开（修了 → ❌ · 回流 T2）|
| 3 | DoD ≤ 3 条 + 可机检 | DoD 含 quickstart 场景或 CI 命令（不可机检 → ❌）|
| 4 | 风险 ≥ 1 个 + 降级 | 至少 1 风险条目带 fallback（无 → ❌）|
| 5 | 留痕：候选 / 选定 / 排除 | 涉及候选选择时三段齐全（候选 / 选定 / 排除理由 · 缺 → ❌）|

## Mode: `review`（T4.3 代码评审 · 5 条红旗）

| # | 红旗 | 判据 |
|---|---|---|
| 1 | 契约漂移 | 代码与 `contracts/*.yaml` 不一致（schema 字段 / 错误码 / 状态码）|
| 2 | 数据红线触碰 | 触 `data-redline` skill 8 红线之一未脱敏 |
| 3 | 测试缺失 | 新逻辑无对应测试 / quickstart 场景未跑通 |
| 4 | 留痕缺失 | commit message 无 `Closes #N` / 无关联契约版本号 |
| 5 | 跨 BC 偷渡 | PR 触及非声明 BC（违反 task-decomp-fanout 颗粒红线）|

## 输出
```
docs/reviews/<feature-id>/
└── <YYYY-MM-DD>-<mode>-<target>.md
```
格式：每条 ✅/❌ + 异常项备注 + 修复建议。

## 与 reviewer subagent 的关系
T4.3 强烈推荐用 `reviewer` subagent 在隔离 context 跑本 skill（Writer-Reviewer 隔离），避免审批人看到 implementer 草稿历史被带偏见。

## Worked Example

**Input**
```
/gate-checklist plan specs/042-<feature>/plan.md
```

**Output** (`docs/reviews/042-<feature>/2026-01-15-plan-plan.md`)
```markdown
# Plan Gate · 042-<feature> · 2026-01-15
| # | 条目 | 结果 | 备注 |
|---|------|------|------|
| 1 | 引用 spec/plan/contracts | ✅ | spec.md#L1, contracts/<bctx>.yaml#L40 |
| 2 | 不修 feature spec | ✅ | diff 无 spec.md 改动 |
| 3 | DoD ≤ 3 + 可机检 | ❌ | DoD 第 4 条无 CI 命令 → 补 quickstart 场景 |
| 4 | 风险 ≥ 1 + 降级 | ✅ | 见 plan §6 |
| 5 | 候选/选定/排除 | ✅ | 见 plan §3 |
Verdict: BLOCKED · fix item 3 then re-run.
```
