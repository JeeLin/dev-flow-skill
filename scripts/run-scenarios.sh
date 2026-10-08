#!/usr/bin/env bash
# 状态机场景推演（二期夹具，语义层）
#
# 读取 scripts/fixtures/SNN.md 的里程碑状态快照，按 skills/mdflow/SKILL.md「状态机」
# 推演下一步动作并与 expected 断言。静态 grep 门禁仍见 scripts/check.sh；
# 语义层的状态机推演不接入 check.sh（措辞改写易误报，语义验证归二期夹具）。
set -u
cd "$(dirname "$0")/.." || exit 1

FIXTURES="scripts/fixtures/SNN.md"

TOTAL=0
FAIL=0
pass() { TOTAL=$((TOTAL + 1)); printf '  PASS  %s\n' "$1"; }
fail() { TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$1"; }

# ----状态机推演（与 SKILL.md「状态机」逐 IF 对应）----
# 参数：flow_status review_round bugs_square abandoned has_milestone
dispatch() {
  local flow="$1" round="$2" bugs="$3" ab="$4" has="$5"
  local i has_x all47

  # IF 没有里程碑文档，或全部里程碑均已结束（8 步全勾完成，或 状态=已放弃）
  if [ "$has" = "false" ] || [ "$ab" = "true" ]; then
    echo "步骤1"; return
  fi
  # 8 步全勾 → 入口分支回到步骤1
  if [ "$flow" = "（none）" ] || [[ "$flow" != *"☐"* ]]; then
    echo "步骤1"; return
  fi

  # IF 步骤1/2/3 未勾选
  for i in 1 2 3; do
    if [[ "$flow" == *"${i}☐"* ]]; then
      echo "步骤$i"; return
    fi
  done

  # 步骤3 已勾选：以下处理审查轮
  all47=true
  for i in 4 5 6 7; do
    [[ "$flow" == *"${i}☐"* ]] && all47=false
  done

  # IF 步骤3 ✓ 且 审查轮状态行含 —（断点恢复）→ 第一个 — 的步骤
  if [ "$round" != "（none）" ] && [[ "$round" == *"—"* ]]; then
    for i in 4 5 6 7; do
      if [[ "$round" == *"${i}—"* ]]; then
        echo "步骤$i"; return
      fi
    done
  fi

  # IF 步骤3 ✓ 且 状态行 4/5/6/7 均为 ✓/✗ 且（4-7 未全勾 或 含 ✗）→ 轮末统一判断
  if [ "$round" != "（none）" ] && [[ "$round" != *"—"* ]]; then
    has_x=false
    for i in 4 5 6 7; do
      [[ "$round" == *"${i}✗"* ]] && has_x=true
    done
    if [ "$has_x" = "true" ] || [ "$all47" = "false" ]; then
      # 任一 ✗ → 统一打回 → 步骤3
      if [ "$has_x" = "true" ]; then
        echo "步骤3"; return
      fi
      # 轮末全 ✓（勾选 4/5/6/7 后继续匹配）；Bugs⬜ 随之一起打回
      if [ "$bugs" -gt 0 ]; then
        echo "步骤3"; return
      fi
    fi
  fi

  # IF 步骤3 ✓ 且 Bugs 表格存在未修复 bug → 统一打回 → 步骤3
  # （注：审查轮进行中——状态行含 ——时已由上文返回，不到此处）
  if [ "$bugs" -gt 0 ]; then
    echo "步骤3"; return
  fi

  # IF 步骤3 ✓ 且 审查轮状态行缺失 且 4-7 未全勾 → 兼容旧里程碑 → 步骤4
  if [ "$round" = "（none）" ] && [ "$all47" = "false" ]; then
    echo "步骤4"; return
  fi

  # IF 步骤8 未勾选 → 步骤8
  if [[ "$flow" == *"8☐"* ]]; then
    echo "步骤8"; return
  fi

  # 8 步全勾（或 4-7 全勾+状态行缺失+没 Bug）→ 下轮走入口分支
  echo "步骤1"
}


# ----标记识别推演（与契约「里程碑状态标记」逐分支对应）----
# 参数：marker_cur marker_blank marker_done marker_foreign
# 顺序即契约分支顺序：非规范词与多命中优先于「无标记但无 🔄」，
# 因为前者是「词汇不认识」，后者只是「标记缺失」，混判会把两类事故压成一条。
dispatch_marker() {
  local cur="$1" blank="$2" done="$3" foreign="$4"
  # 非规范状态词 → 标记未维护，不做别名兼容
  if [ "$foreign" -gt 0 ]; then echo "停止报告"; return; fi
  # 🔄 当前 多命中 → 状态冲突
  if [ "$cur" -ge 2 ]; then echo "停止报告"; return; fi
  # 命中 1 行 → 正常
  if [ "$cur" -eq 1 ]; then echo "继续"; return; fi
  # 无 🔄 且有未开始条目 → 标记未维护，不自行提升
  if [ "$blank" -gt 0 ]; then echo "停止报告"; return; fi
  # 无 🔄 且无未开始条目：须全部为 ✅ 已完成，否则是「条目存在但状态不可识别」
  if [ "$done" -gt 0 ] || [ "$((cur + blank + done + foreign))" -eq 0 ]; then
    echo "调planner"; return
  fi
  echo "停止报告"; return
}

# ---- 驱动：从 SNN.md 解析每个场景断言----
current="" flow="" round="" bugs="" ab="" has=""
mcur="" mblank="" mdone="" mforeign=""

# 跳过文件首的 markdown 标题/说明，直到第一个 ### S 场景
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    "### S"*)
      current="${line#\### }"
      flow=""; round=""; bugs=""; ab=""; has=""
      mcur=""; mblank=""; mdone=""; mforeign=""
      ;;
    flow_status=*)    flow="${line#flow_status=}" ;;
    review_round=*)   round="${line#review_round=}" ;;
    bugs_square=*)    bugs="${line#bugs_square=}" ;;
    abandoned=*)      ab="${line#abandoned=}" ;;
    has_milestone=*)  has="${line#has_milestone=}" ;;
    marker_cur=*)      mcur="${line#marker_cur=}" ;;
    marker_blank=*)    mblank="${line#marker_blank=}" ;;
    marker_done=*)     mdone="${line#marker_done=}" ;;
    marker_foreign=*)  mforeign="${line#marker_foreign=}" ;;
    marker_expected=*)
      [ -z "$current" ] && continue
      mexp="${line#marker_expected=}"
      mgot=$(dispatch_marker "${mcur:-0}" "${mblank:-0}" "${mdone:-0}" "${mforeign:-0}")
      mid="${current%%｜*}"
      if [ "$mgot" = "$mexp" ]; then
        pass "$mid → $mgot"
      else
        fail "$mid → 实际 $mgot，期望 $mexp"
      fi
      current=""
      ;;
    expected=*)
      [ -z "$current" ] && continue
      expected="${line#expected=}"
      got=$(dispatch "$flow" "$round" "$bugs" "$ab" "$has")
      id="${current%%｜*}"
      if [ "$got" = "$expected" ]; then
        pass "$id → $got"
      else
        fail "$id → 实际 $got，期望 $expected"
      fi
      current=""
      ;;
  esac
done < "$FIXTURES"

printf '\n共 %d 项，失败 %d 项\n' "$TOTAL" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
