#!/usr/bin/env bash
# REFERENCE ONLY: sanitized sample, not for production
# check-task-verification.sh · T4 任务结束前自验
# 用途：在 task 标 done 之前，运行 quickstart 场景或最小 smoke test
# 适配：Stop / PostToolUse(Bash matcher=git push)

set -euo pipefail

FEATURE_ID="${FEATURE_ID:-$(git rev-parse --abbrev-ref HEAD | grep -oE '[0-9]{3}-[a-z0-9-]+' | head -1)}"
[[ -n "${FEATURE_ID:-}" ]] || { echo "[SKIP] cannot derive FEATURE_ID from branch"; exit 0; }

QUICKSTART="specs/${FEATURE_ID}/quickstart.md"
[[ -f "$QUICKSTART" ]] || { echo "[SKIP] $QUICKSTART not found"; exit 0; }

# 抽取 quickstart 中的 ```bash``` 块第一段作为 smoke
SMOKE="$(awk '/^```bash$/{f=1;next} /^```$/{f=0} f' "$QUICKSTART" | head -20)"
[[ -n "$SMOKE" ]] || { echo "[SKIP] no bash block in $QUICKSTART"; exit 0; }

echo "[check-task-verification] running smoke from $QUICKSTART:" >&2
echo "$SMOKE" >&2

if ! bash -c "$SMOKE" >/dev/null 2>&1; then
  echo "[BLOCK] check-task-verification: smoke from $QUICKSTART failed" >&2
  exit 2
fi
exit 0
