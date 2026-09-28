# AGENTS.md

## 仓库性质

- OpenCode 技能集合：纯 Markdown（`skills/*/SKILL.md`）+ `tech-briefing/_meta.json`，无构建/测试/lint/CI——勿找 `package.json` 或测试套件。
- 文档与注释均为中文；提交用 conventional commits（`fix(dev-flow):` / `refactor(dev-flow):` / `docs:` …，见 `git log`）。

## 安装（本机已就绪）

- `~/.config/opencode/skills/` 下 6 个软链接指向 `skills/*`（dev-flow、dev-bug、devflow-review、dev-acceptance、milestone-planner、tech-briefing），改 `skills/` 即时生效，无需安装步骤。
- README 中的 `~/.dsh/skill` 是另一套工具的安装方式，与本机无关。

## 改动技能时的联动检查（最容易出错）

各技能以步骤号/文件名/符号交叉引用，改一处必须全库 grep：

```bash
grep -rn "<旧关键词>" skills/ README.md CHANGELOG.md
```

必须保持一致的锚点：

- `dev-flow/SKILL.md` 是流程权威（8 步、状态机、审查轮状态行、门禁与打回）；devflow-review（步骤2/5 调用）、dev-acceptance（步骤7 调用）头部的「供 dev-flow 步骤X调用」及报告文件名 `stepX-*.md` 与之双侧写死。
- 严重度 🔴🟡🟢 语义唯一定义在 dev-flow「严重度分级契约」，其他技能只引用不重定义。
- `{milestone-start-ref}` = 里程碑文档 `## Context` 中的 commit hash，**不是 git tag**；变更列表必须 `git diff --name-only {milestone-start-ref}`，**禁止裸 git diff**（步骤3 已全部提交时结果为空 → 假通过）。
- 状态机唯一状态源：Flow Status 勾选框 +「审查轮状态行」；报告文件只作证据。已废弃机制（`.rejected` 改名、逐审查打回）仅存在于历史 CHANGELOG 条目，属正常，勿回改。
- 里程碑文档默认路径 `.dev-flow/milestones/`（README「项目要求」段的 `docs/milestones/` 已过时，以 SKILL.md 为准）。

## CHANGELOG

- Keep a Changelog 格式，新条目进 `## [Unreleased]`。
- 已发布版本条目是历史记录，即使其描述的机制已被移除也不改写。

## .gitignore

- `docs/`、`.dev-flow`、`dev-flow-workspace/` 是测试产物，勿提交。
