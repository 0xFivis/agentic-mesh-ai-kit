<!-- REFERENCE ONLY: sanitized sample, not for production -->
# ci-prompts/ · SSOT for CI Review Prompts

## 单一来源（SSOT）

`review.md.tmpl` 是**所有** CI 流水线 review 步骤的 prompt 来源。任何 vendor 的 GitHub Action（Claude Code Action / OpenAI Codex Action / GitHub Copilot Coding Agent / Cursor CLI）通过 `prompt-file: .github/ci-prompts/review.md` 引用。

## 为什么 SSOT

- 避免 4 个 vendor 各自演化出 5 套不一致的评审标准（一致性 = 团队信任）
- 任何评审口径变更只改一处
- 与 `skills/gate-checklist/SKILL.md` 的 5 条红旗保持对齐

## 覆盖（overrides）

仅当某 vendor 必须差异化时，把 SSOT 复制到 `overrides/<vendor>.md`（例 `overrides/codex.md`），并在 vendor workflow 内显式引用 override 路径。**不要** 修改 SSOT。

每个 override 文件首行必须引用 SSOT：
```
<!-- DERIVED from ../review.md.tmpl · only contains <vendor> diff -->
```

## 引用示例

```yaml
# .github/workflows/ci.yml
- name: AI Review (Claude Code Action)
  uses: anthropics/claude-code-action@v1
  with:
    prompt-file: .github/ci-prompts/review.md
    # ↑ install.sh step 9 把 review.md.tmpl 渲染到此路径
```
