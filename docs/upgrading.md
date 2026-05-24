<!-- REFERENCE ONLY: sanitized template, fill before use -->
# Upgrading ai-kit

> ai-kit 用平台根 `.ai-kit-version` 文件追踪当前版本（内容 = ai-kit git tag · v6 D21）。

## 升级流程

```bash
cd <your-platform-repo>
./scripts/upgrade.sh           # ai-kit 自带，或从最新版 ai-kit 拉取
```

`upgrade.sh` 做三件事：

1. **读取本地版本**：从平台根 `.ai-kit-version` 读出当前 tag
2. **三方合并**（祖先 / 本地 / 新版）：
   - 祖先 = 本地版本 tag 对应的 ai-kit 文件树
   - 本地 = 平台仓内当前已落地的 ai-kit 资产（可能被用户魔改）
   - 新版 = 目标 tag 对应的 ai-kit 文件树
   - 冲突文件输出 `.rej` + 终端提示
3. **写新版本**：成功后写入新 tag 到 `.ai-kit-version`

## 升级前

1. 提交本地所有 .ai-kit 相关改动（升级会触发合并）
2. 备份魔改文件（如 `templates/rules/<vendor>/*.tmpl` 已自定义）
3. 看 ai-kit `CHANGELOG.md` 当前版到目标版的 breaking changes

## 升级后验证

```bash
cat .ai-kit-version              # 应等于新 tag
ls -la CLAUDE.md                 # 应 symlink → AGENTS.md（Step 1 idempotent）
npx skills list                  # 12 个 skill 全 symlink ok
grep -r "prompt-file:" .github/workflows/  # 全部指向 .github/ci-prompts/review.md
```

## Breaking changes 处理

ai-kit `CHANGELOG.md` 用 SemVer：

- **patch**（0.1.1 → 0.1.2）：纯修复，可直接 upgrade.sh
- **minor**（0.1.x → 0.2.0）：新 skill / 新 type / 新约束，可能需手动迁移；CHANGELOG 含「Manual migration」节
- **major**（0.x → 1.0）：必须先看 [`docs/migrations/0.x-to-1.0.md`](migrations/0.x-to-1.0.md)（如有）

## 与 arch-kit 升级的区别

| | arch-kit | ai-kit |
|---|---|---|
| 版本文件 | `.arch-kit-version`（平台根）| `.ai-kit-version`（平台根）|
| 升级脚本 | `scripts/upgrade-arch-kit.sh`（在 arch-kit 派生时复制） | `scripts/upgrade.sh`（ai-kit 提供）|
| 升级范围 | 骨架 `.tmpl` / 配置 / `tech-standards/` | AI 配置 / skills / templates / playbook |
| 互不依赖 | ✅（v6 D12 两仓零耦合） | ✅ |
