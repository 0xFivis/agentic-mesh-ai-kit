<!-- REFERENCE ONLY: sanitized sample, not for production -->
# 12 · <Platform> 落地差距分析（Gap Analysis）

> 调研日期：2026-05-19
> 范围：把 [ai-workflow/](../) 方法论硬套到 <platform> workspace（<docs-repo> + tech-docs + tech-standards）跑一遍，找出缺口
> 类型：诊断报告（read-only），不含执行计划
> Agent 假设：以 **Claude Code** 为示例 agent（`.claude/` 路径为示例）；若选 Cursor / Copilot / Codex ，请对照 [project-bootstrap §3](../onboarding/project-bootstrap.md#3--%E5%BB%BA-agent-%E9%80%82%E9%85%8D%E5%B1%82rules--skills--agents--hooks) 替换为对应 dotdir（`.cursor/` / `.github/` / `.codex/`）

---

## 1. AI 方法论能力快照

[ai-workflow/](../) 定义了完整的 AI 协作体系：

- **4-Phase 循环**：Explore → Plan → Implement → Commit（[ai-agent-playbook.md §1.2](../ai-agent-playbook.md)）
- **11 个 Skill**：T0~T7 与 SOP 1:1 绑定（[§4.4](../ai-agent-playbook.md)）
- **2 个 Subagent**：explorer / reviewer（[§5.3](../ai-agent-playbook.md)）
- **规格五件套**：spec / plan / contracts / data-model / quickstart（[§6.2](../ai-agent-playbook.md)）
- **跨工具兼容**：Claude Code / Cursor / GitHub Copilot

**成熟度判断**：方法论设计完整度 ≈ 95%，但工程化落地 ≈ 0%（仓里无 `.claude/`、无 `scripts/spec-init.sh`、无 CI gate、无 `constitution.md`、无代码仓）。

---

## 2. 前置假设核查表

| 假设项 | 实际现状 | 阻塞级 |
|---|---|---|
| `scripts/spec-init.sh` | ❌ 不存在（仅 3 个 Python 脚本） | 🟠 半阻塞 |
| `<agent-dir>/`（示例：`.claude/` rules/skills/agents/settings.json） | ❌ 不存在 | 🔴 硬阻塞 |
| `memory/constitution.md` | ❌ 不存在 | 🔴 硬阻塞 |
| `.github/workflows/` 含 lint/test/contract-lint/security | ❌ 仅 `deploy-vercel.yml` | 🔴 硬阻塞 |
| 根 [AGENTS.md](../../AGENTS.md) 完整 5 节 | 🟡 仅 2 行 → CLAUDE.md | 🟠 半阻塞 |
| `.github/copilot-instructions.md` | ❌ 不存在 | 🟠 半阻塞 |
| [tech-standards/](../../tech-standards/) STD-01~08 | 🟢 完整 | ✅ |
| [tech-docs/adr/](../../tech-docs/adr/) | 🟢 18 篇 + PENDING | ✅ |
| [tech-docs/services/](../../tech-docs/services/) 详设 | 🟡 34 个目录只有 README 框架 | 🟠 |
| [<docs-repo>/prd/](../../<docs-repo>/prd/) | 🟡 <identity-verification> 最完整，其它 L1/L2/L3 不齐 | 🟠 |
| `<backend-repo> / flutter / web` 代码仓 | ❌ 全不存在 | 🟠 |
| Spec-Kit `/speckit.*` 安装 | ❌ 未安装（playbook 已允许脚本兜底） | 🟢 可选 |

---

## 3. Dry-Run：<identity-verification> L1 身份验证 走 T0→T6

选择理由：[<docs-repo>/prd/02_<identity-verification>/01_<identity-verification>-Overview.md](../../<docs-repo>/prd/02_<identity-verification>/01_<identity-verification>-Overview.md) 最完整，涉及 BC-08↔BC-07/09/04 三个依赖，代表典型业务流。

| 步 | 输入 | 应产出落点 | 卡点 |
|---|---|---|---|
| **T0 Intake** | PRD + constitution.md（❌缺） | `specs/042-<identity-verification>-l1-identity/spec.md` | 🟠 无 constitution → 自检无锚 |
| **T1 影响分析** | T0 + [tech-docs/01_业务上下文与限界上下文.md](../../tech-docs/01_业务上下文与限界上下文.md) | `specs/.../impact-map.md` | 🟡 service SDD 空；可能触发 R 横切 |
| **T2 详设五件套** | 五段 prompt 链：spec→plan→data-model→contracts→quickstart | `specs/042-<identity-verification>-l1-identity/{*.md, contracts/}` | 🔴 无 `contract-lint.yml` CI；🟠 STD 缺示例 |
| **T3 任务包** | T2 五件套 | `tasks.md` + 6~8 个 GitHub Issue | 🟠 `/speckit.taskstoissues` 不可用 → 脚本兜底 |
| **T4.1 写方案** | task 一行 + 五件套 | Issue body / tasks.md 扩展 | 🟠 `gate-checklist` Skill 未实装 |
| **T4.2 编码** | 五件套 + tasks.md | `<backend-repo>/services/<identity-verification>-service/` | 🔴 **代码仓不存在 → 完全不能跑** |
| **T4.3 评审** | PR diff | PR review record | 🟠 `reviewer` agent 未在 `.claude/agents/` 落地 |
| **T4.4 QA** | merged + quickstart.md | 测试报告 | 🟠 `qa-cases` Skill 未实装；无 stage 环境 |
| **T4.5 业务验收** | QA 报告 | 验收对照表 | ✅（纯人决策） |

**首处硬阻塞**：T2（contract lint CI）
**致命阻塞**：T4.2（代码仓 + CI gate 全缺）

---

## 4. SDD / Spec-Kit Gap

- ❌ `constitution.md` 不存在 — Spec-Kit 与 playbook §1.6 都强制要求
- ❌ `specs/NNN-<slug>/` 目录约定未落地（脚本未入仓）
- ❌ `tasks.md ↔ GitHub Issue` 镜像机制无（无 sync hook 也无 Issue 模板）
- ❌ 任务的 `verification:` 字段无 CI 验证管道支撑
- ✅ 五件套结构已在文档中定义清楚（playbook §6.2 + §1.6）
- ⚠️ 是否安装官方 Spec-Kit 未决（playbook 允许脚本兜底，建议先脚本）

---

## 5. 流程顺畅度四问

| 问题 | 结论 | 关键证据 |
|---|---|---|
| 新功能立项 → AI 产五件套？ | ⚠️ | 方法论完整 + PRD 完整，但缺 `constitution.md` & 11 个 Skill 实装，AI 没有 prompt 锚点 |
| 架构变更 R 横切？ | ⚠️ | ADR 模板齐，但 `adr-writing` skill 未实装；ADR ↔ spec/contracts 双向同步机制空白 |
| 编码产 microservice？ | ❌ | 代码仓不存在；`verification:` 指向的 npm scripts 也未定义 |
| CI 拦截劣质输出？ | ❌ | `.github/workflows/` 只有 deploy；lint/test/contract-lint/SAST/commitlint 全缺 |

---

## 6. 缺口清单

### 🔴 P0 — 必补，否则寸步难行

| # | 缺什么 | 为什么 | 补法 | 工作量 |
|---|---|---|---|---|
| 1 | `memory/constitution.md` | Context Bundle §1.6 强制；spec 链需参照 | 架构组起草 ≤ 9 条不变原则 | **S** |
| 2 | `<agent-dir>/{rules,skills,agents,settings.json}`（示例 `.claude/`；Cursor=`.cursor/` · Copilot=`.github/` · Codex=`.codex/`） | 无配置 = agent 无法识别 skill/hook | 按 playbook §3~5 建模板 + 3 个示例 | **M** |
| 3 | `scripts/spec-init.sh` 入仓 | 五件套初始化无脚本 → 手工易遗漏 | 按 playbook §6.2(b) 骨架实现 | **S** |
| 4 | `.github/workflows/{lint,test,contract-lint,security}.yml` | AI 输出无门禁 | spectral / ESLint / jest / semgrep 标准模板 | **M** |
| 5 | `<backend-repo>/` 骨架（含 <identity-verification>-service 示例 + AGENTS.md scripts） | T4.2 完全无法 dry-run | Node + TS + 一个 service 骨架 | **L** |

### 🟠 P1 — 强烈建议

- 根 [AGENTS.md](../../AGENTS.md) 补齐 Setup/Style/Test/PR/Security 5 节（**S**）
- 11 个 Skill 实装文件（优先 tech-intake / bc-impact-map / contract-first）（**L**）
- `specs/` 目录开张 + 先跑 1 个真实功能（**S**）
- 服务 SDD 内容补齐（<identity-verification>-service 先跑通做模板）（**M**）
- `.github/ISSUE_TEMPLATE/` + `PULL_REQUEST_TEMPLATE.md` + `CODEOWNERS`（**S**）

### 🟡 P2 — 可延后

- 官方 Spec-Kit 安装（vs 自研脚本二选一）
- `.github/copilot-instructions.md`、Cursor/Codex 同构配置
- `<mobile-app>` / `<web-app>` 仓
- ADR ↔ spec 自动双向同步 hook
- T7 retro-audit auto memory（Claude Code 2.1.59+）

---

## 7. 可行性结论

**现状不能跑 → 补 P0 可做文档级 dry-run → 补 P0+P1 可产生产代码。**

| 阶段 | 结论 | 关键依赖 |
|---|---|---|
| 今天 | ❌ 无法跑 | 4 项硬阻塞，最多走 T0→T2 文档流 |
| 补 P0 后（~2-3 周） | ⚠️ 文档级 dry-run | 完整 T0→T6，但编码阶段需 mock |
| 补 P0+P1 后（~6-8 周） | ✅ 生产代码 | <identity-verification> L1 可作首个真实 sprint |

**建议立刻动手的最小集（约 1 周可见效）**：

1. 草 `memory/constitution.md`
2. 建 `.claude/skills/contract-first/SKILL.md`
3. 入仓 `scripts/spec-init.sh`
4. 加 `lint + test + contract-lint` 三条 CI
5. 补根 [AGENTS.md](../../AGENTS.md)

---

## 附 · 报告生成方式

由 explorer 子代理只读探查 [ai-workflow/](../) + [<docs-repo>/](../../<docs-repo>/) + [tech-docs/](../../tech-docs/) + [tech-standards/](../../tech-standards/) + workspace 根目录后产出，未修改任何文件。
