<!-- REFERENCE ONLY: sanitized sample, not for production -->
---
name: reviewer
description: Codex 隔离审查 agent。Writer-Reviewer 模式 Reviewer 角色，read-only sandbox，输出 REVIEW.md。
model: gpt-5-codex
approval_policy: read-only
tools: ["read_file", "grep", "glob"]
sandbox:
  mode: workspace
  network: blocked
skills:
  - gate-checklist
  - data-redline
---

# Reviewer · Codex 变体

> Codex CLI 通过 profile + sandbox 实现隔离。本文件落 `.codex/agents/reviewer.md`，由 `~/.codex/config.toml` 的 `[agents] search_paths` 识别。

## 关键差异

| Claude | Codex |
|--------|-------|
| `permissionMode: read-only` | `approval_policy: read-only` + `sandbox.mode: workspace` |
| `isolation: worktree` | 通过 Codex 内置进程隔离 |
| `hooks.SubagentStop` | OS-level post-exec hook（`config.toml [hooks] post_edit`） |

## 落盘机制

Codex 不提供 SubagentStop。REVIEW.md 由本 agent 直接 `Write` 到 `docs/reviews/<feature-id>/REVIEW.md`（read-only 模式下需临时切到 `auto-edit` 或由主代理代写）。

## 其余 3 subagent

explorer / doc-writer / security-auditor 在 Codex 下行为对齐 Claude 版，按相同 frontmatter 改 3 字段即可：
- `model` → `gpt-5-codex` / `gpt-5-codex-mini`
- `permissionMode` → `approval_policy`
- `tools` → snake_case（`read_file` / `grep` / `glob`）

参考 canonical：`templates/agents/claude/<name>.md`。
