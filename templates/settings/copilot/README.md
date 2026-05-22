<!-- REFERENCE ONLY: sanitized sample, not for production -->
# settings · GitHub Copilot

Copilot 走 VS Code settings.json，分两层：

- **workspace**：`.vscode/settings.json`（建议）
- **user**：用户全局（不在本仓管理）

`install.sh` step 8 把以下片段 merge 到 `.vscode/settings.json`：

```json
{
  "chat.useCustomAgentHooks": true,
  "github.copilot.chat.codeGeneration.useInstructionFiles": true,
  "chat.promptFiles": true,
  "chat.modeFilesLocations": [
    { "pattern": ".github/chatmodes/*.chatmode.md" }
  ]
}
```

MCP 配置见 `mcp/copilot/.vscode-mcp.json.tmpl`（顶层键 `servers`，落 `.vscode/mcp.json`）。
