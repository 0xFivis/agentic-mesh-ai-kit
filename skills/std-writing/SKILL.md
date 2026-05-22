---
name: std-writing
description: R 横切 · STD-NN 标准草稿 skill。基于 ADR-accepted 的横切决策，填充 STD-NN 模板，覆盖范围 / 规则 / 反例 / 例外申请流程。决策由人 Approve，AI 只产草稿。
disable-model-invocation: false
allowed-tools: ["Read", "Write"]
argument-hint: "<std-id> <title>"
arguments:
  - name: std-id
    required: true
    description: "STD 编号，例 STD-02-api"
  - name: title
    required: true
context: fork
paths:
  - "tech-standards/STD-**"
---

# STD Writing Skill

> **何时调用**：R 横切 · 任何 ADR-accepted 涉及横切规则（API / 数据 / 事件 / 安全 / 可观测 / 测试 / 部署 / 编码）时。
> **权威**：playbook + tech-standards 仓 README。

## STD 5 段结构（硬模板）
1. **范围（Scope）**：本 STD 适用哪些场景 / 不适用哪些（边界明确）
2. **规则（Rules）**：编号列出强制条款（MUST / MUST NOT / SHOULD / MAY，按 RFC 2119）
3. **示例 / 反例**：每条强规则配 ✅ 正例 + ❌ 反例代码片段
4. **例外申请**：何种情况可申请例外 + 申请流程 + 审批人
5. **关联**：上游 ADR-ID / 下游影响的 spec / 历史变更

## 硬约束

- **必须配套 ADR**：没有 ADR-accepted 不允许新建 STD（防止规则空降）
- **MUST 条款必有反例**：只列正例不算合格
- **状态机**：`draft → review → published → superseded`

## 输出
`tech-standards/STD-<NN>-<topic>/<sub-rule>.md` 或仓库本地 `docs/standards/`。

## 现有 STD 编号空间
参 `tech-standards/README.md`：

- STD-01 编码（coding）
- STD-02 API
- STD-03 数据
- STD-04 事件
- STD-05 安全
- STD-06 可观测
- STD-07 测试
- STD-08 部署
新增需先在 tech-standards 顶层 README 占号，避免冲突。

## Gate（进 published）

- ADR 关联齐全 + 反例齐全 + 例外流程明确 → Arch Lead + Domain Lead 双 Approve

## Worked Example

**Input**
```
/std-writing STD-02-api "REST 命名与版本化"
upstream ADR: ADR-007 (accepted)
```

**Output** (`docs/standards/STD-02-api/naming.md` 片段)
```markdown
# STD-02 · REST 命名与版本化
## 1. Scope
所有对外 HTTP/JSON API。内部 RPC 见 STD-04。
## 2. Rules
- **MUST** 资源用复数 (`/orders` not `/order`)
- **MUST NOT** 在 path 暴露内部 ID 类型 (`/u/{uuid}` ❌)
## 3. Examples
✅ `GET /orders/{id}`
❌ `GET /getOrderById?id=...`
## 4. Exception
填申请单 → Arch Lead Approve。
## 5. Related
Upstream: ADR-007 · Downstream: 所有 svc spec.md
```
