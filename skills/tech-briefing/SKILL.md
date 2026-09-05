---
name: tech-briefing
description: 每日科技早报生成器。自动抓取 Hacker News、GitHub Trending、AI 论文、新工具等数据源，生成结构化的中文科技早报。支持每日/每周模式，可自定义聚焦领域。
---

# tech-briefing — 科技早报生成器

## 使用方式

用户说「生成早报」「科技早报」「tech briefing」等类似意图时，调用本 Skill。

## 核心流程

按以下顺序调用搜索工具采集数据，然后组装为早报：

### 第一步：并行采集（3 次搜索）

同时发起以下搜索，不要串行等待：

```
搜索 1 — HN 热门：
  platform_search(platform="hn", query="top stories today", maxResults=10)

搜索 2 — GitHub Trending：
  platform_search(platform="github", query="trending repositories today", maxResults=10)

搜索 3 — AI / 综合科技新闻：
  advanced_search(query="AI breakthrough OR model release OR developer tool", timeRange="day", maxResults=10)
```

### 第二步：补充采集（按需）

如果用户要求聚焦某个领域，或第一步数据不足，追加搜索：

| 场景 | 搜索 |
|------|------|
| AI 专题不足 | `advanced_search(query="LLM research paper new model", timeRange="day")` |
| 需要新工具 | `web_search(queries=["new developer tool launched today", "Product Hunt top today"])` |
| 需要中文源 | `platform_search(platform="v2ex", query="hot today")` |
| 周报模式 | 将所有 `timeRange` 改为 `"week"`，`maxResults` 提高到 10 |

### 第三步：组装输出

从搜索结果中筛选 **最有价值的 10-15 条**，按以下板块组织：

---

## 输出格式

```markdown
📰 科技早报 | {YYYY-MM-DD}
{一句话定位，如：每日精选 · Hacker News · GitHub · AI · 新工具}

---

🔥 Hacker News 热门（3-5 条）

1. **{标题}**
   {≤30字中文摘要}
   💬 {N} 讨论 | 🔥 {N} 赞

2. ...

---

🌟 GitHub 热门（3-5 条）

1. **{owner/repo}** ⭐{Stars} ({语言})
   {≤30字中文简介}

2. ...

---

🤖 AI 动态（2-4 条）

1. **{标题}**
   {2-3句中文解读}

2. ...

---

🛠 新工具 / 新项目（2-3 条）

1. **{名称}** — {一句话定位}
   {亮点}

---

📌 今日要点
・ {趋势洞察1}
・ {趋势洞察2}
・ {趋势洞察3}
```

## 格式规则

- **日期**：使用当天实际日期
- **编号**：每个板块独立编号，从 1 开始
- **加粗**：标题、仓库名、关键数字用 `**bold**`
- **语言**：中文为主，技术术语保留英文（如 Hacker News、GitHub、LLM、Rust）
- **摘要长度**：每条 ≤30 字；AI 解读 ≤80 字
- **今日要点**：3-5 条，每条一句话，用 `・` 开头
- **分隔线**：板块之间用 `---` 分隔
- **不编造**：所有数据必须来自搜索结果，搜不到就不写

## 用户参数

用户可在请求中追加以下参数（自然语言即可）：

| 意图 | 处理方式 |
|------|----------|
| 「聚焦 AI」/「AI 专题」 | AI 板块扩展到 5-6 条，其他板块精简到 2 条 |
| 「聚焦安全」/「安全专题」 | 搜索增加 `"security vulnerability CVE"`, 安全内容优先 |
| 「周报」/「weekly」 | timeRange=week, 每板块 Top 5, 末尾加「本周趋势」 |
| 「英文版」 | 输出改为英文 |
| 「推送到飞书」 | 生成后询问是否需要发送到飞书群聊 |

## 数据源说明

| 数据源 | 工具 | 特点 |
|--------|------|------|
| Hacker News | `platform_search(hn)` | 技术社区风向标，热度/评论数可靠 |
| GitHub Trending | `platform_search(github)` | 开源项目趋势，含 Star/语言 |
| 综合科技新闻 | `advanced_search` / `web_search` | 覆盖 TechCrunch、Verge、ArXiv 等 |
| V2EX | `platform_search(v2ex)` | 中文技术社区（按需） |

## 质量标准

1. **时效性**：只收录 24h 内内容（周报为 7 天）
2. **准确性**：数据来自搜索结果，不编造 Star 数、评论数
3. **价值性**：优先选择对开发者有实际价值的内容
4. **简洁性**：全报控制在 15 条以内，避免信息过载
5. **可读性**：中文摘要要通顺，不机翻
