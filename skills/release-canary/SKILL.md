---
name: release-canary
description: T5 部署阶段 skill。产出灰度方案 + 回滚剧本 + 观测指标基线。AI 无 prod 写权限，仅出草稿 / 观察 / 建议，部署执行由人。
disable-model-invocation: false
allowed-tools: ["Read", "Write"]
argument-hint: "<feature-id>"
arguments:
  - name: feature-id
    required: true
context: fork
paths:
  - "specs/<feature-id>/release.md"
  - "specs/<feature-id>/rollback.md"
---

# Release Canary Skill

> **何时调用**：T5 部署 · T4 全 Gate 通过后。
> **权威**：playbook（AI 无 prod 写权限 · 只产草稿 / 观察 / 建议）。
> **硬红线**：本 skill **禁挂 Bash hook 执行部署命令**。

## 输入
1. `specs/<feature-id>/plan.md` + `quickstart.md`
2. `specs/<feature-id>/impact-map.md`（high 风险项 = 重点监控）
3. 现有 SLO / SLI 基线（从 observability 仓 / Grafana dashboard 链接）

## 输出 1：`release.md`（灰度方案）

```markdown
## 灰度阶段

| 阶段 | 流量 | 持续 | 观察指标 | 进阶判据 |
|---|---|---|---|---|
| canary-1 | 1% | 30 min | latency p99 < X / err rate < Y | 全绿 → canary-2 |
| canary-2 | 10% | 2 h | + 业务指标 Z | 全绿 → 50% |
| 50% | 50% | 4 h | ... | 全绿 → 100% |
| ga | 100% | - | - | - |

## 监控告警

- alert-1: <metric> > <threshold> → 自动钉钉 + 暂停推进
- alert-2: ...

## DoR（启动 canary-1 前必备）

- [ ] T4 全 Gate 绿
- [ ] rollback.md Approved
- [ ] on-call 排班确认
```

## 输出 2：`rollback.md`（回滚剧本）

```markdown
## 触发条件

- 自动：alert-1 / alert-2 触发即回滚
- 手动：on-call 判断业务异常

## 回滚步骤（按顺序）
1. <step 1> · 命令示例 · 预期耗时
2. <step 2> · ...
3. ...

## 数据回滚

- DB schema 是否需 down migration？（是 → 列脚本；否 → 标 N/A）
- 缓存清理范围
- 消息队列处理（pending 消息丢弃 / 重处理）

## 验证

- [ ] 流量回旧版后 metric 恢复
- [ ] 用户侧无残留状态
```

## Gate（进 T6 观测窗）

- release.md + rollback.md 双 Approve（SRE Lead + PM-Tech）
- canary-1 启动前 on-call 签到
- AI 草稿留痕：方案候选 / 选定 / 排除
