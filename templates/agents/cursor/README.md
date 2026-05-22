<!-- REFERENCE ONLY: sanitized sample, not for production -->
# agents · Cursor

Cursor 的 subagent 模板，frontmatter 与 Claude Code 高度兼容；差异：

| Claude 字段 | Cursor 等价 |
|------------|-------------|
| `permissionMode: read-only` | `tools:` 仅声明 Read/Grep/Glob |
| `isolation: worktree` | `contextIsolation: true` |
| `hooks:` | 由 `.cursor/hooks.json` 集中管 |

本目录提供 1 个 canonical reviewer 适配；其余 3 个 subagent（explorer / doc-writer / security-auditor）参考 `templates/agents/claude/<name>.md` 即可（绝大多数 frontmatter 字段相容；如需差异化，按上表手工改 2 行）。

落盘位置：`.cursor/agents/<name>.md`。
