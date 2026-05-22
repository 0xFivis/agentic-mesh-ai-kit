<!-- REFERENCE ONLY: sanitized sample, not for production -->
# hooks · GitHub Copilot

GitHub Copilot 的 hook 能力较弱（Preview 阶段），原生支持的 hook 入口：

1. **`chat.useCustomAgentHooks: true`**（VS Code settings）→ 启用 agent frontmatter 内 `hooks:` 字段
2. **GitHub Actions**（CI 层）→ 通用守门（best practice）
3. **pre-commit / husky**（git 层）→ 跨 agent 共用

本仓策略：Copilot hook 走 **CI Actions** 路径（见 `.github/workflows/ci.yml`），而非编辑器 hook，以保证多平台一致。

5 个共享脚本（`hooks/_shared/*.sh`）通过 Actions step 直接调用：

```yaml
- name: hook · check-no-verify
  run: bash scripts/hooks/check-no-verify.sh "${{ github.event.head_commit.message }}"
- name: hook · check-closes-issue
  run: bash scripts/hooks/check-closes-issue.sh
- name: hook · check-needs-clarification
  run: bash scripts/hooks/check-needs-clarification.sh
- name: hook · check-task-verification
  run: bash scripts/hooks/check-task-verification.sh
- name: hook · check-no-secrets
  run: bash scripts/hooks/check-no-secrets.sh
```

由 `ci-prompts/review.md.tmpl` 的 SSOT 评审 prompt 配合实现 Writer-Reviewer 隔离的等价语义。
