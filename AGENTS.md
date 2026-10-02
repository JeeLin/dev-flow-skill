# AGENTS.md

## 仓库性质

- OpenCode 技能集合：纯 Markdown（`skills/*/SKILL.md`）+ `tech-briefing/_meta.json` + `scripts/check.sh`，无构建/测试/lint/CI——勿找 `package.json` 或测试套件。
- 文档与注释均为中文；提交用 conventional commits（`fix(dev-flow):` / `refactor(dev-flow):` / `docs:` …，见 `git log`）。
- 技能集为 `mdflow`（`tech-briefing` 属独立技能，与本家族无关）。旧 dev-flow 技能集已于 `refactor(dev-flow): 移除旧 dev-flow 技能集` 提交删除，如需找回走 git 历史，**不要凭记忆恢复文件**。

## 安装（本机已就绪）

- `~/.config/opencode/skills/` 下 6 个软链接指向本仓库 `skills/*`：mdflow、mdflow-review、mdflow-acceptance、mdflow-bug、mdflow-planner、tech-briefing。改 `skills/` 即时生效，无需安装步骤。
- README 中的 `~/.dsh/skill` 是另一套工具的安装方式，与本机无关。

## 改动技能时的联动检查（最容易出错）

拓扑：`skills/mdflow/{SKILL.md, references/{contract.md, template.md, step1-8.md}}` + 4 个纯函数子技能。契约**单边**书写，改一处必须全库 grep：

```bash
grep -rn "<旧关键词>" skills/ README.md CHANGELOG.md
./scripts/check.sh   # 改动契约/结构/步骤文件后必须 35 项全绿（A 契约 / B git 基准 / C 结构，含 A9 废弃里程碑机制）
./scripts/run-scenarios.sh   # 二期状态机场景推演（场景底稿见 scripts/scenarios.md）
```

必须保持一致的锚点：

- `skills/mdflow/SKILL.md` 是流程权威（8 步、状态机、审查轮状态行、**统一打回动作**单点定义、门禁与分发表）；`references/step1-8.md` 每步 `## GUARD/## ACT/## MARK` 是该步唯一详述，分发表指向的文件必须存在。
- 跨技能契约唯一源 `references/contract.md`：严重度分级（含校准样例）、发现登记格式（可证伪三要素）、git 基准规则、2/4/5/7 审查职责切割、报告清单（`stepX-*.md` 文件名只写在这里）、发现→规则沉淀。子技能只引用不重定义，头部**不写**「供…步骤X调用」，**不硬编码**报告文件名（经 `report_path` 参数传入）。
- 调用名写死在 `references/step2.md`/`step4.md`/`step5.md`（`mdflow-review`）与 `step7.md`（`mdflow-acceptance`），改子技能名必须同步。
- `{milestone-start-ref}` = 里程碑文档 `## Context` 中的 commit hash（步骤1 用 `git rev-parse HEAD` 写入，一次写入终身保留），**不是 git tag**；变更列表必须 `git diff --name-only {milestone-start-ref}`，**禁止裸 git diff、禁止 `HEAD~N` 计数**。
- 状态机唯一状态源：Flow Status 勾选框 +「审查轮状态行」；报告文件只作证据，不参与状态判断。打回后按 4→5→6→7 **整轮重跑**，不做定点复验。
- 里程碑文档默认路径 `.mdflow/milestones/`（项目 `AGENTS.md` 可覆盖），不要写成 `docs/milestones/`。
- `scripts/check.sh` 每条规则对应一个真实事故（见规则上方注释），不得删规则。**新事故按"谁使用时读得到"分层回灌**：① 执行期错误 → 补 `stepN.md`/`contract.md` 硬规则（使用侧每次执行必读，是唯一对使用者生效的提醒）；② 可 grep 的代码问题 → 补目标项目 `AGENTS.md` 审查维度（经沉淀管线）；③ 名称/结构漂移 → 补 check.sh 规则（只门禁本仓库）。执行期事故若不写进步骤文件/契约，使用者永远无提醒；check.sh 语义断言一律不入（措辞改写易误报，语义验证属 `scripts/scenarios.md` 二期夹具）。

## CHANGELOG

- Keep a Changelog 格式，新条目进 `## [Unreleased]`。
- 已发布版本条目是历史记录，即使其描述的机制已被移除也不改写。

## .gitignore

- `docs/`、`.dev-flow`、`.mdflow`、`dev-flow-workspace/` 是测试产物，勿提交（`.dev-flow` 为历史残留，`.mdflow` 为现行约定）。
