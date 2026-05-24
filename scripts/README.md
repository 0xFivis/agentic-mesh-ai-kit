<!-- REFERENCE ONLY: sanitized template, fill before use -->
# scripts/ · ai-kit 安装与升级脚本

## 文件

| 脚本 | 用途 | 入口 |
|---|---|---|
| `install.sh` | 平台首次安装 ai-kit：复制 4 家原生 AI 配置 + symlink skills + 落地 L1 AGENTS.md（根 + 10 处嵌套通用） | `bash <(curl -fsSL .../install.sh)` 或本地 `./install.sh` |
| `upgrade.sh` | 升级 ai-kit：三方合并（祖先 / 本地 / 新版）+ 写 `.ai-kit-version` | `./upgrade.sh` |

## install.sh 10 步骩要

1. **Step 1**：根 AGENTS.md（`templates/agents-md/root/`）落地 + Claude `CLAUDE.md` symlink
2. **Step 1.5**（v6 D19）：L1 嵌套通用 AGENTS.md 非破坏铺底 10 处（`apps/ packages/ ops/ testing/ contracts/ specs/ docs/{,architecture,adr,services}/`）
3. **Step 2**：spec-kit `specify init . --integration <vendor> --here`
4. **Step 3**：skills symlink 到 4 家原生路径（`.claude/skills/` · `.cursor/skills/` · `.github/skills/` · `.codex/skills/`）
5. **Step 4**：rules → 4 家原生位置
6. **Step 5**：hooks → 4 家原生（`_shared/*.sh` 复制 · 各家 `settings.json` / `hooks.json` 落地）
7. **Step 6**：MCP → 4 家独立配置（cursor 不 symlink claude · v6 D14）
8. **Step 7**：CI prompt SSOT 落地 `.github/ci-prompts/review.md`
9. **Step 8**：settings → 各家
10. **Step 9**：sub-agents（`templates/agents/`）→ 各家原生
11. **Step 10**：写 `.ai-kit-version`（平台根 · v6 D21）

> 实际脚本步号见 `install.sh` 内注释。

## 红线

- `install.sh` **绝不** patch arch-kit 生成的工作流 yaml（D29 零侵入）
- `install.sh` **绝不** 假设 arch-kit 骨架存在（独立可用 · Phase D step 24 验证）
- 缺 `uvx` → 显式报错指引（非静默失败 · Phase D step 26）

## 业务子域 AGENTS.md

不在 `install.sh` 流程内。需要时跑：

```bash
claude skill scaffold-agents-md   # 或 4 家等价命令
```

skill 扫描 `apps/* packages/*`，缺者添加，已有跳过（v0.1 不做 IDE/CLI 自动 hook）。
