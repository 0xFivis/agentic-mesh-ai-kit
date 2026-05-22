<!--
来源：ai-workflow/templates/checklists/04-t7-retro-9-points.md
权威：ai-workflow/ai-agent-playbook.md
触发：T7 复盘 · feature 关闭前
-->

# T7 · 复盘 9 项 Audit Checklist

> 由 `retro-audit` skill 跑出草稿后，retro 会议上逐条过堂。

## A. 流程类（3 条）

| # | 项 | 判定 | 证据链接 | Action |
|---|---|---|---|---|
| 1 | Gate 完整性：T0 / G1 / G2 / G3 / G4 / T7 每道都有 Approve 留痕？ |  |  |  |
| 2 | DoR 守门：T4.2 启动前 Context Bundle ⑨ 件齐全？ |  |  |  |
| 3 | AI 草稿留痕：所有 AI 起草工件带候选 / 选定 / 排除三段？ |  |  |  |

## B. 质量类（3 条）

| # | 项 | 判定 | 证据 | Action |
|---|---|---|---|---|
| 4 | 契约一致性：main 上代码与 `contracts/*.yaml` 一致？ |  |  |  |
| 5 | 测试覆盖：4 象限实际 vs 计划 · mutation kill rate ≥ 70%？ |  |  |  |
| 6 | 红线触碰：涉及的 data-redline 项全部脱敏 / 加密？ |  |  |  |

## C. 协作类（3 条）

| # | 项 | 判定 | 证据 | Action |
|---|---|---|---|---|
| 7 | 跨 BC 偷渡：PR 仅触及声明的 BC？ |  |  |  |
| 8 | Reviewer 隔离：T4.3 用 reviewer subagent 独立 context 跑？ |  |  |  |
| 9 | Skill / Subagent 命中率：实际用了哪些？哪些该用未用？ |  |  |  |

## Action Items

- [ ] <action> · owner: <人> · due: <date> · issue: #<N>
- [ ] ...

## 指标快照

- 交付周期：T0 → T6 用时 **<X>** 天
- Gate 等待：T4.3 Review 平均 **<Y>** h
- 测试覆盖：**<%>**
- 事故 / 回滚数：<n>

## Memory 沉淀

- [ ] retro-audit skill 已写 `.claude/memory/lessons/<YYYY-MM>-<feature-id>.md`
- [ ] **不沉淀本次具体业务规则**（避免污染未来 feature）
- commit hash：<sha>

## Feature 关闭判据

- 9 项全过 OR 有 Action Items 兜底 + 责任人
- Action Items 全部进 backlog
- Memory 沉淀 commit 完成
