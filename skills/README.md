# Skills · agentic-mesh-ai-kit

本目录提供 **15 个 SKILL.md**（13 活跃 + 2 暂停），遵循 [agentskills.io](https://agentskills.io) 元数据规范（`name` / `description` / `allowed-tools` / `disable-model-invocation` / `argument-hint`），可被 Claude Code、Cursor、GitHub Copilot、OpenAI Codex CLI 四类 agent 通过 [vercel-labs/skills](https://github.com/vercel-labs/skills) CLI（`npx skills add <name>`）统一安装到本地 `.skills/` 或各 agent 原生目录。

> **本仓不是 skill 注册中心**：本目录仅打包与本平台 SOP 强绑定的 skill；通用 skill 请直接走 agentskills.io 检索。
> **权威列表与状态**以 [`../playbook.md` §2.3](../playbook.md#23-agent-skills) 为准，本表与之同步。

## 15-skill 索引

| # | Skill | 触发阶段 | 模型可主动调用 | 状态 | 一句话 |
|---|-------|----------|----------------|------|--------|
| 1  | [tech-intake](tech-intake/SKILL.md)               | T0           | ✅ | 活跃 | spec.md 二次自检（非必选，spec-kit 增强型）|
| 2  | [adr-writing](adr-writing/SKILL.md)               | R 横切       | ✅ | 活跃 | ≥2 候选 + 决策矩阵 + 排除理由 |
| 3  | [std-writing](std-writing/SKILL.md)               | R 横切       | ✅ | 活跃 | STD-NN 5 段模板 + 反例 |
| 4  | [bc-impact-map](bc-impact-map/SKILL.md)           | T1           | ✅ | 活跃 | 业务变更 → BC/服务/契约/数据影响表 |
| 5  | ~~[contract-first](contract-first/SKILL.md)~~     | T2           | ✅ | **暂停** | 被 `/speckit.plan` 替代（OpenAPI / 事件 schema / 数据迁移）|
| 6  | ~~[task-decomp-fanout](task-decomp-fanout/SKILL.md)~~ | T3       | ✅ | **暂停** | 被 `/speckit.tasks` + `/speckit.taskstoissues` 替代 |
| 7  | [task-plan-drafting](task-plan-drafting/SKILL.md) | T4.1         | ✅ | 活跃 | 单 task 技术方案 + 实施步骤草稿（5 段）|
| 8  | [gate-checklist](gate-checklist/SKILL.md)         | T4.1 / T4.3  | ✅ | 活跃 | plan 自评 5 条 + Code Review 5 条红旗（双模复用）|
| 9  | [self-review-agent](self-review-agent/SKILL.md)   | T4.2 / PR 前 | ✅ | 活跃 | 编码者自审 lint+（语义层 · 非强制）|
| 10 | [qa-cases](qa-cases/SKILL.md)                     | T4.2         | ✅ | 活跃 | 4 象限测试矩阵 + 探索性 mutation 测试 |
| 11 | [release-canary](release-canary/SKILL.md)         | T6           | ⛔ | 活跃 | release.md + rollback.md（AI 无 prod 写权限）|
| 12 | [retro-audit](retro-audit/SKILL.md)               | T7           | ⛔ | 活跃 | audit checklist + auto memory 沉淀 |
| 13 | [data-redline](data-redline/SKILL.md)             | 横切（always loaded）| ✅ | 活跃 | 4 级分级 + 8 红线 |
| 14 | [scaffold-agents-md](scaffold-agents-md/SKILL.md) | 手动         | ⛔ | 活跃 | 业务子域 AGENTS.md 占位生成（never overwrite）|
| 15 | [new-service-bootstrap](new-service-bootstrap/SKILL.md) | T4 特殊 lane | ✅ | 活跃 | 新建服务 3 步引导（包裹 arch-kit `new-service.sh`）|

> `⛔ disable-model-invocation: true` 表示带副作用或需人审，仅允许人类显式调用（`/skill-name ...`）。
> **暂停**项保留在目录里供历史参考，spec-kit slash-command 已覆盖其能力。

## 安装（4 agent · 任选）

```bash
# 任一 agent 仓库内执行（13 个活跃 skill，暂停项不分发）：
npx skills add tech-intake adr-writing std-writing bc-impact-map \
                task-plan-drafting gate-checklist self-review-agent qa-cases \
                release-canary retro-audit data-redline scaffold-agents-md \
                new-service-bootstrap
```

> 也可一次性安装全部 15 个（含暂停项）：追加 `contract-first task-decomp-fanout` 即可。
> 或直接通过 `agentic-mesh-ai-kit/scripts/install.sh`（step 4）按目录自动扫描分发。

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
- 本仓 plan：[../playbook.md §2.3](../playbook.md#23-agent-skills)（权威）/ 本仓内 `_research/14-agentskills-io-and-skills-cli.md`
