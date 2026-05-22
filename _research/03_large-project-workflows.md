<!-- REFERENCE ONLY: sanitized sample, not for production -->
# 03 · 大项目工作流 — 2026/Q2 研究

> **写作语境校准**（重要）：<Platform> 当前 `<platform>` workspace 处于**立项 / 架构编写阶段**——`tech-docs` `tech-standards` `<docs-repo>` `team-operating-model` 是活跃的文档型 submodule，代码仓（实施期推荐 `quantix-platform` monorepo，见 §3.1）是规划中的形态。本篇**双阶段**给建议：  
> ① **立项期**（当前，文档/架构/SOP 为主） · ② **实施期**（未来，代码服务落地） · ③ **过渡决策**（从文档到首个 service 之间必须先就位的东西）  
> 前置阅读：[02 编程范式](02_coding-paradigms-2026.md) · [04 工具全景](04_tool-landscape-2026.md) · [06 子代理编排](06_subagent-orchestration.md) · [07 Skills](07_skills-and-prompts.md)

---

## §0 一句话结论

大型 AI Coding 项目的成败由 **5 个工程化骨架**决定，与模型品牌无关：

1. **作用域机制**（路径限定 + Subagent 隔离 + Worktree 沙箱 + Hook 红线）
2. **文档即上下文**（架构/ADR/Skill/NOTES 入仓，AI 与人共享一份事实）
3. **Spec → Plan → Code → Review 四段流水线**（每段产物入仓、可回放）
4. **PR 驱动 + 双层 Review**（L1 AI Review 在 CI / L2 人 Review 看业务）
5. **Long-horizon 跨会话续接**（Issue ID 锚点 + NOTES.md + 云端 agent）

**<Platform> 立项期**的关键不是上面 5 条本身，而是 **"把这 5 条以 SOP/Skill/模板形式预先沉淀"**——等 quantix-platform 第一个服务 PR 之前，`.claude/skills/qx-*` / `tech-standards/STD-01-coding` / `team-operating-model/03_协作流程/05_技术实施周期SOP.md` / `.github/workflows/ai-review.yml` 已经就绪。第一个服务上线时，AI 协作就是"按 SOP 执行"，不是"边写边发明"。

**立项期 5 件最重要的事**（本周可启动）：
1. **冻结 4 段流水线 SOP**——写进 `team-operating-model/03_协作流程/`
2. **沉淀 6 个 <Platform> Skill**——`.claude/skills/qx-{commit, review-pr, release, migrate-service, arch-diagram, prd-extract}`（参考 [07 §6.1](07_skills-and-prompts.md)）
3. **定 entry file 单源**——按 [01 结论](01_entry-file-support-matrix.md)，AGENTS.md 单源 + 各工具 symlink/import；现在父仓与所有 submodule 校准一遍
4. **写 "首个 service 启动 checklist"**——见本文 §5
5. **选定 AI Review 工具**（CodeRabbit / Greptile / Bugbot 三选一，见 §3.3）

---

## §1 立项期 vs 实施期 vs 过渡期 — 三阶段心智图

```
┌─────────────── 立项期（现在 · 文档/架构/SOP）───────────────┐
│ 仓库形态：<platform> parent + 文档型 submodule              │
│ AI 角色：写 PRD / 画图 / 起 ADR / 起 SOP / Spec Kit         │
│ 关键产物：tech-docs / tech-standards / SOP / Skill / 模板    │
│ 流水线：Discuss → Draft → Audit → Commit                     │
│ 工具栈：Claude Code（Skills 主用）+ Cursor（文档编辑）       │
└──────────────────────────┬───────────────────────────────────┘
                           │ 过渡期 — 见 §5 checklist
                           ▼
┌─────────────── 实施期（未来 · 代码服务落地）────────────────┐
│ 仓库形态：quantix-platform Monorepo（apps/* + packages/*）  │
│ AI 角色：写代码 / 跑测试 / 提 PR / Review                   │
│ 关键产物：代码 / 测试 / API 契约 / 部署清单                  │
│ 流水线：Spec → Plan → Code → Review → Deploy                │
│ 工具栈：Claude Code + Codex CLI（CI） + Cursor +            │
│         CodeRabbit + Codex Cloud（长任务）                   │
└──────────────────────────────────────────────────────────────┘
```

**两期不变量**（贯穿始终）：
- AGENTS.md / CLAUDE.md 入口文件单源（01 结论）
- Skill 是唯一可执行知识载体（07 结论）
- Hook = 强制红线、CLAUDE.md = 软性事实、Skill = 流程
- 4 段流水线（Spec → Plan → Code → Review）

**两期不同点**：

| 维度 | 立项期 | 实施期 |
|------|--------|--------|
| 主要"代码" | Markdown 文档、HTML 图、JSON spec | Go/Dart/TS 实际程序 |
| Review 重点 | 边界、术语、内部一致性 | 正确性、性能、安全 |
| 验证手段 | 人审、Docsify 渲染、链接 lint | 单测/集测/压测/AI Review |
| 节奏 | 文档周迭代，可 squash | PR 小步高频，<500 行 diff |
| Subagent | doc-writer / arch-diagram / prd-extract | reviewer / debugger / test-runner / migration-worker |

---

## §2 五大工程化骨架（实施期为主，立项期已部分落地）

### 骨架 1：作用域机制（防 AI 越界）

| 机制 | 实现 | 立项期用法 | 实施期用法 |
|------|------|-----------|-----------|
| **路径限定 Skill/Rule** | `paths:` glob | tech-docs 各章节按目录限定 | 按服务限定（services/wallet/**） |
| **Subagent + tools 白名单** | `.claude/agents/*.md` | 已用 prd-writing、archify | 加 reviewer/debugger/test-runner |
| **Worktree 隔离** | `git worktree add` | 单仓文档并行可暂不用 | 多 Claude 并行**必用** |
| **Sandbox / VM** | Codex sandbox / Devin VM | 文档无需 | 部署、长任务必用 |
| **Hook 红线** | PreToolUse 拦截 | 拦 `rm -rf docs/` | 拦 `git push --force` / 改 migrations / push prod |

### 骨架 2：文档即上下文（"AI 与人同读一份"）

| 文档 | 立项期位置 | 实施期位置 | 谁读 |
|------|-----------|-----------|------|
| `AGENTS.md` / `CLAUDE.md` | 各 submodule 根 | 各代码 repo 根 | 每次 session 自动注入 |
| 架构 / 边界 | `tech-docs/01-08*.md` | 同左（不变） | AI 按需 read，或 Skill 引用 |
| 决策记录 ADR | `tech-docs/adr/00X-*.md` | 同左 | AI 决策前先 read |
| 标准 / 红线 | `tech-standards/STD-0X-*/` | 同左 | Hook 强制 + Skill 提示 |
| 服务详设 | `tech-docs/services/<svc>/` | 同左（代码侧链回） | AI 写代码前 read |
| `SKILL.md` | `.claude/skills/qx-*/` | 同左（跨仓 symlink） | 按需 progressive disclosure |
| `NOTES.md` / `SPEC.md` | 单文档草稿 | 单 issue 草稿 | session 跨会话续接 |

**Anthropic 官方铁律**（[best-practices](https://code.claude.com/docs/en/best-practices)）：
- CLAUDE.md **越短越好**——"每行问：删了 Claude 会犯错吗？不会就删"
- 长 reference 进 Skill 按需加载，不堆进 CLAUDE.md
- 强制规则用 **Hook**（CLAUDE.md 是 advisory，Hook 是 deterministic）

### 骨架 3：Spec → Plan → Code → Review 流水线（核心）

```
┌──────── 1. SPEC ────────┐  ┌────── 2. PLAN ──────┐  ┌─── 3. CODE ───┐  ┌── 4. REVIEW ──┐
│ PRD / Issue / ADR 输入  │  │ Plan Mode / Explore │  │ Subagent 实现 │  │ AI Review:    │
│ → Claude interview 用户 │  │ → 输出 PLAN.md      │  │ Worktree 并行 │  │   CodeRabbit  │
│ → 写 SPEC.md（含验收）  │  │   分步骤、风险、影响│  │ 边写边测      │  │   Greptile    │
│ → 入仓 + Linear 编号    │  │ → **人审** → 放行   │  │ → 提 PR       │  │   Bugbot      │
└─────────────────────────┘  └─────────────────────┘  └───────────────┘  └────┬──────────┘
                                                                              │
                                                                      人 Approve → merge
```

**纪律**：
- **每段必留文件产物**（SPEC.md / PLAN.md / 实现 diff / Review comments）
- **段间换 fresh session**——写完 SPEC 后 `/clear`，新会话只带 SPEC.md 入场做 PLAN
- **Plan 必须人审**——Anthropic 官方明确"Plan 是产物，看完再放行"

**<Platform> 立项期已部分实现**：
- "SPEC" = PRD 章节 / tech-docs 服务详设
- "PLAN" = `tech-docs/PHASE-X-PLAN.md` / 服务详设的"实施梯队"
- "CODE" = 文档定稿提交
- "REVIEW" = `tech-docs/_audits/` 中的审计文档

**实施期需补的**：把这四段从"文档活动"明确翻译成"代码活动"，写进 `team-operating-model/03_协作流程/05_技术实施周期SOP.md`（§6 给详细动作）。

### 骨架 4：PR 驱动 + 双层 Review

| 层 | 工具 | 关注 | 强度 | 时延 |
|----|------|------|------|------|
| **L1 AI Review**（CI） | CodeRabbit / Greptile / Bugbot / Claude `/security-review` | 风格、明显 bug、security smell、test 缺失 | block merge | 1-3 min |
| **L2 人 Review** | 团队 senior + service owner | 设计合理性、业务边界、tradeoff | block merge | 小时 ~ 天 |

### 骨架 5：Long-horizon 任务跨会话续接

| 方案 | 机制 | <Platform> 适用 |
|------|------|------------|
| Claude Code `claude --resume` + `/rewind` | 命名 session 持久化 | 单人短周期任务 |
| Codex Cloud / Claude Code on Web | 云端 VM 保活，过夜跑 | 数据迁移、压测、大规模重构 |
| **NOTES.md / SPEC.md 入仓** | 状态外部化 | **所有项目必备** |
| Linear / Jira issue ↔ Agent | 任务编号 anchor | 团队协作必需 |
| Agent Teams（v2.1.117+ 实验） | 共享 task board | 实验阶段，暂不入产线 |

**Anthropic 官方 Writer/Reviewer 双 session**：A 写代码，B 在 fresh context review——避免"自己写自己审"偏见。<Platform> 关键代码（payment/wallet/migration）默认采用。

---

## §3 仓库与工具栈选型 — 实施期决策

### 3.1 实施期仓库形态决策

<Platform> 文档当前用 "parent + submodule" 形态（**仅文档合理**——文档型 submodule 没有跨仓原子改动需求）。代码阶段不要延续此模式，3 个真候选：

| 候选 | 描述 | 优点 | 缺点 | 推荐度 |
|------|------|------|------|--------|
| **A. 代码也做 submodule** | <backend-repo> / -flutter / -web 作为 submodule 挂回 parent | 入口统一 | **两边好处都没拿到**——跨仓原子性无、submodule 操作复杂 | ★☆☆☆☆ |
| **B. Multi-repo** | 每个端独立 GitHub repo | 启动简单、权限按仓粒度 | 跨端原子改动 = N 个 PR 串联；共享类型靠 codegen 兜；CI 看不到全局；AI 跨端重构看不全 | ★★★☆☆ |
| **C. Monorepo + Turborepo/Nx**（推荐） | 单 `quantix-platform` 仓 + workspace + build graph | 跨端原子 PR；共享类型直接 import；schema 漂移 CI 立挂；AI 上下文最全；CODEOWNERS 路径级 review | 需 1 名 DevOps 扛 Turborepo/Nx 起步 | **★★★★★** |

#### 推荐：**C（Monorepo）+ 极少独立 repo**

**主体**：单仓 `quantix-platform/` —— Turborepo（轻）或 Nx（重）作 build graph，承载 backend / flutter / web / contracts 全部代码。  
**例外独立 repo**：仅当出现以下场景才拆出去——

| 场景 | 是否真需要 | <Platform> 当前判断 |
|------|----------|---------------|
| 监管强制"代码必须留在 X 国 git host" | ✅ | 暂无 |
| 外包 / 第三方合作方接入 | ✅ | 暂无；未来按 §3.4 方案处理 |
| 收购 / 分拆代码 | ✅ | 远期不考虑 |
| "高敏感模块普通工程师不能看"（钱包/<identity-verification>/资金等） | ❌ **不需要**——白盒更安全；敏感的是**数据和密钥**，靠 Vault/KMS/部署密钥/数据库 RBAC 隔离，**与 repo 组织无关** | 无 |

**核心澄清**："代码可见性"不是安全控制（Security through obscurity 是反模式）。真正要隔离的是**数据 + 密钥 + 部署权限**，那 3 个跟 monorepo 还是 multi-repo **没有关系**。Monorepo + CODEOWNERS + Vault/KMS + 数据库 RBAC + OIDC 部署环境隔离，足以扛金融场景。

**Monorepo 内部权限怎么做**：
- **流程权限**：CODEOWNERS 路径级强制 review（`/backend/wallet/** @wallet-team @security-team`）
- **CI/部署**：Turborepo `affected` / Nx `affected` 只跑改动相关项目；部署密钥按 GitHub Environment 绑（wallet pipeline 拿不到 trading 的 prod secret）
- **审计**：所有 PR review 与 merge 留痕；secret scanning 全仓跑

#### <Platform> 实施期仓库形态

```
<platform>/                  ← 文档父仓（保留现状，文档型 submodule）
  tech-docs/                  ← submodule
  tech-standards/             ← submodule
  <docs-repo>/               ← submodule
  team-operating-model/       ← submodule
  ai-workflow/                ← 本仓 AI 协作研究

quantix-platform/             ← 代码 Monorepo（新建，独立 GitHub repo）
  apps/
    backend-trading/          (Go)
    backend-account/          (Go)
    backend-wallet/           (Go) — CODEOWNERS @wallet @security
    backend-<identity-verification>/              (Go) — CODEOWNERS @<identity-verification> @compliance
    web-terminal/             (TS)
    web-admin/                (TS)
    mobile/                   (Flutter)
  packages/
    api-contracts/            ← OpenAPI/Protobuf/AsyncAPI 单源 + codegen
    shared-types/             ← 跨端共享类型/枚举/错误码
    shared-ui/                ← Web/Flutter 共享设计 token
  .github/workflows/          ← ai-review / schema-diff / test / build
  .claude/                    ← skills/ agents/ hooks/（单源）
```

仅当未来出现监管或外包硬需求时，再拆 `quantix-{module}/` 独立 repo。

### 3.4 外包接入方案（未来真有外包时按场景选）

| 方案 | 实现 | 适用场景 |
|------|------|---------|
| **接口隔离 + Mock 仓** | 独立 `quantix-mobile-contracts/`（OpenAPI + Prism mock + 生成的 client stub），外包对 mock 开发 | **外包做移动/前端最佳** |
| **独立 repo** | 拆出 `quantix-{外包模块}/` 给外包 push，本方 review 合并 | 局部模块外包（落地页、独立工具） |
| **JIT 临时账号** | SSO/SCIM 临时账号 + repo 级权限 + 自动到期 | 短期项目 |
| **VDI / Codespaces 企业版** | 代码不落本地盘 | 高敏感（<Platform> 一般用不到） |

**反模式**：把外包加为整个 monorepo collaborator 然后"靠 CODEOWNERS 兜"——外包能 clone 全部 history，**CODEOWNERS 只挡 merge 不挡 read**。

### 3.2 工具栈推荐（按角色）

承 [04 工具全景](04_tool-landscape-2026.md) 的 <Platform> 推荐组合，按角色再拆：

| 角色 | 立项期 | 实施期 |
|------|--------|--------|
| **架构师 / 文档** | Claude Code + Cursor + archify/prd-writing skills | Claude Code（Plan Mode 设计 ADR）+ Cursor |
| **后端开发** | (旁观) | **Claude Code 主** + Codex CLI（CI/批改）+ Cursor（IDE）+ Codex Cloud（长任务） |
| **移动开发** | (旁观) | Cursor 主 + Claude Code 辅 + Copilot |
| **前端开发** | (旁观) | Cursor 主 + Claude Code 辅 + Copilot |
| **DevOps / 平台** | Claude Code | Claude Code + Codex CLI（Infra as Code） |
| **测试** | — | Codex CLI fan-out + Claude Code（test plan）+ Aider（局部修测试） |
| **Code Review** | 人审 + archify-format-audit skill | **CodeRabbit** + Claude `/security-review` + 人审 |
| **PM / BA** | Claude Code + prd-writing skill | Claude Code + Linear MCP |

### 3.3 AI Review 工具三选一

| 工具 | 优势 | 劣势 | <Platform> 适配 |
|------|------|------|------------|
| **CodeRabbit** | 1.5M+ repo 覆盖，多语言强，中文 review，PR 评论体验好 | 整 codebase 索引一般 | **★★★★★ 主选** |
| **Greptile** | codebase-wide 索引强，跨文件理解好 | 价格高，中文一般 | ★★★☆☆ 备选（大重构期切） |
| **Cursor Bugbot** | 与 Cursor IDE 一体 | 仅服务 Cursor 用户 | ★★☆☆☆ 个人补充 |

**<Platform> 决策**：CodeRabbit 入 CI 作为 L1 强制；本地 `claude /security-review` 作为 L0 自查；Bugbot 留给个人订阅自选。

---

## §4 跨端与跨语言上下文同步

**问题**：实施期 Backend(Go) / Flutter(Dart) / Web(TS) 同时改，API 契约、错误码、事件 schema **不能漂移**。

> **Monorepo 优势在此显现**：`packages/api-contracts/` 是 workspace package，三端直接 import；改 spec → 三端 codegen → 一个 PR 验完——multi-repo 要拆 N 个 PR 串联。

### 4.1 三种同步机制对比

| 机制 | 实现 | 一致性 | 维护成本 | <Platform> |
|------|------|--------|---------|---------|
| **契约单源 + codegen + workspace import**（Monorepo） | `packages/api-contracts/` workspace package，三端 codegen 进 `packages/shared-types/`，三端直接 import | **强（编译期 + 一个 PR 原子）** | 低 | **主用** |
| **契约 codegen 跨独立 repo 发包** | 仅当模块拆独立 repo 时；npm/go module 私有发包 | 中（版本号管理痛苦） | 中 | 仅外包场景用 |
| **Skill reference 共享** | `.claude/skills/qx-api-conventions/reference.md` | 中（靠 AI 自觉） | 低 | 辅用（约束 AI 命名风格） |
| **MCP server 暴露 schema** | 自建 MCP 读 tech-standards | 中（按需查） | 高 | 暂不上 |

### 4.2 跨端 PR 工作流（Monorepo 原子模式）

```
# Monorepo 推荐姿势：一个分支 → 一个 PR → 跨端原子改完
cd quantix-platform
git checkout -b feat/QX-1234-add-stop-loss

[session 1] claude
  → 改 packages/api-contracts/openapi.yaml
  → turbo run codegen  （自动 regenerate go/dart/ts client）
  → 跨 apps/backend-trading/、apps/mobile/、apps/web-terminal/ 同时改实现
  → turbo run test --filter=...[main]  （只跑 affected）

→ 提单 PR：QX-1234-add-stop-loss
  - CI: schema diff ✓ / 三端 test ✓ / CodeRabbit ✓
  - CODEOWNERS auto-request: @trading-team @mobile-team @web-team
  - 一次 merge，三端原子上线
```

**纪律**：
- **跨端改动**：Monorepo 内一个 PR 原子完成；不要拆 N 个 PR
- **单端改动**：仍单 PR 即可；Turborepo `affected` 只跑相关 CI
- **大型重构**：开 `git worktree` 并行多 Claude session，互不阻塞
- **不要乱用云端 long-horizon**：能在 PR 内完成的不开 Codex Cloud

---

## §5 立项 → 实施 过渡 Checklist（首个 service 启动前必备）

quantix-platform 第一个服务 PR 之前，**以下清单必须 100% 就位**（quantix-platform 仓建好但暂不开放业务 PR）：

### 5.1 文档/规范类（tech-docs / tech-standards 责任）

- [ ] **tech-standards/STD-01-coding/** — 各语言（Go/Dart/TS）的命名/格式/lint
- [ ] **tech-standards/STD-02-api/** — OpenAPI 模板 + codegen 工具链
- [ ] **tech-standards/STD-03-data/** — 字段命名、时间戳、货币、ID 规则
- [ ] **tech-standards/STD-04-events/** — AsyncAPI / 事件命名 / topic naming
- [ ] **tech-standards/STD-05-security/** — secrets / auth / encryption / PII
- [ ] **tech-standards/STD-06-observability/** — 日志/指标/trace 字段约定
- [ ] **tech-standards/STD-07-testing/** — 单测/集测/压测 准入门槛
- [ ] **tech-standards/STD-08-deployment/** — 部署 manifest / CI pipeline 模板
- [ ] **tech-docs/services/<svc>/** — 第一个服务的详设已 stable

### 5.2 协作 SOP（team-operating-model 责任）

- [ ] **05_技术实施周期SOP.md** — 写明 Spec→Plan→Code→Review 四段（每段 deliverables / DoD）
- [ ] **PR 模板**（`.github/pull_request_template.md`）含：跨仓 PR 链接 / Closes # / AI Review 结果
- [ ] **Issue 模板** — 区分 spec / bug / chore，强制带验收用例
- [ ] **Code Review checklist** — L2 人审专用

### 5.3 AI Coding 基础设施（ai-workflow 责任）

- [ ] **AGENTS.md / CLAUDE.md 单源策略**就位（quantix-platform monorepo 在仓根 + 关键 apps/<svc>/CLAUDE.md 分层；文档父仓 <platform> 各 submodule 现状保留，按 01 结论）
- [ ] **`.claude/skills/qx-*` 6 个核心 Skill** 已建并测试通过（按 07 §6.1）
- [ ] **`.claude/agents/qx-*` 6 个 Subagent** 已建（按 06 §0）
- [ ] **Hook 红线脚本**——拦 `rm -rf` / `git push --force` / 改 migrations / push prod
- [ ] **`scripts/sync-skills.py`**——把 `.claude/skills/` 同步到 `.cursor/rules/` + `.github/prompts/`（按 07 I-7）；monorepo 内单源即可，文档父仓 <platform> 与 quantix-platform 之间用 git submodule 引用或 CI mirror

### 5.4 CI/CD（DevOps 责任）

- [ ] **`.github/workflows/ai-review.yml`** — CodeRabbit + Claude `/security-review` 双跑，block merge
- [ ] **`.github/workflows/schema-diff.yml`** — 检测 OpenAPI/Protobuf/AsyncAPI 跨仓漂移
- [ ] **`.github/workflows/test.yml`** — 单测 + 集测必跑
- [ ] **`.github/workflows/build.yml`** — 多语言 build 矩阵
- [ ] **Pre-commit hooks**（lefthook/husky）— lint + secrets 检测 + SKILL.md 同步检查

### 5.5 工具账号 / 订阅（采购责任）

- [ ] CodeRabbit 团队订阅
- [ ] Claude Code Max（团队级）
- [ ] OpenAI Codex Cloud（按需）
- [ ] Linear / Jira（任务管理）
- [ ] Sentry / Datadog（观测）

---

## §6 立项期的具体下一步（<Platform> 本周可执行）

| # | 动作 | 责任 | 产物位置 | 预计 |
|---|------|------|---------|------|
| 1 | 起草 **05_技术实施周期SOP.md**（四段流水线 + <Platform> 化字段） | 架构 + 运营 | `team-operating-model/03_协作流程/05_技术实施周期SOP.md` | 2 天 |
| 2 | 起草 **6 个 qx-* Skill** 初版（commit/review-pr/release/migrate-service/arch-diagram/prd-extract） | AI 协作负责人 | `<platform>/.claude/skills/qx-*/SKILL.md` | 2 天 |
| 3 | 起草 **6 个 qx-* Subagent** 初版 | 同上 | `<platform>/.claude/agents/qx-*.md` | 1 天 |
| 4 | 校准 **AGENTS.md / CLAUDE.md 单源**——全部 submodule 检一遍 | 各 submodule owner | 各 submodule 根 | 半天 |
| 5 | 写 **scripts/sync-skills.py** + pre-commit hook | DevOps | parent repo | 1 天 |
| 6 | 选型 **AI Review 工具**（CodeRabbit 试 1 个月） | 架构 | 试用账号 | 1 天 |
| 7 | 起草 **首个 service 启动 checklist**（本文 §5）作为团队 onboarding 文档 | 运营 | `team-operating-model/03_协作流程/06_首服务启动_checklist.md` | 1 天 |
| 8 | 起草 **PR / Issue 模板** | 运营 | 各 repo `.github/` 模板 | 半天 |

**4 段流水线先在文档活动内 dry run**：用立项期"PRD/tech-docs 编写"作为试点，跑通 SPEC→PLAN→CODE→REVIEW 四段（已在 `tech-docs/_audits/` 部分体现），把卡点暴露出来，再迁到代码活动。

---

## §7 业界标杆案例（公开来源）

| 团队 | 工作流 | 启示 |
|------|--------|------|
| **Anthropic 内部** | Plan Mode → Implement → Writer/Reviewer 双 session；CLAUDE.md 短而精；Hook 强制 lint | [Best Practices](https://code.claude.com/docs/en/best-practices) |
| **Sourcegraph** | Cody codebase 索引；PR 由 Cody 出第一稿 review；MCP 暴露内部知识库 | sourcegraph.com/blog |
| **Stripe** | Spec-First；AI 自动列 PR 影响的下游 service；强制 ADR 入仓 | stripe.com/engineering 公开演讲 |
| **Shopify** | Cursor + Claude Code 并用；`.cursor/rules` + `.claude/skills` 双源同步脚本；强制对应 test | shopify.engineering |
| **GitHub** | Copilot Coding Agent 接收 Issue → 起 branch → 提 PR → CI 自动跑 | docs.github.com/copilot |
| **Cursor 团队（自营）** | Cloud Agents（旧称 Background Agents）+ Bugbot；PR 在内部 review 才合并 | cursor.com/blog |

**共性 3 条**（<Platform> 必须遵守）：
1. 强制 plan/spec 入仓——不允许 AI 直接 commit main
2. AI Review 在 CI 必跑——L1 不通过 = block merge
3. 小步 PR / 高频——平均 PR <500 行

---

## §8 反模式 8 项

| # | 反模式 | 修复 |
|---|--------|------|
| 1 | 立项期不沉淀 SOP/Skill，等实施期"边写边发明" | §5 checklist 先行 |
| 2 | 让 AI 直接在 main / master 改 | branch 保护 + PR 必跑 AI review |
| 3 | CLAUDE.md 写 1000+ 行 | 拆 Skill 按需加载；CLAUDE.md ≤200 行 |
| 4 | 一个 session 横跨多个不相关任务（"kitchen sink"） | 任务间 `/clear` |
| 5 | 大型重构不开 worktree、多 Claude 抢同一文件树 | 每会话独立 worktree |
| 6 | AI Review 当摆设（CI 跑了但人不看） | L1 标红必处理；CI block merge |
| 7 | 跨仓 PR 不串编号 / 不锚 Issue | PR 模板强制 `Closes #` + 跨仓链接 |
| 8 | 提交 AI 生成代码不跑测试（"trust-then-verify gap"） | pre-commit 强制跑 test |

---

## §9 <Platform> 启示（I-1 ~ I-12）

| # | 启示 | 落地位置 | 阶段 |
|---|------|---------|------|
| **I-1** | **立项期就把 §5 checklist 全部就位**，等 quantix-platform 第一个 service PR 前完成 | `team-operating-model/03_协作流程/06_首服务启动_checklist.md` | 立项期 |
| **I-2** | **4 段流水线**（Spec→Plan→Code→Review）写成 SOP，所有团队铁律 | `team-operating-model/03_协作流程/05_技术实施周期SOP.md` | 立项期 |
| **I-3** | 实施期仓库形态选 **C（Monorepo + Turborepo/Nx）**，单 `quantix-platform` 仓承载 backend/web/mobile/contracts；文档父仓 <platform> 保留现状（仅文档型 submodule） | 架构 ADR | 过渡决策 |
| **I-4** | **L1 AI Review 在 CI 必跑**（CodeRabbit + Claude `/security-review`），block merge | `.github/workflows/ai-review.yml` | 实施期 |
| **I-5** | 跨端改动 **Monorepo 内单 PR 原子完成**；跨独立 repo 才拆多 PR + Ticket 串联 | PR 模板 + Turborepo affected | 实施期 |
| **I-6** | **6 个 qx-* Skill + 6 个 qx-* Subagent** 立项期建好；parent repo 单源 + sync 脚本分发 | `.claude/skills/` `.claude/agents/` | 立项期 |
| **I-7** | CLAUDE.md ≤200 行；长 reference 进 Skill；强制规则进 Hook | 各 repo CLAUDE.md 模板 | 持续 |
| **I-8** | 跨语言契约：标准（命名/格式/红线）在 `tech-standards/STD-02-api`；可执行 spec + codegen 在 `quantix-platform/packages/api-contracts/`，CI 验 schema 不漂移 | tech-standards + monorepo workspace | 立项期定 + 实施期跑 |
| **I-9** | Worktree 作为多 Claude 并行的唯一隔离机制 | SOP 写明 | 实施期 |
| **I-10** | **Writer/Reviewer 双 session 模式**作为关键代码（payment/wallet/migration）默认 | Skill `qx-paired-review` | 实施期 |
| **I-11** | Long-horizon 任务必绑 Linear/Jira issue ID；Codex Cloud / Web 起任务时写 `Closes QX-1234` | SOP | 实施期 |
| **I-12** | **立项期用四段流水线 dry run 文档活动**——把卡点暴露在文档期，不要带进代码期 | `tech-docs/_audits/` 已部分实现，固化为模板 | 立项期 |

---

## §10 未尽事项（→ 后续文档）

1. **AI Review 工具选型 PoC**（CodeRabbit vs Greptile vs Bugbot）——转 08
2. **CI/CD 与 AI agent 的具体集成模板**（GitHub Actions / GitLab CI 实际 yml）——转 08
3. **Long-horizon 任务的可观测性**（成本 / 时长 / 触发率仪表盘）——转 08
4. **<Platform> 4 段流水线 SOP 模板**（含 SPEC.md / PLAN.md 字段定义）——转 09 业界 SOP 后给具体模板
5. **AI 改 migration / schema 的安全策略**（hook + 人审 + dry-run）——转 08
6. **首服务启动 checklist** 的实际 markdown 模板——转 team-operating-model 在地起草
7. **Plugin 跨 repo 分发**（实施期 Skill 从 symlink 升级为 plugin）——转 07 + 续篇

---

## §11 参考链接索引（一手）

1. Anthropic Claude Code Best Practices — <https://code.claude.com/docs/en/best-practices>
2. Claude Code Common Workflows — <https://code.claude.com/docs/en/common-workflows>
3. Claude Code Worktrees — <https://code.claude.com/docs/en/worktrees>
4. Claude Code on the Web — <https://code.claude.com/docs/en/claude-code-on-the-web>
5. Agent Teams（实验） — <https://code.claude.com/docs/en/agent-teams>
6. Claude Code Headless（CI 集成） — <https://code.claude.com/docs/en/headless>
7. Plan Mode — <https://code.claude.com/docs/en/permission-modes>
8. CodeRabbit — <https://www.coderabbit.ai/>
9. Greptile — <https://www.greptile.com/>
10. Cursor Cloud Agents + Bugbot — <https://cursor.com/docs/cloud-agents>
11. GitHub Copilot Coding Agent — <https://docs.github.com/copilot/concepts/about-copilot-coding-agent>
12. Devin — <https://devin.ai/>
13. OpenAI Codex Cloud — <https://developers.openai.com/codex>
14. Shopify Engineering — <https://shopify.engineering>
15. Sourcegraph Blog — <https://sourcegraph.com/blog>
16. Turborepo Docs — <https://turborepo.com/docs>
17. Nx Docs — <https://nx.dev/getting-started/intro>
18. GitHub CODEOWNERS — <https://docs.github.com/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners>
19. OWASP "Security through obscurity" — <https://owasp.org/www-community/Avoid_security_by_obscurity>

---

**前置**：[01 入口文件](01_entry-file-support-matrix.md) · [02 编程范式](02_coding-paradigms-2026.md) · [04 工具全景](04_tool-landscape-2026.md) · [06 子代理编排](06_subagent-orchestration.md) · [07 Skills](07_skills-and-prompts.md)  
**后续**：08 质量/安全/评估 · 09 业界 SOP 标杆 · A1 SOP 评审
