# 日志记录

dev-flow 执行日志用于事后分析技能表现、迭代优化，默认关闭。

## 开关

环境变量 `DEV_FLOW_LOG`：

- `1` / `true` → 开启
- 未设置或其它值 → 关闭

## 日志文件

路径：`{project-root}/.dev-flow/log.jsonl`

`.dev-flow/` 目录需加入项目的 `.gitignore`。

## 事件类型

共 5 种事件，覆盖技能执行全链路：

### 1. `step` — 步骤执行

每个步骤执行完毕时记录。

```jsonl
{"ts":"...","event":"step","version":"v1.2.0","step":3,"action":"complete","duration_s":320,"project":{"lang":"typescript","framework":"express"},"subtasks":{"total":5,"done":5}}
```

| 字段 | 必需 | 说明 |
|------|------|------|
| `step` | 是 | 步骤编号 1-8 |
| `action` | 是 | `complete` / `skip` |
| `duration_s` | 否 | 耗时秒数 |
| `project` | 否 | `{lang, framework}` 从 AGENTS.md 提取，仅 step=1 时记录 |
| `subtasks` | 条件 | step=3 时记录 `{total, done}` |

### 2. `reject` — 打回

打回发生时记录。

```jsonl
{"ts":"...","event":"reject","version":"v1.2.0","step":5,"category":"security","detail":"权限中间件缺少输入验证","file":"src/middleware/auth.ts","reentry_step":5}
```

| 字段 | 必需 | 说明 |
|------|------|------|
| `step` | 是 | 被打回的步骤 |
| `category` | 是 | 打回分类：`design` / `code_quality` / `security` / `test_failure` / `gate_failure` / `other` |
| `detail` | 是 | 具体问题描述 |
| `file` | 否 | 涉及的文件路径 |
| `reentry_step` | 是 | 重入步骤（通常=step，打回步骤2时=1） |

**category 由技能根据打回位置自动判定：**
- 步骤 2 打回 → `design`
- 步骤 5 精简/审查打回 → 看报告中的维度标记（`code_quality` / `security`）
- 步骤 6 门禁失败 → `gate_failure`（附 `gate_detail`）
- 步骤 7 设计不一致 → `design`

### 3. `gate` — 门禁检查

步骤 6 门禁逐项检查时记录。

```jsonl
{"ts":"...","event":"gate","version":"v1.2.0","checks":[{"name":"compile","passed":true},{"name":"lint","passed":false,"detail":"3 errors in src/"},{"name":"coverage","passed":true,"value":"91%"}]}
```

| 字段 | 必需 | 说明 |
|------|------|------|
| `checks` | 是 | 数组，每项 `{name, passed, detail?, value?}` |

### 4. `plan` — 里程碑规划

milestone-planner 规划完毕时记录。

```jsonl
{"ts":"...","event":"plan","version":"v1.2.0","version_type":"minor","subtask_count":5,"features":["用户 CRUD","前端列表页"],"dependency":"v1.1.0","principle_applied":"核心到周边"}
```

| 字段 | 必需 | 说明 |
|------|------|------|
| `version_type` | 是 | `patch` / `minor` / `major` |
| `subtask_count` | 是 | 子任务数量 |
| `features` | 是 | 功能列表 |
| `dependency` | 否 | 依赖的前置版本 |
| `principle_applied` | 是 | 命中的规划原则 |

### 5. `version` — 版本决策

步骤 8 提交时记录版本号变更。

```jsonl
{"ts":"...","event":"version","from":"1.1.0","to":"1.2.0","type":"minor","file":"package.json"}
```

## 保留策略

每次执行步骤 1 时，删除 30 天前的日志行。文件不存在或为空则跳过。

## 注意事项

- 日志是辅助数据，Flow Status 仍是唯一权威
- 写入失败不阻断流程，跳过即可
- 不记录敏感信息
- `category` 和 `project` 由技能自动判定，无需用户配置

## 优化用法

积累足够日志后可分析：

| 分析维度 | 数据来源 | 优化方向 |
|----------|----------|----------|
| 拒绝原因分布 | `reject.category` 聚合 | 加强对应审查维度的指引 |
| 门禁误报率 | `gate.checks` 统计 | 调整默认门禁阈值 |
| 各步骤耗时 | `step.duration_s` 均值 | 简化慢步骤或拆分大步骤 |
| 规划质量 | `plan.subtask_count` vs `reject` 关联 | 优化子任务拆分粒度指引 |
| 版本号准确率 | `version.type` 与 milestone-planner 对比 | 修正版本递增规则 |
| 项目类型适配 | `reject` × `project` 交叉 | 针对特定技术栈补充指引 |
