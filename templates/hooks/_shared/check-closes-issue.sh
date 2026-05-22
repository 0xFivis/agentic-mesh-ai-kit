#!/usr/bin/env bash
# REFERENCE ONLY: sanitized sample, not for production
# check-closes-issue.sh · commit message 必含 `Closes #N` / `Fixes #N` / `Refs #N`
# 适配：git commit-msg hook + agent PostToolUse (Bash matcher=git commit)
# 退出码：0=放行 · 2=阻断

set -euo pipefail

MSG_FILE="${1:-.git/COMMIT_EDITMSG}"
[[ -f "$MSG_FILE" ]] || { echo "[SKIP] no commit msg file"; exit 0; }

MSG="$(cat "$MSG_FILE")"

# 跳过 merge / revert / chore(release)
if echo "$MSG" | grep -qiE "^(Merge|Revert|chore\(release\))"; then
  exit 0
fi

if ! echo "$MSG" | grep -qiE "(Closes|Fixes|Refs|Relates to) #[0-9]+"; then
  echo "[BLOCK] check-closes-issue: commit message 必须含 'Closes #N' / 'Fixes #N' / 'Refs #N' 留痕" >&2
  echo "Current message:" >&2
  echo "$MSG" >&2
  exit 2
fi
exit 0
