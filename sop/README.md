# sop/

> 跨厂商通用的"工作流 SOP"。skill 触发后由 agent 加载，作为执行剧本。

## 清单

| SOP | 用途 |
|---|---|
| [tech-delivery-sop.md](tech-delivery-sop.md) | 技术交付主流程（spec → plan → implement → review → deliver） |

## 与 skills 的关系

- `skills/<skill>/SKILL.md` 是**触发器**（YAML frontmatter + 何时调用 + 调用什么）
- `sop/<sop>.md` 是**执行剧本**（详细步骤、检查清单、产出物）
- skill 可在正文里 `详见 sop/<sop>.md` 引用本目录

## 与 playbook.md 的关系

- `playbook.md`（仓根）= **一页全景**，给人快速理解全套协作矩阵
- `sop/` = **可执行剧本**，agent 加载用
