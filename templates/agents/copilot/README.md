<!-- REFERENCE ONLY: sanitized sample, not for production -->
# agents · GitHub Copilot

Copilot 的 subagent 实现路径：

1. **Custom Chat Modes**（VS Code · 推荐）：`.github/chatmodes/<name>.chatmode.md`，由设置 `chat.modeFilesLocations` 启用
2. **Spaces / Coding Agent**（GitHub.com）：在 Space 设置内填 system prompt + 工具白名单

本目录提供 1 个 canonical reviewer 适配；其余 3 个 subagent（explorer / doc-writer / security-auditor）的 system prompt 可直接复用 `templates/agents/claude/<name>.md` body 段（去掉 Claude 专属 frontmatter）。

落盘位置：`.github/chatmodes/<name>.chatmode.md`（VS Code）或 GitHub Space 设置面板（在线）。
