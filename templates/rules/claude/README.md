<!-- REFERENCE ONLY: sanitized template, fill before use -->
# rules · Claude Code

Claude Code 的路径作用域规则放在 `.claude/rules/<topic>.md`，用 `paths:` frontmatter 限定生效范围。
参考 [playbook §2.2](../../../playbook.md) 4 家对照表。

## 文件命名

- 文件名 = `<topic>.md`，topic 用 kebab-case，对应一个业务/技术关注点
- 本目录内 `contracts-first.md.tmpl` 是 `<topic>` 占位示例（参 cursor / copilot 同名版本）
- 平台落地后按需新增：`api-layer.md` · `data-migration.md` · `security-audit.md` ...

## frontmatter 必含字段

```yaml
---
paths:
  - "<glob-pattern>"   # 上下文含匹配文件时才注入该 rule
---
```

## 入口层与本层的关系

- 根 `CLAUDE.md` = symlink → `AGENTS.md`（由 install.sh step 1 完成）= **Always 注入**
- 本目录 `<topic>.md` = **Auto-Attached 注入**（仅匹配 paths 时）

两者互补：仓库级红线放 `AGENTS.md`，路径级细则放本目录。

## 跨家对照

| 家 | 对应文件 | 字段 |
|---|---|---|
| Claude Code | `.claude/rules/<topic>.md` | `paths:` |
| Cursor | `.cursor/rules/<topic>.mdc` | `globs:` |
| GitHub Copilot | `.github/instructions/<topic>.instructions.md` | `applyTo:` |
| OpenAI Codex | `<dir>/AGENTS.md` 或 `<dir>/AGENTS.override.md` | 无 frontmatter，靠物理位置 |

> Codex 没有同类 `.codex/rules/*.md`；`.codex/rules/*.rules` 是 Starlark 沙箱准入策略，归 hooks 范畴（[playbook §2.5](../../../playbook.md)）。
