<!-- REFERENCE ONLY: sanitized sample, not for production -->
# Memory 跨工具支持矩阵（Claude / Cursor / Codex / Copilot）

> 一手来源（截至 2026-05）：
> - Claude Code Memory — https://code.claude.com/docs/en/memory
> - Claude Code Sub-agents（含 subagent persistent memory）— https://code.claude.com/docs/en/sub-agents#enable-persistent-memory
> - Codex AGENTS.md — https://developers.openai.com/codex/guides/agents-md
> - **Codex Memories（auto memory）— https://developers.openai.com/codex/memories**
> - Copilot Memory（public preview）— https://docs.github.com/en/copilot/concepts/agents/copilot-memory
> - Copilot Memory user-level preferences 更新 — https://github.blog/changelog/2026-05-15-copilot-memory-supports-user-preferences-for-pro-pro-users
> - Cursor Memories — `cursor.com/docs/agent/memories`（页面经常返回 404，以产品内 Settings → Memories 为准）

---

## 1. 共识基线

| 概念 | 解释 |
|---|---|
| 人写指令（manual） | 项目里 commit 的 markdown 文件，每次会话开头自动注入。沉淀团队级规范。 |
| Agent 自写（auto） | 工具自己在会话里学到的偏好，由它自己写回某个位置，下次自动召回。 |
| Scope 维度 | managed / user / project / local（gitignored） — 四家覆盖度不同 |

**四家全部支持人写**；**auto memory 现已四家全有**——Codex 自 2026-04-15 起新增 `Memories` 特性（off by default，`~/.codex/memories/` 本地文件），不再是「Codex 无 auto」。

---

## 2. 人写指令对照

| 维度 | Claude Code | Cursor | Codex | Copilot |
|---|---|---|---|---|
| 主文件名 | `CLAUDE.md` | `.cursor/rules/*.mdc` + `AGENTS.md` | `AGENTS.md` | `.github/copilot-instructions.md` |
| Scope 层数 | **4**：managed policy / user / project / local | 2：用户全局 rules / 项目 rules | 2：global / project 链 | 1.5：仓库 + path-scoped |
| 加载方式 | 从 cwd 沿目录树**向上**全部 concat，附加 `CLAUDE.local.md` | rules 按 `alwaysApply` / glob / agent-requested 触发 | 从 project root **向下**到 cwd，每级一个文件，concat | 仓库 root 自动加，`.github/instructions/*.instructions.md` 按 `applyTo` 触发 |
| Path-scoped | `.claude/rules/*.md` + frontmatter `paths:` glob | `.mdc` frontmatter `globs:` | 在 nested 目录放 `AGENTS.md` 或 `AGENTS.override.md` | `.github/instructions/*.instructions.md` + frontmatter `applyTo:` |
| 跨工具兼容 | 可 `@AGENTS.md` import；`/init` 也读 `.cursorrules` / `.windsurfrules` | `AGENTS.md` 被识别 | 原生 `AGENTS.md` | `AGENTS.md` / `CLAUDE.md` 自动识别 |
| 重命名 / 别名 | 通过 `@path` import | 自定义文件名需放到 `.cursor/rules/` 下 | `project_doc_fallback_filenames`（TOML 列表） | 不支持 |
| 私有不入库 | `CLAUDE.local.md`（建议 .gitignore） | 用户级 rules 走云同步 | 用 `~/.codex/AGENTS.md` 全局 | 用户 profile 设置 |
| 上限 | 单文件目标 < 200 行；超大用 `paths:` 切；imports 也算 context | 无明确字节上限 | **32 KiB**（`project_doc_max_bytes` 可调） | 仓库级无硬上限，过大可能截断 |
| 覆盖机制 | 后加载覆盖（cwd 优先级最高）；managed 不可被排除 | rule 之间不显式覆盖，靠匹配规则 | **`AGENTS.override.md`** 同级覆盖 `AGENTS.md` | path-scoped 后于 root 加载 |
| 排除特定文件 | `claudeMdExcludes` glob | rule 设 `alwaysApply: false` | 删 override / 缩小 cwd | 关闭具体 `.instructions.md` |
| 块级 HTML 注释 | `<!-- -->` 在注入前剥离 | 无文档说明 | 无文档说明 | 无文档说明 |

**位置一览（人写）**：

```
Claude:
  /Library/Application Support/ClaudeCode/CLAUDE.md   # managed policy (macOS)
  /etc/claude-code/CLAUDE.md                          # managed policy (Linux/WSL)
  C:\Program Files\ClaudeCode\CLAUDE.md               # managed policy (Windows)
  ~/.claude/CLAUDE.md                                 # user
  ~/.claude/rules/*.md                                # user rules
  ./CLAUDE.md  或  ./.claude/CLAUDE.md                 # project
  ./.claude/rules/*.md                                # project rules（支持 paths frontmatter）
  ./CLAUDE.local.md                                   # local（gitignore）

Cursor:
  ~/.cursor/rules/*.mdc                               # 用户全局
  ./.cursor/rules/*.mdc                               # 项目
  ./AGENTS.md                                         # 兼容入口

Codex:
  ~/.codex/AGENTS.md                                  # global（受 CODEX_HOME 控制）
  ~/.codex/AGENTS.override.md                         # global override
  ./AGENTS.md                                         # project root
  ./<nested>/AGENTS.md                                # nested per-directory
  ./<nested>/AGENTS.override.md                       # nested override
  + project_doc_fallback_filenames 配的别名

Copilot:
  ./.github/copilot-instructions.md                   # 仓库级，默认开
  ./.github/instructions/<name>.instructions.md       # path-scoped，frontmatter applyTo
  ./AGENTS.md  /  ./CLAUDE.md                         # 自动识别
  用户 profile（VS Code Settings: Custom Instructions）# 个人级
```

---

## 3. Agent 自写（auto memory）对照

| 维度 | Claude Code | Cursor | Copilot | Codex |
|---|---|---|---|---|
| 是否支持 | ✅ 默认开（v2.1.59+） | ✅ Memories（默认开） | ✅ Copilot Memory（public preview） | ✅ Memories（**默认关**，2026-04-15+） |
| 写到哪 | 主 agent：`~/.claude/projects/<project>/memory/MEMORY.md` + 同目录 topic 文件；<br>subagent：见 §3a | 云端用户账户，IDE Settings → Memories 可查 | GitHub 账户（[github.com/settings/copilot/memory](https://github.com/settings/copilot/memory)） | **本地** `~/.codex/memories/`（受 `CODEX_HOME` 影响） |
| 启动加载量 | MEMORY.md 前 **200 行 / 25 KB**（topic 文件按需读） | 由 Cursor 注入，开发者不可见 | 由 Copilot 后台注入，按 surface 不同（见 §4） | Codex 注入摘要 / 持久条目 / 近期输入 |
| 触发写入 | Claude 自判 + 用户「记住 …」 | 类似 | 类似；按 stated / inferred 偏好 | **后台异步**生成，避免在 thread 进行中或速率限制接近时写 |
| Scope | 单 repo / worktree；**machine-local，不跨机** | 用户级，**跨项目跨机** | 仓库级 fact + 用户级 preference（见 §4） | 用户级，**跨项目跨机的本地文件**（不跨机器） |
| 跨机同步 | ❌ | ✅（云） | ✅（云） | ❌（本地） |
| 默认 / 关闭 | 默认开 ⟶ `/memory` 面板 · `autoMemoryEnabled: false` · `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` | 默认开 ⟶ Settings → Memories | 见 §4（按 plan 不同） | **默认关**；`config.toml` 加 `[features] memories = true` 或 app Settings 打开；EEA / UK / CH **launch 时不可用** |
| Per-thread / per-session 控制 | `/memory` | — | — | `/memories` 命令控制当前 thread 是否使用 / 生成 |
| 改路径 | `autoMemoryDirectory`（user / policy / `--settings`） | 不可改 | 不可改 | 通过 `CODEX_HOME` 改根；目录名固定 `memories/` |
| 审计 / 编辑 | 纯 markdown，本地编辑 | UI 单条 review/delete | UI 单条 review/delete + **每条带 citation** | 「视为 generated state」可读但**不建议手编**；含 secret 自动 redact |
| 配置粒度 | `autoMemoryEnabled` / `autoMemoryDirectory` | UI 开关 | github.com/settings + repo / org 策略 | `memories.generate_memories` / `memories.use_memories` / `memories.disable_on_external_context` / `memories.min_rate_limit_remaining_percent` / `memories.extract_model` / `memories.consolidation_model` |

### 3a. Claude Code Subagent 持久 memory（容易和 CLAUDE.md scope 搞混，单独列）

Subagent 的 frontmatter 有独立的 `memory` 字段，**三档 scope**，每档对应**固定磁盘路径**：

| `memory:` | 路径 | 用途 |
|---|---|---|
| `user` | `~/.claude/agent-memory/<agent-name>/` | 跨项目共享该 subagent 自己的记忆 |
| `project` | `.claude/agent-memory/<agent-name>/` | 提交进仓库，团队共享 |
| `local` | `.claude/agent-memory-local/<agent-name>/` | gitignored 本地私有 |

- 每个目录里有一个 `MEMORY.md`，subagent 启动时前 **200 行 / 25 KB** 自动注入。
- 开启 memory 时 `Read` / `Write` / `Edit` 工具自动被授权（用来读写自己的 memory 目录）。
- 与主 agent 的 `CLAUDE.md` 加载链 **不共享**（subagent 不读 `CLAUDE.md`，主 agent 也不读 `agent-memory/`）。

### 3b. Cursor / Copilot 本地物 ≠ memory（防混淆）

虽然 Cursor / Copilot 的 auto memory **源头都在云端**，但本地确实有一些**容易被误认成 memory** 的文件，澄清如下：

| 本地物 | 工具 | 是不是 memory | 实际用途 |
|---|---|---|---|
| `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb` | Cursor | ❌ | 沿用 VS Code 的本地 SQLite 缓存（聊天历史、UI state、workspace cache）。memory **不在此**，云端 source of truth。论坛多次报 `state.vscdb I/O 卡死`，与 memory 无关。 |
| `~/.cursor/`（Remote SSH 时出现） | Cursor | ❌ | Agent runtime 文件（日志 / MCP socket / 二进制）。 |
| `.cursor/rules/*.mdc` | Cursor | ❌ | **人写**的 rules（§2 manual），不是 auto memory。 |
| `~/.vscode/extensions/github.copilot-*/` | Copilot | ❌ | 扩展二进制 + 模型缓存，不含 memory。 |
| VS Code SQLite chat history | Copilot | ❌ | 聊天 transcript，跟 Copilot Memory 是两回事。 |

**Copilot 官方文档原话**：「Copilot Memory is enabled per user, not per repository... For individual Copilot Pro and Copilot Pro+ subscribers, Copilot Memory is on by default and can be disabled in **personal Copilot settings on GitHub**.」管理 UI 仅在 `github.com/settings/copilot/memory`。

**Cursor 论坛版主原话**（[forum.cursor.com](https://forum.cursor.com) "Cursor position desync" 线程）：「As for **memories and user rules, they're stored in the cloud and not locally**.」

---

## 4. Copilot Memory 现状（public preview）

**状态**：public preview（官方注明 "in public preview and is subject to change"），尚未 GA。

### 4.1 计划可用性

| 计划 | 默认状态 | 备注 |
|---|---|---|
| Copilot Pro / Pro+ | **on by default** | 含 repo-level facts + **user-level preferences** |
| Copilot Business / Enterprise | **off by default** | 管理员需在 org / enterprise 设置启用；启用后用户级 preferences 也可用 |

> 早先 2026-05-15 changelog 说「Pro/Pro+ early access user preferences」，到当前官方文档里这一项已并入 GA-preview 文档主线，4 个 plan 都覆盖（plan 决定默认开关与 admin 控制）。

### 4.2 用在哪些 Copilot surface

| Surface | 用到 repo-level facts | 用到 user-level preferences |
|---|---|---|
| Copilot **coding agent**（cloud agent） | ✅ | ✅（发起人的） |
| Copilot **code review** | ✅ | ❌（不用 user prefs） |
| Copilot **CLI** | ✅ | ✅（**仅当前用户**） |
| Copilot Chat (IDE / web) | — | — |

> 注意：**普通 IDE 内 Copilot Chat 当前不消费 Memory**——别把 Memory 跟 Chat 的 Custom Instructions 混为一谈。

### 4.3 关键机制

- **Citation**：每条 fact / preference 都附 "why" 引用（代码片段、过往对话），UI 可点查。
- **写入资格**：repo-level fact 仅由对该 repo **有 write 权限**的用户操作产生；user-level preference 仅当前用户产生。
- **校验**：repo-level fact 在被使用前会针对**当前 branch 状态** revalidate，过期事实不再生效。
- **TTL**：**未使用条目 28 天自动删除**，每次使用重置计时器。
- **管理 UI**：https://github.com/settings/copilot/memory（个人），org / enterprise 层在 Copilot 策略面板。
- **Personal Context** 是另一个独立特性（让 Copilot 检索你的私人 repo 语料）——**不要与 Memory 并列**。

---

## 5. 字段命名速查

| 概念 | Claude | Cursor | Codex | Copilot |
|---|---|---|---|---|
| 项目级指令 | `CLAUDE.md` | `.cursor/rules/*.mdc` | `AGENTS.md` | `.github/copilot-instructions.md` |
| Path-scoped frontmatter 键 | `paths:` | `globs:` | （靠目录位置） | `applyTo:` |
| 本地不入库 | `CLAUDE.local.md` | 用户 rules | `CODEX_HOME` 改家目录 | profile |
| Auto 默认 | 开 | 开 | **关** | Pro/Pro+ 开；Business/Enterprise 关 |
| Auto 关闭方式 | `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` / `/memory` | UI | 不开 `memories=true` 即可；或 `/memories` per-thread | github.com/settings/copilot/memory |
| Auto 存储 | 本地 `~/.claude/projects/<project>/memory/` | 云 | 本地 `~/.codex/memories/` | 云（github.com） |
| Per-thread 切换 | `/memory` | — | `/memories` | — |

---

## 6. 跨家迁移配方

**基线策略**：项目根放一份 `AGENTS.md` 作为四家共识源。

| 谁 | 接入方式 |
|---|---|
| Codex | 原生读 `AGENTS.md` |
| Copilot | 原生识别 `AGENTS.md`（也识别 `CLAUDE.md`） |
| Cursor | 原生识别 `AGENTS.md` |
| Claude | 建 `CLAUDE.md`，第一行 `@AGENTS.md`；之后追加 Claude 专属段（`.claude/rules/` 用于 path-scoped） |

**重命名仓库** `TEAM_GUIDE.md` → Codex 用 `project_doc_fallback_filenames = ["TEAM_GUIDE.md"]`；其他工具仍需 `AGENTS.md`（可 symlink）。

**大单仓**：用各家 path-scoped 机制按子目录拆，不要把 200+ 行塞进根 `AGENTS.md`。

---

## 7. <platform> 适用性建议

| 场景 | 建议 |
|---|---|
| 项目共识基线 | 根 `AGENTS.md`（已存在，指向 `CLAUDE.md`） |
| Claude 专属 path-scoped | 用 `.claude/rules/<topic>.md` + `paths:` frontmatter，例如 `tech-docs/**/*.md` 配文档写作规则 |
| Copilot path-scoped | `.github/instructions/<name>.instructions.md` + `applyTo:` |
| Cursor path-scoped | `.cursor/rules/<topic>.mdc` + `globs:` |
| 个人不入库 | `CLAUDE.local.md`（已 .gitignore） |
| 不开 auto memory 的合规理由 | 跨机不同步、不能审计、可能记入敏感信息；如团队要开，约定 `/memory` 周审一次 |

---

## 8. 红线（不要再犯的错）

1. ❌ 不要说「Claude 从 `brain/` 提炼」——根本没有 `brain/` 概念。
2. ⚠️ **要区分**两个 `user|project|local`：① `CLAUDE.md` 的 4 层 scope 是 **managed / user / project / local**；② subagent frontmatter 的 `memory:` 是 **user / project / local 三档**且对应固定路径（`~/.claude/agent-memory/<name>/` · `.claude/agent-memory/<name>/` · `.claude/agent-memory-local/<name>/`）——**别把这两件事混成一件**。
3. ❌ 不要写「Copilot Memory 已 GA」——当前仍是 **public preview**。
4. ❌ 不要把 Copilot Memory 写成「只对 Pro/Pro+」——4 个 plan 都覆盖，差别是**默认开关与 admin 控制**。
5. ❌ 不要把 Copilot Memory 和 Personal Context 并列——两个独立机制。
6. ❌ 不要说 Copilot Memory 用在 IDE Chat——当前只用在 **coding agent / code review / CLI**。
7. ❌ 不要说 Codex 「无 auto memory」——**2026-04-15 起**有 `Memories`（off by default，本地 `~/.codex/memories/`，EEA/UK/CH launch 时不可用）。
8. ❌ 不要把 Codex Memories 写成「云端」——是**本地文件**，受 `CODEX_HOME` 控制。
9. ❌ 不要给 Cursor / Copilot 写出「具体文件路径」——它们的 auto memory 在云端，不在磁盘文件里（Claude / Codex 才是本地文件）。
10. ❌ 不要忘记 Codex 的 32 KiB `project_doc_max_bytes` 上限——文档大了会被截断。
11. ❌ 不要在 `CLAUDE.md` 里塞 200 行以上——超出会降低遵循率，应改用 `.claude/rules/` + `paths:` 切分。
12. ❌ 不要把 `autoMemoryDirectory` 放到 project / local settings——只有 user / policy / `--settings` 接受，防 cloned repo 劫持写入。
13. ❌ 不要忘记 managed CLAUDE.md 在 macOS 是 `/Library/Application Support/ClaudeCode/CLAUDE.md`，不在 `~`。
14. ❌ 不要假设 Copilot Memory 永久保留——**未使用 28 天自动删**（每次使用重置计时器）。
