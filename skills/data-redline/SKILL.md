---
name: data-redline
description: 资料分级与数据红线 skill · 横切始终在 context（settings.json alwaysLoaded）。提供 4 级数据分类 + 8 条不可越红线 + 触红线的脱敏 / 加密 / 留痕处理流程。任何涉及用户数据 / 凭证 / PII / 资金的代码与文档必须先过这把尺。
disable-model-invocation: false
allowed-tools: ["Read"]
context: inherit
---

# Data Redline Skill

> **何时调用**：横切 · **始终在 context**（在 `settings.json` 配 `skills.alwaysLoaded` 强制保活）。
> **权威**：playbook + tech-standards/STD-05-security。

## 资料 4 级分类

| 级别 | 定义 | 示例 | 处理 |
|---|---|---|---|
| **L1 公开** | 已对外公开 | 营销页 / 公开 API 文档 | 无限制 |
| **L2 内部** | 仅员工 / 合作伙伴 | 架构图 / 内部 wiki | 不外发 / 不入公网仓 |
| **L3 受限** | 部分员工（按角色 / RBAC）| 用户脱敏数据 / 业务指标 | 日志加密 / 访问审计 |
| **L4 高敏** | 严格限定 + 不可入 prompt | 凭证 / 身份证明原件 / 登录密码 / 私钥 / Token / PII 明文 | **禁入 AI prompt** / 加密存储 / 审计 / 销毁记录 |

## 8 条不可越红线（**触一条立即停**）
1. **L4 数据明文入 prompt** —— 任何 AI 调用前必须脱敏 / 替换为 placeholder
2. **生产凭证写入代码 / 配置文件 / 提交历史**（用 secret manager）
3. **真实用户 PII 入测试 / 示例 / dev 数据库**（用 faker 生成）
4. **资金 / 仓位 / 订单数据日志明文打印**（必须 mask 中间段）
5. **私钥 / Token 落 git 历史**（即使后续删除 → 必须 rotate）
6. **跨 BC 直接读对方私有数据表**（必须走 API · STD-02）
7. **prod 数据未脱敏即拉到 dev / staging**（必须 anonymize pipeline）
8. **AI 草稿包含真实客户 ID / 邮箱 / 手机号 / 身份证**（必须替换为 `<USER-ID>` 等占位）

## 触红线后的处理

| 场景 | 处理 |
|---|---|
| 即将提交的代码触线 | **拒绝提交** · 改为脱敏 / placeholder |
| 已提交的历史触线 | rotate 受影响凭证 · `git filter-repo` 清历史 · 写入 incident 留痕 |
| AI 草稿触线 | 草稿作废重出 · 留痕本次触线原因 |
| spec / ADR / STD 触线 | 文档版回退 + 重审 |

## 与其他 skill 的协同

- `qa-cases` skill 的「红线」象限必须每条都对应到本 skill 的 8 红线
- `gate-checklist` skill review 模式第 2 条红旗直接引用本 skill
- `retro-audit` skill 9 项审计第 6 条引用本 skill

## 集成（Claude Code 示例）
在 `.claude/settings.json`：

```json
{
  "skills": {
    "alwaysLoaded": ["data-redline"]
  }
}
```
其他 agent 没有 alwaysLoaded 概念，靠 `description:` 字段高频召回（Copilot / Codex / Cursor）。

## Worked Example

**Input**（待审 prompt 片段）
```
请帮我把这条用户记录写入测试数据库：
  user_id=U-1001, email=alice@example.com, password=P@ssw0rd, token=eyJ...
```

**Output**（skill 触发后改写）
```
[REDLINE-2,3,5 TRIGGERED] 拒绝原样写入。改用 placeholder：
  user_id=<USER-ID>, email=<EMAIL>, password=<SECRET>, token=<TOKEN>
并在 docs/incidents/<YYYY-MM-DD>-prompt-redline.md 留痕。
```
