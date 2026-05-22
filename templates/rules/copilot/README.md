<!-- REFERENCE ONLY: sanitized sample, not for production -->
# rules · GitHub Copilot

GitHub Copilot 的两种 rule 源：

1. **Repository instructions**：`.github/copilot-instructions.md`（全仓常驻）
2. **Path-scoped instructions**：`.github/instructions/<name>.instructions.md`（含 frontmatter `applyTo: <glob>`）

本目录提供：
- `copilot-instructions.md.tmpl` — 仓库级根指令（落 `.github/copilot-instructions.md`）
- `instructions/contracts-first.instructions.md.tmpl` — 路径作用域示例（落 `.github/instructions/`）

启用条件：
- VS Code 设置 `github.copilot.chat.codeGeneration.useInstructionFiles: true`（由 `settings/copilot/` 模板设置）

**与 AGENTS.md 的关系**：Copilot 自 2024.10+ 原生读 `AGENTS.md`，本目录的指令文件是「Copilot 专属补充」（避免污染其他 agent）。
