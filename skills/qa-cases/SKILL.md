---
name: qa-cases
description: T4.4 测试用例生成 + 探索性 mutation 测试 skill。从 contracts + quickstart + impact-map 抽测试矩阵，覆盖正常 / 边界 / 异常 / 红线四象限，产出可执行测试代码骨架。
disable-model-invocation: false
allowed-tools: ["Read", "Write", "Edit", "Bash"]
argument-hint: "<feature-id> [--mutation]"
arguments:
  - name: feature-id
    required: true
  - name: mutation
    required: false
    description: "加 --mutation 启用探索性变异测试"
context: fork
paths:
  - "tests/<feature-id>/**"
  - "specs/<feature-id>/test-matrix.md"
---

# QA Cases Skill

> **何时调用**：T4.4 QA 验收（T4.2 编码完成、T4.3 评审通过后）。
> **权威**：playbook。

## 输入
1. `specs/<feature-id>/contracts/*.yaml`
2. `specs/<feature-id>/quickstart.md`（自验场景）
3. `specs/<feature-id>/impact-map.md`（风险分级）
4. `specs/<feature-id>/data-model.md`（状态机 / 字段约束）

## 测试矩阵（四象限）

| 象限 | 覆盖 | 用例数下限 |
|---|---|---|
| 正常 | quickstart 场景逐条 | ≥ quickstart 场景数 |
| 边界 | 字段约束边界值（min / max / null / empty / unicode）| 每字段 ≥ 2 |
| 异常 | contract 定义的所有错误码 / 状态码 | 每错误码 ≥ 1 |
| 红线 | impact-map 标 high 风险项 + data-redline 8 红线触碰场景 | 每风险条 ≥ 1 |

## 输出
```
tests/<feature-id>/
├── normal/             ← 正常用例
├── boundary/           ← 边界
├── error/              ← 异常
└── redline/            ← 红线
specs/<feature-id>/test-matrix.md     ← 4 象限覆盖率矩阵 + 测试 ID 映射
```

## Mutation Mode（探索性 · 可选）
加 `--mutation` 时启用：
1. 用 `mutmut` / `stryker` 类工具对 PR 涉及代码注入变异
2. 跑全套测试，统计 mutation kill rate
3. **kill rate < 70%** → 失败，要求补测试
4. 报告落 `specs/<feature-id>/_mutation-report.md`

## Gate（进 T4.5）

- 4 象限覆盖率 100%（每象限至少满足下限）
- mutation kill rate ≥ 70%（如启用）
- 所有 high 风险项均有用例覆盖

## Worked Example

> 占位示例 · 待 v0.2+ 填充真实业务场景。

**Input**：
```
specs/FEAT-042/contracts/<service-name>.openapi.yaml
specs/FEAT-042/quickstart.md
specs/FEAT-042/impact-map.md
specs/FEAT-042/data-model.md
```

**调用**：
```bash
claude skill qa-cases FEAT-042 --mutation
```

**Output**：
```
tests/FEAT-042/
├── normal/test_<entity>_create.py        # quickstart 场景
├── boundary/test_<attribute>_limits.py   # min/max/null/empty/unicode
├── error/test_4xx_5xx.py                 # 每错误码 ≥ 1
└── redline/test_<redline-name>.py        # impact-map high + data-redline
specs/FEAT-042/test-matrix.md             # 4 象限覆盖率矩阵
specs/FEAT-042/_mutation-report.md        # kill rate（启用 --mutation 时）
```
