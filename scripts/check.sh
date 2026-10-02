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

# ---------- 汇总 ----------

printf '\n共 %d 项，失败 %d 项\n' "$TOTAL" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
