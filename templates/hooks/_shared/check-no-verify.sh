#!/usr/bin/env bash
# REFERENCE ONLY: sanitized sample, not for production
# check-no-verify.sh · 拦截 `git commit --no-verify` / `git push --no-verify`
# 适配：claude PreToolUse(Bash) · cursor beforeShellExecution · codex pre_exec_filter
# 退出码：0=放行 · 2=阻断（hook 协议）

set -euo pipefail

CMD="${CLAUDE_TOOL_INPUT:-${CURSOR_SHELL_CMD:-${1:-}}}"

if [[ "$CMD" == *"--no-verify"* ]]; then
  echo "[BLOCK] check-no-verify: --no-verify 不允许 (绕过 pre-commit / pre-push hook = 违反留痕红线)" >&2
  exit 2
fi
exit 0
