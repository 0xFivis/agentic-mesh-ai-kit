#!/usr/bin/env bash
# REFERENCE ONLY: sanitized sample, not for production
# check-no-secrets.sh · 提交前 / 读文件前扫描凭证泄漏
# 适配：claude PreToolUse(Write|Edit) · cursor beforeSubmitPrompt · git pre-commit

set -euo pipefail

# 默认扫 staged diff；可通过 $1 指定文件
if [[ -n "${1:-}" ]]; then
  TARGET="$1"
  CONTENT="$(cat "$TARGET" 2>/dev/null || echo "")"
else
  CONTENT="$(git diff --cached 2>/dev/null || git diff 2>/dev/null || echo "")"
fi
[[ -n "$CONTENT" ]] || exit 0

# 高信号 pattern · 命中任一 = 阻断
PATTERNS=(
  'AKIA[0-9A-Z]{16}'                                    # AWS Access Key
  'aws_secret_access_key\s*=\s*[A-Za-z0-9/+=]{40}'      # AWS Secret
  'ghp_[A-Za-z0-9]{36}'                                 # GitHub PAT
  'github_pat_[A-Za-z0-9_]{82}'                         # GitHub fine-grained PAT
  'sk-[A-Za-z0-9]{32,}'                                 # OpenAI / generic
  'xox[baprs]-[A-Za-z0-9-]{10,}'                        # Slack
  '-----BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY'     # PEM private key
  'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.'         # JWT
)

HITS=0
for p in "${PATTERNS[@]}"; do
  if echo "$CONTENT" | grep -qE "$p"; then
    echo "[BLOCK] check-no-secrets: matched pattern /$p/" >&2
    HITS=$((HITS+1))
  fi
done
(( HITS == 0 )) || { echo "[BLOCK] 触 data-redline 红线 #5/#2/#1 · 请 rotate 后重提" >&2; exit 2; }
exit 0
