#!/usr/bin/env python3
"""技能内转发壳：把调用交给共享实现 `skills/_shared/feishu_push.py`。

**为什么保留这个文件**：文档与 autopilot 里写死的是技能内的固定路径
（`.opencode/skills/<技能名>/scripts/feishu_push.py`），且外部守护进程会把这套
技能物化到每次运行的独立工作目录里。删掉本文件就等于让所有既有调用路径失效，
因此这里保留一个「薄壳」——按 `__file__` 相对的路径加载共享实现，
实现本身只在 `skills/_shared/feishu_push.py` 存一份。

选它而不选软链或 importlib 再导出的原因：
- 软链：部分 git 流程（Windows检出、归档导出、`cp` 不带 -d 的物化）不可靠，
  断链后 exec 出来是一个语法错误堆栈，很难排查。
- 再导出：物化到运行目录后 `sys.path` 未必包含 `skills/`，需要额外注入路径，
  多一层失败模式。

壳里因此显式校验共享文件存在并给出可读报错——共享文件丢失必须是响亮失败，
而不是 `ImportError: No module named ...` 或一段裸 traceback。

用法（与共享实现完全一致，参数透传）：
    feishu_push.py --text "..."
    feishu_push.py --markdown-file ./report.md
    cat body.md | feishu_push.py --markdown -

退出码沿用共享实现：0 已发送 / 2 用法或环境不对 / 1 发送失败。
"""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

# 共享实现在技能集的兄弟目录：skills/_shared/feishu_push.py
_SHARED = Path(__file__).resolve().parent.parent.parent / "_shared" / "feishu_push.py"


def _load_shared():
    """按 __file__ 相对路径加载共享实现，返回其 main 函数。"""
    if not _SHARED.is_file():
        print(
            f"feishu_push: 缺少共享实现 {_SHARED}；"
            "本文件只是转发壳，完整逻辑只存在于 skills/_shared/feishu_push.py。",
            file=sys.stderr,
        )
        raise SystemExit(2)
    spec = importlib.util.spec_from_file_location("_shared_feishu_push", _SHARED)
    if spec is None or spec.loader is None:
        print(f"feishu_push: 无法加载共享实现 {_SHARED}", file=sys.stderr)
        raise SystemExit(2)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


if __name__ == "__main__":
    sys.exit(_load_shared().main())
