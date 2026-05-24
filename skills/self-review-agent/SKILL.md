---
name: self-review-agent
description: AI 自检 skill。在 PR 提交前主动跑语义层审查，输出"一致性矩阵 + 物理状态 + 红线复核 + 轻量提示"的结构化报告。与 CI hooks（机械约束）互补：CI 阻断硬错，本 skill 抓决策锚回、影响面漏项、STD/ADR 一致性等语义问题。触发词：自检 / self-review / 复审 / 提交前审查。
disable-model-invocation: false
allowed-tools: ["Read", "Grep", "Glob", "Bash"]
argument-hint: "<scope-path: file|dir|PR-branch>"
arguments:
  - name: scope-path
    required: true
    description: "审查范围：单文件 / 目录 / 分支 diff"
context: fork
paths:
  - "specs/**"
  - "docs/**"
  - "contracts/**"
  - "tech-standards/**"
  - "apps/**"
---

# Self-Review Agent Skill

> **何时调用**：人工 / AI 完成一段工作（spec、plan、impact-analysis、服务文档、ADR、STD、代码）后，提交 PR **之前**主动跑一次。
> **与 CI hooks 边界**：CI 8 hooks（见 `docs/architecture/00_governance.md §7`）拦机械错（schema drift / role badge 缺失 / spec lint）；本 skill 抓语义错（决策未锚回 D-编号 / 影响面漏项 / STD-ADR-架构三方一致性）。
> **与 gate-checklist 边界**：`gate-checklist` 是固定 5 条门，本 skill 是开放式深审；推荐先跑 gate-checklist 再跑 self-review。

## 输入

1. `<scope-path>`：被审范围
2. 隐式上下文：
   - `docs/architecture/00_governance.md`（SSOT 三层 + ROLE 红线 + 矩阵）
   - `tech-standards/STD-NN-*.md`（9 个 STD）
   - `docs/adr/`（既有决策）
   - `agentic-mesh-ai-kit/playbook.md`（流程权威）

## 步骤

1. **读 scope**：扫被审文件 / 目录，识别类型（spec / plan / impact-analysis / 服务文档 / ADR / STD / 代码）
2. **决策锚回扫描**：grep `D\d+` / `W\d+` / `ADR-\d{4}` / `STD-\d{2}` 引用；列每条决策是否有出处
3. **一致性矩阵**：对受影响的 SSOT（contracts / STD / ADR / 服务文档 / migrations）做交叉对照，找漂移
4. **ROLE 红线**：检查 .md 第 1-2 行是否带 `<!-- ROLE: SSOT|VIEW|SPEC|AUTO ... -->`；VIEW 文件是否复制了 schema（违反 §1 红线 1）
5. **影响面漏项**：对照 `impact-analysis.md` 8 类（contracts/STD/ADR/服务/迁移/事件/SLO/风险），找未声明但代码触及的项
6. **轻量提示**：识别非阻塞但应记账的潜在债（命名不规范 / 注释 TODO / 测试覆盖薄弱）

## 输出格式

参照本仓库 Phase B/C 复审报告模式，5 段结构：

```markdown
# Self-Review · <scope> · <YYYY-MM-DD>

## 一致性矩阵（N 处 SSOT 必须一致）
| 项 | 源 A | 源 B | 源 C | 一致 |
|---|---|---|---|---|
| ... | ... | ... | ... | ✅ / ❌ |

## 物理状态
- 文件存在性 / 行数 / 关键标志位 ✅

## 决策锚回
| 引用 | 出处 | 合规 |
|---|---|---|
| D17 | playbook §1.6 | ✅ |
| 未锚 | — | ❌ → 补 |

## 红线复核
- §1 红线 1（VIEW 不复制 schema）：✅ / ❌
- §1 红线 2（SSOT 全局唯一）：✅ / ❌
- §1 红线 3（AUTO 文件禁手改）：✅ / ❌

## 轻量提示（不阻塞，记账）
1. ...
2. ...

## 结论
- 阻塞项：N 条 → 必须修
- 记账项：M 条 → 可入下次迭代
- Verdict: PASS / BLOCKED
```

## Gate（结论判定）

- **BLOCKED**：任何一致性矩阵 ❌ / 任何红线 ❌ / 决策锚回缺失 ≥1
- **PASS-with-notes**：仅轻量提示 ≥1，无阻塞
- **PASS**：全 ✅

## 与其他 skill 协同

- 前置：`gate-checklist`（plan / review 模式）— 固定 5 条门
- 后置：人工 approver review（PM-Tech / Tech Lead）
- 并行：`data-redline`（若触及数据面）/ `bc-impact-map`（若 impact-analysis 不完整）

## Worked Example

**Input**
```
/self-review-agent docs/services/svc-12-order-api/
```

**Output**（节选）
```markdown
# Self-Review · svc-12-order-api · 2026-05-24

## 一致性矩阵（3 处 SSOT）
| 项 | api.md | contracts/order/openapi/svc-12/ | _registry.yaml | 一致 |
|---|---|---|---|---|
| POST /orders 端点 | 已记 | 已记 | type=api | ✅ |
| 错误码 4001 | 已记 | ❌ 缺 | — | ❌ |

## 红线复核
- §1 红线 1：api.md 是 VIEW，未发现 schema 复制 ✅
- §1 红线 3：_data-index.md 顶部带 AUTO 标记 ✅

## 结论
- 阻塞：1（错误码 4001 在 api.md 出现但 contracts 缺定义 → 补 contracts 再合）
- Verdict: BLOCKED
```
