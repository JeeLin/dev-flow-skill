#!/usr/bin/env bash
# dev-flow 日志写入 helper
# 用法:
#   log.sh step  <version> <step_num> [extra_json]
#   log.sh reject <version> <step_num> <category> <detail> [extra_json]
#   log.sh gate  <checks_json>
#   log.sh plan  <version> <version_type> <subtask_count> <features_json> [extra_json]
#   log.sh version <from> <to> <type> <file>
#   log.sh cleanup
#
# JSON 值通过环境变量传递，避免 shell 引号转义问题：
#   LOG_EXTRA='{"file":"src/auth.ts"}' log.sh step v1.0.0 3
#   LOG_CHECKS='[{"name":"compile","passed":true}]' log.sh gate
#   LOG_FEATURES='["用户CRUD","前端列表"]' log.sh plan v1.1.0 minor 5
#
# 不设置环境变量时使用默认值（空对象/数组）。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/.dev-flow"
LOG_FILE="${LOG_DIR}/log.jsonl"

mkdir -p "$LOG_DIR"

export NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
if [ -n "${LOG_EXTRA:-}" ]; then EXTRA="$LOG_EXTRA"; else EXTRA='{}'; fi

case "${1:-}" in
  step)
    VERSION="${2:?missing version}"
    STEP_NUM="${3:?missing step_num}"
    python3 -c "
import sys, json, os
obj = {
  'ts': os.environ['NOW'],
  'event': 'step',
  'version': sys.argv[1],
  'step': int(sys.argv[2]),
  'action': 'complete',
}
extra = json.loads(sys.argv[3])
obj.update(extra)
json.dump(obj, sys.stdout, ensure_ascii=False)
print()
" "$VERSION" "$STEP_NUM" "$EXTRA" >> "$LOG_FILE"
    ;;

  reject)
    VERSION="${2:?missing version}"
    STEP_NUM="${3:?missing step_num}"
    CATEGORY="${4:?missing category}"
    DETAIL="${5:?missing detail}"
    python3 -c "
import sys, json, os
obj = {
  'ts': os.environ['NOW'],
  'event': 'reject',
  'version': sys.argv[1],
  'step': int(sys.argv[2]),
  'category': sys.argv[3],
  'detail': sys.argv[4],
  'reentry_step': int(sys.argv[2]),
}
extra = json.loads(sys.argv[5])
obj.update(extra)
json.dump(obj, sys.stdout, ensure_ascii=False)
print()
" "$VERSION" "$STEP_NUM" "$CATEGORY" "$DETAIL" "$EXTRA" >> "$LOG_FILE"
    ;;

  gate)
    CHECKS="${LOG_CHECKS:-[]}"
    python3 -c "
import sys, json, os
obj = {
  'ts': os.environ['NOW'],
  'event': 'gate',
  'checks': json.loads(sys.argv[1]),
}
json.dump(obj, sys.stdout, ensure_ascii=False)
print()
" "$CHECKS" >> "$LOG_FILE"
    ;;

  plan)
    VERSION="${2:?missing version}"
    VERSION_TYPE="${3:?missing version_type}"
    SUBTASK_COUNT="${4:?missing subtask_count}"
    FEATURES="${LOG_FEATURES:-[]}"
    python3 -c "
import sys, json, os
obj = {
  'ts': os.environ['NOW'],
  'event': 'plan',
  'version': sys.argv[1],
  'version_type': sys.argv[2],
  'subtask_count': int(sys.argv[3]),
  'features': json.loads(sys.argv[4]),
}
extra = json.loads(sys.argv[5])
obj.update(extra)
json.dump(obj, sys.stdout, ensure_ascii=False)
print()
" "$VERSION" "$VERSION_TYPE" "$SUBTASK_COUNT" "$FEATURES" "$EXTRA" >> "$LOG_FILE"
    ;;

  version)
    FROM="${2:?missing from}"
    TO="${3:?missing to}"
    TYPE="${4:?missing type}"
    FILE="${5:?missing file}"
    python3 -c "
import sys, json, os
obj = {
  'ts': os.environ['NOW'],
  'event': 'version',
  'from': sys.argv[1],
  'to': sys.argv[2],
  'type': sys.argv[3],
  'file': sys.argv[4],
}
json.dump(obj, sys.stdout, ensure_ascii=False)
print()
" "$FROM" "$TO" "$TYPE" "$FILE" >> "$LOG_FILE"
    ;;

  cleanup)
    if [ -f "$LOG_FILE" ]; then
      python3 -c "
import json, datetime, os
p = os.environ.get('LOG_FILE')
if p and os.path.exists(p):
    cutoff = (datetime.datetime.now() - datetime.timedelta(days=30)).isoformat()
    kept = []
    for line in open(p):
        line = line.strip()
        if not line:
            continue
        try:
            if json.loads(line).get('ts', '') >= cutoff:
                kept.append(line)
        except json.JSONDecodeError:
            kept.append(line)
    with open(p, 'w') as f:
        f.write(('\n'.join(kept) + '\n') if kept else '')
" LOG_FILE="$LOG_FILE"
    fi
    ;;

  *)
    echo "用法: $0 {step|reject|gate|plan|version|cleanup} [args...]" >&2
    echo "" >&2
    echo "JSON 值通过环境变量传递:" >&2
    echo "  LOG_EXTRA='{}' $0 step <version> <step_num>" >&2
    echo "  LOG_CHECKS='[...]' $0 gate" >&2
    echo "  LOG_FEATURES='[...]' $0 plan <version> <type> <count>" >&2
    exit 1
    ;;
esac
