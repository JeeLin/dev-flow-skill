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

## MARK

5. **生成并向用户输出「里程碑完成汇报」**（内容以里程碑文档、Bugs 表与 git 记录为依据，不凭对话记忆）：
   - **里程碑**：`{version}` {标题}（{patch/minor/major}）
   - **交付内容**：逐子任务一句话说明实际交付了什么
   - **修复的 bug**：按 🔴→🟡→🟢 列出标题并附数量统计（从缺陷池转入的注明）
   - **打回与审查轮**：共 {打回记录行数} 次打回、最终状态行（如 `第2轮｜4✓ 5✓ 6✓ 7✓`）
   - **变更概况**：自 `{milestone-start-ref}` 起 {N} 个提交（`git log {milestone-start-ref}..HEAD --oneline` 计数），主要改动的模块/文件
   - **发布收尾**：版本号 {旧→新}、CHANGELOG 新版本条目、DEVELOPMENT.md 标记推进结果

   （汇报先于勾选：输出被中断时步骤8 保持未勾选，下次调用自然重入本步骤补发，完全依赖文档状态、不依赖对话记忆）
6. 勾选 Flow Status 步骤8
7. 提交变更到 git（GUARD：`git status` 无待提交则跳过）：
   - `git check-ignore -q {milestone-dir}` 检测里程碑目录是否被 gitignore
   - 未被忽略：`git add {milestone-dir} docs/DEVELOPMENT.md CHANGELOG.md {version-file} && git commit -m "docs: milestone {version} completed"`
   - 已被忽略：`git add CHANGELOG.md {version-file} && git commit -m "chore: release {version}"`
   - `{version-file}` 为第2步更新的版本文件（如 `package.json`、`Cargo.toml`、`go.mod` 等）

## 门禁

所有检查通过。

## 版本管理

版本号在步骤1 根据已完成里程碑确定并写入里程碑文档，本步骤负责更新项目文件中的版本号：

| 项目类型 | 检测文件 | 更新命令 |
|----------|----------|----------|
| JavaScript/TypeScript | `package.json` | 使用包管理器更新版本（如 `npm version`、`bun version` 或手动修改） |
| Rust | `Cargo.toml` | 手动修改后运行 `cargo update -w` 同步 Cargo.lock |
| Python | `pyproject.toml` / `setup.cfg` | 手动修改 |
| Go | `go.mod` | 手动修改（`go mod edit -version=vX.Y.Z`） |
