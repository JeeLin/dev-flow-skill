# 步骤8：提交

## GUARD

- 前置状态：步骤4/5/6/7 已勾选，Flow Status 步骤8 未勾选
- 幂等（重入不重复）：
  - CHANGELOG 版本标题行（`## [{version}] - YYYY-MM-DD`）已存在 → 跳过 CHANGELOG 插入
  - `git status` 无待提交变更 → 跳过提交

## ACT

1. 检查：commit 粒度（一子功能点一 commit）、commit message 格式（conventional commits）、产品文档未被污染
2. 更新项目文件中的版本号（见「版本管理」）
   - Rust 项目：更新 `Cargo.toml` 后必须运行 `cargo update -w` 同步 `Cargo.lock`
3. 更新 `CHANGELOG.md`（GUARD：版本标题行已存在则整步跳过）：
   - 若 `CHANGELOG.md` 不存在或缺少 `## [Unreleased]` 标题，先创建/补齐基础结构（含 `## [Unreleased]` 行及 Keep a Changelog 头部），再继续
   - 在 `## [Unreleased]` 下方插入新版本条目，遵循 [Keep a Changelog](https://keepachangelog.com/)：
     - 标题行：`## [{version}] - YYYY-MM-DD`
     - 只使用有变更的分类：Added / Changed / Fixed / Removed，每条以 `- ` 开头，简明描述
     - 示例：
       ```
       ## [1.1.0] - 2026-07-01

       ### Added
       - 用户管理：支持用户 CRUD API 和前端管理页面

       ### Fixed
       - 登录页面：修复表单提交后未重置状态的问题
       ```
4. 更新 `DEVELOPMENT.md` 的里程碑状态标记（与 mdflow-planner 图例一致，标记含空格 `← 新增（下一步）`）：
   - 本里程碑条目从 `← 新增（下一步）` / `🔄 当前` 改为 `✅ 已完成`
   - 下一个待做里程碑（若有）的标记前移为 `← 新增（下一步）`，使下次步骤1 能正确识别「下一个里程碑」
   - 避免 planner 再次运行时因找不到已完成标记而重复追加 `## 里程碑划分` 段落
5. 沉淀候选汇总与裁决（汇总先于汇报，列定义唯一源见契约「沉淀候选格式」）：
   - 采集三来源并按「发现/模式」去重合并成台账行（同一模式跨轮/跨来源只留一行，`来源` 逗号分隔、`出现轮次` 记轮报告轮次）：
     - `round1..round{N}` **全部轮**的 step2/4/5/7 报告 `## 沉淀建议` 表格——步骤4/5 门禁是零发现，通过轮恒空、被打回轮才携带发现，只扫最终轮台账必空
     - `对话`：本次会话审查/协作过程中的观察补录
     - `历史`：目标项目跨里程碑报告统计
   - 追加/补全里程碑文档 `## 沉淀候选` 台账（创建里程碑时只有表头），随后逐行向维护者呈现，裁决 ⬜ → ✅ 接受 / ❌ 拒绝
   - ✅ 行：由 session 按「候选去向」半自动写入 `scripts/check.sh` / 目标项目 `AGENTS.md` 的代码审查维度 / 技能侧硬规则，写入后立即跑 `scripts/check.sh` 与 `scripts/run-scenarios.sh` 双门禁，不绿则回滚该条写入并改标 ❌ 留档
   - ❌ 行：只留档，不写入任何目标文件
   - 幂等：已 ✅/❌ 的行不重置、台账只增不删，重入只补新候选与 ⬜ 行

## MARK

6. **生成并向用户输出「里程碑完成汇报」**（内容以里程碑文档、Bugs 表与 git 记录为依据，不凭对话记忆）：
   - **里程碑**：`{version}` {标题}（{patch/minor/major}）
   - **交付内容**：逐子任务一句话说明实际交付了什么
   - **修复的 bug**：按 🔴→🟡→🟢 列出标题并附数量统计（从缺陷池转入的注明）
   - **打回与审查轮**：共 {打回记录行数} 次打回、最终状态行（如 `第2轮｜4✓ 5✓ 6✓ 7✓`）
   - **沉淀候选**：共 {N} 条（✅ 接受 {n1} 已写入、❌ 拒绝 {n2} 留档、⬜ 待裁决 {n3}——⬜ 非零时不勾选步骤8，先完成 ACT 第5 步裁决）
   - **变更概况**：自 `{milestone-start-ref}` 起 {N} 个提交（`git log {milestone-start-ref}..HEAD --oneline` 计数），主要改动的模块/文件
   - **发布收尾**：版本号 {旧→新}、CHANGELOG 新版本条目、DEVELOPMENT.md 标记推进结果

   （汇报先于勾选：输出被中断时步骤8 保持未勾选，下次调用自然重入本步骤补发，完全依赖文档状态、不依赖对话记忆）
7. 勾选 Flow Status 步骤8（前置：ACT 沉淀候选无 ⬜ 待裁决行）
8. 提交变更到 git（GUARD：`git status` 无待提交则跳过）：
   - `git check-ignore -q {milestone-dir}` 检测里程碑目录是否被 gitignore
   - 未被忽略：`git add {milestone-dir} docs/DEVELOPMENT.md CHANGELOG.md {version-file} && git commit -m "docs: milestone {version} completed"`
   - 已被忽略：`git add CHANGELOG.md {version-file} && git commit -m "chore: release {version}"`
   - `{version-file}` 为第2步更新的版本文件（如 `package.json`、`Cargo.toml`、`go.mod` 等）

## 门禁

所有检查通过；沉淀候选台账无 ⬜ 待裁决行（全部 ✅/❌，Accept 项已写入并通过双门禁）。

## 版本管理

版本号在步骤1 根据已完成里程碑确定并写入里程碑文档，本步骤负责更新项目文件中的版本号：

| 项目类型 | 检测文件 | 更新命令 |
|----------|----------|----------|
| JavaScript/TypeScript | `package.json` | 使用包管理器更新版本（如 `npm version`、`bun version` 或手动修改） |
| Rust | `Cargo.toml` | 手动修改后运行 `cargo update -w` 同步 Cargo.lock |
| Python | `pyproject.toml` / `setup.cfg` | 手动修改 |
| Go | `go.mod` | 手动修改（`go mod edit -version=vX.Y.Z`） |
| Java/Kotlin | `pom.xml`（Maven）/ `build.gradle`（Gradle） | Maven：`mvn versions:set -DnewVersion=vX.Y.Z -DgenerateBackupPoms=false`；Gradle：手动修改 `version` |
| C#/.NET | `.csproj` / `Directory.Build.props` | `dotnet build /p:Version=X.Y.Z`（或手动修改 `Version`） |
