#!/usr/bin/env bash
# agentic-mesh-ai-kit / bootstrap.sh
# ----------------------------------------------------------------------
# 远程一行式安装入口 — 把 kit clone 到临时目录后调 scripts/install.sh
#
# 用法（在目标消费仓的根目录下执行）：
#   bash <(curl -sSL https://raw.githubusercontent.com/0xFivis/agentic-mesh-ai-kit/main/bootstrap.sh) --vendor all
#
# 环境变量：
#   KIT_REF      指定分支/Tag/Commit（默认 main）
#   KIT_REPO     覆盖仓库 URL（默认 https://github.com/0xFivis/agentic-mesh-ai-kit.git）
#   KEEP_TMP     设为 1 时保留临时 clone 目录用于排查
#
# 所有其它参数透传给 scripts/install.sh：
#   --vendor <claude|cursor|copilot|codex|all>
#   --no-spec-kit  --skip-agent-check  --dry-run  --target <dir>
# ----------------------------------------------------------------------

set -euo pipefail

KIT_REPO="${KIT_REPO:-https://github.com/0xFivis/agentic-mesh-ai-kit.git}"
KIT_REF="${KIT_REF:-main}"
KEEP_TMP="${KEEP_TMP:-0}"
ORIG_PWD="$PWD"

log()  { printf '\033[1;34m[bootstrap]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }

command -v git >/dev/null  || { err "需要 git";  exit 127; }
command -v bash >/dev/null || { err "需要 bash"; exit 127; }

TMP="$(mktemp -d -t agentic-mesh-ai-kit.XXXXXX)"
cleanup() {
  if [[ "$KEEP_TMP" == "1" ]]; then
    log "保留临时目录: $TMP"
  else
    rm -rf "$TMP"
  fi
}
trap cleanup EXIT

log "仓库: $KIT_REPO"
log "Ref:  $KIT_REF"
log "临时目录: $TMP"

# 1) shallow clone
if ! git clone --depth=1 --branch "$KIT_REF" --quiet "$KIT_REPO" "$TMP" 2>/dev/null; then
  # 退化路径：分支不存在时尝试 commit/tag 全量 clone
  log "shallow clone 失败，回退到全量 clone 后 checkout $KIT_REF"
  rm -rf "$TMP"
  git clone --quiet "$KIT_REPO" "$TMP"
  ( cd "$TMP" && git checkout --quiet "$KIT_REF" )
fi

# 2) 回到用户原始目录，调 installer。TARGET 显式指定为原始 PWD
cd "$ORIG_PWD"
log "调用 $TMP/scripts/install.sh"
TARGET="$ORIG_PWD" exec bash "$TMP/scripts/install.sh" "$@"
