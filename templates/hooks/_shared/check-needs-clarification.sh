#!/usr/bin/env bash
# REFERENCE ONLY: sanitized sample, not for production
# check-needs-clarification.sh · 待澄清项守门
# 用途：阻止 T1 启动前 spec.md 仍存在 `[BLOCK-T1]` / `[NEEDS-CLARIFICATION]` 标记
# 适配：beforeSubmitPrompt / SessionStart / PreCommit

set -euo pipefail

TARGETS=(specs/**/spec.md)
shopt -s globstar nullglob

HITS=0
for f in "${TARGETS[@]}"; do
  if grep -qE "\[(BLOCK-T1|NEEDS-CLARIFICATION|TBD-CRITICAL)\]" "$f"; then
    echo "[BLOCK] check-needs-clarification: $f 仍含待澄清标记" >&2
    grep -nE "\[(BLOCK-T1|NEEDS-CLARIFICATION|TBD-CRITICAL)\]" "$f" >&2
    HITS=$((HITS+1))
  fi
done
(( HITS == 0 )) || exit 2
exit 0
