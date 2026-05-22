<!-- REFERENCE ONLY: sanitized sample, not for production -->
# 09 · 业界 AI Coding SOP 标杆 — 2026/Q2 研究

> 前置：[03 大项目工作流](03_large-project-workflows.md) · [06 子代理编排](06_subagent-orchestration.md) · [08 质量/安全/评估](08_quality-security-evaluation.md)  
> 主题：8 个公开有 AI Coding SOP 的团队怎么干，共性 / 差异 / <Platform> 可抄的部分；最后给一份**<Platform> 综合 SOP 模板**。

---

## §0 一句话结论 + 立项期 5 件最重要的事

**业界 AI Coding SOP 在 2026 已收敛**——8 个标杆团队的做法 ≥80% 重叠：4 段流水线（Spec→Plan→Code→Review）、PR 必经 AI Review、关键路径 Writer/Reviewer 双 session、Long-horizon 任务异步化（Codex Cloud / Claude Web）。  
**剩下 20% 差异**主要在：①Spec-First vs Issue-First；②单 PR 体量上限；③人审强度；④AI agent 是否能自动 merge。

**<Platform> 立项期 5 件最重要的事**：

1. **抄 Anthropic 4 段流水线**——Explore → Plan → Implement → Commit，写进 SOP（每段产物固定）
2. **抄 Shopify "no PR without AI review" 政策**——L1 CI block，无例外
3. **抄 Stripe Spec-First**——所有 service feature 强制有 PRD/服务详设 + ADR 决策后才 plan
4. **抄 Anthropic Writer/Reviewer 双 session**——payment/wallet/migration/risk 4 类 PR 默认双 session
5. **抄 GitHub Copilot Coding Agent 模式**——Linear/Jira issue → claude/codex 接管出第一稿 PR；人 review 决定 merge

---

## §1 8 个标杆团队对照

| # | 团队 | 核心模式 | 来源 |
|---|------|---------|------|
| 1 | **Anthropic** | Explore→Plan→Implement→Commit 4 段；CLAUDE.md 短；Writer/Reviewer | code.claude.com/docs/best-practices |
| 2 | **OpenAI** | Codex CLI 主；Codex Cloud 跑 long-horizon；AGENTS.md 标准 | developers.openai.com/codex |
| 3 | **GitHub**（自营 + Copilot 团队） | Coding Agent：Issue → Branch → PR → CI；Copilot Workspace 出第一稿 | github.blog |
| 4 | **Stripe** | Spec-First；ADR 强制；AI 列下游 service 影响 | stripe.com/engineering |
| 5 | **Shopify** | "no PR without AI review"；`.cursor/rules` + `.claude/skills` 双源同步 | shopify.engineering |
| 6 | **Sourcegraph** | Cody codebase 索引；PR 由 Cody 出第一稿 review；自建 MCP | sourcegraph.com/blog |
| 7 | **Cursor**（自营） | Cloud Agents（旧称 Background Agents）跑批；Bugbot CI；本地 `.cursor/agents/` + Composer 主 | cursor.com/blog |
| 8 | **Vercel** | v0 出 UI；AI 写迁移；Sentry-AI debug | vercel.com/blog |

---

## §2 共性 SOP（8 团队 ≥6 家共用，强建议 <Platform> 照抄）

### 共性 1：四段流水线（无人不用）

```
1. Spec / Explore     → 入口：PRD / Issue / ADR 草稿
                       产物：SPEC.md（验收用例）
                       AI 任务：interview 用户、读老代码、列影响面
2. Plan               → 入口：SPEC.md
                       产物：PLAN.md（步骤、风险、回滚方案）
                       AI 任务：Plan Mode，输出分步骤，等人放行
3. Implement          → 入口：PLAN.md
                       产物：代码 + 测试 + PR
                       AI 任务：Subagent 实现；Worktree 并行
4. Review / Commit    → 入口：PR
                       产物：merge + 文档更新 + 回滚锚点
                       AI 任务：CodeRabbit/Bugbot；人审业务
```

**8 团队全部采纳**。差异仅在命名：Anthropic 用 "Explore/Plan/Implement/Commit"；OpenAI 用 "Plan/Code/Review"；GitHub 用 "Issue→Branch→PR"。本质同构。

### 共性 2：CLAUDE.md / AGENTS.md 短且活

| 共识 | 做法 |
|------|------|
| 入口文件 ≤200 行 | 长 reference 进 Skill |
| 强制规则进 Hook | CLAUDE.md 是 advisory，Hook 是 deterministic |
| 跟代码一起 review | CLAUDE.md 改动也走 PR |
| 自动注入 | 不要手动 paste 进 prompt |

### 共性 3：L1 AI Review 在 CI 必跑

**8 团队 7 家在 CI 必跑 AI Review**（Cursor 自营除外，因为他们自己测）。block merge，无 "skip" 选项。

### 共性 4：Long-horizon 任务异步化

- **Anthropic**：Claude Code on Web（VM 保活）
- **OpenAI**：Codex Cloud
- **GitHub**：Copilot Coding Agent（云端跑）
- **Cursor**：Cloud Agents（旧称 Background Agents）

**共识**：开发者电脑不跑超过 1h 的任务；起到云端，issue ID 绑定，人下班继续跑。

### 共性 5：Issue / Ticket 绑定 + 强制可回滚锚点

- 所有 AI agent 任务必绑 Issue ID（Linear/Jira/GitHub Issue）
- PR 描述强制 `Closes #` + 跨仓 PR 互链
- AI 生成的 PR 打 `ai-generated` label 便于统计 + 回滚

### 共性 6：关键路径双 session（Writer/Reviewer）

Anthropic / Stripe / Sourcegraph / Shopify 都明确：**关键代码** = AI 写 + 另一个 fresh session AI 看 + 人审。

---

## §3 差异：4 个值得分析的分歧点

### 分歧 1：Spec-First vs Issue-First

| 派别 | 团队 | 流程 |
|------|------|------|
| **Spec-First**（强） | Stripe、Anthropic 内部、<Platform>（建议） | 必须先有 SPEC.md/PRD/ADR；AI 不允许直接接 issue 写代码 |
| **Issue-First**（轻） | GitHub Copilot Coding Agent、Cursor Background | Issue 文本就是 spec；AI 先写第一稿 PR，人在 PR 上 review |

**<Platform> 取舍**：**Spec-First**——金融场景必须有 PRD/服务详设作为 SoT；Issue-First 适合改 bug 或小功能。<Platform> 可允许 "<50 行 diff" 走 Issue-First 快通道。

### 分歧 2：单 PR 体量上限

| 团队 | 上限 | 说明 |
|------|------|------|
| Anthropic 内部 | 软上限 ~500 行 | 超了 reviewer 抱怨多 |
| Stripe | 软上限 ~400 行 | 强烈鼓励拆 |
| Shopify | 软上限 ~300 行 | 倡导"小步" |
| GitHub | 无强制，AI agent 倾向 ~200 行 | Coding Agent 自动拆 |

**<Platform> 建议**：软上限 **400 行 diff**；超了 PR 模板提示"考虑拆分"；硬上限 1000 行直接 block（CI 检查）。

### 分歧 3：AI 是否能自动 merge

| 派别 | 团队 | 说法 |
|------|------|------|
| **禁止** | Anthropic（公开博文）、<Platform> 建议、金融业普遍 | "AI 不接触 main，必经人审" |
| **限制场景允许** | GitHub（自家 dependabot 自动 merge 小补丁）、Vercel（doc-only PR） | 仅文档/依赖小升级 |
| **实验性允许** | 部分 startup | 全自动 pipeline；接受高回滚率 |

**<Platform> 决策**：**禁止 AI 自动 merge**，除了下面 3 类（仍需 L1 CI 全绿）：
1. 纯文档 PR（only `.md` / `tech-docs/`）
2. 依赖小版本升级（patch only，Dependabot）
3. CI/lint 配置无业务影响的 chore

### 分歧 4：Subagent 用得多深

| 派别 | 团队 |
|------|------|
| **轻量**（按需起 1-2 个） | 多数 startup |
| **重度**（多个常驻 agent + 编排） | Anthropic（Agent Teams 实验）、Sourcegraph |

**<Platform> 建议**：起步轻量（6 个 qx-* 按需起），半年后看 telemetry 决定是否上 Agent Teams。

---

## §4 每个团队的"一招值得学"

### 4.1 Anthropic — **Writer/Reviewer 双 session 模式**

A 写代码，B 在 fresh context review。**核心点**：B 不能读 A 的对话历史，只读最终 PR + spec，避免"自己审自己"偏见。  
**<Platform> 落地**：`qx-paired-review` Skill 化，关键代码默认开。

### 4.2 OpenAI — **AGENTS.md 跨模型标准 + Codex CLI fan-out**

AGENTS.md 是跨模型/跨 IDE 通用 spec（[01 已研究](01_entry-file-support-matrix.md)）；Codex CLI 一行 `codex exec` 可起 N 个并行任务跑批。  
**<Platform> 落地**：批量测试/批量 lint 修复用 Codex CLI fan-out。

### 4.3 GitHub — **Copilot Coding Agent：Issue → Auto-branch → PR**

在 Issue 上 `@copilot` 触发，自动开 branch、写代码、提 PR、跑 CI、贴评论。人只看 PR。  
**<Platform> 落地**：用 Claude Code Web 同模式；Linear ticket 加 "Claude" 标签触发自动起任务。

### 4.4 Stripe — **AI 列下游 service 影响 + 强制 ADR**

改 API 前 AI 自动 list 哪些下游 service 调这个 endpoint；ADR 模板写死 5 字段（Context / Decision / Status / Consequences / Alternatives）。  
**<Platform> 落地**：`qx-impact-analysis` Skill；ADR 模板已在 `tech-docs/adr/`。

### 4.5 Shopify — **`.cursor/rules` + `.claude/skills` 双源同步脚本**

单源 yaml 配置 → 脚本生成 `.cursor/rules/*.mdc` + `.claude/skills/*/SKILL.md` + `.github/prompts/*.prompt.md`。  
**<Platform> 落地**：[07 I-7](07_skills-and-prompts.md) `scripts/sync-skills.py` 已规划。

### 4.6 Sourcegraph — **Cody codebase 索引 + 自建 MCP**

把整个 codebase 索引成向量库，AI 查代码先走索引而非 grep；自建 MCP server 暴露 wiki/runbook/服务详设。  
**<Platform> 落地**：远期可选，立项期不上；用 Claude `--add-dir` + Skill reference 足够。

### 4.7 Cursor — **Cloud Agents + Bugbot CI**（Cloud Agents 旧称 Background Agents）

Cloud Agents 在云端跑长任务（多入口：cursor.com/agents + Slack/GitHub/Linear/API）；Bugbot 是 Cursor 自营 AI Review，IDE 内可直接评论。  
**<Platform> 落地**：Bugbot 留个人订阅；团队级 AI Review 用 CodeRabbit。

### 4.8 Vercel — **v0 出 UI 第一稿 + Sentry-AI debug**

v0 把 prompt 转 UI 组件代码；Sentry-AI 自动分析 runtime error 提修复 PR。  
**<Platform> 落地**：v0 远期可用于 Admin 后台原型；Sentry-AI 可在实施期评估。

---

## §5 <Platform> 综合 SOP 模板（建议入 `team-operating-model/03_协作流程/05_技术实施周期SOP.md`）

```
┌────────────────────── <Platform> 技术实施周期 SOP ──────────────────────┐
│                                                                       │
│ STAGE 1: SPEC（必有产物 SPEC.md / PRD / ADR）                          │
│   触发：Linear ticket QX-NNNN 创建                                    │
│   产物：tech-docs/services/<svc>/spec/QX-NNNN.md                      │
│   AI 任务：Claude interview → 列影响面 → 写验收用例                    │
│   出口：spec PR merged + ADR（如必要）                                │
│                                                                       │
│ STAGE 2: PLAN（必经 Plan Mode + 人审）                                │
│   触发：spec merged                                                   │
│   产物：PR description 内的 PLAN section（步骤/风险/回滚）             │
│   AI 任务：Claude Plan Mode (Ctrl+G) 输出 plan → 人 review            │
│   出口：approve 才放行 implement                                     │
│                                                                       │
│ STAGE 3: IMPLEMENT（PR 驱动，软上限 400 行）                          │
│   触发：plan approved                                                 │
│   产物：代码 + 单测 + 集测 + 文档更新                                 │
│   AI 任务：Subagent 实现；关键代码 Writer/Reviewer 双 session        │
│   出口：所有 L1 检查全绿                                              │
│                                                                       │
│ STAGE 4: REVIEW（L1 自动 + L2 人审）                                  │
│   L1（自动 block merge）：                                            │
│     • CodeRabbit                                                     │
│     • Claude /security-review                                        │
│     • CodeQL SAST + Trivy SCA + gitleaks                            │
│     • 测试覆盖率 ≥80%                                                │
│     • schema diff（跨端）                                            │
│   L2（人审）：                                                       │
│     • service owner 看业务边界                                       │
│     • senior 看 tradeoff                                             │
│   出口：approve → squash merge                                       │
│                                                                       │
│ STAGE 5: POST-MERGE                                                  │
│   • AI label `ai-generated` 自动统计                                  │
│   • 4 指标仪表盘更新（通过率/回滚率/成本/finding）                    │
│   • Sentry 监控 7 天；revert 自动标 `ai-rollback`                     │
└───────────────────────────────────────────────────────────────────────┘
```

**关键纪律**（写进 SOP 强制条款）：
1. 跳段必须 ADR 记录原因
2. AI 不能自动 merge（除文档/依赖 patch/chore 3 类）
3. PR 软上限 400 行，硬上限 1000 行（CI block）
4. 关键代码（payment/wallet/migration/risk）必须 Writer/Reviewer 双 session
5. spec 必须先 merged 才能开 implement PR

---

## §6 反模式（业界踩过的坑）

| # | 反模式 | 出处 / 教训 |
|---|--------|----------|
| 1 | AI 直接接 issue 写大 PR（无 spec） | GitHub 早期 Coding Agent；导致一堆 "AI 写得很自信但错的方向" PR |
| 2 | CLAUDE.md 写成 SOP 长文（>500 行） | Anthropic 公开反复警告；token 浪费且 AI 忽略后半 |
| 3 | L1 AI Review 当摆设（CI 跑但人不看） | 多个 startup 教训；最终演变为 "AI 帮 AI 看，没人看" |
| 4 | Long-horizon 不绑 issue，开发者电脑跑过夜 | 普遍；电脑睡眠就死，无追溯 |
| 5 | Subagent 起一堆但不限 tools | 安全风险，权限失控 |
| 6 | 复制 Anthropic SOP 不本土化 | 失败模式：金融业抄 startup 节奏，监管不通过 |
| 7 | AI 写测试只为通过覆盖率，"恒真断言" | Shopify 公开教训，必须人审 assertion |
| 8 | 所有 PR 强制走全套门禁，doc/chore 也跑 30min CI | 反向影响速度；分流 fast-track 必要 |

---

## §7 <Platform> 启示（I-1 ~ I-10）

| # | 启示 | 落地位置 | 阶段 |
|---|------|---------|------|
| **I-1** | **抄 Anthropic 4 段流水线**作 SOP 主线；命名沿用 Spec/Plan/Implement/Review | `team-operating-model/03_协作流程/05_技术实施周期SOP.md` | 立项期定 |
| **I-2** | **Spec-First** 强制（>50 行 diff 必须有 SPEC.md / PRD）；<50 行 chore 允许 Issue-First 快通道 | SOP 写明 | 立项期定 |
| **I-3** | **AI 不能自动 merge**，3 类例外（doc/dep-patch/chore）；其余必经人 review | branch protection + bot 规则 | 立项期 |
| **I-4** | **PR 软上限 400 行 / 硬上限 1000 行**（CI block） | `.github/workflows/pr-size.yml` | 立项期 |
| **I-5** | **Writer/Reviewer 双 session** 对 payment/wallet/migration/risk 强制；做成 `qx-paired-review` Skill | `.claude/skills/qx-paired-review/` | 立项期 |
| **I-6** | **Long-horizon 必绑 Linear ticket** + Codex Cloud / Claude Web；开发者电脑禁跑 >1h 任务 | SOP + onboarding | 立项期 |
| **I-7** | **Issue → AI auto-PR 通道**：Linear ticket 加 `claude` label 触发自动出第一稿 PR | 自建 webhook + Claude Code Web | 实施期 |
| **I-8** | **Shopify 双源同步脚本**：`scripts/sync-skills.py` 单源 yaml → 三 IDE rule 文件 | parent repo | 立项期 |
| **I-9** | **AI 列下游 service 影响**：`qx-impact-analysis` Skill，改 API 必跑 | `.claude/skills/qx-impact-analysis/` | 立项期 Skill |
| **I-10** | **AI 写测试必人审 assertion**——SOP 写明；CI 检测"恒真断言"（mutation testing 周跑） | `tests/mutation/` + SOP | 实施期 |

---

## §8 未尽事项（→ A1 / 后续）

1. <Platform> SOP 模板的实际 markdown 起草 → `team-operating-model/03_协作流程/` 在地写
2. Linear/Jira AI 接管的具体 webhook 配置 → DevOps 在地
3. `qx-paired-review` / `qx-impact-analysis` / `qx-tdd` Skill 的 SKILL.md 实际内容 → `.claude/skills/` 在地
4. 业界标杆数据点（合并率 / 成本 / 回滚率）的持续追踪机制 → 季度 ADR 更新
5. 监管对 AI 生成代码的具体要求（GDPR / FCA / MiFID II / <jurisdiction-1> SFC / 新加坡 MAS）→ 独立合规专题
6. <Platform> 跟某个标杆做 1 个月并行 PoC（建议 Shopify SOP 抄完做 30 天对比）→ A1 评审给方法

---

## §9 参考链接索引（一手）

1. Anthropic Best Practices — <https://code.claude.com/docs/en/best-practices>
2. Anthropic Common Workflows — <https://code.claude.com/docs/en/common-workflows>
3. Anthropic Engineering Blog — <https://www.anthropic.com/engineering>
4. Anthropic Agent Teams（实验） — <https://code.claude.com/docs/en/agent-teams>
5. OpenAI Codex CLI — <https://developers.openai.com/codex/cli>
6. OpenAI Codex Cloud — <https://developers.openai.com/codex>
7. GitHub Copilot Coding Agent — <https://docs.github.com/copilot/concepts/about-copilot-coding-agent>
8. GitHub Blog（AI 工程文） — <https://github.blog/ai-and-ml/>
9. Stripe Engineering — <https://stripe.com/blog/engineering>
10. Shopify Engineering — <https://shopify.engineering>
11. Sourcegraph Blog — <https://sourcegraph.com/blog>
12. Cursor Blog — <https://cursor.com/blog>
13. Cursor Cloud Agents（旧 Background Agents）— <https://cursor.com/docs/cloud-agents>
14. Vercel v0 — <https://v0.dev/>
15. Vercel Blog — <https://vercel.com/blog>
16. Linear API（webhook 触发） — <https://developers.linear.app/docs>

---

**前置**：[03 大项目工作流](03_large-project-workflows.md) · [06 子代理编排](06_subagent-orchestration.md) · [08 质量/安全/评估](08_quality-security-evaluation.md)  
**后续**：A1 SOP 评审（_analysis/） · 00 总览
