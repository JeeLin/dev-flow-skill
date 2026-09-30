# dev-flow

里程碑开发流程 skill 集合。自动检测项目状态，串行驱动 8 步开发流程（写文档→设计核对→开发→精简→审查→测试→功能验收→提交）。

当前仓库**两套技能并行**，新套验证通过后再确认切换，切换前旧套原地保留：

| 技能集 | 主技能 | 子技能 |
|--------|--------|--------|
| **mdflow（新）** | `skills/mdflow` —— 薄索引 + `references/`（唯一契约 `contract.md`、模板 `template.md`、`step1-8.md`） | `mdflow-review` / `mdflow-acceptance` / `mdflow-bug` / `mdflow-planner` |
| dev-flow（旧） | `skills/dev-flow` —— 单文件主技能 | `devflow-review` / `dev-acceptance` / `dev-bug` / `milestone-planner` |

一致性检查：`scripts/check.sh`（A 契约一致性 / B git 基准 / C 结构完整性，34 项只读 grep 规则，每条对应一个历史事故）。

## 安装

```bash
# 克隆到本地
git clone git@github.com:JeeLin/dev-flow-skill.git ~/dev-flow-skill

# 创建 skill 目录并 symlink
mkdir -p ~/.dsh/skill

# mdflow 技能集
ln -s ~/dev-flow-skill/skills/mdflow ~/.dsh/skill/mdflow
ln -s ~/dev-flow-skill/skills/mdflow-review ~/.dsh/skill/mdflow-review
ln -s ~/dev-flow-skill/skills/mdflow-acceptance ~/.dsh/skill/mdflow-acceptance
ln -s ~/dev-flow-skill/skills/mdflow-bug ~/.dsh/skill/mdflow-bug
ln -s ~/dev-flow-skill/skills/mdflow-planner ~/.dsh/skill/mdflow-planner

# 旧技能集（并行保留期）
ln -s ~/dev-flow-skill/skills/dev-flow ~/.dsh/skill/dev-flow
ln -s ~/dev-flow-skill/skills/dev-acceptance ~/.dsh/skill/dev-acceptance
ln -s ~/dev-flow-skill/skills/devflow-review ~/.dsh/skill/devflow-review
ln -s ~/dev-flow-skill/skills/dev-bug ~/.dsh/skill/dev-bug
ln -s ~/dev-flow-skill/skills/milestone-planner ~/.dsh/skill/milestone-planner
```

## 使用

在任何项目的会话中输入：

```
/mdflow     （旧套：/dev-flow）
```

Skill 会自动检测当前项目状态，从上次完成的步骤继续。

## 流程

| 步骤 | 名称 | 说明 |
|------|------|------|
| 1 | 编写里程碑文档 | 创建标准化的里程碑开发文档 |
| 2 | 设计核对 | 对照产品文档检查设计是否偏离 |
| 3 | 开发 | 按子任务逐个实现 |
| 4 | 代码精简 | 消除重复、过度设计 |
| 5 | 代码审查 | 多维度审查，发现问题登记，轮末统一打回 |
| 6 | 测试验证 | 运行测试命令，检查覆盖率 |
| 7 | 功能验收 | 从 git diff 出发独立验证实现是否满足需求 |
| 8 | 提交 | 最终检查，完成里程碑并输出完成汇报 |

> 步骤4-7 组成一个**审查轮**：连续执行、轮内不打回，轮末统一判定，任一步不通过则一次性打回步骤3，修复后整轮重跑。

## 项目要求

需要项目中有以下文件：

- `AGENTS.md` — 项目约定（技术栈、代码规范、目录结构）
- `docs/PRODUCT.md` — 产品定位和功能边界
- `docs/DEVELOPMENT.md` — 整体规划与里程碑划分
- `.dev-flow/milestones/` — 里程碑文档目录（项目 `AGENTS.md` 可覆盖）

这些是项目级文件，不属于本 skill 的一部分。
