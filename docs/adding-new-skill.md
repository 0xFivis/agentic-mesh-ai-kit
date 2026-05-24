# Adding a New Skill

> 给 ai-kit 添加一个新的 SKILL。

## SKILL 是什么

一个 skill = 一个 trigger-based 工作流封装。frontmatter 告诉 agent **何时触发**，正文告诉 agent **做什么**。

## 目录结构

```
skills/<skill-name>/
├── SKILL.md             ← 触发器 + 主流程（必有）
├── README.md            ← 给人看的设计说明（可选）
├── checklists/*.md      ← 引用的检查清单（可选）
└── examples/*.md        ← 示例（可选）
```

## SKILL.md 模板

```markdown
---
name: <skill-name>
description: |
  <一句话：何时使用 + 触发关键词>
triggers:
  - <关键词 1>
  - <关键词 2>
inputs:
  - <输入需要什么>
outputs:
  - <产出什么>
---

# <Skill Name>

## When to use

<触发场景：用户说什么 / agent 在做什么时 invoke>

## Prerequisites

- <前置条件>

## Steps

1. <步骤 1>
2. <步骤 2>

## Output

<产出物格式 / 落点>

## Anti-patterns

- <常见误用 1>
```

## 命名规范

- kebab-case，动宾结构优先：`audit-prd`、`scaffold-agents-md`、`retro-audit`
- 一个 skill 一件事；功能正交

## 注册

不需要手动注册。`scripts/install.sh` step 4 自动扫描 `skills/*/SKILL.md` 并分发到各厂商目录。

## 与 SOP 的关系

- skill 复杂时 → 在 SKILL.md 引 `sop/<sop>.md`
- skill 简单时 → 全部写在 SKILL.md 内

## 提交清单

- [ ] `SKILL.md` 有 frontmatter（name / description / triggers）
- [ ] description 包含触发关键词（agent 靠它匹配）
- [ ] 已在 `templates/README.md` / `playbook.md` 提及（若属核心 skill）
- [ ] 已本地 install 到一个 target 仓做端到端 smoke
