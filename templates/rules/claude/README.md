<!-- REFERENCE ONLY: sanitized sample, not for production -->
# rules · Claude Code

Claude Code 的「rules」即 `CLAUDE.md` 层级（`~/.claude/CLAUDE.md` → 仓库根 `CLAUDE.md` → 子目录 `CLAUDE.md`）。

**装配方式**：

- 仓库根：`ln -s AGENTS.md CLAUDE.md`（由 install.sh step 1 处理）
- 子目录：所有 `<dir>/AGENTS.md` 同时被 Claude Code 视为 CLAUDE.md（4.x+）；无需额外 symlink

**本目录不放任何 `.mdc` / `.instructions.md` 等异构 rule 文件**，因 Claude Code 没有等价机制。

如需声明 Claude-only 行为，请追加在仓库根 `AGENTS.md` 的 `## 7. AI 协作 SOP` 节内（用 `> Claude Code only:` 引用块标注），其他 agent 会忽略。
