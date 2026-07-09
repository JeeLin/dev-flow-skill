# dev-flow

里程碑开发流程 skill。自动检测项目状态，串行驱动 8 步开发流程。

## 安装

```bash
# 克隆到本地
git clone git@github.com:JeeLin/dev-flow-skill.git ~/dev-flow-skill

# 创建 skill 目录并 symlink
mkdir -p ~/.claude/skills
ln -s ~/dev-flow-skill/skills/dev-flow ~/.claude/skills/dev-flow
ln -s ~/dev-flow-skill/skills/milestone-planner ~/.claude/skills/milestone-planner
```

## 使用

在任何项目的会话中输入：

```
/dev-flow
```

Skill 会自动检测当前项目状态，从上次完成的步骤继续。

## 流程

| 步骤 | 名称 | 说明 |
|------|------|------|
| 1 | 编写里程碑文档 | 创建标准化的里程碑开发文档 |
| 2 | 设计核对 | 对照产品文档检查设计是否偏离 |
| 3 | 开发 | 按子任务逐个实现 |
| 4 | 代码精简 | 消除重复、过度设计 |
| 5 | 代码审查 | 多维度审查，发现问题打回 |
| 6 | 测试验证 | 运行测试命令，检查覆盖率 |
| 7 | 设计再确认 | 确认实现与设计一致 |
| 8 | 提交 | 最终检查，完成里程碑 |

## 项目要求

需要项目中有以下文件：

- `AGENTS.md` — 项目约定（技术栈、代码规范、目录结构）
- `docs/PRODUCT.md` — 产品定位和功能边界
- `docs/milestones/` — 里程碑文档目录

这些是项目级文件，不属于本 skill 的一部分。
