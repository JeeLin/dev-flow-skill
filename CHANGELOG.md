# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

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
