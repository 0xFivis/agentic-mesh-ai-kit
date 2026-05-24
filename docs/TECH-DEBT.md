# Tech Debt · agentic-mesh-ai-kit

> 仅记录本仓相关的技术债。Arch-kit 侧债务见 `agentic-mesh-arch-kit/docs/TECH-DEBT.md`。
> 更新规则：完成项打 ✅ 并保留行；不再有效项移到 `## 已归档`。

最近更新：2026-05-24（Phase A–E 收尾后初版）

---

## P2 · 文档与契约一致性

### AI-01 · D28 `type:` 字段未引入，但 SKILL 已用 hack
- **位置**：`skills/new-service-bootstrap/SKILL.md` Step 4
- **现状**：yaml 块用 `role: ${TYPE}` 借 `role` 字段承载 `--type` 概念。若未来 arch-kit `_registry.yaml.tmpl` 引入独立 `type:` 字段（D28 规划），D3 SKILL + `new-service.sh --type` MATRIX 需联动更新。
- **建议**：D28 立项时把"3 处联动"列入 checklist：`_registry.yaml.tmpl` / `new-service.sh` / `new-service-bootstrap/SKILL.md`。

### AI-02 · playbook §3.6 附表内容未审
- **位置**：`playbook.md §3.6`
- **现状**：本轮 Phase A–E 修了 §T4.1/4.2/§3.1/§3.2/§3.4/§3.7，没动 §3.6 "新建服务"清单；可能与新 D3 SKILL 的 7 步序号、产物列表略偏。
- **建议**：下次迭代顺手把 §3.6 附表与 `new-service-bootstrap/SKILL.md` 步骤交叉比对一次。

### AI-03 · `impact-analysis.md.tmpl` 10 节强校验缺失
- **位置**：`templates/specs/impact-analysis.md.tmpl` + `skills/bc-impact-map/SKILL.md`
- **现状**：模板规定 10 节每节 `[ ] 无影响 · 理由` 必填，但 `bc-impact-map` skill 输出 + CI 都没强校验"10 节齐全 + 每节至少一个勾选"。
- **建议**：在 ai-kit 加 `hooks/check-impact-analysis.sh`（或纳入 self-review-agent 步骤 2 的物理状态扫描），对 `specs/**/impact-analysis.md` 做存在性 + 节标题正则匹配。

---

## P3 · 工程化 / 维护性

### AI-04 · 3 个新 skill 缺端到端 sample run
- **位置**：`skills/{self-review-agent,new-service-bootstrap,task-plan-drafting}/`
- **现状**：SKILL.md 写得齐，但无 `examples/` 或 reference output；新使用者首次跑容易跑歪。
- **建议**：每个 skill 加 `examples/sample-input.md` + `examples/sample-output.md`（取一个真实 PR 脱敏即可）。

---

## P2 · memory 体系开放项补录

### AI-06 · `templates/specs/constitution.md.tmpl` 不存在（decisions-log W4 / handoff A5）
- **位置**：`agentic-mesh-ai-kit/templates/specs/constitution.md.tmpl`（沿用现有 `templates/specs/` 复数目录，与 `impact-analysis.md.tmpl` 同级；handoff A5 中的 `templates/spec/` 单数为笔误，统一归并到 `specs/`）。
- **落地**：`.specify/memory/constitution.md`（spec-kit 默认路径，由 `scripts/install.sh` `specify init` 之后的 post-init `render_tmpl` 覆盖）。
- **实测**：`ls templates/specs/` 只有 `impact-analysis.md.tmpl`，无 `constitution.md.tmpl`，未提供平台特定 9 条不变原则脚手架。
- **影响**：spec-kit `specify init` 只写入通用骨架到 `.specify/memory/constitution.md`；playbook L642 / L677 + `skills/tech-intake/SKILL.md` 引用 `memory/constitution.md` 作"仓库级不变原则单例"拿不到本平台真实锚。
- **建议**：新建 `templates/specs/constitution.md.tmpl`（≤9 条顶级原则占位）+ 在 `scripts/install.sh` `specify init` 之后追加 `render_tmpl "$KIT_ROOT/templates/specs/constitution.md.tmpl" ".specify/memory/constitution.md"`。

### AI-07 · Codex hooks 2 挂点未落实（decisions-log W6）
- **位置**：`templates/hooks/codex/hooks.json.tmpl`
- **现状**：playbook §3.7 / §6.3 明确 Codex 至少应挂 `UserPromptSubmit`（扫 `[NEEDS CLARIFICATION]`）+ `PreToolUse`（拦 `--no-verify` / secret）两个事件；当前模板内容未核对是否含这两条。
- **建议**：审一遍 `hooks.json.tmpl`，缺则补齐 2 个 `type: command` handler。

### AI-08 · tech-intake skill 重新定位未做（inventory-skills 待办 #2）
- **位置**：`skills/tech-intake/SKILL.md`
- **现状**：description 仍写"输出 SPEC.md 草稿"，与 inventory-skills 确认结论"应改为对 spec-kit 产出的 spec.md 做二次自检 · 不起草 spec.md"冲突；当前易与 `/speckit.specify` 职责打架。
- **建议**：改 `description` + body Step 序，明确"输入：已存在 spec.md ｜ 输出：审检 issues 列表 + 可选 patch 建议"，并在 README/skills 列表注明"非必选 · 起手用 `/speckit.specify`"。

---

## TD · 跨仓治理 / 流程 / 知识类技术债（明确推迟，避免遗忘）

> 状态：本轮 R2 系统审计沉淀；非阻塞当下“心智模型 + SOP+AI 流程清晰可落地”目标，**待心智模型/落地框架完成后**集中处理。
>
> 以下条目从 memory `decisions-log.md §E` 同步过来；arch-kit 侧 TECH-DEBT 同步一份（两边都保留，便于任一仓独立阅读）。

| # | 债务 | 类别 | 触发条件 |
|---|------|------|---------|
| TD1 | 架构组角色定义（人数/SLA/选拔/oncall） | 治理 | team-operating-model 同步成熟时 |
| TD2 | 横切 R 监控节奏（频率/触发/输出 action）| 治理 | 第一次实跑 retro 后 |
| TD3 | 争议解决路径（作者 vs reviewer 不一致升级链）| 治理 | 首次出现实际争议 |
| TD4 | D20 签字授权矩阵细化（每个 Gate 的可授权条件枚举）| 治理 | 团队首次跑通完整 SOP 后 |
| TD5 | CI 链路总图（W12/W15/W16/lint/sync 触发顺序+失败处置）| 工具 | W12+W16 任一落地时 |
| TD6 | PR template / Issue template 化（回写③ checkbox / open-questions label）| 工具 | W17 reviewer-agent 落地前 |
| TD7 | gate-checklist 5 条具体内容核对（与 playbook cross-check）| 工具 | T4.1 首次实跑前 |
| TD8 | bctx 重组流程（服务跨 bctx 迁移 contracts/<bctx>/ 路径变更）| 流程 | 首次出现需求时 |
| TD9 | 服务下线/deprecated 流程 + `_registry.yaml` status 字段 | 流程 | 第一个服务下线时 |
| TD10 | 跨子仓落地 roadmap（ai-workflow/playbook/arch-kit/ai-kit/tech-standards 实施顺序）| 实施 | 心智模型定型后立即处理（最优先 TD）|
| TD11 | emergency hotfix lane 显式化（虽 D20 已通用授权机制覆盖，可能需单独 SOP 短路径）| 流程 | 首次紧急 fix 后 retro |
| TD12 | _data-index.md 自动化前的过渡期描述（W12 未上前如何看 schema 状态）| 工具 | W12 排期前 |
| TD13 | AI agent (Claude/Codex/Copilot/Cursor) 差异化使用指南 | 知识 | 第二个 agent 接入时 |
| TD14 | 新人 onboarding 路径（design-philosophy → SOP → playbook → inventory 阅读图）| 知识 | 第一个新人加入时 |
