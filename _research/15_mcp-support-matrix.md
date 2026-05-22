<!-- REFERENCE ONLY: sanitized sample, not for production -->
# 15 · 四家 AI Agent MCP Servers 能力对照表

> 调研日期：2026-05-20
> 一手来源：
> - Claude Code：https://code.claude.com/docs/en/mcp
> - Cursor：https://cursor.com/docs/context/mcp
> - OpenAI Codex：https://developers.openai.com/codex/mcp
> - GitHub Copilot：https://code.visualstudio.com/docs/copilot/customization/mcp-servers

---

## 0. 共识基线

四家都原生支持 [Model Context Protocol](https://modelcontextprotocol.io/)，把外部工具（GitHub / Postgres / Notion / Figma / Sentry / 浏览器…）以统一协议暴露给 agent。

- **传输方式**：stdio（本地进程）/ Streamable HTTP（远程）/ SSE（多数仍兼容但 Claude 已标记 deprecated）
- **协议能力**：工具 Tools / 提示 Prompts / 资源 Resources（@-mention 引用）/ Elicitation / Roots，四家覆盖度高
- **认证**：四家都支持 OAuth 2.0；远程服务器返回 401/403 时自动进入认证流

---

## 1. 配置位置 / 格式对照（**最容易踩坑**）

| 工具 | 配置文件位置 | 格式 | 顶层键 |
|---|---|---|---|
| Claude Code | 项目 `.mcp.json`（团队共享，纳入 VCS）<br>用户/本地 `~/.claude.json` <br>企业 `managed-mcp.json`（OS 级路径，IT 部署） | JSON | `mcpServers` |
| Cursor | 项目 `.cursor/mcp.json` <br>全局 `~/.cursor/mcp.json` | JSON | `mcpServers` |
| OpenAI Codex | 全局 `~/.codex/config.toml` <br>项目 `.codex/config.toml`（仅 trusted 项目） | **TOML** | `[mcp_servers.<name>]`（表） |
| GitHub Copilot | 工作区 `.vscode/mcp.json` <br>用户 profile（`MCP: Open User Configuration`）<br>custom agent frontmatter `mcp-servers:`（仅 `target: github-copilot`） | JSON | **`servers`**（不是 `mcpServers`） |

**红线**：
- ❌ 不存在"四家通用 `.mcp.json`"这种说法
- ❌ Claude 的 `.mcp.json` 不能直接喂给 Cursor / Codex / Copilot：路径不对 + Codex 还要换格式 + Copilot 顶层键名不同

---

## 2. 传输方式 / 认证 / 高级特性

| 维度 | Claude Code | Cursor | Codex | Copilot |
|---|---|---|---|---|
| stdio | ✅ | ✅ | ✅ | ✅ |
| HTTP / Streamable HTTP | ✅ | ✅ | ✅ | ✅ |
| SSE | ✅（**已 deprecated**，建议用 HTTP）| ✅ | ❌（无 SSE，仅 STDIO + HTTP）| ✅ |
| OAuth | ✅ `/mcp` 命令交互登录；`--client-id` / `--callback-port` / `oauth.scopes` / `authServerMetadataUrl` 精细控制 | ✅ 固定回调 `cursor://anysphere.cursor-mcp/oauth/callback`；`auth` 块支持静态客户端凭据 | ✅ `codex mcp login <name>`；可设 `mcp_oauth_callback_port` / `mcp_oauth_callback_url` | ✅ 首次启动需 trust 对话框；通过扩展信任流 |
| Bearer Token / 自定义 Header | `headers` + `headersHelper`（动态生成）| `headers` 字段 | `bearer_token_env_var` + `http_headers` + `env_http_headers` | `headers` 字段 |
| 环境变量插值 | `${VAR}` / `${VAR:-default}`；`CLAUDE_PROJECT_DIR` | `${env:NAME}` / `${userHome}` / `${workspaceFolder}` / `${workspaceFolderBasename}` / `${pathSeparator}` | TOML 内部不强调插值，提供 `env` / `env_vars` 转发 | `${input:xxx}` 输入变量；环境文件 |

---

## 3. 各家独有能力

### 3.1 Claude Code 独有

- **Scope 三级 + 优先级**：`local` → `project` → `user`，加上 plugin / claude.ai connector 共五级
- **Tool Search**（默认开启）：MCP 工具按需载入而非全量塞入上下文；`alwaysLoad: true` 可豁免
- **Plugin 内嵌**：plugin 可在 `plugin.json` 或 plugin 根 `.mcp.json` 内 inline 声明 MCP server（**不是** subagent 内嵌）
- **企业 managed-mcp.json**：IT 可强制 allowlist/denylist；支持按 `serverName` / `serverCommand` / `serverUrl`（含通配）匹配
- **`MAX_MCP_OUTPUT_TOKENS`**：单工具输出超 10K tokens 给警告，可调阈值；server 可用 `anthropic/maxResultSizeChars` 单独提高
- **Channels**：MCP server 可声明 `claude/channel` 推送消息进会话（CI 结果、监控告警等）
- **Claude Code 自己当 MCP server**：`claude mcp serve` 暴露 Claude 的工具给其他 MCP 客户端
- **`claude mcp add-from-claude-desktop`**：从 Claude Desktop 配置一键导入（仅 macOS/WSL）

### 3.2 Cursor 独有

- **MCP Apps 扩展**：MCP 工具除常规响应外，可返回**交互式 UI 视图**（渐进增强，不支持也能工作）
- **`envFile`**：仅 stdio server 支持，从 `.env` 加载更多环境变量
- **扩展 API**：`vscode.cursor.mcp.registerServer()` 编程注册（无需改 `mcp.json`）
- **Marketplace 一键安装**：cursor.com/marketplace 的官方插件可"Add to Cursor"按钮 + OAuth 一步完成
- **图像返回**：MCP 工具可返回 base64 图像，自动附加到聊天

### 3.3 OpenAI Codex 独有

- **细粒度工具管控**（其他三家都没这么细）：
  - `enabled_tools` / `disabled_tools`：白/黑名单（黑后置生效）
  - `default_tools_approval_mode`：`auto` / `prompt` / `approve`（每个 server 默认审批策略）
  - `tools.<tool>.approval_mode`：**单个工具**单独覆写审批策略
- **`required: true`**：启动失败即让 Codex 启动失败（强依赖）
- **`startup_timeout_sec` / `tool_timeout_sec`**：显式超时配置（默认 10 / 60s）
- **`experimental_environment = "remote"`**：stdio server 通过远程执行器跑（远程开发支持）
- **`env_vars` 跨远程拉取**：`{ name = "REMOTE_TOKEN", source = "remote" }`
- **Plugin MCP 控制位**：`[plugins."xxx".mcp_servers.<server>]` 控 plugin 自带 MCP 的 on/off 与审批

### 3.4 GitHub Copilot 独有

- **`sandboxEnabled: true`**（**仅 macOS / Linux**）：本地 stdio server 跑沙箱，限制文件 / 网络；沙箱内工具调用自动批准
  ```json
  "sandbox": {
    "filesystem": { "allowWrite": ["${workspaceFolder}"] },
    "network":    { "allowedDomains": ["api.example.com"] }
  }
  ```
- **Extension Gallery 集成**：Extensions 视图按 `@mcp` 搜索 → 一键 Install / Install in Workspace
- **Settings Sync**：MCP 配置可跨设备同步
- **`MCP: Reset Trust`**：可重置已信任的 server 列表
- **Custom agent frontmatter `mcp-servers:`**：仅 `target: github-copilot`（cloud agents），与本地 `.vscode/mcp.json` 是**两个独立通道**
- **企业级 GitHub Policy 集中管控**：组织级别 allow/deny

---

## 4. 字段命名差异速查

| 含义 | Claude | Cursor | Codex | Copilot |
|---|---|---|---|---|
| 顶层容器 | `mcpServers` | `mcpServers` | `[mcp_servers.X]` TOML 表 | **`servers`** |
| 启动命令 | `command` | `command` | `command` | `command` |
| 参数 | `args` | `args` | `args` | `args` |
| 环境变量 | `env` | `env` + `envFile`(stdio) | `env` + `env_vars` | `env` |
| 远程地址 | `url` | `url` | `url` | `url` |
| HTTP 头 | `headers` | `headers` | `http_headers` / `env_http_headers` | `headers` |
| 类型字段 | `type: "http"\|"sse"\|"stdio"` | `type` 仅 stdio 必填 | 隐式（有 `command` 即 stdio，有 `url` 即 HTTP）| `type: "http"\|"stdio"` |
| 工具白名单 | 无原生（用 permission 控）| 无原生 | `enabled_tools` | `Configure Tools` UI |
| 单 server 启停 | `/mcp` UI | `/mcp` UI | `enabled = false` | Right-click + `Enable/Disable` |

---

## 5. 跨家迁移配方

| 从 | 到 | 转换动作 |
|---|---|---|
| Claude `.mcp.json` | Cursor | 改路径为 `.cursor/mcp.json`，键名不变；OAuth 重定向自动用 Cursor 协议；env 插值改 `${env:NAME}` |
| Claude `.mcp.json` | Copilot | 改路径为 `.vscode/mcp.json`；**顶层 `mcpServers` → `servers`**；其余结构基本兼容 |
| Claude `.mcp.json` | Codex | **翻译为 TOML** 写入 `~/.codex/config.toml`；每个 server 一节 `[mcp_servers.<name>]`；HTTP 头改 `http_headers` |
| Cursor `.cursor/mcp.json` | Claude | 改路径为 `.mcp.json`；插值语法 `${env:X}` → `${X}` |
| 任何家 | Copilot 启用沙箱 | 加 `"sandboxEnabled": true` + 可选 `sandbox.filesystem.allowWrite` / `sandbox.network.allowedDomains`（macOS/Linux only）|

---

## 6. <platform> 适用性建议

| 需求 | 推荐做法 |
|---|---|
| 团队共享：所有人装 GitHub / Postgres / Notion | Claude 主仓库放 `.mcp.json` 入 VCS；Cursor 用户镜像到 `.cursor/mcp.json`；Copilot 镜像到 `.vscode/mcp.json` 并改顶层键 |
| 跨仓库引用 IB / <identity-verification> 等业务 docs | 起 Postgres MCP 接 metadata DB 或 filesystem MCP 指向 `<docs-repo>/prd/` |
| 防止 Codex MCP 跑高危工具 | 用 `default_tools_approval_mode = "approve"` 或 `tool.X.approval_mode = "approve"` |
| 防止 Copilot MCP 越权写文件 | `sandboxEnabled: true` + `allowWrite: ["${workspaceFolder}"]` |
| 企业级集中管控 | Claude `managed-mcp.json` allowlist / Copilot GitHub Policy |
| 大输出 MCP 工具不爆上下文 | Claude `MAX_MCP_OUTPUT_TOKENS` 或 server 加 `anthropic/maxResultSizeChars` |

---

## 7. 红线 / 易踩坑

1. **`.mcp.json` 不是通用文件名** — 只有 Claude 用这个名 + 路径。其余三家路径全不同
2. **Copilot 顶层键是 `servers` 不是 `mcpServers`** — 直接 copy Claude 配置会被忽略
3. **Codex 是 TOML 不是 JSON** — 别复制粘贴 JSON 进去
4. **Claude 的 plugin inline MCP ≠ subagent inline** — subagent frontmatter 并不能内嵌 MCP；inline 仅出现在 plugin manifest
5. **Copilot custom agent frontmatter 的 `mcp-servers:` 仅对 cloud agents 生效**（`target: github-copilot`）；本地 IDE 用 `.vscode/mcp.json`
6. **Copilot 沙箱仅 macOS/Linux**，Windows 不可用
7. **Cursor `envFile` 仅 stdio**，远程 HTTP/SSE server 不支持
8. **Claude SSE 已 deprecated**，新接入优先 HTTP
9. **企业 `managed-mcp.json` 是系统级路径**（`/Library/Application Support/ClaudeCode/` 等），需管理员权限部署，不是用户目录
10. **OAuth 重定向 URI 各家约定不同** —— Cursor 固定 `cursor://...`、Codex 走 `mcp_oauth_callback_url`、Claude 走 `--callback-port`；接入第三方 OAuth app 需逐家注册

---

## 8. 参考链接

- 协议本身：https://modelcontextprotocol.io/introduction
- Claude Code MCP：https://code.claude.com/docs/en/mcp
- Cursor MCP：https://cursor.com/docs/context/mcp
- Codex MCP：https://developers.openai.com/codex/mcp
- Copilot / VS Code MCP：https://code.visualstudio.com/docs/copilot/customization/mcp-servers
- 本仓库现有交叉资料：
  - [ai-agent-playbook.md §2.6](../ai-agent-playbook.md)（playbook 简表版）
  - [templates/mcp/.mcp.json.template](../templates/mcp/.mcp.json.template)（Claude/Cursor 直接可用）
