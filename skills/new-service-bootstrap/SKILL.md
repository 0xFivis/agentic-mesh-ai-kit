---
name: new-service-bootstrap
description: 新建微服务的"智能引导层"，包裹 arch-kit 的 scripts/new-service.sh 机械脚本。前置 5 问访谈 → 预检冲突 → 执行脚本 → 按访谈结果填充新建文件的占位符 → 登记 _registry.yaml → 给出 contracts 骨架建议与 PR 描述模板。触发词：新建服务 / bootstrap service / new service / 加服务。
disable-model-invocation: false
allowed-tools: ["Read", "Grep", "Glob", "Bash", "Write", "Edit"]
argument-hint: "<bctx> <NN> <role> [--type api|worker|saga|gateway]"
arguments:
  - name: bctx
    required: false
    description: "限界上下文（如 order / wallet）。若未提供则访谈环节询问"
  - name: NN
    required: false
    description: "服务序号两位数字（如 12）。若未提供则建议下一个可用值"
  - name: role
    required: false
    description: "服务角色（如 api / processor / engine）"
  - name: --type
    required: false
    description: "类型 ∈ {api, worker, saga, gateway}。若未提供则访谈"
context: fork
paths:
  - "apps/**"
  - "docs/services/**"
  - "contracts/**"
---

# New Service Bootstrap Skill

> **定位**：`scripts/new-service.sh` 是机械脚手架（mkdir + 文件矩阵实例化 + _registry 行）；本 skill 是其**智能包裹层**，提供前置访谈、占位符填充、contracts 引导。
> **权威**：`docs/architecture/00_governance.md §5`（消费仓根路径）+ `playbook.md §3.6` 附表。
> **不重复脚本职责**：本 skill 不再写 mkdir / cp .tmpl，只做"问 + 填 + 注 + 引导"。

## 触发与边界

- ✅ 触发：用户说"新建服务" / "加 svc-12-order-api" / "bootstrap service"
- ❌ 不触发：现有服务文档修改（用 `self-review-agent`）/ contracts 新增（用 `contract-first`）

## 步骤

### Step 0 · 前置访谈（5 个必答）

| # | 问题 | 校验 |
|---|---|---|
| 1 | 限界上下文 bctx？ | 必须已在 `_context-map.yaml` 已登记；新 bctx 需先开 ADR + 更新 `_context-map.yaml` 与 `01_业务上下文.md` |
| 2 | 服务编号 NN？ | 扫 `apps/svc-*` 取下一个未占用的两位数 |
| 3 | 服务角色 role？ | 小写连字符（api / processor / ledger-writer / ...） |
| 4 | 类型 type ∈ {api, worker, saga, gateway}？ | 决定文件矩阵列数（governance §5.2）|
| 5 | 一句话职责 + owner team + 上游 / 下游 + 初始 SLO？ | 用于填 README.md 与 `_registry.yaml` services 条目 |

### Step 1 · 预检

```bash
# bctx 注册检查（_context-map.yaml 为权威）
grep -q "name: ${BCTX}" docs/architecture/_context-map.yaml || echo "❌ bctx 未在 _context-map.yaml 登记，需先开 ADR"

# NN 冲突检查
[ -d "apps/svc-${NN}-${BCTX}-${ROLE}" ] && echo "❌ svc-${NN} 已存在"

# type 白名单
echo "${TYPE}" | grep -qE '^(api|worker|saga|gateway)$' || echo "❌ type 非法"
```

任一 ❌ → 停，回 Step 0。

### Step 2 · 执行脚本

```bash
bash scripts/new-service.sh "${BCTX}" "${NN}" "${ROLE}" --type "${TYPE}"
```

期望输出：实例化 N 个 .md 文件（按 type 在 4×8 矩阵中的列数）+ _registry.yaml 追加一行。

### Step 3 · 填充占位符（按访谈结果）

逐文件 sed 替换或 `Edit` 工具填入：

| 文件 | 待填占位符 | 数据源 |
|---|---|---|
| `docs/services/svc-${NN}-${BCTX}-${ROLE}/README.md` | `<svc>` `<bounded-context>` 业务职责段 | Q1, Q5 |
| `docs/services/.../runbook.md` | 接班人 / oncall 信道 / 紧急联络 | 团队配置 |
| `docs/services/.../non-functional.md` | SLO 初值（P99 延迟 / 吞吐 / 可用性）| 团队基线 |
| `docs/services/.../api.md`（若 type ∈ api/gateway）| 首批 ≥3 个端点草拟 | Q5 职责拆解 |
| `docs/services/.../events.md`（若 type ∈ api/worker/saga）| 发布 / 订阅事件列表 | Q5 上下游 |
| `docs/services/.../saga.md`（若 type=saga）| 编排步骤 + 补偿动作 | Q5 + 调研 |
| `docs/services/.../state-machine.md`（若 type ∈ worker/saga）| 核心状态 + 转换 | Q5 + 调研 |

> 不填全也可，但每个未填项必须留 `TODO(<owner>, <due-date>)` 显式标记，由 `self-review-agent` 后续审。

### Step 4 · 登记 _registry.yaml

按 `docs/services/_registry.yaml.tmpl` 实际 schema 在 `services:` 列表追加条目（字段：`name / bctx / role / owner / repo / runtime / slo{availability, latency_p95_ms} / contracts{provides, consumes}`）：

```yaml
services:
  - name: svc-${NN}-${BCTX}-${ROLE}
    bctx: ${BCTX}
    role: ${TYPE}                                # 与 --type 一致（api/worker/saga/gateway）
    owner: <team-or-handle>
    repo: <git-url-or-path>
    runtime: <go|rust|python|node>
    slo:
      availability: 99.9
      latency_p95_ms: 200
    contracts:
      provides:
        - contracts/${BCTX}/openapi/svc-${NN}-${BCTX}-${ROLE}/v1/api.yaml   # 若 type ∈ api/gateway
      consumes:
        - contracts/<other-bctx>/asyncapi/<event>.v1.yaml                    # 若有事件订阅
```

> 若本次新建涉及发布事件，同时在顶层 `events:` 列表追加发布者条目；schema 字段见 `_registry.yaml.tmpl` 示例。

### Step 5 · 建议 contracts 骨架

按 type 给出待建 contracts 路径与初始 spec 模板提示：

| type | 建议路径 | 初始内容 |
|---|---|---|
| api | `contracts/${BCTX}/openapi/svc-${NN}-${BCTX}-${ROLE}/v1.yaml` | OpenAPI 3.1 stub + Q5 中拆解的端点 |
| gateway | 同上 | OpenAPI 3.1 stub + 转发规则 |
| worker | `contracts/${BCTX}/asyncapi/${SVC}-subscribe.yaml` | AsyncAPI 2.6 订阅 schema |
| saga | OpenAPI（若有补偿 API）+ AsyncAPI（编排消息）| 双产物 |

> contracts 实际编写不由本 skill 完成，调 `contract-first` skill 继续。

### Step 6 · 收尾产出

输出给用户：

1. ✅ 已创建文件清单（路径 + 行数）
2. 📝 未填占位符 TODO 清单（带 owner + due-date）
3. 🔗 推荐下一步 skills：`contract-first`（写契约）/ `adr-writing`（若有架构决策）
4. 📋 PR 描述模板：

```markdown
## 新建服务 svc-${NN}-${BCTX}-${ROLE}

- 类型：${TYPE}
- 职责：<Q5 一句话>
- 上游：<...>
- 下游：<...>

### 产出物
- [ ] apps/svc-${NN}-... 骨架（new-service.sh）
- [ ] docs/services/svc-${NN}-... 文件矩阵（${type} 触及 N 列）
- [ ] _registry.yaml 注册
- [ ] contracts/${BCTX}/... 骨架（TODO · contract-first skill）
- [ ] 首个 ADR（若 type=saga 或跨 BC 调用）

### Gate
- self-review-agent ✅
- gate-checklist plan ✅
```

## Gate（skill 自身 DoD）

- Step 0 5 问全答（任一空则不进 Step 1）
- Step 1 预检全 ✅
- Step 2 脚本退出码 0
- Step 4 _registry.yaml 字段无 `<...>` 残留
- Step 6 输出包含 4 个段落（清单 / TODO / next-skills / PR 模板）

## 与其他 skill 协同

- 前置：`bc-impact-map`（确认本服务在 impact-map 中）
- 后置：`contract-first`（写契约）/ `adr-writing`（写决策）/ `self-review-agent`（自检 PR）
- 互斥：本 skill 单次只建一个服务；批量建议拆 N 个 PR

## Worked Example

**Input**
```
/new-service-bootstrap order 12 api --type api
```

**Step 0 访谈**（已填部分跳过）：
- Q5：「订单查询与下单 API，上游 wallet / risk，下游 mt5-adapter」

**Step 2 输出**
```
实例化 docs/services/svc-12-order-api (type=api → 5 文件: README runbook non-functional api events)
追加 _registry.yaml: svc-12-order-api
```

**Step 6 输出**（节选）
```
✅ 创建文件：5 个 .md（共 287 行）
📝 TODO: api.md 端点待补 ×3 / non-functional SLO 初值待团队确认
🔗 下一步：调 contract-first 写 contracts/order/openapi/svc-12-order-api/v1.yaml
```
