#!/usr/bin/env bash
# agentic-mesh-ai-kit / scripts/upgrade.sh
# 三方合并升级（基线 = 上次安装的 kit 版本；用户改动 = 目标仓现状；新版 = 当前 kit）
# 用法：bash scripts/upgrade.sh [--from <old-version>] [--dry-run]
# 前提：目标仓存在 .ai-kit-version

set -euo pipefail

KIT_VERSION="$(cat "$(dirname "$0")/../VERSION" 2>/dev/null || echo "0.1.0")"
KIT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${TARGET:-$PWD}"
DRY_RUN="false"
FROM_VERSION=""

log()  { printf '\033[1;34m[upgrade]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)    FROM_VERSION="$2"; shift 2 ;;
    --dry-run) DRY_RUN="true"; shift ;;
    --target)  TARGET="$2"; shift 2 ;;
    -h|--help) grep '^#' "$0" | head -10; exit 0 ;;
    *) err "未知参数: $1"; exit 2 ;;
  esac
done

cd "$TARGET"

[[ -f .ai-kit-version ]] || { err "缺少 .ai-kit-version；请先 scripts/install.sh"; exit 2; }
CURRENT="$(cat .ai-kit-version | tr -d '[:space:]')"
[[ -z "$FROM_VERSION" ]] && FROM_VERSION="$CURRENT"

log "目标仓库 : $TARGET"
log "已安装版本: $CURRENT  (基线 = $FROM_VERSION)"
log "新版本    : $KIT_VERSION"

if [[ "$CURRENT" == "$KIT_VERSION" ]]; then
  warn "版本一致，无需升级。"
  exit 0
fi

# 拉取基线 kit（用 git tag）
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
BASE="$WORK/base"
NEW="$WORK/new"
mkdir -p "$BASE" "$NEW"

log "准备基线版本 $FROM_VERSION → $BASE"
if git -C "$KIT_ROOT" rev-parse "v$FROM_VERSION" >/dev/null 2>&1; then
  git -C "$KIT_ROOT" archive "v$FROM_VERSION" | tar -x -C "$BASE"
else
  warn "未找到 git tag v$FROM_VERSION；改用当前 kit 作为基线（合并质量降级）"
  cp -R "$KIT_ROOT/." "$BASE/"
fi
cp -R "$KIT_ROOT/." "$NEW/"

# 候选合并文件清单（与 install.sh 落点对齐）
declare -a CANDIDATES=(
  "AGENTS.md"
  ".claude/settings.json"
  ".claude/settings.local.json"
  ".cursor/settings.json"
  ".cursor/hooks.json"
  ".cursor/rules/contracts-first.mdc"
  ".github/copilot-instructions.md"
  ".github/instructions/contracts-first.instructions.md"
  ".codex/AGENTS.override.md"
  ".codex/hooks.json"
  ".codex/config.toml"
  ".mcp.json"
  ".cursor/mcp.json"
  ".vscode/mcp.json"
  ".github/ci-prompts/review.md"
)

merge_one() {
  local rel="$1"
  local base_path new_path user_path
  user_path="$TARGET/$rel"
  # 找 base/new 对应的源（.tmpl 或纯文件）
  base_path="$(find "$BASE/templates" -path "*/${rel##*/}.tmpl" -print -quit 2>/dev/null || true)"
  new_path="$(find "$NEW/templates" -path "*/${rel##*/}.tmpl" -print -quit 2>/dev/null || true)"
  [[ -z "$base_path" || -z "$new_path" ]] && { warn "skip $rel (找不到对应模板)"; return; }
  [[ -f "$user_path" ]] || { log "+ 新增 $rel"; [[ "$DRY_RUN" == "true" ]] || { mkdir -p "$(dirname "$user_path")"; cp "$new_path" "$user_path"; }; return; }

  # 用户与新版相同 → noop
  if cmp -s "$user_path" "$new_path"; then log "= $rel (相同)"; return; fi
  # 用户与基线相同 → 直接覆盖为新版
  if cmp -s "$user_path" "$base_path"; then
    log "↑ $rel (未改动，升级到新版)"
    [[ "$DRY_RUN" == "true" ]] || cp "$new_path" "$user_path"
    return
  fi
  # 真三方：git merge-file
  log "⚡ $rel (三方合并)"
  if [[ "$DRY_RUN" == "true" ]]; then return; fi
  cp "$user_path" "$user_path.local"
  if git merge-file -L user -L base -L new "$user_path" "$base_path" "$new_path"; then
    log "  ✓ 干净合并；旧版备份 $rel.local"
  else
    warn "  ✗ 冲突写入 $rel；备份 $rel.local；请手动 resolve <<<<<<< markers"
  fi
}

for f in "${CANDIDATES[@]}"; do merge_one "$f"; done

# Skills / agents / hooks 目录策略：新增的复制；已存在的提示用户手动 diff
copy_new_in_dir() {
  local src_root="$1" dst_root="$2"
  [[ -d "$src_root" ]] || return
  while IFS= read -r f; do
    local rel="${f#$src_root/}"
    local dst="$dst_root/$rel"
    if [[ ! -e "$dst" ]]; then
      log "+ 新增 $dst"
      [[ "$DRY_RUN" == "true" ]] || { mkdir -p "$(dirname "$dst")"; cp "$f" "$dst"; }
    fi
  done < <(find "$src_root" -type f)
}

copy_new_in_dir "$NEW/skills" ".claude/skills" 2>/dev/null || true
copy_new_in_dir "$NEW/skills" ".cursor/skills" 2>/dev/null || true
copy_new_in_dir "$NEW/skills" ".codex/skills" 2>/dev/null || true

if [[ "$DRY_RUN" != "true" ]]; then
  echo "$KIT_VERSION" > .ai-kit-version
  log "+ 写 .ai-kit-version = $KIT_VERSION"
fi

log "升级完成。请："
log "  1) git diff 复查所有改动"
log "  2) 解决任何 .local 备份与冲突标记"
log "  3) 运行 hooks/_shared/*.sh 健康检查"
