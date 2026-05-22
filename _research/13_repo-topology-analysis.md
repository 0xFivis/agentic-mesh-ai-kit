<!-- REFERENCE ONLY: sanitized sample, not for production -->
# 13 · 仓库拓扑与 AI 方法论的最佳匹配（调研）

> 调研日期：2026-05-19
> 范围：基于 [ai-workflow/ai-agent-playbook.md](../ai-agent-playbook.md) + [_research/11_spec-driven-development-and-4phase.md](11_spec-driven-development-and-4phase.md)，回答"采用本方法论的项目应建成什么形态的仓库才是最佳实践"
> 类型：决策前调研，输出指向 ADR-0019

---

## 0 · TL;DR

- **结论**：**代码 Monorepo + 文档 / 标准 Submodule** 是最匹配本方法论的形态
- **核心驱动**：Spec-Kit `/speckit.implement` 与 4-Phase Bundle 都假设 `specs/` 与 `apps/` 同 git root
- **业界对照**：spec-kit 自身、Anthropic claude-cookbooks、Vercel turborepo 全部 monorepo；spec-kit 官方 quickstart `specify init my-project` 默认单仓
- **现状评估**：当前 <platform> parent + 7 个子仓的"文档维护仓"形态，使命已完成，进入编码后需切换至 monorepo

---

## 1 · 方法论对仓库形态的 6 条硬约束

| # | 约束 | 出处 | 失败后果（多仓） |
|---|---|---|---|
| 1 | `specs/NNN-<slug>/` 与代码同 git root | Spec-Kit `/speckit.implement` + playbook §1.6 | spec→code 路径解析中断，AI 无法落地 |
| 2 | `contracts/` 路径稳定，被 spec 引用 + 被 code 消费 | playbook §6.2 五件套 | code-gen / lint 链断裂 |
| 3 | R 横切（ADR/STD 改动）应能与 spec/code **同 1 PR** | playbook §4.4 R 行 + SOP §3.3 | 跨仓 PR 失原子性，回滚困难 |
| 4 | AI Context Bundle 一次 ingest 9 项 | playbook §1.6 | 跨仓 clone/path 切换增 token、增错率 |
| 5 | CI gate 在代码 PR 上拦截 | playbook §7.2 | 文档仓的 CI 无法保护代码质量 |
| 6 | CODEOWNERS 按 BC/合规边界分审批 | SOP §3.5 | 跨仓审批权限矩阵难维护 |

**关键洞察**：约束 1~5 都强烈偏向 **specs/code 同根**；只有约束 6 在 multi-repo 与 monorepo+CODEOWNERS 之间打平。

---

## 2 · 业界基准对照

### 2.1 GitHub Spec-Kit 自身（102k★）

仓结构（quickstart `specify init my-project` 产物）：

```
my-project/
├── .specify/                # 模板 + 预设 + 扩展
│   ├── templates/
│   ├── presets/
│   └── extensions/
├── specs/                   # ← spec 五件套 SoT，与代码同根
├── memory/
│   └── constitution.md
├── .claude/ 或 .codex/      # 按所选 integration 落入
├── AGENTS.md
└── <你的 apps/packages>
```

**关键证据**：

- 官方 README 第 2 步 `specify init my-project --integration copilot` 默认**单仓 single root**
- `/speckit.implement` 是相对路径 `specs/NNN-feature/` 直接生成 / 修改源码
- 模板系统（`.specify/templates/overrides/`）只对**当前仓**生效

### 2.2 Anthropic claude-cookbooks（43k★）

```
claude-cookbooks/
├── .claude/                 # skills / agents / hooks
├── CLAUDE.md
├── capabilities/            # 按能力域分包
├── claude_agent_sdk/
├── managed_agents/
├── skills/
├── tool_use/
└── ...                      # 全部领域代码同根
```

**关键证据**：

- 全 monorepo，按"能力域"而非"前后端"切分目录
- `.claude/` 进入 git 共享；`CLAUDE.md` 单根（不分 sub-CLAUDE）

### 2.3 Vercel turborepo（30k★，**多语言 monorepo 标杆**）

```
turborepo/
├── apps/docs/               # Next.js docs site
├── packages/                # 共享库
├── crates/                  # Rust 工作区
├── cli/                     # CLI
├── docs/link-checker/
├── examples/                # 数十个示例
├── turborepo-tests/
├── AGENTS.md
├── pnpm-workspace.yaml      # JS 工作区
├── Cargo.toml               # Rust 工作区
├── turbo.json               # Turborepo 配置
└── .github/                 # CI gate（Rust + TS + MDX 统一）
```

**关键证据**：

- 跨语言（Rust 70% + TS 19% + MDX 10%）一个仓搞定
- `AGENTS.md` 单根；CI workflows 一个 `.github/`
- 这是"backend + web + 文档"三件套 monorepo 的标准范式

### 2.4 反例 · 多仓但靠 npm package 分发 spec

理论候选：把 spec / contracts 单独发包（如 `@quantix/contracts`），多个代码仓 npm 安装消费。

**实际问题**：

- `/speckit.implement` 不认 npm 包路径，需自研适配
- contracts 改动要先发 npm → 跨仓 bump → 跨仓 PR，节奏倍增
- AI session 跨仓切换，Bundle ingest 破碎

**结论**：除非已是大企业 polyrepo 强约束环境，否则不推荐。

---

## 3 · 4 个候选拓扑评分

| 维度 / 权重 | A 全合一 Mono | **B 代码 Mono + 文档 Sub** | C 全分仓（现状） | D Spec 中央仓 + 代码 polyrepo |
|---|---|---|---|---|
| C1 specs/code 同根 (10) | 10 | 10 | 0 | 0 |
| C2 contracts 路径稳定 (8) | 8 | 8 | 2 | 5 |
| C3 R 横切原子 PR (7) | 7 | 5 | 0 | 0 |
| C4 Bundle 一次 ingest (9) | 9 | 8 | 2 | 3 |
| C5 CI gate (8) | 8 | 8 | 4 | 8 |
| C6 审批分层 (6) | 4 | 6 | 6 | 6 |
| 跨语言 build 复杂度 (-5) | -3 | -3 | -1 | -1 |
| 仓体积控制 (-4) | -4 | -2 | -1 | -1 |
| PM 自治 (5) | 2 | 5 | 5 | 5 |
| AI session 切换成本 (-7) | -7 | -6 | -1 | -1 |
| **加权总分** | **34** | **39** | **16** | **24** |

**B 胜出**，主因：保留 PM 与横切团队的自治节奏，同时把 spec/ADR/code 关键三件强绑同根。

---

## 4 · 推荐拓扑 B · 详细形态

```
<product>-platform/                  # 主 git root（编码 + 决策 SoT）
├── memory/
│   └── constitution.md              # ≤9 条不变原则（playbook §1.6 第 2 项）
├── specs/                           # Spec-Kit SoT
│   └── NNN-<slug>/
│       ├── spec.md
│       ├── plan.md
│       ├── data-model.md
│       ├── contracts/               # ← 被 packages/contracts/ 直接消费
│       ├── quickstart.md
│       └── tasks.md
├── packages/                        # 跨 app 共享
│   ├── contracts/                   # 从 specs/*/contracts/ build
│   ├── shared-types/
│   └── ui-kit/
├── apps/
│   ├── backend/                     # Node/Go/Python services
│   ├── web/                         # Next/React
│   └── mobile/                      # Flutter
├── docs/                            # 与代码同根 ← 关键反直觉点
│   ├── architecture/                # 顶层 8 篇（原 tech-docs/01~08）
│   ├── adr/                         # ADR 库（R 横切同 PR 必须）
│   └── services/                    # service SDD
├── .claude/                          # 示例 agent；Cursor=.cursor/  Copilot=.github/  Codex=.codex/
│   ├── rules/
│   ├── skills/                      # 11 个 Skill
│   ├── agents/                      # explorer / reviewer
│   └── settings.json                # Hook（PostToolUse 等）
├── .specify/                        # Spec-Kit 模板 + overrides
├── .github/
│   ├── workflows/                   # lint / test / contract-lint / security / canary
│   ├── ISSUE_TEMPLATE/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── CODEOWNERS                   # apps/* + docs/adr/* + packages/contracts/* 分审批
├── scripts/
│   ├── spec-init.sh
│   ├── contracts-build.sh
│   └── verify-bundle.sh
├── AGENTS.md                        # 5 节单源
├── CLAUDE.md                        # → AGENTS.md
├── pnpm-workspace.yaml              # JS 工作区
└── README.md

# Submodules（外部自治，只读消费）
├── product-docs/        @submodule  # PRD + 原型 + UIKit + 竞品（PM 主）
└── tech-standards/      @submodule  # STD-01~08（架构组主）
```

### 4.1 为什么 `docs/` 进主仓而非 submodule（关键反直觉点）

**原因**：约束 #3。R 横切场景下，改 ADR 与改 spec/contracts 必须**1 个 PR 完成**：

- 若 ADR 在 submodule：需 2 个 PR + 指针 bump，AI agent 体验崩坏
- 若 ADR 在主仓：1 个 PR atomic，CI 一次跑过

**判别标准**：

| 内容 | 与编码节奏耦合度 | 应放位置 |
|---|---|---|
| 顶层架构 / ADR / service SDD | 高（每个 R 都改） | 主仓 `docs/` |
| 横切标准 STD-01~08 | 中（季度更新） | submodule `tech-standards/` |
| PRD / 原型 / UIKit / 竞品 | 低（PM 节奏） | submodule `product-docs/` |
| 方法论（playbook / SOP） | 跨项目复用 | 独立仓 `ai-workflow/`（git subrepo 或独立） |

### 4.2 工具链建议

- **包管理**：pnpm workspace（JS/TS 轻量）
- **跨语言 build**：Turborepo（TS-first，最易上手）；如未来需要更强缓存可升 Bazel
- **Flutter**：apps/mobile/ 内用 `melos` 管理 dart packages
- **大文件**：git-lfs 限定 `apps/web/public/`、`apps/mobile/assets/`
- **submodule 自动更新**：CI 跑 `git submodule update --remote` + bot PR（每周）

---

## 5 · 从现状迁移路径（如决议走 B）

| 步 | 动作 | 风险 |
|---|---|---|
| 1 | 新建 `quantix-platform` 主仓 + Spec-Kit init | 低 |
| 2 | [tech-docs/](../../tech-docs/) 全量**复制**进 `quantix-platform/docs/`，原仓冻结归档 | 中（需 CI 链接重写） |
| 3 | [<docs-repo>/](../../<docs-repo>/) 改为 `product-docs` submodule 挂入 | 低 |
| 4 | [tech-standards/](../../tech-standards/) submodule 挂入 | 低 |
| 5 | [ai-workflow/](../) 内容拆：方法论保留独立仓（跨项目复用）；项目级 `.claude/` 配置移入主仓 | 中（需边界审计） |
| 6 | 当前 parent repo `<platform>` 改为 meta（README + 子仓索引）或 archive | 低 |
| 7 | 按 Bootstrap 模板（`ai-workflow/onboarding/project-bootstrap.md`）补 4 条 CI + `.claude/` + scripts | 中 |
| 8 | 跑 <identity-verification> L1 dry-run 验证 | 中（首次跑必有摩擦） |

预计工作量：**1~2 周完成结构搬迁；3~4 周完成首个 dry-run**。

---

## 6 · 风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
|---|---|---|---|
| 主仓体积膨胀（3 大 app + docs） | 中 | 中 | 用 git-lfs + sparse-checkout；Turborepo remote cache |
| 跨语言 CI 慢 | 高 | 中 | Turborepo task pipeline + matrix build；只跑 affected |
| submodule 不一致 | 中 | 中 | CI gate：submodule sha 与 main 锁定；bot 自动 bump |
| PM 不愿放弃独立仓节奏 | 低 | 低 | 保留 `product-docs` submodule，PM 工作流不变 |
| 监管审计要求代码隔离 | 低 | 高 | CODEOWNERS + branch protection 已可满足；若硬要求物理隔离，退至方案 D |

---

## 7 · 待 ADR 决策的开放问题

1. **方法论仓（ai-workflow）独立 vs 进主仓 `.ai/`**：跨项目复用 vs 单仓自洽
2. **product-docs 是否要保留 PRD 静态站点 Docsify**：保留则需要主仓不要重复部署
3. **第一个 sprint 跑哪个 feature**：<identity-verification> L1 vs 资金充值 vs <external-system> 集成
4. **monorepo 工具链**：Turborepo vs Nx vs 纯 pnpm workspace
5. **是否安装官方 Spec-Kit CLI**：是 → `.specify/` 标准；否 → 仅用 `scripts/spec-init.sh` 兜底

以上 5 个问题在 ADR-0019 决议中应明确给出答案。

---

## 8 · 参考资料

- [GitHub Spec-Kit · README](https://github.com/github/spec-kit#readme) — 单仓 quickstart
- [Anthropic claude-cookbooks · 仓结构](https://github.com/anthropics/claude-cookbooks) — `.claude/` + monorepo by domain
- [Vercel turborepo · 仓结构](https://github.com/vercel/turborepo) — 跨语言 monorepo 范式
- [ai-workflow/_research/11_spec-driven-development-and-4phase.md](11_spec-driven-development-and-4phase.md) — SDD 与 4-Phase 调研（前置）
- [ai-workflow/_research/12_gap-analysis-quantix.md](12_gap-analysis-quantix.md) — quantix 落地差距（前置）
