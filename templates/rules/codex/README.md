<!-- REFERENCE ONLY: sanitized sample, not for production -->
# rules · OpenAI Codex CLI

Codex 原生读 `AGENTS.md`（项目根 + 子目录），其他家不知道的 Codex-only 覆盖项落 `<dir>/AGENTS.override.md`。

**关键约定**：
- `AGENTS.md`（共读）：仅放跨 agent 通用规则
- `AGENTS.override.md`（Codex-only）：放仅 Codex 应遵守的差异化规则；其他 agent 看不到
- 不自动派生：`AGENTS.override.md` 必须手写，install.sh 不生成（避免静默差异）

本目录提供 `AGENTS.override.md.tmpl` 模板，按需 `cp` 到目标子目录。
