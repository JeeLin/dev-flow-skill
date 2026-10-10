#!/usr/bin/env python3
"""Push a report to Feishu via the configured Lark/Feishu bot.

Used by the Multica autopilots ("科技早报" / "邮件分析") as the delivery
channel. Credentials live in the lark-cli config, NOT in this file.

Usage:
    feishu_push.py --text "..."                 # plain text
    feishu_push.py --markdown-file ./body.md    # rich post message
    cat body.md | feishu_push.py --markdown -   # read from stdin

Exit codes:
    0  sent
    2  bad usage / missing lark-cli / not configured
    1  send failed (message NOT delivered)
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path

LARK_CLI = shutil.which("lark-cli")

# 收件人**不写死**：本仓库是公开仓库，写死 open_id 等于公开某个人的飞书账号标识。
# 但也不能「只认环境变量」——agent 运行时环境里这些变量通常是空的，那样定时任务
# 会静默发不出消息。故收件人按以下顺序解析，任何一步命中即可：
#   1. 命令行 --user-id / --chat-id
#   2. 环境变量 FEISHU_PUSH_USER_ID / FEISHU_PUSH_CHAT_ID
#   3. 技能内的 config.toml（部署方自行填写，不入库；见 config.example.toml）
# 三处都没有时明确报错退出（码 2），绝不静默失败。
CONFIG_NAME = "feishu_push.toml"


def _load_config() -> dict:
    """读取技能目录内的 config.toml（与脚本同目录或上一级），缺失返回空 dict。"""
    import tomllib

    here = Path(__file__).resolve().parent
    for candidate in (here / CONFIG_NAME, here.parent / CONFIG_NAME):
        try:
            if candidate.is_file():
                with candidate.open("rb") as fh:
                    return tomllib.load(fh)
        except (OSError, tomllib.TOMLDecodeError):
            continue
    return {}


CONFIG = _load_config()
DEFAULT_USER_ID = (
    os.environ.get("FEISHU_PUSH_USER_ID") or CONFIG.get("user_id", "")
)
DEFAULT_CHAT_ID = (
    os.environ.get("FEISHU_PUSH_CHAT_ID") or CONFIG.get("chat_id", "")
)

TIMEOUT = int(os.environ.get("FEISHU_PUSH_TIMEOUT", "120"))


def die(code: int, message: str) -> "int":
    print(f"feishu_push: {message}", file=sys.stderr)
    return code


def read_input(
    markdown: str | None, text: str | None, file_arg: str | None, markdown_file: str | None
) -> tuple[str, str]:
    """Return (kind, payload) where kind is 'markdown' or 'text'."""
    if markdown_file:
        with open(markdown_file, encoding="utf-8") as fh:
            return "markdown", fh.read()
    if file_arg:
        with open(file_arg, encoding="utf-8") as fh:
            return ("markdown" if file_arg.endswith(".md") else "text", fh.read())
    if markdown == "-":
        return "markdown", sys.stdin.read()
    if text == "-":
        return "text", sys.stdin.read()
    return ("markdown" if markdown else "text", markdown or text or "")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--text")
    ap.add_argument("--markdown")
    ap.add_argument("--file", dest="file_arg")
    ap.add_argument(
        "--markdown-file", dest="markdown_file", help="read markdown body from this file"
    )
    ap.add_argument("--user-id", default=DEFAULT_USER_ID)
    ap.add_argument("--chat-id", default=DEFAULT_CHAT_ID)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if not LARK_CLI:
        return die(2, "lark-cli not found on PATH")

    kind, payload = read_input(args.markdown, args.text, args.file_arg, args.markdown_file)
    if not payload.strip():
        return die(2, "refusing to send an empty message")

    if not args.chat_id and not args.user_id:
        return die(
            2,
            "no recipient: pass --chat-id/--user-id, set FEISHU_PUSH_CHAT_ID/"
            "FEISHU_PUSH_USER_ID, or fill in feishu_push.toml next to this script",
        )

    target = ["--chat-id", args.chat_id] if args.chat_id else ["--user-id", args.user_id]

    # Bot identity: this app has no user login, and bot tokens are what the
    # tenant allows for outbound group/p2p messages.
    cmd = [LARK_CLI, "im", "+messages-send", "--as", "bot", *target]
    if kind == "markdown":
        cmd += ["--markdown", payload]
    else:
        cmd += ["--text", payload]

    # Keeps retries from double-posting the same report.
    cmd += ["--idempotency-key", uuid.uuid4().hex[:32]]

    if args.dry_run:
        cmd.append("--dry-run")

    try:
        proc = subprocess.run(
            cmd, capture_output=True, text=True, timeout=TIMEOUT
        )
    except subprocess.TimeoutExpired:
        return die(1, f"lark-cli timed out after {TIMEOUT}s; message state unknown")

    out = proc.stdout.strip()
    if proc.returncode != 0:
        return die(1, f"lark-cli exited {proc.returncode}: {proc.stderr.strip()[:400]}")

    try:
        parsed = json.loads(out[out.find("{") :])
    except (ValueError, json.JSONDecodeError):
        print(out)
        return 0 if proc.returncode == 0 else 1

    if not parsed.get("ok"):
        return die(1, f"send rejected: {json.dumps(parsed.get('error', {}), ensure_ascii=False)[:400]}")

    data = parsed.get("data", {})
    print(
        json.dumps(
            {
                "ok": True,
                "chat_id": data.get("chat_id"),
                "message_id": data.get("message_id"),
                "kind": kind,
                "dry_run": args.dry_run,
            },
            ensure_ascii=False,
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
