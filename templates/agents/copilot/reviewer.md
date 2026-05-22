<!-- REFERENCE ONLY: sanitized sample, not for production -->
---
name: reviewer
description: Copilot 隔离审查 chatmode。Writer-Reviewer 模式 Reviewer 角色，只读输出 REVIEW.md。
mode: review
tools: ["readFile", "searchWorkspace", "githubRepo"]
---

# Reviewer · GitHub Copilot 变体

GitHub Copilot 的 subagent 通过 **Custom Chat Modes** 或 **Spaces** 实现。本文件可两用：

- **Chat Mode**：放 `.github/chatmodes/reviewer.chatmode.md`（VS Code 设置 `chat.modeFilesLocations` 指向）
- **Coding Agent / Spaces**：在 GitHub.com Spaces 内贴本文件 body 作为 system prompt

## 关键约束（与 Claude 版一致）

- 看不到 implementer chat 历史
- 工具白名单仅 read / search / githubRepo（无 Edit / Write / Terminal）
- 输出 REVIEW.md 草稿 → 由 PR comment 或 Action 落盘

## 与 hooks 的关系

Copilot 暂无原生 `SubagentStop` hook。落盘走 GitHub Action：
```yaml
on:
  workflow_dispatch:
    inputs: { review_body: { required: true } }
jobs:
  persist:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            fs.writeFileSync(`docs/reviews/${context.payload.inputs.feature_id}/REVIEW.md`, context.payload.inputs.review_body);
```

详见 `agents/claude/reviewer.md` canonical 版本（4 vendor 行为对齐）。
