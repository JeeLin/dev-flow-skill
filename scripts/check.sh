#!/usr/bin/env bash
# mdflow 技能仓库一致性检查（只读 grep 规则，不做自动修复，不做风格 lint）
# A 组：契约一致性 | B 组：git 基准规则 | C 组：结构完整性
# 每条规则对应一个历史上真实踩过的坑，新增规则时在注释中标注对应事故。
# 场景化夹具测试（端到端状态机推演）属二期，场景底稿见 scripts/scenarios.md。

set -u
cd "$(dirname "$0")/.." || exit 1

TOTAL=0
FAIL=0

pass() { TOTAL=$((TOTAL + 1)); printf '  PASS  %s\n' "$1"; }
fail() { TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$1"; }
section() { printf '\n%s\n' "$1"; }

# ---------- A 组：契约一致性 ----------

section "A 契约一致性"

# A1 frontmatter name 必须等于目录名（技能按 name 匹配，不一致会静默失配）
a1_bad=""
for f in skills/*/SKILL.md; do
  dir=$(basename "$(dirname "$f")")
  name=$(sed -n 's/^name: //p' "$f" | head -n1)
  [ "$name" = "$dir" ] || a1_bad="$a1_bad $dir(name=$name)"
done
if [ -z "$a1_bad" ]; then pass "A1 name==dir（全部技能）"; else fail "A1 name!=dir:$a1_bad"; fi

# A2 严重度语义唯一定义在 contract.md，子技能只引用不重定义（两套语义漂移的事故）
if grep -q '^## 严重度分级契约' skills/mdflow/references/contract.md; then
  pass "A2 严重度契约唯一源 contract.md"
else
  fail "A2 严重度契约唯一源 contract.md"
fi
for s in mdflow-review mdflow-acceptance mdflow-bug; do
  if grep -q 'references/contract.md' "skills/$s/SKILL.md"; then pass "A2 引用契约: $s"; else fail "A2 引用契约: $s"; fi
done

# A3 报告文件名双侧一致（契约清单 == 步骤文件实际使用；双侧写死漂移的事故）
contract_reports=$(grep -o 'step[0-9]-[a-z-]*\.md' skills/mdflow/references/contract.md | sort -u)
step_reports=$(grep -rho 'step[0-9]-[a-z-]*\.md' skills/mdflow/references/step*.md | sort -u)
if [ -n "$contract_reports" ] && [ "$contract_reports" = "$step_reports" ]; then
  pass "A3 报告文件名契约==步骤文件"
else
  fail "A3 报告文件名契约!=步骤文件"
fi

# A4 子技能不得硬编码报告文件名（应经 report_path 参数传入，单边契约原则）
if grep -rq 'step[0-9]-[a-z-]*\.md' skills/mdflow-review skills/mdflow-acceptance skills/mdflow-bug skills/mdflow-planner; then
  fail "A4 子技能硬编码报告文件名"
else
  pass "A4 子技能报告路径已参数化"
fi

# A5 子技能不得带流程头（「供…步骤X调用」类回声；契约挪到调用方的事故）
if grep -rq '供.*步骤\|供 dev-\|供 devflow' skills/mdflow-*/SKILL.md; then
  fail "A5 子技能残留流程头"
else
  pass "A5 子技能无流程头"
fi
if grep -rq '^description:.*步骤' skills/mdflow-*/SKILL.md; then
  fail "A5 description 含步骤号"
else
  pass "A5 description 无步骤号"
fi

# A6 步骤文件调用的技能必须真实存在（改名后忘改调用方的事故）
a6_bad=0
for name in $(grep -rho 'name: "mdflow-[a-z]*"' skills/mdflow/references/ | sed 's/name: "//;s/"//' | sort -u); do
  if [ -f "skills/$name/SKILL.md" ]; then pass "A6 调用技能存在: $name"; else fail "A6 调用技能缺失: $name"; a6_bad=1; fi
done
[ "$a6_bad" -eq 0 ] || true

# A7 mdflow 体系内残留旧技能名（迁移漏改的事故）
if grep -rq 'devflow-review\|dev-acceptance\|dev-bug\|milestone-planner' skills/mdflow/ skills/mdflow-*/; then
  fail "A7 残留旧技能名"
else
  pass "A7 无旧技能名残留"
fi

# A8 发现→规则沉淀管线落地（审查报告必须含沉淀建议段）
for s in mdflow-review mdflow-acceptance; do
  if grep -q '沉淀建议' "skills/$s/SKILL.md"; then pass "A8 沉淀建议段: $s"; else fail "A8 沉淀建议段: $s"; fi
done

# A9 废弃里程碑机制：Flow Status 必有 状态 字段（状态机排除已放弃文档，缺字段则无法识别废弃 milestone 导致卡死）
if grep -q '状态：' skills/mdflow/references/template.md; then
  pass "A9 模板 Flow Status 有状态字段"
else
  fail "A9 模板 Flow Status 缺少状态字段"
fi

# ---------- B 组：git 基准规则 ----------

section "B git 基准规则"

# B1 变更范围必须走 {milestone-start-ref}（裸 git diff 在全部提交后为空 → 审查假通过的事故）
for f in skills/mdflow/references/step4.md skills/mdflow/references/step5.md; do
  if grep -q 'git diff --name-only {milestone-start-ref}' "$f"; then
    pass "B1 diff 基准: $(basename "$f")"
  else
    fail "B1 diff 基准: $(basename "$f")"
  fi
done
for f in skills/mdflow/references/step7.md skills/mdflow-acceptance/SKILL.md; do
  if grep -q 'git diff {milestone-start-ref}' "$f"; then
    pass "B1 验收 diff 基准: $(basename "$f")"
  else
    fail "B1 验收 diff 基准: $(basename "$f")"
  fi
done

# B2 禁止 HEAD~N 计数基准（依赖提交数假设的事故）
if grep -rq 'git diff HEAD~\|git diff HEAD\^' skills/mdflow/ skills/mdflow-*/; then
  fail "B2 使用了 HEAD~N 基准"
else
  pass "B2 无 HEAD~N 基准"
fi

# B3 ref 来源必须是 rev-parse 且契约警示 tag 不可用（里程碑文档在 gitignored 目录、tag 不存在的事故）
if grep -q 'git rev-parse HEAD' skills/mdflow/SKILL.md && grep -q 'git rev-parse HEAD' skills/mdflow/references/step1.md; then
  pass "B3 ref 来源 rev-parse HEAD"
else
  fail "B3 ref 来源 rev-parse HEAD"
fi
if grep -q 'git tag' skills/mdflow/references/contract.md; then
  pass "B3 tag 基准警示在契约"
else
  fail "B3 tag 基准警示在契约"
fi

# ---------- C 组：结构完整性 ----------

section "C 结构完整性"

# C1 每个步骤文件必须有 GUARD/ACT/MARK 三节（幂等结构缺失导致重入重复执行的事故）
for i in 1 2 3 4 5 6 7 8; do
  f="skills/mdflow/references/step$i.md"
  missing=""
  for sec in GUARD ACT MARK; do
    grep -q "^## ${sec}\$" "$f" 2>/dev/null || missing="$missing $sec"
  done
  if [ -z "$missing" ]; then pass "C1 三段式: step$i"; else fail "C1 三段式: step$i 缺:$missing"; fi
done

# C2 分发表 8 行且指向的文件都存在（分发断链的事故）
n=$(grep -c 'references/step[0-9]\.md' skills/mdflow/SKILL.md)
if [ "$n" -eq 8 ]; then pass "C2 分发表 8 行"; else fail "C2 分发表行数=$n（应为 8）"; fi
c2_missing=""
for i in 1 2 3 4 5 6 7 8; do
  [ -f "skills/mdflow/references/step$i.md" ] || c2_missing="$c2_missing step$i"
done
if [ -z "$c2_missing" ]; then pass "C2 步骤文件齐全"; else fail "C2 步骤文件缺失:$c2_missing"; fi

# C3 模板 8 个勾选框 + 状态行初始值（与状态机推断不一致的事故）
n=$(grep -c '^- \[ \] 步骤' skills/mdflow/references/template.md)
if [ "$n" -eq 8 ]; then pass "C3 模板 8 勾选框"; else fail "C3 模板勾选框=$n（应为 8）"; fi
if grep -q '审查轮：第1轮｜4— 5— 6— 7—' skills/mdflow/references/template.md; then
  pass "C3 状态行初始值"
else
  fail "C3 状态行初始值"
fi

# C4 轮次公式两侧一致（打回记录行数 + 1；计数与状态行脱节的事故）
if grep -q '打回记录行数 + 1' skills/mdflow/SKILL.md && grep -q '打回记录行数 + 1' skills/mdflow/references/template.md; then
  pass "C4 轮次公式一致"
else
  fail "C4 轮次公式一致"
fi

# C5 沉淀候选三侧齐全（契约台账列定义 / 模板小节 / step8 汇总记录，改一处忘两处的事故类，与 A3/C2 同源）
c5_missing=""
grep -q '### 沉淀候选格式' skills/mdflow/references/contract.md || c5_missing="$c5_missing contract"
grep -q '^## 沉淀候选$' skills/mdflow/references/template.md || c5_missing="$c5_missing template"
grep -q '沉淀候选汇总记录' skills/mdflow/references/step8.md || c5_missing="$c5_missing step8"
if [ -z "$c5_missing" ]; then pass "C5 沉淀候选三侧齐全"; else fail "C5 沉淀候选缺失:$c5_missing"; fi

# C6 mdflow 产出文档禁用繁体字元（码点级，字表独立维护于 scripts/cjk-forbidden.txt）
#    事故：mdflow 会话写 CJK 时产出简繁混写污染——消费者 REX 的 .mdflow 文档实测 188 处 / 33 字元
#    （现状/设计核对/门槛 等词被写成繁体形），而 REX 自身 README/AGENTS.md 传统计 0，证明非项目习惯；
#    本仓历史亦出现过把 C5 锚点第二字写成同形繁体（U+6DFA）的事故。故按字表做码点级拦截，零语义断言。
#    本规则注释本身不得写字面禁字，否则自指违反（与 C5 同源教训）。
c6_tbl="scripts/cjk-forbidden.txt"
if [ ! -f "$c6_tbl" ]; then
  fail "C6 缺字表 $c6_tbl"
else
  c6_pat=$(mktemp)
  # 去掉每行注释与空白，每行只留一个字元（保持逐行，供 grep -f 逐条定长匹配）
  sed 's/#.*//' "$c6_tbl" | sed 's/[[:space:]]//g' | grep -v '^$' > "$c6_pat"
  if [ ! -s "$c6_pat" ]; then
    fail "C6 字表为空"
  else
    c6_hits=$(grep -rnF -f "$c6_pat" \
      --include='*.md' --include='*.sh' \
      skills scripts README.md AGENTS.md CHANGELOG.md 2>/dev/null \
      | grep -v "^$c6_tbl:" | head -n 5)
    if [ -z "$c6_hits" ]; then
      pass "C6 无禁用繁体字元"
    else
      fail "C6 命中禁用繁体字元: $(echo "$c6_hits" | tr '\n' ' ')"
    fi
  fi
  rm -f "$c6_pat"
fi

# C7 锚点位置校验：U+6C89 之后必须紧跟 U+6DC0（沉淀 是本仓库唯一的 U+6C89 用法）
#    事故：锚点第二字曾被写成形近繁体/形近简体（U+6DFA / U+6168 / U+6DF7），而 慨/混
#    本身是合法简体字（感慨/混乱），全局禁字会误伤，故只能按「位置」而非「字集」判定——
#    位置规则同时覆盖未来任何形近替代，无需枚举。
#    注意：禁用字面八进制手算会错（曾把 U+6C89 写成 \346\265\201 → 假绿灯），
#    故此处用 python \u 转义生成，不手算字节。
c7_hits=$(python3 -c "
import pathlib
CHEN = '\u6C89'
DIAN = '\u6DC0'
targets = []
for r in ['skills', 'scripts', 'README.md', 'AGENTS.md', 'CHANGELOG.md']:
    p = pathlib.Path(r)
    if p.is_file():
        targets.append(p)
    elif p.is_dir():
        targets += [f for f in p.rglob('*')
                    if f.is_file() and f.suffix in ('.md', '.sh')]
out = []
for f in targets:
    try:
        t = f.read_text(encoding='utf-8')
    except Exception:
        continue
    for i, ch in enumerate(t):
        if ch != CHEN:
            continue
        nxt = t[i + 1] if i + 1 < len(t) else ''
        if nxt != DIAN:
            out.append('%s:%d next=U+%04X' % (f, t.count(chr(10), 0, i) + 1, ord(nxt)))
print('; '.join(out[:5]) if out else 'CLEAN')
")
if [ "$c7_hits" = "CLEAN" ]; then
  pass "C7 沉淀锚点位置正确"
else
  fail "C7 沉淀锚点被形近字替换: $c7_hits"
fi

# C8 缺陷池搬运必须无损且成对（planner 丢 bug / 只删不写的事故类，与 B/C 类同源）
#    事故链：缺陷池 bug 曾经只经 DEVELOPMENT.md 一行自由文本中转，描述列（可证伪三要素 +
#    grep 锚点）在搬运中压缩丢失，步骤5 审查无锚点可定位；且 planner 承诺「全部纳入 +
#    必须删行」却无闸门，漏写即静默丢 bug。本规则只断言契约文本仍在位（零语义断言）。
c8_missing=""
grep -q '缺陷池消费' skills/mdflow-planner/SKILL.md || c8_missing="$c8_missing planner"
grep -q '描述列原样搬运' skills/mdflow-planner/SKILL.md || c8_missing="$c8_missing planner-desc"
grep -q '写入行数 == 缺陷池条目数' skills/mdflow-planner/SKILL.md || c8_missing="$c8_missing planner-pair"
grep -q '只读不改' skills/mdflow/references/step1.md || c8_missing="$c8_missing step1"
grep -q '不自行补写' skills/mdflow/references/step1.md || c8_missing="$c8_missing step1-stop"
grep -q '写入行数 == 缺陷池条目数' skills/mdflow/SKILL.md || c8_missing="$c8_missing skill"
grep -q '缺陷池搬运必须无损且成对' scripts/check.sh || c8_missing="$c8_missing self"
if [ -z "$c8_missing" ]; then pass "C8 缺陷池搬运无损且成对"; else fail "C8 缺陷池搬运约定缺失:$c8_missing"; fi

# C9 子任务文件认领与点名核对（无序并行改同一 file:line 互相覆盖/行号位移；照名字误改无关代码的事故类）
#    事故链：GitPulse v0.7.0 设计审查实证——子任务「文件结构」跨节重复认领同一 file:line
#    且无依赖声明，步骤3 互相覆盖；另一子任务按用例名点名要改写的既有用例，步骤3 未核对
#    实际内容就照名字改掉了无关用例。模板与契约此前都没有对应概念（纯真空）。零语义断言。
c9_missing=""
grep -q '^## 子任务文件认领$' skills/mdflow/references/contract.md || c9_missing="$c9_missing contract-claim"
grep -q '单向有序链' skills/mdflow/references/contract.md || c9_missing="$c9_missing contract-order"
grep -q '\*\*依赖\*\*' skills/mdflow/references/template.md || c9_missing="$c9_missing template-field"
grep -q '文件认领自查' skills/mdflow/references/step1.md || c9_missing="$c9_missing step1-claim"
grep -q '点名核对' skills/mdflow/references/step1.md || c9_missing="$c9_missing step1-named"
grep -q '点名核对' skills/mdflow/references/step3.md || c9_missing="$c9_missing step3-named"
grep -q '与文档描述不符即' skills/mdflow/references/step3.md || c9_missing="$c9_missing step3-stop"
grep -q '未 ✅ 时不得动手' skills/mdflow/references/step3.md || c9_missing="$c9_missing step3-dep"
if [ -z "$c9_missing" ]; then pass "C9 子任务文件认领与点名核对"; else fail "C9 子任务认领约定缺失:$c9_missing"; fi

# C10 提交前必须验证构建与测试（实现 lane 在 shell 不可用时把未编译代码留在工作树的事故类）
#    事故链：GitPulse v0.7.0 设计审查实证——派发实现 lane 时 shell 不可用，代码以 E0308
#    未编译状态留在工作树并被直接提交，直到步骤6 才暴露，整轮审查返工。原步骤3 门禁只有
#    「精简必查清单」自查、不含构建/测试，步骤8 也只查 git status，属流程级空洞。零语义断言。
c10_missing=""
grep -q '^## 提交前验证$' skills/mdflow/references/contract.md || c10_missing="$c10_missing contract"
grep -q '不得伪造通过' skills/mdflow/references/contract.md || c10_missing="$c10_missing contract-nofake"
grep -q '未通过不得进入 MARK' skills/mdflow/references/step3.md || c10_missing="$c10_missing step3"
grep -q '代码不得以未编译状态留在工作树' skills/mdflow/references/step3.md || c10_missing="$c10_missing step3-shell"
grep -q '构建与测试通过' skills/mdflow/references/step3.md || c10_missing="$c10_missing step3-gate"
grep -q '构建与测试通过' skills/mdflow/references/step8.md || c10_missing="$c10_missing step8"
if [ -z "$c10_missing" ]; then pass "C10 提交前验证构建与测试"; else fail "C10 提交前验证约定缺失:$c10_missing"; fi

# C11 沉淀建议表头是解析锚点，列不可增删改名换序（跨项目实测 31 份报告仅 16 份标准 5 列的事故类）
#    事故链：步骤8 按列名取值解析各轮报告的沉淀建议表，而实测 9 份报告改了列、6 份整表缺失；
#    列漂移会解析出错误的候选去向并写歪台账，且缺表被静默跳过（看着像"这轮没沉淀"）。
#    本规则断言表头文本与「不可增删改名换序」「不合规不入台账」的约定仍在位（零语义断言）。
c11_missing=""
HDR='| 序 | 发现/模式 | 可 grep | 候选去向 | 草案（匹配模式 → 期望） |'
grep -q '表头 5 列是解析锚点' skills/mdflow/references/contract.md || c11_missing="$c11_missing contract-hdr"
grep -q '不合规报告不入台账' skills/mdflow/references/contract.md || c11_missing="$c11_missing contract-reject"
grep -q '当场退回该轮重生成' skills/mdflow/references/step8.md || c11_missing="$c11_missing step8-reject"
for pair in "skills/mdflow-review/SKILL.md 3" "skills/mdflow-acceptance/SKILL.md 1"; do
  set -- $pair
  n=$(grep -cF "$HDR" "$1")
  if [ "$n" -ne "$2" ]; then c11_missing="$c11_missing $(basename $(dirname $1))-hdr($n)"; fi
done
n=$(grep -cF '表头 5 列不得增删、改名或换序' skills/mdflow-review/SKILL.md)
[ "$n" -eq 3 ] || c11_missing="$c11_missing review-note($n)"
n=$(grep -cF '表头 5 列不得增删、改名或换序' skills/mdflow-acceptance/SKILL.md)
[ "$n" -eq 1 ] || c11_missing="$c11_missing acceptance-note($n)"
if [ -z "$c11_missing" ]; then pass "C11 沉淀建议表头列不可漂移"; else fail "C11 沉淀建议表头约定缺失:$c11_missing"; fi

# C12 断言有效性必须进内置代码审查维度集（恒真断言/不可达输入/同义复述/未被调用的事故类）
#    事故链：跨 3 项目复现——GitPulse 台账 #38/#45、OCC step4-backend、REX v0.90.0 #231，
#    step7 验收点名「应入步骤5 清单」。恒真断言与 f(x)==f(x) 式委派让测试全绿而缺陷未覆盖，
#    步骤6/7 反而给出绿灯。核实缺口：3 个项目 AGENTS.md 均无「## 代码审查维度」段，
#    全部回退到 mdflow-review 内置 6 维度（无测试/断言项），step5 无任何断言相关字样。
c12_missing=""
grep -q '^  | 7 | 测试有效性 |' skills/mdflow-review/SKILL.md || c12_missing="$c12_missing dimension"
grep -q '测试有效性（需精读测试文件本身' skills/mdflow-review/SKILL.md || c12_missing="$c12_missing weighting"
grep -q '断言有效性必查' skills/mdflow/references/step5.md || c12_missing="$c12_missing step5-act"
grep -q '恒真断言' skills/mdflow/references/step5.md || c12_missing="$c12_missing step5-tautology"
grep -q '不可达输入组合' skills/mdflow/references/step5.md || c12_missing="$c12_missing step5-unreachable"
grep -q '同义复述' skills/mdflow/references/step5.md || c12_missing="$c12_missing step5-restate"
grep -q '未被调用' skills/mdflow/references/step5.md || c12_missing="$c12_missing step5-uncalled"
grep -q '断言有效性四类无效形态均已核对' skills/mdflow/references/step5.md || c12_missing="$c12_missing step5-gate"
if [ -z "$c12_missing" ]; then pass "C12 断言有效性维度已落地"; else fail "C12 断言有效性约定缺失:$c12_missing"; fi

# C13 报告名允许分片后缀且读取一律按前缀（跨项目实测报告文件名分裂的事故类）
#    事故链：实测消费者仓库报告名分裂为前后端分侧（step5-frontend/backend）、
#    三段拆分（step7-part1..3）、单步多份（step6-test.md 与 step6-tests.md 并存）
#    等形态。契约原本只认一个固定文件名，读报告方按名字找，找不到就以为本步零发现
#    ——报告只是证据但「找不到」被当成了「没有」，是静默假通过。新增分片后缀规则后
#    必须同时固定「按前缀读取」，否则新规则只会再添一种漏读。本规则零语义断言。
c13_missing=""
grep -q '分片后缀（允许）' skills/mdflow/references/contract.md || c13_missing="$c13_missing contract-suffix"
grep -q '轮次不进文件名' skills/mdflow/references/contract.md || c13_missing="$c13_missing contract-round"
grep -q '不因文件名差异漏读' skills/mdflow/references/contract.md || c13_missing="$c13_missing contract-prefix"
grep -q '而判定本步零发现' skills/mdflow/references/contract.md || c13_missing="$c13_missing contract-nozero"
for i in 2 4 5 6 7; do
  grep -q '分片形态见契约' "skills/mdflow/references/step$i.md" || c13_missing="$c13_missing step$i"
done
if [ -z "$c13_missing" ]; then pass "C13 报告分片后缀与按前缀读取"; else fail "C13 报告名规则缺失:$c13_missing"; fi

# C14 技能侧修正必须回流消费者台账（台账裁决长期停留在过时状态的事故类）
#    事故链：某消费者 v0.91.0 步骤2 台账仍挂着「缺陷池 bug 未纳入里程碑」且标 ❌ 技能侧，
#    而该修正早已在技能仓库落地（无同步机制）——后续 session 会照着过期台账重复劳动。
#    回流只标状态 + 追加注记，不重置已有裁决、不代改 check.sh/AGENTS.md 去向的行。
c14_missing=""
grep -q '^### 技能侧修正回流$' skills/mdflow/references/contract.md || c14_missing="$c14_missing contract"
grep -q '规则名锚点' skills/mdflow/references/contract.md || c14_missing="$c14_missing contract-anchor"
grep -q '不重置裁决' skills/mdflow/references/contract.md || c14_missing="$c14_missing contract-idempotent"
grep -q '技能侧无权代改' skills/mdflow/references/contract.md || c14_missing="$c14_missing contract-scope"
grep -q '见「技能侧修正回流」' skills/mdflow/references/contract.md || c14_missing="$c14_missing contract-xref"
grep -q '技能侧修正回流' skills/mdflow/references/step8.md || c14_missing="$c14_missing step8"
grep -q '历史裁决留档' skills/mdflow/references/step8.md || c14_missing="$c14_missing step8-keep"
if [ -z "$c14_missing" ]; then pass "C14 技能侧修正回流台账"; else fail "C14 台账回流约定缺失:$c14_missing"; fi

# C15 step6 质量门禁不可漏写（跳过验证后判绿的事故类，与 C10 提交前验证同源）
#    事故链：OCC 的 AGENTS.md 定义 `scripts/check-coverage.sh 98`（98% 覆盖率门槛），
#    但 v0.3.0 / v0.1.0 / v0.2.1 的 step6 报告「质量门禁」表竟没有覆盖率行，结论却写 ✅
#    ——等于在从未执行覆盖率校验的前提下判绿，直到下游才发现。GitPulse 则固结了
#    `Lines 92.29% (>=90%)` 的阈值+实际数值形态。该纪律跨项目存在但无门禁强制，
#    故落技能侧：已定义（命令非空）的门检项必须固结，覆盖率须写明阈值+实际值。
#    本规则只断言契约文本与步骤约定仍在位（零语义断言）。
c15_missing=""
grep -q '步骤6 质量门禁表格不可漏写' skills/mdflow/references/contract.md || c15_missing="$c15_missing contract"
grep -q '阈值 | 实际数值' skills/mdflow/references/contract.md || c15_missing="$c15_missing contract-value"
grep -q '不可漏写 .AGENTS.md. 中定义的任一非空门检项' skills/mdflow/references/step6.md || c15_missing="$c15_missing step6-act"
grep -q '不可漏写、不可只写' skills/mdflow/references/step6.md || c15_missing="$c15_missing step6-gate"
if [ -z "$c15_missing" ]; then pass "C15 step6 质量门禁不可漏写"; else fail "C15 step6 门禁约定缺失:$c15_missing"; fi

# ---------- 汇总 ----------

printf '\n共 %d 项，失败 %d 项\n' "$TOTAL" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
