<!-- REFERENCE ONLY: sanitized sample, not for production -->
# agents · OpenAI Codex CLI

Codex 的 subagent 通过 `.codex/agents/<name>.md` 识别，由项目级 `.codex/config.toml` 的 `[agents] search_paths` 启用（同一份 `[agents] search_paths` 也可写在用户级 `~/.codex/config.toml`）。

字段差异 vs Claude：
- `model` → `gpt-5-codex` 系列
- `permissionMode` → `approval_policy`（`read-only` / `suggest` / `auto-edit` / `full-auto`）
- `tools` → snake_case
- `isolation` → 由 `sandbox.mode` 配合实现

本目录提供 1 个 canonical reviewer 适配；其余 3 个 subagent 按上述字段差异从 `templates/agents/claude/` 改名拷贝即可。
