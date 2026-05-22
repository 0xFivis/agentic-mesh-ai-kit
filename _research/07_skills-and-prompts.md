<!-- REFERENCE ONLY: sanitized sample, not for production -->
# 07 · Skills 与 Prompt Files — 2026/Q2 研究

> ⚠️ **部分内容已被超越（SUPERSEDED 2026-05）**
> §6 / §6.1 内 6 个 `qx-*` skill 推荐列表是本文初版假设，已被 `ai-agent-playbook.md` §2.3 「11 个 Skill 权威索引」（`tech-intake / bc-impact-map / contract-first / task-decomp-fanout / gate-checklist / qa-cases / release-canary / retro-audit / adr-writing / std-writing / data-redline`）取代。任何实施以 playbook §2.3 为准。本文以下章节仅作研究追溯保留，不再是落地依据。

> 本文聚焦"可复用的 procedural knowledge"如何被打包：Anthropic 主导的 **Agent Skills 开放标准**（agentskills.io），及与 Cursor Rules / GitHub Copilot Prompt Files / Codex CLI 的横向对照。  
> 与 06（subagent 编排）/ 05（context engineering）配套阅读：Skill = "知识包"，Subagent = "执行人"，Rule/Memory = "始终在场的事实"。

---

## §0 一句话结论

**Skill 是 2026 年 agent 生态唯一跨厂商收敛的开放格式**——`<dir>/SKILL.md` + YAML frontmatter + progressive disclosure 三件套，被 Claude Code / Copilot / Codex / Junie / Factory / Goose / Mistral Vibe / Laravel Boost / Spring AI 等 10+ 客户端原生支持（见 [agentskills.io/clients](https://agentskills.io/clients)）。Cursor "Manual Rules" 与 Copilot "Prompt Files" 是该格式的早期同形物。<Platform> 应**以 SKILL.md 为唯一可执行知识载体**，CLAUDE.md / .cursorrules / copilot-instructions.md 只放"事实"，"流程"全部下沉到 `.claude/skills/` 并在 Cursor/Copilot 镜像目录里软链或同步。

**5 个落地动作**：
1. 仓库根建 `.claude/skills/qx-*/`，至少 6 个：`commit` / `review-pr` / `release` / `migrate-service` / `arch-diagram` / `prd-extract`
2. 每个 Skill `description` 字段 ≤200 字，**写"何时用"而非"做什么"**——这是模型自动触发的唯一信号
3. **副作用类 Skill 必须 `disable-model-invocation: true`**（commit/deploy/release），只允许 `/skill-name` 手动触发
4. 大 reference（API spec / 长 checklist）放进 `SKILL.md` 同目录 `reference.md`，在主文件用 `[reference.md](reference.md)` 引用，**按需加载省 token**
5. 用 `paths:` glob 限定生效范围（如 `paths: ["services/**/*.go"]`），避免 description 跨语境误触发

---

## §1 Skill = 什么 / 为什么收敛

### 1.1 定义（agentskills.io 原文）

> A skill is a folder containing a `SKILL.md` file. This file includes metadata (`name` and `description`, at minimum) and instructions that tell an agent how to perform a specific task. Skills can also bundle scripts, reference materials, templates, and other resources.

```
my-skill/
├── SKILL.md          # 必需：metadata + 指令
├── scripts/          # 可选：可执行代码（Claude 能 Bash 调用）
├── references/       # 可选：详细文档（按需加载）
├── examples/         # 可选：示例输出
└── assets/           # 可选：模板 / 资源
```

### 1.2 Progressive Disclosure（三阶段加载）

| 阶段 | 加载内容 | Token 成本 |
|------|---------|----------|
| **Discovery**（启动） | 仅 `name` + `description` | ~50 token/skill |
| **Activation**（命中） | 整个 `SKILL.md` body | 视文件大小（建议 <500 行） |
| **Execution**（执行） | 按需 `Read(reference.md)` / `Bash(scripts/x.py)` | 仅实际用到的部分 |

这是 Skill 对 CLAUDE.md / .cursorrules **最本质的优势**——后两者**永远在 context 里烧 token**，Skill 平时只占 50 token，被触发才展开。

### 1.3 为什么 2026/Q2 收敛？

| 时间线 | 事件 |
|--------|------|
| 2025/Q4 | Anthropic 发布 Agent Skills 标准，开源至 `agentskills/agentskills` repo |
| 2026/Q1 | Claude Code / GitHub Copilot / OpenAI Codex 三家同时声明兼容 |
| 2026/Q1 | Junie / Factory / Goose / Mistral Vibe / Laravel Boost 跟进 |
| 2026/Q2 | agentskills.io 列出 15+ 兼容客户端，事实标准成立 |

收敛动因：**SKILL.md 格式极简**（YAML + Markdown），无需 SDK，文件即合约，跨厂商零成本迁移。

---

## §2 SKILL.md Frontmatter 完整字段（Claude Code 实现）

来源：[code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills)。其他客户端实现可能是子集，但字段名稳定。

| 字段 | 必需 | 取值 | 用途 |
|------|------|------|------|
| `name` | 否 | 小写 + 数字 + 连字符，≤64 字符 | 显示名；省略则用目录名 |
| `description` | **强烈推荐** | 自然语言 | **模型靠这个判断何时触发**；与 `when_to_use` 合计 ≤1536 字符 |
| `when_to_use` | 否 | 触发短语 / 示例请求 | 追加到 description，共用 1536 字符上限 |
| `disable-model-invocation` | 否 | `true` / `false`（默认 false） | true = 只能 `/skill-name` 手动调；副作用类必填 |
| `user-invocable` | 否 | `true` / `false`（默认 true） | false = 不出现在 `/` 菜单，仅模型自动触发 |
| `allowed-tools` | 否 | 空格分隔 / YAML list | 该 skill 激活时**免确认**的工具列表，如 `Bash(git add *) Bash(git commit *)` |
| `paths` | 否 | glob list | **限定生效路径**，如 `paths: ["services/**/*.go"]` 仅在改这些文件时模型才会自动加载 |
| `model` | 否 | `haiku` / `sonnet` / `opus` / `inherit` | 该 skill 激活时切模型；turn 结束自动恢复 |
| `effort` | 否 | `low` / `medium` / `high` / `xhigh` / `max` | 该 skill 激活时覆盖 effort |
| `context` | 否 | `fork` | 设为 fork = **在子代理里执行该 skill**（隔离 context） |
| `agent` | 否 | `Explore` / `Plan` / `general-purpose` / 自定义 | `context: fork` 时指定 agent type |
| `arguments` | 否 | 空格分隔名字列表 | 命名位置参数，对应 `$name` 替换 |
| `argument-hint` | 否 | `[issue-number]` 样式 | 自动补全提示 |
| `hooks` | 否 | hooks 配置 | 该 skill lifecycle 内的 PreToolUse / PostToolUse |
| `shell` | 否 | `bash` / `powershell` | `!` 注入命令的 shell |

### 2.1 String Substitution（动态参数）

| 占位符 | 含义 |
|--------|------|
| `$ARGUMENTS` | 全部参数原串 |
| `$ARGUMENTS[N]` / `$N` | 第 N 个位置参数（0 起算） |
| `$<name>` | `arguments:` 里声明的命名参数 |
| `${CLAUDE_SESSION_ID}` | 当前会话 ID（日志用） |
| `${CLAUDE_EFFORT}` | 当前 effort 等级 |
| `${CLAUDE_SKILL_DIR}` | 当前 skill 目录绝对路径（**调用 bundled script 必用**） |

### 2.2 Dynamic Context Injection（`!` 注入）

`SKILL.md` body 里写 `` !`<cmd>` `` 或 ```` ```! ```` fenced block，**预处理时执行 shell，输出替换占位**，Claude 看到的是结果而非命令本身：

```markdown
---
name: pr-summary
description: Summarize changes in a pull request
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---

## Pull request context
- PR diff: !`gh pr diff`
- Changed files: !`gh pr diff --name-only`

## Your task
Summarize this pull request...
```

→ Claude 实际看到 PR diff 文本，**不再额外开一轮工具调用**，省 1 个 turn + 缓存友好。

### 2.3 Lifecycle（关键认知）

- Skill 一旦被触发，**整个 body 进入对话作为一条 message，余下整个 session 都保留**
- Claude **不会**在后续 turn 重读 skill 文件——写"始终适用的 standing instructions"，不要写"一次性步骤"
- Auto-compaction 触发时：每个 skill 保留**最新一次调用的前 5000 token**，合计预算 **25000 token**，按"最近调用优先"填充，旧 skill 可能被整丢
- **结论**：单个 SKILL.md body **保持 <500 行**；超长 reference 拆 `reference.md`，body 里写 "see [reference.md](reference.md)"

---

## §3 横向对照表 — 跨厂商实现

| 产品 | 支持格式 | 文件位置 | 自动触发机制 | 手动调用 | 与 Claude SKILL.md 兼容度 |
|------|---------|---------|------------|---------|----------|
| **Claude Code** | SKILL.md (原生) | `~/.claude/skills/`<br>`.claude/skills/` (project)<br>`<plugin>/skills/` | description 关键词匹配 + `paths:` glob | `/skill-name [args]` | ★★★★★ 参考实现 |
| **GitHub Copilot** | Prompt Files (.prompt.md) | `.github/prompts/` | "Use prompt file" 显式选择 | `/prompt-name` in Chat | ★★★☆☆ frontmatter 字段名不同；2026/Q1 起兼容 SKILL.md 子集 |
| **OpenAI Codex CLI** | SKILL.md 兼容 | `.codex/skills/` 或 `.claude/skills/`（reuse） | description 匹配 | `/skill-name` | ★★★★☆ 2026/Q1 起声明兼容 |
| **Cursor**（2.4+） | **SKILL.md 原生** + Rules (.mdc 旧形态) | `.cursor/skills/<n>/SKILL.md`（兼容 `.claude/skills/`、`.codex/skills/`、`.agents/skills/`）+ `.cursor/rules/` | description + `paths` + `disable-model-invocation`（Skills）/ Always / Auto Attached / Agent Requested / Manual（Rules）| `/skill-name` 或 `@RuleName` | ★★★★★ 原生 agentskills.io；内置 `/migrate-to-skills` 一键迁旧 Rules |
| **Junie (JetBrains)** | SKILL.md | `.junie/skills/` | description 匹配 | UI 菜单 | ★★★★☆ |
| **Goose** | SKILL.md | `~/.config/goose/skills/` | description 匹配 | `/skill` | ★★★★☆ |
| **Factory** | SKILL.md | project | description 匹配 | UI | ★★★★☆ |
| **Mistral Vibe** | SKILL.md | `.vibe/skills/` | description 匹配 | CLI | ★★★★☆ |
| **Aider** | 无 Skill；仅 `.aider.conf.yml` + CONVENTIONS.md | repo root | 始终在 context | 无 | ★☆☆☆☆ |
| **Amp** | `.agents/checks/*.md`（review-only） | `.agents/checks/` | 不自动触发，subagent 显式 read | 无 | ★★☆☆☆ |

### 3.1 Cursor Skills（2.4+）vs Cursor Rules（旧）vs Claude Skill

> **2026-05 更新**：Cursor 2.4 起原生支持 `agentskills.io` 标准，与 Claude Skill 字段同形；旧 `.cursor/rules/*.mdc` 仍可用，但建议跑 `/migrate-to-skills` 迁移。下表展示三者字段对照：

| 概念 | Claude Skill 字段 | **Cursor Skill 字段（新）** | Cursor Rule 字段（旧） |
|------|------------------|---------------------------|---------------------|
| 何时自动触发 | `description` + `paths` | `description` + `paths`（同 Claude）| `description` (Agent Requested) / `globs` (Auto Attached) |
| 始终在 context | （不支持，用 CLAUDE.md） | （不支持，用 AGENTS.md） | `alwaysApply: true` |
| 仅手动 | `disable-model-invocation: true` | `disable-model-invocation: true`（同 Claude）| type = Manual（`@RuleName`） |
| 工具白名单 | `allowed-tools` | `allowed-tools`（同 Claude）| 不支持 |
| 资源包 | `scripts/` `references/` `assets/` | `scripts/` `references/` `assets/`（同 Claude）| 不支持 |
| 远程安装 | Plugin marketplace | GitHub remote import | 不支持 |

### 3.2 GitHub Copilot Prompt Files 字段对照

```yaml
---
mode: agent              # ↔ 无对应（Claude 由 model 字段控制）
tools: [codebase, terminal]  # ↔ allowed-tools
description: ...         # ↔ description
---
```

Copilot prompt files **不支持** progressive disclosure 与 `paths:` 自动触发，是 Skill 的简化子集。

---

## §4 三类制品 vs Skill 的边界

| 制品 | 何时用 | 何时**不**用 Skill 替代 |
|------|--------|---------------------|
| **CLAUDE.md / .cursorrules** | "永远不变的事实"：技术栈、命名规范、目录约定 | 当事实 > 30 行 → 拆成 `paths:` 限定的 Skill |
| **Subagent (06)** | 需要**新鲜 context** / 长任务 / 隔离工具集 | 短指令、纯知识 → 用 Skill `context: fork` 一行解决 |
| **Slash Command (`.claude/commands/`)** | 旧式自定义命令（向后兼容） | 新项目**全用 Skill**；commands 与 skills 同名时 skill 优先 |
| **MCP Server** | 跨多个 agent / 跨语言、需要状态、需要远程 API | 一次性脚本 → bundled script in Skill |
| **Hook** | **强制性**红线（拦截 commit / 阻止 rm -rf） | 软性建议 → Skill description |
| **Plugin** | 跨多个团队 / 跨 repo 分发 | 单团队 / 单 repo → project skill |

### 4.1 Skill ↔ Subagent 双向耦合（06 §2 补充）

```
Skill with context: fork    →    SKILL.md body 作为 subagent prompt
Subagent with skills: field →    subagent 启动时整本 SKILL 注入其 system prompt
```

两者方向相反：前者是"在子代理里跑这段流程"，后者是"给这个子代理预装这本手册"。

---

## §5 反模式 7 项

| # | 反模式 | 后果 | 正确做法 |
|---|--------|------|---------|
| 1 | description 写"做什么"而非"何时用" | 模型不知道何时该调，永不自动触发 | 写"当用户问 X / 改 Y 类文件 / 准备 Z 操作时" |
| 2 | 所有 Skill 都 `user-invocable: true` 全列在 `/` 菜单 | 菜单爆炸、descriptions 被 1% context budget 截断丢关键字 | 后台知识类设 `user-invocable: false` |
| 3 | 副作用类（deploy/commit/migrate）没设 `disable-model-invocation: true` | 模型擅自触发部署 / 删数据 | 副作用 Skill **必须**禁自动 |
| 4 | SKILL.md body 写 1000+ 行 | session 内永久占 context，auto-compact 后只留 5000 token 截断 | body <500 行，长 reference 拆同目录 `*.md` 并在 body 用链接引用 |
| 5 | 不设 `paths:`，description 在所有语境匹配 | 在 frontend 项目下也加载 backend skill，浪费 token | `paths: ["services/payment/**"]` 显式限定 |
| 6 | `allowed-tools` 给整个 `Bash(*)` | 单个 skill 把整个 shell 解锁，绕过 permission | 精确到 `Bash(git status *)` `Bash(gh pr *)` |
| 7 | bundled script 写绝对路径 / 相对路径 | plugin 安装到他人环境路径变 | 用 `${CLAUDE_SKILL_DIR}/scripts/x.py` |

---

## §6 <Platform> 启示（I-1 ~ I-8）

> ⚠️ **本节已超越**：I-1 / 6.1 中 6 个 `qx-*` skill 列表为初版设想，已被 playbook §2.3 的 11 skill 权威索引取代。名字主要变化：`qx-commit` → 并入 commit-msg lint hook ∨ 不单独出 skill；`qx-review-pr` → `gate-checklist` skill + reviewer subagent；`qx-release` → `release-canary`；`qx-migrate-service` → `bc-impact-map` + `contract-first`；`qx-arch-diagram` → 归 archify skill（项目级，不入跨家 11）；`qx-prd-extract` → `tech-intake` · `bc-impact-map` 两者覆盖。I-2/I-3/I-4/I-5/I-6 的原则仍有效。

| # | 启示 | 落地动作 |
|---|------|---------|
| **I-1** | `.claude/skills/qx-*` 入仓，初版 6 个 | `qx-commit` / `qx-review-pr` / `qx-release` / `qx-migrate-service` / `qx-arch-diagram`（调 Archify）/ `qx-prd-extract`（调 prd-writing skill） |
| **I-2** | **副作用类必禁自动**：`qx-commit` / `qx-release` / `qx-deploy` 一律 `disable-model-invocation: true` | 防"模型看代码 OK 就自己 push prod" |
| **I-3** | description 模板统一为"当 [用户场景] 时，[Skill 名] 会 [行为]" | 写在 `.claude/skills/_TEMPLATE.md`，新建 skill 复制起手 |
| **I-4** | `paths:` 必填，按 BC 切片：`services/wallet/**` `services/trading/**` `<mobile-app>/**` | 防止后端 review 流程在前端 PR 误触发 |
| **I-5** | 大流程类 Skill 用 `context: fork` + `agent: qx-explorer` 隔离 | 如 `qx-review-pr` 在 explorer 子代理跑，不污染主 context |
| **I-6** | reference material 一律拆 `reference.md`，body 用 `[ref](reference.md)` 链接 | 保 200-行 SKILL.md，符合 05 §7 token 预算 |
| **I-7** | Cursor / Copilot **同步镜像**：因 Cursor 2.4 已原生支持 SKILL.md，**直接软链** `.claude/skills/qx-*/` → `.cursor/skills/qx-*/`（同形，无需 frontmatter 重写）；Copilot 端用脚本 `scripts/sync-skills.py` 将同一 SKILL.md 衍生到 `.github/prompts/qx-*.prompt.md`（仅 frontmatter 转 `mode/tools/description`） | 一处编辑、三处生效；pre-commit hook 校验同步；Cursor 旧 rules → 一次 `/migrate-to-skills` 迁清 |
| **I-8** | 每季度 `/doctor` 检 skill listing budget；overflow 则把低频 skill 设 `skillOverrides: "name-only"` 或 `skillListingBudgetFraction: 0.02` | 见 05 §9 I-8 季度 context audit |

### 6.1 推荐 6 个 <Platform> Skill 速览

| Skill | 触发场景 | 关键字段 |
|-------|---------|---------|
| `qx-commit` | 用户说"commit"/"提交" | `disable-model-invocation: true` `allowed-tools: Bash(git add *) Bash(git commit *) Bash(git status *)` |
| `qx-review-pr` | 用户说"review PR"/PR 编号 | `context: fork` `agent: qx-reviewer` `allowed-tools: Bash(gh *)` |
| `qx-release` | 用户说"发版"/"release v*" | `disable-model-invocation: true` `argument-hint: [version]` |
| `qx-migrate-service` | 用户改 `services/*/migrations/**` | `paths: ["services/**/migrations/**"]` `model: opus` |
| `qx-arch-diagram` | 用户说"画架构图"/"生成 diagram" | 调 archify skill；`allowed-tools: Bash(python3 *)` |
| `qx-prd-extract` | 用户说"提取 PRD"/"page spec" | 引用 prototype-from-prd skill；body <100 行 |

---

## §7 未尽事项（→ 后续文档）

1. **Skill 与 Hook 的强制性梯度** —— 何时该 hook，何时该 skill description？转 08 质量/安全/评估
2. **Plugin 分发**（团队级 / 跨 repo）的发布、版本、签名机制 —— 转 03 大项目工作流
3. **Copilot Prompt Files 与 SKILL.md 的自动 lint 与同步脚本实现**（Cursor 端已与 Claude 同形，无需转换）—— 转 03
4. **SKILL.md 的 RAG/检索增强**（当 skill 数 >50 时）—— 转 08
5. **Skill 触发的可观测性**：哪些 skill 被自动触发了？命中率？由谁触发？→ 转 08（指标 + 评估）
6. **Skill 与 Subagent `memory: project`（06 §2.4）的合一/分工** —— 待 Anthropic 出更明确指南

---

## §8 参考链接索引（一手）

1. Anthropic Agent Skills 主文档 — <https://code.claude.com/docs/en/skills>
2. Agent Skills 开放标准官网 — <https://agentskills.io/>
3. Agent Skills 规范全文 — <https://agentskills.io/specification>
4. Agent Skills 兼容客户端列表 — <https://agentskills.io/clients>
5. Agent Skills 开源 repo — <https://github.com/agentskills/agentskills>
6. Claude Code Subagents（与 Skill 双向耦合） — <https://code.claude.com/docs/en/sub-agents>
7. Claude Code Permissions（`allowed-tools` 与 deny rules） — <https://code.claude.com/docs/en/permissions>
8. Claude Code Plugins（Skill 分发） — <https://code.claude.com/docs/en/plugins>
9. Claude Code Hooks（强制性 vs Skill 软性） — <https://code.claude.com/docs/en/hooks>
10. Cursor Rules 文档 — <https://cursor.com/docs> （检索 "rules"）
11. GitHub Copilot Prompt Files — <https://docs.github.com/copilot> （检索 "prompt files"）
12. OpenAI Codex CLI Skills 兼容声明 — <https://developers.openai.com/codex>

---

**前置阅读**：[05 上下文工程](05_context-engineering.md) §8（决策清单 file/Skill/Subagent/MCP/Hook） · [06 子代理编排](06_subagent-orchestration.md) §2.2（subagent `skills:` 字段）  
**后续**：03 大项目工作流 · 08 质量/安全/评估
