# SNN 场景夹具（状态机推演，二期）

按 `skills/mdflow/SKILL.md`「状态机」逐场景推演下一步动作；`scripts/run-scenarios.sh` 读本文件断言 `expected`。

字段：

- `flow_status` — Flow Status 8 个勾选框：`✓`=已勾选、`☐`=未勾选；无里程碑文档时为 `（none）`
- `review_round` — 审查轮状态行 `第N轮｜4x 5x 6x 7x`，x ∈ `—`/`✓`/`✗`；旧里程碑缺失时为 `（none）`
- `bugs_square` — Bugs 表 ⬜（待修复）行数
- `abandoned` — 唯一候选里程碑 `状态` 为 `已放弃`（无其它进行中里程碑）
- `has_milestone` — 是否存在里程碑文档
- `expected` — 状态机应分发到的步骤

标记识别场景另用 `marker_*` 字段（契约「里程碑状态标记」的五分支识别规则）：

- `marker_cur` — DEVELOPMENT.md 中标记 `🔄 当前` 的条目数
- `marker_blank` — 无标记（未开始）条目数
- `marker_done` — 标记 `✅ 已完成` 的条目数
- `marker_foreign` — 非规范状态词条目数（消费者自写 `进行中` / `In Progress` 等）
- `marker_expected` — 识别判定：`继续` / `调planner` / `停止报告`

> 标记识别场景只验「识别判定」，不验状态机分发：两者是不同层，`dispatch` 与 `dispatch_marker` 分开。

> S23-S25 为子技能输入输出场景（维度来源、报告文件名、缺陷池），不属状态机推演，无夹具。

### S01｜无里程碑文档；DEVELOPMENT.md 无下一个里程碑 → 先调 mdflow-planner 再进步骤1
flow_status=（none）
review_round=（none）
bugs_square=0
abandoned=false
has_milestone=false
expected=步骤1

### S02｜步骤1 未勾选、文档已存在但 ## Context 无 ref → 补写 ref 后勾选
flow_status=1☐ 2☐ 3☐ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=第1轮｜4— 5— 6— 7—
bugs_square=0
abandoned=false
has_milestone=true
expected=步骤1

### S03｜步骤1 未勾选、ref 已写但此后产生新 commit → 不重新 rev-parse，直接勾选
flow_status=1☐ 2☐ 3☐ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=第1轮｜4— 5— 6— 7—
bugs_square=0
abandoned=false
has_milestone=true
expected=步骤1

### S04｜被打回版文档（打回记录含步骤2 大问题）、步骤1 未勾选 → 按打回记录重写后勾选
flow_status=1☐ 2☐ 3☐ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=第2轮｜4— 5— 6— 7—
bugs_square=0
abandoned=false
has_milestone=true
expected=步骤1

### S05｜步骤1 ✓、步骤2 报告 ❌ 小问题（已登记 Bugs）→ 改文档后重跑步骤2，步骤1 保持勾选
flow_status=1✓ 2☐ 3☐ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=第1轮｜4— 5— 6— 7—
bugs_square=1
abandoned=false
has_milestone=true
expected=步骤2

### S06｜步骤2 报告 ❌ 大问题 → 统一打回（取消步骤1 及后续勾选、打回记录 +1、状态行重置）→ 步骤1
flow_status=1☐ 2☐ 3☐ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=第2轮｜4— 5— 6— 7—
bugs_square=1
abandoned=false
has_milestone=true
expected=步骤1

### S07｜步骤2 报告 ✅、人工审核=开启 → 步骤2 勾选前暂停等确认，确认后勾选进步骤3
flow_status=1✓ 2☐ 3☐ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=第1轮｜4— 5— 6— 7—
bugs_square=0
abandoned=false
has_milestone=true
expected=步骤2

### S08｜断点恢复：状态行 第1轮｜4✓ 5— 6— 7— → 从步骤5 继续，不重跑步骤4
flow_status=1✓ 2✓ 3✓ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=第1轮｜4✓ 5— 6— 7—
bugs_square=0
abandoned=false
has_milestone=true
expected=步骤5

### S09｜状态行 第1轮｜4✓ 5✓ 6✓ 7✓、4-7 未勾 → 轮末全 ✓ 勾选 4/5/6/7 → 步骤8
flow_status=1✓ 2✓ 3✓ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=第1轮｜4✓ 5✓ 6✓ 7✓
bugs_square=0
abandoned=false
has_milestone=true
expected=步骤8

### S10｜状态行 第1轮｜4✓ 5✗ 6✓ 7✗、轮末判断被中断 → 统一打回 → 步骤3
flow_status=1✓ 2✓ 3✓ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=第1轮｜4✓ 5✗ 6✓ 7✗
bugs_square=2
abandoned=false
has_milestone=true
expected=步骤3

### S11｜旧里程碑：状态行缺失且 4-7 未全勾 → 初始化状态行 → 步骤4
flow_status=1✓ 2✓ 3✓ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=（none）
bugs_square=0
abandoned=false
has_milestone=true
expected=步骤4

### S12｜步骤4 已登记发现并写 4✗，轮内不打回 → 继续步骤5
flow_status=1✓ 2✓ 3✓ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=第1轮｜4✗ 5— 6— 7—
bugs_square=1
abandoned=false
has_milestone=true
expected=步骤5

### S13｜步骤7 中断：已登记 2 条发现、状态行 7 仍为 — → 重入重跑步骤7
flow_status=1✓ 2✓ 3✓ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=第1轮｜4✓ 5✓ 6✓ 7—
bugs_square=2
abandoned=false
has_milestone=true
expected=步骤7

### S14｜步骤7 报告 ❌：先登记 Bugs 再写 7✗ → 轮末统一打回
flow_status=1✓ 2✓ 3✓ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=第1轮｜4✓ 5✓ 6✓ 7—
bugs_square=0
abandoned=false
has_milestone=true
expected=步骤7

### S15｜步骤5 报告仅 🟢：登记入 Bugs 并置本步 ✗ → 轮末打回（不允许「🟢 不阻断」放行）
flow_status=1✓ 2✓ 3✓ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=第1轮｜4✓ 5— 6— 7—
bugs_square=0
abandoned=false
has_milestone=true
expected=步骤5

### S16｜状态行缺失（无轮进行）、Bugs 有 ⬜ 行（mdflow-bug 中途报的）→ 统一打回 → 步骤3
flow_status=1✓ 2✓ 3✓ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=（none）
bugs_square=1
abandoned=false
has_milestone=true
expected=步骤3

### S17｜审查轮进行中（4✓ 5— 6— 7—）、轮内步骤5 新登记 2 条 ⬜ → 不回退，继续步骤5
flow_status=1✓ 2✓ 3✓ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=第1轮｜4✓ 5— 6— 7—
bugs_square=2
abandoned=false
has_milestone=true
expected=步骤5

### S18｜步骤3 进行中（子任务 1 ✓、2 ⬜ 中断重入）→ 从子任务 2 续做
flow_status=1✓ 2✓ 3☐ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=第1轮｜4— 5— 6— 7—
bugs_square=0
abandoned=false
has_milestone=true
expected=步骤3

### S19｜步骤7 报告 ✅ 且轮末判断完成 → 先输出里程碑完成汇报再勾选 → 步骤8
flow_status=1✓ 2✓ 3✓ 4✓ 5✓ 6✓ 7✓ 8☐
review_round=第1轮｜4✓ 5✓ 6✓ 7✓
bugs_square=0
abandoned=false
has_milestone=true
expected=步骤8

### S20｜步骤8 中断（CHANGELOG 已插版本条目未提交）→ 幂等重入补汇报、勾选、提交 → 步骤8
flow_status=1✓ 2✓ 3✓ 4✓ 5✓ 6✓ 7✓ 8☐
review_round=第1轮｜4✓ 5✓ 6✓ 7✓
bugs_square=0
abandoned=false
has_milestone=true
expected=步骤8

### S21｜里程碑目录在 .gitignore → 步骤8 跳过文档 git 提交、只提交 CHANGELOG/版本文件
flow_status=1✓ 2✓ 3✓ 4✓ 5✓ 6✓ 7✓ 8☐
review_round=第1轮｜4✓ 5✓ 6✓ 7✓
bugs_square=0
abandoned=false
has_milestone=true
expected=步骤8

### S22｜8 步全勾 → 入口分支「全部里程碑均已结束 → 步骤1」，开始下一个里程碑
flow_status=1✓ 2✓ 3✓ 4✓ 5✓ 6✓ 7✓ 8✓
review_round=第1轮｜4✓ 5✓ 6✓ 7✓
bugs_square=0
abandoned=false
has_milestone=true
expected=步骤1

### S26｜唯一候选里程碑 `状态`=已放弃 → 排除后无进行中里程碑 → 步骤1
flow_status=1✓ 2☐ 3☐ 4☐ 5☐ 6☐ 7☐ 8☐
review_round=第1轮｜4— 5— 6— 7—
bugs_square=0
abandoned=true
has_milestone=true
expected=步骤1


---

## H 组：里程碑标记识别（契约「里程碑状态标记」）

### S28｜DEVELOPMENT.md 有 1 条 `🔄 当前`、2 条无标记 → 正常识别，继续
marker_cur=1
marker_blank=2
marker_done=3
marker_foreign=0
marker_expected=继续

### S29｜全部条目均 `✅ 已完成`（无待做）→ 未定义下一个里程碑，调 planner 规划
marker_cur=0
marker_blank=0
marker_done=8
marker_foreign=0
marker_expected=调planner

### S30｜有空条目但无 `🔄 当前`（标记未维护）→ 停止并报告，不自行提升
marker_cur=0
marker_blank=2
marker_done=3
marker_foreign=0
marker_expected=停止报告

### S31｜出现非规范状态词 `进行中` → 停止并报告，不做别名兼容
marker_cur=0
marker_blank=1
marker_done=3
marker_foreign=1
marker_expected=停止报告

### S32｜`🔄 当前` 命中 2 行（状态冲突）→ 停止并报告
marker_cur=2
marker_blank=1
marker_done=3
marker_foreign=0
marker_expected=停止报告
