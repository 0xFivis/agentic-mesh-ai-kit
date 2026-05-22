# Skills · agentic-mesh-ai-kit

本目录提供 **12 个 SKILL.md**，遵循 [agentskills.io](https://agentskills.io) 元数据规范（`name` / `description` / `allowed-tools` / `disable-model-invocation` / `argument-hint`），可被 Claude Code、Cursor、GitHub Copilot、OpenAI Codex CLI 四类 agent 通过 [vercel-labs/skills](https://github.com/vercel-labs/skills) CLI（`npx skills add <name>`）统一安装到本地 `.skills/` 或各 agent 原生目录。

> **本仓不是 skill 注册中心**：本目录仅打包与本平台 SOP 强绑定的 12 个 skill；通用 skill 请直接走 agentskills.io 检索。

## 12-skill 索引

| # | Skill | 触发阶段 | 模型可主动调用 | 一句话 |
|---|-------|----------|----------------|--------|
| 1 | [tech-intake](tech-intake/SKILL.md) | T0 | ✅ | 8 项自检 → `specs/<id>/spec.md` 草稿 |
| 2 | [adr-writing](adr-writing/SKILL.md) | R 横切 | ✅ | ≥2 候选 + 决策矩阵 + 排除理由 |
| 3 | [std-writing](std-writing/SKILL.md) | R 横切 | ✅ | STD-NN 5 段模板 + 反例 |
| 4 | [bc-impact-map](bc-impact-map/SKILL.md) | T1 | ✅ | 业务变更 → BC/服务/契约/数据影响表 |
| 5 | [contract-first](contract-first/SKILL.md) | T2 | ✅ | 五件套 spec→plan→data-model→contracts→quickstart |
| 6 | [task-decomp-fanout](task-decomp-fanout/SKILL.md) | T3 | ✅ | tasks.md + DAG + N Issue 派生 |
| 7 | [gate-checklist](gate-checklist/SKILL.md) | T4.1 / T4.3 | ✅ | plan 自评 + review 红旗双模 |
| 8 | [qa-cases](qa-cases/SKILL.md) | T4.2 | ✅ | 4 象限测试矩阵生成 |
| 9 | [release-canary](release-canary/SKILL.md) | T6 | ⛔ | release.md + rollback.md（含副作用，需手动触发） |
| 10 | [retro-audit](retro-audit/SKILL.md) | T7 | ⛔ | 12 项 audit + Action Items + memory 沉淀 |
| 11 | [data-redline](data-redline/SKILL.md) | 横切（alwaysLoaded） | ✅ | 4 级分级 + 8 红线 |
| 12 | [scaffold-agents-md](scaffold-agents-md/SKILL.md) | 手动 | ⛔ | 业务子域 AGENTS.md 占位生成（never overwrite） |

> `⛔ disable-model-invocation: true` 表示带副作用或需人审，仅允许人类显式调用（`/skill-name ...`）。

## 安装（4 agent · 任选）

```bash
# 任一 agent 仓库内执行：
npx skills add tech-intake adr-writing std-writing bc-impact-map contract-first \
                task-decomp-fanout gate-checklist qa-cases release-canary \
                retro-audit data-redline scaffold-agents-md
```

各 agent 默认安装路径（CLI 会自动识别）：

| Agent | 路径 |
|-------|------|
| Claude Code | `.claude/skills/<name>/` |
| Cursor | `.cursor/skills/<name>/` |
| GitHub Copilot | `.github/skills/<name>/` |
| OpenAI Codex CLI | `.codex/skills/<name>/`（如 codex 不支持 skills，则保留为可读知识） |

## 规范来源

- agentskills.io · [SKILL.md frontmatter spec](https://agentskills.io/docs/skill-format)
- vercel-labs/skills · [CLI README](https://github.com/vercel-labs/skills)
- 本仓 plan：[../playbook.md](../playbook.md)（安装后路径）/ 本仓内 `_research/14-agentskills-io-and-skills-cli.md`
