<!-- REFERENCE ONLY: sanitized sample, not for production -->
---
name: scaffold-agents-md
description: 业务子域 AGENTS.md 手动脚手架 skill。扫描 apps/* / packages/* / 自定义 path，在缺少 AGENTS.md 的子目录下生成最小 AGENTS.md 占位（never overwrite）。仅手动调用，install.sh 不自动触发。
disable-model-invocation: true
allowed-tools: ["Read", "Write", "Glob"]
argument-hint: "[--paths=<glob1,glob2,...>] [--dry-run]"
arguments:
  - name: paths
    required: false
    description: "逗号分隔 glob 列表，默认 apps/*,packages/*"
  - name: dry-run
    required: false
    description: "只报告将创建的文件，不写盘"
context: fork
paths:
  - "apps/**/AGENTS.md"
  - "packages/**/AGENTS.md"
---

# Scaffold AGENTS.md Skill

> **何时调用**：用户在业务子域（如 `apps/<svc>` / `packages/<lib>`）需要独立 AGENTS.md 边界声明时**手动**触发。
> **权威**：plan v6 §四 D22。install.sh 仅在 step 1.5 处理 10 个固定通用目录的根级 AGENTS.md；业务子域的细分由本 skill 按需触发。

## 行为约束（硬规则）

- **never overwrite**：目标路径已存在 AGENTS.md → 跳过 + 报告 `SKIP: exists`
- **never delete**：不允许移除任何现有文件
- **only manual**：禁止被任何 hook / CI / install 脚本自动调用
- **scope-bounded**：默认仅扫 `apps/*,packages/*` 一级子目录，深度 = 1；显式 `--paths` 才扩展

## 输出模板（写入目标 AGENTS.md）

```markdown
<!-- AGENTS.md · scaffolded by scaffold-agents-md skill -->
# AGENTS.md · <dir-name>

## Scope
本目录边界与职责（请补全）。

## Inputs / Outputs
- 上游依赖：<TBD>
- 对外暴露：<TBD>

## Local Conventions
- 编码 / 测试 / 命名等子域特殊约定（无则写 inherit-from-root）。

## Red Lines
- 子域特有红线（无则继承根级 AGENTS.md）。
```

## Worked Example

**Input**
```
/scaffold-agents-md --paths=apps/*,packages/*
```

**Output**（控制台报告）
```
CREATE apps/<svc-a>/AGENTS.md
CREATE apps/<svc-b>/AGENTS.md
SKIP   apps/<svc-c>/AGENTS.md (exists)
CREATE packages/<lib-a>/AGENTS.md
Total: created=3 skipped=1
```

## Gate
无 Gate（仅生成占位 · 内容由各域 owner 补全）。
