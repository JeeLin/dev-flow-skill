---
name: email-analysis
description: Scheduled agent-driven analysis of unread 163.com email — IMAP fetch, LLM classify/summary, deliver to Feishu.
---

# Email Analysis (unread 163.com)

Scheduled workflow triggered by the autopilot `📧 邮件分析与推送（迁移自 Hermes)` (`0 9,12,15,18 * * 1-5`, Asia/Shanghai). Migrated from Hermes; runs natively on this host — no Docker volume dependency.

## Native host layout (not Docker)

| What | Host path | Notes |
|------|-----------|-------|
| Fetch script | `/opt/email-analyzer/email_analyzer.py` | migrated from Hermes volume, `BODY.PEEK[]` |
| Credentials | `/opt/email-analyzer/config.toml` | root:root `0600` — never log or post these |
| Config fallback | `/opt/config.toml` | symlink → `/opt/email-analyzer/config.toml` |
| himalaya CLI | `/usr/local/bin/himalaya` | v2.2.1, official binary |
| himalaya config | `/root/.config/himalaya/config.toml` | `0600`, generated from the legacy v1 config |

The old Hermes assets remain read-only in the Docker volume `test-hermes-zsw75t_hermes-data` for reference; nothing in the live path reads from it.

## Step 1 — fetch unread mail (read-only)

```bash
python3 /opt/email-analyzer/email_analyzer.py --json
```

Returns `{"count": N, "emails": [...]}`. Uses `BODY.PEEK[]`, so **fetching never marks mail as read** — runs are idempotent and safe to repeat. If `count == 0`, stop without pushing (no unread mail means nothing to deliver).

## Step 2 — analyze each email

For every email, emit exactly:

- **重要程度**: 🔴 紧急 / 🟠 重要 / ⚪ 普通 / ⚫ 低
- **分类**: 💰 金融 / 💼 工作 / 📦 电商 / 💬 社交 / 📮 订阅 / 📢 广告 / 🔒 安全 / 📧 其他
- 2–3 sentence summary
- 行动项 (action item)
- 截止日期 (deadline)

If the body contains any unsubscribe keyword (退订 / 取消订阅 / preferences / unsubscribe), append `📮 含退订链接` at the end of that email's block.

## Step 3 — deliver the report

Write the report body to `./report.md` in the run's working directory, then push
it to Feishu. 推送脚本随本技能物化在
`.opencode/skills/email-analysis/scripts/feishu_push.py`，是**自足副本**——
守护进程只物化技能自身的文件，因此它不引用技能集里的任何兄弟目录：

```bash
python3 .opencode/skills/email-analysis/scripts/feishu_push.py --markdown-file ./report.md
```

源码唯一一份在 `skills/_shared/feishu_push.py`，各技能目录下的副本由
`python3 scripts/sync_feishu_push.py` 生成。**改逻辑请改 `_shared/` 再重新生成**，
直接编辑技能内的副本会被覆盖，且 `scripts/sync_feishu_push.py --check` 会判为漂移。

Success prints `{"ok": true, "message_id": "om_..."}`; failure exits non-zero.
Retry at most once. 推送失败必须如实报告，不得静默吞掉。

**若本次运行存在 issue**（即 autopilot 配成 `create_issue`），可额外把同一份正文
发一条 issue 评论作为审计留档；配成 `run_only` 时**没有 issue 可发**，不要尝试。

### 收件人从哪来（部署方必须配其一）

收件人**不写死**（本仓库公开，写死 open_id 等于公开个人飞书账号标识）。按优先级解析：

1. `--user-id` / `--chat-id` 参数
2. `FEISHU_PUSH_USER_ID` / `FEISHU_PUSH_CHAT_ID` 环境变量
3. 技能脚本同目录（或上一级）的 `feishu_push.toml`，格式见
   `skills/_shared/config.example.toml`

三处都没有时脚本以退出码 2 明确报错，**不会静默失败**。

⚠️ **agent 运行时的环境变量经常是空的**，只配环境变量的部署会在定时任务里
逐次失败——所以生产部署应当写 `feishu_push.toml`（该文件名已被 `.gitignore` 排除）。
凭证在 lark-cli 自身配置（`/root/.lark-cli/config.json`，`0600`），
不在本技能或脚本里。

## himalaya CLI (optional, for manual mail ops)

The **email CLI** `pimalaya/himalaya` is a Rust binary and has **no npm/bun package** — `bun add himalaya` installs an unrelated HTML→JSON parser. Install from the official release tarball instead:

```bash
curl -fL -o /tmp/himalaya.tgz \
  https://github.com/pimalaya/himalaya/releases/download/v2.2.1/himalaya.x86_64-linux.tgz
tar xzf /tmp/himalaya.tgz -C /tmp && install -m 755 /tmp/himalaya /usr/local/bin/himalaya
```

Usage (v2 renamed `folder` → `mailbox`, and dropped `-u/--unseen`):

```bash
himalaya -a jjee mailbox list
himalaya -a jjee envelope list -s 20
```

### 163.com gotchas baked into the config

v2 dropped the v1 `backend` table entirely — a v1 config fails with *"configures no supported backend"*. Three settings make 163/Coremail work:

- `imap.sasl-ir = false` — 163 advertises SASL-IR falsely and rejects inline credentials.
- `imap.id.auto = true` + `imap.id.fields = { name = false, version = false }` — 163 requires an IMAP `ID` after AUTH; its canned payload is refused with `Unsafe Login`, so send `ID NIL`. (`imap.id.fields` is a **bool** map — string values are a TOML schema error.)
- SASL **LOGIN**, not PLAIN — 163 answers PLAIN with `NO AUTHENTICATE Not support mechanism`.

SMTP lives under `smtp.server = "smtps://smtp.163.com:465"` in the same file.

## Credentials

Kept in `0600` files rather than the agent's custom env, because agent actors cannot write their own agent secrets. A human owner can migrate them to the platform secret store with:

```bash
multica agent env set e3d4b276-238f-4f5f-8fb6-d16e6c83dcd5 --custom-env-file <file>
```

The script's resolution order is: script-local `config.toml` → `/opt/config.toml` → `EMAIL_ADDRESS` / `EMAIL_PASSWORD` env, so env-based credentials work with no code change.