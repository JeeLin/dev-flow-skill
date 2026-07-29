# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added

- **devflow-review 技能**：新增独立的审查框架技能，覆盖设计审查（步骤2/7）和代码审查（步骤5）
  - 报告模板：`step2-design-review.md`、`step5-code-review.md`、`step7-design-reconfirm.md`
  - 审查维度：从 `AGENTS.md` 的 `## 审查维度` 读取
  - 通过条件：所有维度 ✅ 且无 🔴 必须修复项

- **dev-flow Bug 支持**：在里程碑开发过程中记录和处理 bug
  - 里程碑文档新增 Bugs 表格（优先级 + 来源 + 描述）
  - 步骤3（开发）先完成子任务，再按优先级处理 bug（🔴 > 🟡 > 🟢）
  - 步骤2/5/6/7 支持添加发现的问题到 Bugs 表格
  - 步骤3完成条件包含 Bugs 表格检查

- **Bug 收集入口**：独立 `dev-bug` 技能，通过 `/dev-bug` 命令随时提交 bug，自动判断优先级并写入当前里程碑的 Bugs 表格

### Changed

- **dev-flow 技能更新**：步骤2、5、7 改为调用 `devflow-review` 技能
  - 步骤2：设计审查，传入里程碑文档和产品文档
  - 步骤5：代码审查，传入 git diff 文件列表
  - 步骤7：设计再确认，传入已实现代码和里程碑文档
- **步骤3 原则更新**：明确代码提交时机 - 实现每个子任务后立即提交，修复每个 bug 后立即提交
### Removed

- **evals.json**：移除 dev-flow 的评估文件

### Fixed

- **步骤编号引用**：修正"从步骤2.1开始"为"从步骤2的第一步开始"
- **Rust Cargo.lock 同步**：步骤8 更新版本号后同步 Cargo.lock；步骤6 增加前置检查验证 lock 文件一致性，通过后跳过重复编译检查
- **步骤4/5 git 命令修正**：`git diff` 在步骤3全部提交后返回空，改为对比里程碑开始前的 ref 获取变更文件列表
- **提交原则**：每次 commit 必须同时包含代码变更和里程碑文档的状态变更，确保里程碑文档始终是代码的真实状态

## [0.6.0] - 2026-07-09

### Changed

- 平台兼容：`CLAUDE.md` 引用全部替换为 `AGENTS.md`（OMP 约定）
- 循环命令泛化：移除 Claude Code 专属 `/loop`、`/compact` 引用，改为平台通用描述
- 版本更新命令泛化：`bun version` 改为环境无关的包管理器描述
- README 更新：适配 OMP 安装说明

## [0.5.0] - 2026-06-23

### Fixed

- 版本号示例：milestone-planner 和 dev-flow 步骤1 增加 patch 版本号示例，避免 AI 默认只用 minor

## [0.4.0] - 2026-06-22

### Added

- 里程碑规划技能拆分：将 milestone-planner 从 dev-flow 中拆为独立技能
- 版本号自动判断：里程碑版本号根据内容自动判断 patch/minor/major
- 步骤8 CHANGELOG 更新：提交阶段自动更新 CHANGELOG.md
- 步骤8 提交文档：提交里程碑文档、报告文件和 CHANGELOG 到 git
- 前置检查：执行前检查 CLAUDE.md、产品文档、开发设计文档是否存在
- 步骤6 质量门禁：默认编译/Lint/覆盖率检查，支持 JS/TS、Python、Rust、Go

### Fixed

- 打回记录死锁：步骤1 重写后清空打回记录，避免状态机无限循环
- 门禁措辞统一：步骤5/6/7 从"打回到步骤3"改为"取消勾选，重入步骤X"
- 步骤2 打回报告处理：大问题打回时重命名报告文件为 `.rejected` 后缀

### Changed

- 里程碑标识从 M1/M2/M3 迁移为版本号（v1.0.0/v1.1.0）
- 步骤2 审查细化：小问题自动修正最多3次，超过视为大问题
- 模板 Context 段落新增版本类型标注
- 步骤6 门禁细化：逐项记录覆盖率数值
- 版本管理表扩展：新增 Go 项目支持
- milestone-planner 版本号来源：明确从已完成里程碑递增，package.json 仅作参考

## [0.3.0] - 2026-06-21

### Added

- 循环与上下文管理：通过 `/loop` 自动连续调用，状态持久化到里程碑文档
- 步骤2 打回机制：小问题自动修正；大问题打回到步骤1
- 打回记录表格：里程碑文档模板新增"打回记录"段落
- 打回死锁修复：打回时重命名报告文件为 `.rejected` 后缀

### Changed

- 审查框架简化：从固定维度改为 CLAUDE.md 项目驱动
- 报告路径统一相对于 `docs/milestones/`
- 步骤1 触发条件简化

## [0.2.0] - 2026-06-20

### Added

- 基础数据读取：产品文档、开发设计文档、原型代码
- 路径可配置：默认值 + CLAUDE.md 覆盖机制
- 子任务编号规则：支持字母子编号（1a, 1b）

### Changed

- 移除硬编码路径，改为 CLAUDE.md 驱动

## [0.1.0] - 2026-06-18

### Added

- 8 步里程碑流程：写文档→设计核对→开发→精简→审查→测试→再确认→提交
- 状态机：基于 Flow Status 勾选状态自动判断下一步
- 门禁与打回：步骤5/6/7 不通过时打回重新修复
- 报告系统：审查/精简/测试报告存储在 `{version}-reports/`
- 里程碑文档模板

## [0.0.1] - 2026-06-18

### Added

- 初始版本，基础技能框架
