<!-- REFERENCE ONLY: sanitized sample, not for production -->
# 01 · 入口文件支持矩阵（2026/Q2）

> **目标**：用一张可验证的矩阵厘清"哪个工具读哪个入口文件"，纠正凭记忆作答的常见误区，为后续 <Platform> 多工具协同选型提供事实依据。
>
> **调研窗口**：2026 年 5 月一手官方文档；任何"X 工具支持 Y 文件"的断言都配链接。
>
> **常见误区警告**（用户已点名）：
> - ❌ "大部分工具都原生读 CLAUDE.md" — **不全对**。CLAUDE.md 在 Claude Code、Copilot（VS Code + GitHub.com）、Zed、Warp（通过 `/init` 链接）原生支持；但 Cursor / Windsurf / Cline / Codex / Aider 并不原生读取 CLAUDE.md，需要符号链接或 `@import`。
> - ❌ "AGENTS.md 是 Anthropic 的格式" — **错**。AGENTS.md 由 OpenAI Codex / Amp / Jules / Cursor / Factory 共同发起，现已转交 Linux Foundation 旗下 **Agentic AI Foundation** 维护，被 60k+ 开源仓库采用。Claude Code 反而**不**原生读它（需 `@AGENTS.md` 导入）。
> - ❌ "Zed 用 AGENTS.md" — **不完全**。Zed 支持多种入口文件，但**首个匹配者胜**，顺序是 `.rules > .cursorrules > .windsurfrules > .clinerules > .github/copilot-instructions.md > AGENT.md > AGENTS.md > CLAUDE.md > GEMINI.md`。

---

## 一、事实清单（按工具）

### 1. Claude Code (Anthropic CLI)
- **官方入口**：`CLAUDE.md`、`./CLAUDE.md`、`./.claude/CLAUDE.md`、`./CLAUDE.local.md`（个人，gitignore）、`~/.claude/CLAUDE.md`（用户级）、托管层（policy）
- **AGENTS.md**：⚠️ **不原生读取**。官方做法：在 CLAUDE.md 首行写 `@AGENTS.md` 导入，或 `ln -s AGENTS.md CLAUDE.md`。`/init` 命令会自动读 AGENTS.md / `.cursorrules` / `.windsurfrules` 并整合进 CLAUDE.md
- **`@import` 语法**：✅ 原生支持，最大递归 5 层
- **路径作用域**：✅ `.claude/rules/*.md` + frontmatter `paths: ["src/**/*.ts"]`
- **Subagent**：✅ `.claude/agents/*.md`（独立 context、可配 worktree 隔离、preload skills/mcp/hooks）
- **Skills**：✅ Anthropic 开放标准 `.claude/skills/<x>/SKILL.md`（progressive disclosure）
- **Auto Memory**：✅ `~/.claude/projects/<repo>/memory/MEMORY.md`（Claude 自动写、前 200 行入 context）
- 链接：<https://code.claude.com/docs/en/memory>

### 2. GitHub Copilot (VS Code + GitHub.com)
- **官方入口**（三类并存）：
  - `.github/copilot-instructions.md` — repo-wide
  - `.github/instructions/*.instructions.md` + frontmatter `applyTo: "**/*.ts"` — 路径作用域
  - `AGENTS.md`（嵌套）/ `CLAUDE.md`（根） / `GEMINI.md`（根）— **官方文档明示**：作为 agent instructions 的替代来源
- **优先级**：Personal > Repository > Organization；多种入口文件**并存累加**
- **`@import`**：未文档化（Copilot 自身不依赖 @import；VS Code 端可用 monorepo 父级 `.git` 发现 `chat.useCustomizationsInParentRepositories`）
- **Subagent**：✅ VS Code 中的 "Custom Agents"（`*.agent.md`） + GitHub.com 端 "Copilot Coding Agent" 云端任务
- **Skills**：✅ Agent Skills（VS Code 端有 `/create-skill`，复用 agentskills.io 开放标准）
- **Prompt Files**：✅ `.github/prompts/*.prompt.md`
- 链接：
  - GitHub.com 端：<https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions>
  - VS Code 端：<https://code.visualstudio.com/docs/copilot/copilot-customization>

### 3. Cursor
- **官方入口**：
  - **Project Rules**：`.cursor/rules/*.md` 或 `.mdc`（带 frontmatter `globs:`/`alwaysApply:`/`description:`）
  - **AGENTS.md**：✅ 官方文档专设 "AGENTS.md" 章节，作为 `.cursor/rules` 的简化替代；支持根目录 + 嵌套
  - **User Rules**（全局偏好，Settings → Rules）
  - **Team Rules**（Team/Enterprise 计划，控制台下发）
- **CLAUDE.md**：⚠️ 官方 Rules 文档**未提及** CLAUDE.md
- **导入**：✅ 可从 GitHub 仓拉 `.mdc` 到 `.cursor/rules/imported/<repo>/`
- **优先级**：Team Rules → Project Rules → User Rules（前者优先）
- **Subagent**：✅ **本地** `.cursor/agents/*.md`（同时识别 `.claude/agents/`、`.codex/agents/`，含 user/project 两级）；frontmatter `name / description / model(inherit|id) / readonly / is_background`；内置 **Explore / Bash / Browser**；`/name` 调用；前台 + 后台两种模式
- **Cloud Agent**：✅ **Cloud Agents**（旧称 Background Agents · cursor.com/agents + Slack / GitHub / Linear / API 入口；自带 VM + 远程桌面）
- **Skills**：✅ **agentskills.io 原生**：`.cursor/skills/<name>/SKILL.md`（兼容 `.claude/skills`、`.codex/skills`、`.agents/skills`）；`paths` + `disable-model-invocation` + `scripts / references / assets`；GitHub remote 安装；内置 `/migrate-to-skills`（Cursor 2.4，2026-05）
- **Hooks**：✅ `.cursor/hooks.json`（**Enterprise / Team / Project / User 四级合并**）；事件全集含 `subagentStart/Stop`、`beforeShellExecution`、`beforeMCPExecution`、`beforeReadFile`、`afterFileEdit`、`beforeSubmitPrompt`、`preCompact`、`stop`、`afterAgentResponse / afterAgentThought`、`workspaceOpen` 等；**原生兼容 Claude Code hook 格式**（退出码 2 = deny；`CLAUDE_PROJECT_DIR` 环境变量）
- **Memories**：✅ 自动持久化 + 可编辑
- 链接：<https://cursor.com/docs/rules> · <https://cursor.com/docs/subagents> · <https://cursor.com/docs/skills> · <https://cursor.com/docs/hooks> · <https://cursor.com/docs/cloud-agents>

### 4. OpenAI Codex (CLI + Cloud)
- **官方入口**：`AGENTS.md`（根 + 任意子目录嵌套；OpenAI 自己仓库有 88 个 AGENTS.md 文件）
- **CLAUDE.md**：⚠️ 不原生支持
- **冲突解决**：离编辑文件最近的 AGENTS.md 胜出；用户聊天 prompt 覆盖一切
- **Subagent**：✅ 官方 subagents（`/docs/codex/subagents`）
- **Skills**：✅ 官方 skills（`/docs/codex/skills`）
- **Rules（提示词路径作用域）**：⚠️ 唯一靠嵌套 `<dir>/AGENTS.md`（无 frontmatter glob · 物理位置就近覆盖）
- **Rules（沙箱命令准入策略 · 非提示词）**：✅ `.codex/rules/*.rules` — Starlark `prefix_rule()` + `allow|prompt|forbidden`（execpolicy · 与 Hooks 配合 · `~/.codex/rules/default.rules` + 仓库根 `.codex/rules/*.rules`）· 与提示词不同质 · 官方 <https://developers.openai.com/codex/rules>
- **Hooks**：✅
- **沙箱**：原生，按 OS（macOS Seatbelt / Linux landlock / Windows sandbox / WSL）
- 链接：
  - AGENTS.md 指南：<https://developers.openai.com/codex/guides/agents-md>
  - 总览：<https://developers.openai.com/codex/cli>

### 5. Windsurf (formerly Codeium)
- **官方入口**：
  - **Workspace Rules**：`.windsurf/rules/*.md` + frontmatter `trigger: always_on|model_decision|glob|manual`、`globs:`（每文件 ≤12,000 字符）
  - **Global Rules**：`~/.codeium/windsurf/memories/global_rules.md`（≤6,000 字符，无 frontmatter，always on）
  - **AGENTS.md**：✅ "Location-scoped rules with zero config"，根=always_on，子目录=自动 glob
  - **System Rules**（Enterprise，OS 级 `/Library/Application Support/Windsurf/rules/*.md` 等）
- **CLAUDE.md**：⚠️ 官方 Rules/Memories 文档未提及
- **Memories（Claude Auto Memory 对照）**：✅ 自动记忆 `~/.codeium/windsurf/memories/`（仅本机）
- **Skills**：✅ `.windsurf/skills/`
- **Workflows**：✅ `/workflow-name` slash 命令
- 链接：<https://docs.windsurf.com/windsurf/cascade/memories>

### 6. Cline
- **官方入口**：
  - **`.clinerules/` 目录**（primary，里面所有 `.md`/`.txt` 自动合并）
  - **`.cursorrules`**：✅ 自动检测
  - **`.windsurfrules`**：✅ 自动检测
  - **AGENTS.md**：✅ "Standard format for cross-tool compatibility"
- **CLAUDE.md**：⚠️ 官方 Rules 文档**未列出**作为自动检测来源
- **路径作用域**：✅ `.clinerules/*.md` 文件级 frontmatter `paths: ["src/**"]`（按 open tabs / 提及的文件路径触发）
- **Global Rules**：`~/Documents/Cline/Rules/`
- 链接：<https://docs.cline.bot/features/cline-rules>

### 7. Zed
- **官方入口**：`.rules` 文件（项目根级）。Zed 按以下顺序**首个匹配胜**：
  1. `.rules`
  2. `.cursorrules`
  3. `.windsurfrules`
  4. `.clinerules`
  5. `.github/copilot-instructions.md`
  6. `AGENT.md`
  7. `AGENTS.md`
  8. `CLAUDE.md`
  9. `GEMINI.md`
- **多入口并存的项目里**：Zed 只读**最靠前**的那个文件，CLAUDE.md 在最低优先级
- **Rules Library**：UI 内管理；可 @-mention，可设为 Default Rule（默认插入每次对话）
- 链接：<https://zed.dev/docs/ai/rules>

### 8. Aider
- **官方入口**：⚠️ **无自动发现**。需在 `.aider.conf.yml`（或命令行 `--read`）显式声明：
  ```yaml
  read: AGENTS.md
  # 或多个
  read: [AGENTS.md, CONVENTIONS.md, CLAUDE.md]
  ```
  - 配置文件查找：home → git root → cwd（后者覆盖前者）
- **支持 CLAUDE.md**：仅在你 `read: CLAUDE.md` 时；同理 AGENTS.md
- **官方推荐**：作为 read-only 文件加入（受益于 prompt caching）
- 链接：
  - <https://aider.chat/docs/usage/conventions.html>
  - <https://aider.chat/docs/config/aider_conf.html>

### 9. Warp
- **官方入口**：
  - **Project Rules**：`AGENTS.md`（默认，根 + 嵌套）；`WARP.md`（向后兼容；若同目录两者并存，`WARP.md` 胜）
  - **必须全大写文件名**（`agents.md` 不识别）
  - **Global Rules**：通过 Warp Drive UI 管理
- **CLAUDE.md / AGENT.md / GEMINI.md / .cursorrules / .clinerules / .windsurfrules / .github/copilot-instructions.md**：⚠️ 不自动读，但 `/init` 命令可将这些"链接"到 `AGENTS.md`
- **优先级**：当前子目录 AGENTS.md > 根目录 AGENTS.md > Global Rules
- 链接：<https://docs.warp.dev/knowledge-and-collaboration/rules>

### 10. Gemini CLI
- **官方入口**：默认 `GEMINI.md`；可在 `.gemini/settings.json` 改为：
  ```json
  { "context": { "fileName": "AGENTS.md" } }
  ```
- **CLAUDE.md**：⚠️ 不原生
- 链接（agents.md FAQ 引用）：<https://agents.md/#one-agentsmd-works-across-many-agents>

### 11. 其他通过 agents.md 官方列表确认支持 AGENTS.md
**RooCode** / **Kilo Code** / **Factory** / **Amp**（Sourcegraph）/ **Phoenix** / **Jules** (Google) / **Ona** / **Semgrep** — 均在 agents.md 官方 "One AGENTS.md works across many agents" 列表中（来源：<https://agents.md/>）。

---

## 二、对比矩阵（核心 11 工具 × 9 维度）

| 工具 | 自有主入口 | `AGENTS.md` | `CLAUDE.md` | 路径作用域机制 | `@import` | Subagent | Skills | 自动记忆 | 文档链接 |
|---|---|:--:|:--:|---|:--:|:--:|:--:|:--:|---|
| **Claude Code** | `CLAUDE.md` + `.claude/CLAUDE.md` | 🔗 via `@import`/symlink | ✅ 原生 | `.claude/rules/*.md` + `paths:` | ✅ | ✅ `.claude/agents/*.md` | ✅ 开放标准 | ✅ `MEMORY.md` | [docs](https://code.claude.com/docs/en/memory) |
| **GitHub Copilot** | `.github/copilot-instructions.md` + `.github/instructions/*.instructions.md` | ✅ 原生（嵌套） | ✅ 原生（根） | `applyTo:` frontmatter | ➖ | ✅ `*.agent.md` (VS Code) + Coding Agent (云) | ✅ Agent Skills | ➖ | [docs](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions) |
| **Cursor** | `.cursor/rules/*.mdc` + `.cursor/skills/<n>/SKILL.md` | ✅ 原生（嵌套） | ❌ | rules `globs:` / skill `paths:` | ➖ | ✅ `.cursor/agents/*.md`（兼容 `.claude/agents/`、`.codex/agents/`）+ Cloud Agents（云） | ✅ agentskills.io 原生（`/migrate-to-skills`） | ✅ Memories | [docs](https://cursor.com/docs) · [agents](https://cursor.com/docs/subagents) · [skills](https://cursor.com/docs/skills) · [hooks](https://cursor.com/docs/hooks) |
| **OpenAI Codex** | `AGENTS.md`（嵌套） | ✅ 原生 | ❌ | Rules + AGENTS.md 嵌套 | ➖ | ✅ Subagents | ✅ Skills | ➖ | [docs](https://developers.openai.com/codex/guides/agents-md) |
| **Windsurf** | `.windsurf/rules/*.md` | ✅ 原生 | ❌ | `trigger: glob` + `globs:` | ➖ | ➖ | ✅ Skills | ✅ `~/.codeium/.../memories/` | [docs](https://docs.windsurf.com/windsurf/cascade/memories) |
| **Cline** | `.clinerules/*.md` | ✅ 原生 | ❌ | `paths:` frontmatter | ➖ | ➖ | ✅ Skills | ➖（Memory Bank 模式） | [docs](https://docs.cline.bot/features/cline-rules) |
| **Zed** | `.rules`（首匹配胜） | ✅（优先级 7/9） | ✅（优先级 8/9） | ➖（Rules 是单文件） | ➖ | ✅ Parallel Agents | ➖ | ➖ | [docs](https://zed.dev/docs/ai/rules) |
| **Aider** | 无（需 `read:` 配置） | 🔗 via `read:` | 🔗 via `read:` | ➖（手动 add） | ➖ | ➖ | ➖ | ➖ | [docs](https://aider.chat/docs/usage/conventions.html) |
| **Warp** | `AGENTS.md`（大写文件名） | ✅ 原生 | 🔗 via `/init` 链接 | 子目录 AGENTS.md | ➖ | ➖ | ✅ Skills（含 Skills-as-Agents 云） | ➖ | [docs](https://docs.warp.dev/knowledge-and-collaboration/rules) |
| **Gemini CLI** | `GEMINI.md`（可改名） | 🔗 via `settings.json` | ❌ | ➖ | ➖ | ➖ | ➖ | ➖ | [docs](https://agents.md/) |
| **RooCode / Kilo / Factory / Amp** | 各自规则文件 | ✅（官方列表确认） | ❌（未确认） | 各自方案 | ➖ | 部分 | 部分 | 部分 | [agents.md](https://agents.md/) |

**图例**：✅ 原生支持 / 🔗 间接（导入、链接、配置） / ❌ 不支持 / ➖ 不适用或未文档化

> **Hooks 维度（本 9 维表未列）**：Claude Code ✅ / Cursor ✅（`.cursor/hooks.json` · 4 级 · 兼容 Claude 退出码 2）/ Copilot ✅（agent frontmatter `hooks` Preview）/ Codex ✅ / Windsurf 部分 / Cline ➖ / Zed ➖ / Aider ➖ / Warp ➖ / Gemini ➖。

---

## 三、关键交叉事实

### 3.1 谁原生读 `AGENTS.md`（9 家）
Codex · Cursor · Copilot · Windsurf · Cline · Zed · Warp · Aider（配置后）· Gemini CLI（改名后） + agents.md 列表里另外的 RooCode / Kilo / Factory / Amp / Phoenix / Jules / Ona / Semgrep / VS Code。

### 3.2 谁原生读 `CLAUDE.md`（仅 3 家）
Claude Code · GitHub Copilot · Zed（但 Zed 是首匹配胜，CLAUDE.md 在最低优先级）。

### 3.3 `@import` 语法
仅 **Claude Code** 原生支持 `@path/to/file` 在 Markdown 中递归导入（最多 5 层）。其他工具靠 symlink 或工具自身的 settings 链接。

### 3.4 路径作用域命名差异（核心配置）
| 工具 | 字段名 | 范例 |
|---|---|---|
| Claude Code | `paths:` | `paths: ["src/api/**/*.ts"]` |
| Copilot | `applyTo:` | `applyTo: "**/*.ts,**/*.tsx"` |
| Cursor | `globs:` | `globs: src/components/**/*.tsx` |
| Windsurf | `trigger: glob` + `globs:` | `globs: **/*.test.ts` |
| Cline | `paths:` | `paths: ["src/components/**"]` |

> 几何结构同构，但**字段名各不一样** — 文档模板要为四种命名留接口（<Platform> 要写四份等价规则时不要手抄）。

### 3.5 沙箱 / 安全门 原生程度
- **Codex**：强（OS 级沙箱：Seatbelt/landlock/Windows sandbox）
- **Claude Code**：托管 settings + Hooks + permission modes
- **Copilot**：VS Code Hooks + Coding Agent 云沙箱
- **其他**：弱或无（依赖你自己的 hook + pre-commit）

---

## 四、给 <Platform> 的启示（→ 应沉淀到 SOP / 主文档）

### I-1 选 AGENTS.md 作为"单一事实源"（SSOT）
- AGENTS.md 是当前覆盖面最广的入口（10+ 主流工具原生），且由 LF Agentic AI Foundation 托管，**中立**
- <Platform> 仓库根放一份 `AGENTS.md`；Claude Code 用 `CLAUDE.md` `@AGENTS.md` 导入；其他工具自动识别
- → 写入 `02_coding-paradigms-2026.md` 与未来的 SOP **T1 入口装配** 一节

### I-2 路径作用域规则要写**四份等价文件**（不要复制粘贴）
- `.claude/rules/<topic>.md`（`paths:`）
- `.cursor/rules/<topic>.mdc`（`globs:`）
- `.github/instructions/<topic>.instructions.md`（`applyTo:`）
- `.windsurf/rules/<topic>.md`（`trigger: glob` + `globs:`）
- 这四份文件**应由同一份"路径作用域规则模板"生成**（小脚本即可）；Cline 用 `.clinerules/` 复用 Claude 那份格式
- → 写入未来 `templates/rules/` 的 README

### I-3 嵌套规则覆盖大型 monorepo
所有支持 AGENTS.md 的工具都同义实现"离编辑文件最近的胜出"——这是 monorepo 的天然分发机制。
- <Platform> 各微服务目录放 `AGENTS.md`，写本服务的构建/测试/约定
- 顶层 AGENTS.md 只放跨服务通用规则
- → 写入 `03_large-project-workflows.md`

### I-4 区分"装入 context"与"按需触发"
- **入口文件**（CLAUDE.md / AGENTS.md / 无 frontmatter 的 rules）：每次对话开头进 context，消耗 token
- **路径作用域规则**：触及匹配文件时才装入
- **Skills**：仅在 Claude 判断相关时加载（progressive disclosure）
- **Subagent**：独立 context，主线程不被污染
- → 写入 `05_context-engineering.md` 的"分层心智模型"一节

### I-5 不要把"安全/隔离/审计"押注在 CLAUDE.md / AGENTS.md
- Anthropic 官方原话："Settings rules are enforced by the client regardless of what Claude decides to do. CLAUDE.md instructions shape Claude's behavior but are **not a hard enforcement layer**."
- 真正的硬控制：**Settings**（permissions deny / sandbox）+ **Hooks**（PreToolUse / InstructionsLoaded / 等）+ pre-commit
- → 写入 `08_quality-safety-eval.md`

### I-6 / init 是低成本起点
Claude Code / Cursor / Copilot / Codex / Warp 都有 `/init` slash 命令，自动扫描仓库并生成入口文件初稿。新仓接入时**总是先跑 `/init`**，再人工精修。

### I-7 不要把"工具特性"误传成"标准能力"
- ❌ "用 CLAUDE.md 就能在所有工具用" — 错（仅 3 家原生）
- ❌ "AGENTS.md 是 Anthropic 标准" — 错（Anthropic 偏好 CLAUDE.md，AGENTS.md 是 OpenAI 系发起 + LF 托管）
- ❌ "`.cursorrules` 是 Cursor 专属" — Cline / Zed 都自动识别（向后兼容）
- → 写入未来 `07_skills-and-prompts.md` 与 SOP "T0 工具选型" 的判断题

---

## 五、未尽事项（留待后续调研补全）

1. **Aider 是否在 v0.7x+ 增加了 AGENTS.md 自动发现** — 待跟进 release notes
2. **JetBrains AI Assistant** 对 AGENTS.md / CLAUDE.md 的态度（官方文档目前未覆盖；预计走自己的 `.junie/` 配置）
3. **Continue.dev** v1 后的入口文件机制（`.continue/rules/` 仍在迭代，未列入本矩阵核心 11 家）
4. **Plandex** 对入口文件的处理（CLI agent，未在 agents.md 列表）
5. **Devin / Manus** 等"完全自治型"云 agent 是否读入口文件还是只接受任务描述
6. **Anthropic Skills 标准 vs Copilot Agent Skills 标准** 的兼容性（agentskills.io 是否真"一份能用多家"）— 单列入 `07_skills-and-prompts.md`

---

## 六、参考链接（事实索引）

| 来源 | URL |
|---|---|
| AGENTS.md 官方站 | <https://agents.md/> |
| Agentic AI Foundation (LF) | <https://aaif.io/> |
| Claude Code Memory | <https://code.claude.com/docs/en/memory> |
| GitHub Copilot Custom Instructions | <https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions> |
| VS Code Copilot Customization | <https://code.visualstudio.com/docs/copilot/copilot-customization> |
| Cursor Rules | <https://cursor.com/docs/rules> |
| OpenAI Codex CLI | <https://developers.openai.com/codex/cli> |
| OpenAI Codex AGENTS.md guide | <https://developers.openai.com/codex/guides/agents-md> |
| Windsurf Memories & Rules | <https://docs.windsurf.com/windsurf/cascade/memories> |
| Cline Rules | <https://docs.cline.bot/features/cline-rules> |
| Zed Rules | <https://zed.dev/docs/ai/rules> |
| Aider Conventions | <https://aider.chat/docs/usage/conventions.html> |
| Aider conf | <https://aider.chat/docs/config/aider_conf.html> |
| Warp Rules | <https://docs.warp.dev/knowledge-and-collaboration/rules> |
| Codex 官方 AGENTS.md 样例 | <https://github.com/openai/codex/blob/main/AGENTS.md> |

---

*调研时间：2026-05-18 · 下一篇：`02_coding-paradigms-2026.md`*
