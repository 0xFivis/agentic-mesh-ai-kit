---
name: retro-audit
description: T7 复盘 skill。跑 9 项 audit checklist（流程 / 质量 / 协作三大类），输出复盘草稿 + Action Items 候选 + 自动 memory 沉淀。
disable-model-invocation: false
allowed-tools: ["Read", "Grep", "Write", "Edit"]
argument-hint: "<feature-id>"
arguments:
  - name: feature-id
    required: true
context: fork
paths:
  - "specs/<feature-id>/retro.md"
  - ".claude/memory/**"
---

# Retro Audit Skill

> **何时调用**：T7 复盘 · 部署后观测窗结束。
> **权威**：playbook（9 项 audit checklist + auto memory 沉淀）。

## 9 项 Audit Checklist

### A. 流程类（3 条）
1. **Gate 完整性**：T0 / G1 / G2 / G3 / G4 / T7 是否每道都有 Approve 留痕？缺哪道？
2. **DoR 守门**：T4.2 启动前 Context Bundle ⑨ 件齐全否（spec / plan / data-model / contracts / quickstart）？
3. **AI 草稿留痕**：所有 AI 起草工件是否带候选 / 选定 / 排除三段？

### B. 质量类（3 条）
4. **契约一致性**：合并到 main 的代码是否仍与 `contracts/*.yaml` 一致？（grep diff）
5. **测试覆盖**：4 象限矩阵实际 vs 计划，缺哪个？mutation kill rate ≥ 70%？
6. **红线触碰**：feature 涉及的 data-redline 项是否全部脱敏 / 加密？

### C. 协作类（3 条）
7. **跨 BC 偷渡**：PR 是否仅触及声明的 BC？任何越界？
8. **Reviewer 隔离**：T4.3 是否用 reviewer subagent 在独立 context 跑？
9. **Subagent / Skill 命中率**：本 feature 实际使用了哪些 skill / subagent？哪些该用未用？

### D. Kit 卫生类（3 条 · D26/D27/D28）
10. **抄袭检测 (D26)**：本 feature 引入的 skill/STD/template 是否包含从其他项目原样复制且未删除业务专有名词的痕迹？（grep 项目特定术语清单 = 0 命中）
11. **SANITIZED 头校验 (D27)**：所有从外部样例改写的 `_example/` 与 `templates/*.tmpl` 是否首行带 `<!-- REFERENCE ONLY: sanitized sample, not for production -->`？
12. **Bounded-Context 三规 (D28)**：本 feature 涉及的 contracts 是否满足 (a) bctx 作为 `contracts/<bctx>/` 一级目录 · (b) 跨 bctx 调用必经 ACL · (c) 跨 bctx 共享类型仅落 `contracts/_common/` 且在白名单内（envelope / error / pagination / timestamp / money）？

## 输出 1：`specs/<feature-id>/retro.md`

```markdown
# Retro · <feature-id>

## 9 项 Audit

| # | 项 | 判定 | 证据链接 | Action |
|---|---|---|---|---|
| 1 | Gate 完整性 | ✅/❌ | <link> | - |
| ... |

## Action Items 候选

- [ ] <action> · owner: <人> · due: <date>
- ...

## 指标快照

- 交付周期：T0 → T6 用时 <X> 天
- Gate 等待时长：T4.3 Review 平均 <Y> h
- 测试覆盖：<%>
- 事故数 / 回滚数：...
```

## 输出 2：Auto Memory 沉淀
将本次复盘的**可复用经验**写入 `.claude/memory/lessons/<YYYY-MM>-<feature-id>.md`：

- 失败模式（"上次 X 类 feature 在 Y 步翻车，原因是 Z"）
- 提速诀窍（"X 步在 Y 场景下可省 Z"）
- **不沉淀本次的具体业务规则**（避免污染未来 feature 决策）

## Gate（关闭 feature）

- 9 项 audit 全过 OR 有 Action Items 兜底 + 责任人
- Action Items 进入 backlog（链 issue #）
- memory 沉淀 commit hash 记录在本 retro

## Worked Example

**Input**
```
/retro-audit 042-<feature>
```

**Output** (`specs/042-<feature>/retro.md` 片段)
```markdown
## 12 项 Audit
| # | 项 | 判定 | Action |
|---|----|------|--------|
| 1 | Gate 完整性 | ✅ | - |
| 10 | 抄袭检测 D26 | ❌ | skills/foo/SKILL.md L20 含项目专名 → 替换为 placeholder |
| 11 | SANITIZED 头 D27 | ✅ | - |
| 12 | bctx 三规 D28 | ⚠️ | contracts/_common/billing.yaml 不在白名单 → 移入 contracts/<bctx>/ |
```
