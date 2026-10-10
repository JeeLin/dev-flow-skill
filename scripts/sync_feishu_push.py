#!/usr/bin/env python3
"""从 `skills/_shared/feishu_push.py` 生成各技能内的自足副本。

## 为什么需要这个脚本

推送脚本曾被做成「转发壳 + 运行时 importlib 引用 `skills/_shared/`」。在仓库里
能跑，但**部署后必然失效**：守护进程只物化技能自身的文件
（`.opencode/skills/<技能名>/…`），`skills/_shared/` 不属于任何技能，永远不会
出现在运行目录里。实测物化后调用会直接报「缺少共享实现」并以退出码 2 结束——
定时任务将完全发不出消息。

正确解法是「**源码一份，副本必然可用**」：`_shared/` 是唯一可编辑的源码，
每个技能目录下的副本由本脚本生成。自足副本解决运行时可用性，生成机制解决
「两份相同文件迟早各自漂移」——漂移由 `./scripts/check.sh` 的校验拦下。

## 用法

    python3 scripts/sync_feishu_push.py          # 生成/刷新各技能副本
    python3 scripts/sync_feishu_push.py --check  # 只校验副本与源码是否一致（CI/门禁用）

`--check` 有差异时退出码 1，供 check.sh 断言。
"""

from __future__ import annotations

import ast
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SOURCE = REPO_ROOT / "skills" / "_shared" / "feishu_push.py"

# 需要同步的技能：改动这里等于改动分发范围
TARGET_SKILLS = ("email-analysis", "tech-briefing")

HEADER = '''#!/usr/bin/env python3
"""技能内 feishu_push（由 scripts/sync_feishu_push.py 从 skills/_shared/ 生成）。

**手动编辑本文件会被覆盖**：改 `skills/_shared/feishu_push.py`，然后跑
`python3 scripts/sync_feishu_push.py` 重新生成。

刻意做成自足副本而不是 importlib 引用 `_shared/`：守护进程只物化技能**自身**
的文件（`.opencode/skills/<技能名>/`），`skills/_shared/` 永远不会出现在运行
目录里，运行时引用必断。生成方式保证实现只有一份源码、N 份必然可用的副本。
"""
'''

# 源码自己的 shebang 与模块 docstring 不能原样拼在本 HEADER 之后：模块只能有一个
# docstring，且 `from __future__` 必须位于文件开头的语句区。故生成时剥掉它们，
# 由 HEADER 独占 docstring 位置。
#
# 用 ast 定位 docstring 结束行，而不是正则数引号：多行 docstring 里出现引号、
# 前置空行、单双引号混用等情况都会让正则数错行。
def _strip_preamble(text: str) -> str:
    """去掉源码开头的 shebang 行与紧随其后的模块 docstring（含多行形式）。"""
    lines = text.splitlines(keepends=True)
    drop_until_line = 1  # 1-based；至少剥掉 shebang 所在行

    if lines and lines[0].lstrip().startswith("#!"):
        drop_until_line = 2

    try:
        mod = ast.parse(text)
    except SyntaxError:
        # 源码本身语法错误：不猜，原样拼上去，让下游 py_compile 去报错
        return text
    doc = ast.get_docstring(mod, clean=False)
    if doc is not None and mod.body:
        first = mod.body[0]
        # 只在首个语句确实是 docstring 时才剥
        if isinstance(first, ast.Expr) and isinstance(first.value, ast.Constant):
            drop_until_line = max(drop_until_line, first.end_lineno + 1)

    return "".join(lines[drop_until_line - 1 :])


def rendered() -> str:
    return HEADER + _strip_preamble(SOURCE.read_text(encoding="utf-8"))


def main() -> int:
    if not SOURCE.is_file():
        print(f"sync_feishu_push: 缺少源码 {SOURCE}", file=sys.stderr)
        return 2

    check_only = "--check" in sys.argv[1:]
    want = rendered()
    drifted: list[str] = []

    for skill in TARGET_SKILLS:
        target = REPO_ROOT / "skills" / skill / "scripts" / "feishu_push.py"
        current = target.read_text(encoding="utf-8") if target.is_file() else None
        if current == want:
            print(f"  OK   {skill}")
            continue
        if check_only:
            drifted.append(skill)
            print(f"  DRIFT {skill}（跑 python3 scripts/sync_feishu_push.py 刷新）")
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(want, encoding="utf-8")
            print(f"  写入 {skill}")

    if drifted:
        print(
            f"sync_feishu_push: {len(drifted)} 个技能副本与源码不一致："
            f"{', '.join(drifted)}",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())