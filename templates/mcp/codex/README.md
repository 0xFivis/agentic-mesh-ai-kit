# templates/mcp/codex/

> **Codex 的 MCP 配置不在此目录**。

Codex 的 MCP servers 段（`[mcp_servers.*]`）与 settings / sandbox / skills / agents 一起，
**全部承载在单一文件**：`.codex/config.toml`。
Codex 不识别 `.codex/mcp.json` 或独立的 mcp toml 文件。

## SSOT 位置

→ [`templates/settings/codex/config.toml.tmpl`](../../settings/codex/config.toml.tmpl)

修改 MCP 配置请直接编辑该模板中的 `[mcp_servers.*]` 段。`scripts/install.sh` step 7
对 Codex 不做任何动作；MCP 段由 step 8（settings 渲染）一并落地。

## 与其他厂商对比

| 厂商 | MCP 配置位置 | settings 位置 |
|---|---|---|
| Claude | `.mcp.json`（独立） | `.claude/settings.json` |
| Cursor | `.cursor/mcp.json`（独立） | `.cursor/settings.json` |
| Copilot | `.vscode/mcp.json`（独立） | `.vscode/settings.json` |
| **Codex** | **`.codex/config.toml` `[mcp_servers.*]` 段** | **同一文件** |
