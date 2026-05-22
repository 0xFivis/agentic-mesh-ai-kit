<!--
来源：ai-workflow/templates/checklists/05-data-redline.md
权威：ai-workflow/ai-agent-playbook.md
触发：任何涉及用户数据 / 凭证 / PII / 资金的 PR · 始终在 context（横切）
-->

# 横切 · Data Redline 8 红线 Checklist

> 任何涉及用户数据 / 凭证 / PII / 资金的代码 / 文档 / AI prompt **必须**过本 checklist。触一条立即停。

## 资料 4 级速查

| 级别 | 示例 |
|---|---|
| L1 公开 | 营销页 / 公开 API 文档 |
| L2 内部 | 架构图 / 内部 wiki |
| L3 受限 | 用户脱敏数据 / 业务指标 |
| L4 高敏 | 凭证 / 身份证明原件 / 登录密码 / 私钥 / Token / PII 明文 |

## 8 红线（触一条 = BLOCK）

| # | 红线 | ✅/❌ | 证据 |
|---|---|---|---|
| 1 | L4 数据明文入 AI prompt |  |  |
| 2 | 生产凭证写代码 / 配置 / 提交历史 |  |  |
| 3 | 真实用户 PII 入测试 / 示例 / dev DB |  |  |
| 4 | 资金 / 仓位 / 订单数据日志明文（必须 mask 中段）|  |  |
| 5 | 私钥 / Token 落 git 历史（即使后删 → 必 rotate）|  |  |
| 6 | 跨 BC 直接读对方私有数据表（必走 API · STD-02）|  |  |
| 7 | prod 数据未脱敏即拉到 dev / staging |  |  |
| 8 | AI 草稿含真实客户 ID / 邮箱 / 手机 / 身份证（必占位 `<USER-ID>` 等）|  |  |

## 触线处理

| 场景 | 处理 |
|---|---|
| 即将提交的代码触线 | **拒绝提交** · 改脱敏 / placeholder |
| 已提交的历史触线 | rotate 受影响凭证 · `git filter-repo` 清历史 · 写 incident 留痕 |
| AI 草稿触线 | 草稿作废重出 · 留痕本次触线原因 |
| spec / ADR / STD 触线 | 文档版回退 + 重审 |

## 关联

- skill：`data-redline`（横切 · 始终 in context）
- 上游：STD-05-security
- 下游引用：`gate-checklist` review 模式红旗 #2 · `qa-cases` 红线象限 · `retro-audit` 第 6 项
