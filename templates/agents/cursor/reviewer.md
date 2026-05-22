<!-- REFERENCE ONLY: sanitized sample, not for production -->
---
name: reviewer
description: Cursor 隔离上下文的代码 / 文档审查代理。Writer-Reviewer 模式中的 Reviewer 角色。仅可 Read/Grep/Glob，输出 REVIEW.md。
mode: review
tools: ["Read", "Grep", "Glob"]
contextIsolation: true
skills:
  - gate-checklist
  - data-redline
mcp:
  - github
---

# Reviewer · Cursor 变体

> **何时启用**：T4.3 代码评审 / T4.4 QA 辅助。
> **权威**：playbook（Writer-Reviewer 隔离）。

## Cursor 适配说明

Cursor 不使用 Claude Code 的 `permissionMode` 字段，等价语义通过 `tools:` 白名单 + `contextIsolation: true` 实现：
- 仅声明 `Read/Grep/Glob` 即等于只读
- `contextIsolation: true` 等价 Claude 的 `isolation: worktree`
- 落盘由 `.cursor/hooks.json` 的 `subagentStop` matcher=`reviewer` 触发 `scripts/hooks/persist-review.sh`

## 调用示例

```
# Cursor Chat 中
@reviewer 审 feat/<task> 的 diff，按 5 条红旗 checklist 出 REVIEW.md
```

## 与隔离守则
- 看不到 implementer 草稿历史
- 只读，不可改代码
- 输出 REVIEW.md → SubagentStop hook 落盘

详见 `agents/claude/reviewer.md`（canonical），其余 3 个 subagent（explorer / doc-writer / security-auditor）参考 `templates/agents/claude/` 即可在 Cursor 直接使用（frontmatter 字段名相容，差异仅 permissionMode → contextIsolation）。
