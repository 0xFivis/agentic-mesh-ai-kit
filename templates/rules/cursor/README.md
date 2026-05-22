<!-- REFERENCE ONLY: sanitized sample, not for production -->
# rules · Cursor

Cursor 项目级规则落 `.cursor/rules/<name>.mdc`。本目录提供模板，`install.sh` step 6 拷至 `.cursor/rules/`。

每条规则一份 `.mdc.tmpl`，YAML frontmatter + Markdown body：

```mdc
---
description: 一句话用途
globs:
  - "apps/**"
  - "packages/**"
alwaysApply: false
---
# 规则正文
- ...
```

字段约定：
- `alwaysApply: true` → 全局常驻（慎用，等价于 always-loaded skill）
- `globs:` → 文件路径匹配命中才注入
- 命名：`<purpose>-<scope>.mdc`，避免与官方仓库的 community rule 冲突

本仓提供 1 个示例规则 `contracts-first.mdc.tmpl`，强制在编辑 `contracts/**` 前先 link spec.md。
