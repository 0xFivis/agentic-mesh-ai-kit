#!/usr/bin/env bash
# agentic-mesh-ai-kit / scripts/install.sh
# 一键铺设 4 厂商 AI 协作矩阵到目标仓库
# 用法：  bash scripts/install.sh --vendor <claude|cursor|copilot|codex|all> [--codex-override] [--with-spec-kit] [--dry-run]
# 设计：幂等 + 非破坏（已存在文件跳过并提示用 upgrade.sh）

set -euo pipefail

KIT_VERSION="$(cat "$(dirname "$0")/../VERSION" 2>/dev/null || echo "0.1.0")"
KIT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${TARGET:-$PWD}"
VENDOR="all"
CODEX_OVERRIDE="false"
WITH_SPEC_KIT="false"
DRY_RUN="false"

log()  { printf '\033[1;34m[install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vendor)         VENDOR="$2"; shift 2 ;;
    --codex-override) CODEX_OVERRIDE="true"; shift ;;
    --with-spec-kit)  WITH_SPEC_KIT="true"; shift ;;
    --dry-run)        DRY_RUN="true"; shift ;;
    --target)         TARGET="$2"; shift 2 ;;
    -h|--help)
      grep '^#' "$0" | head -20; exit 0 ;;
    *) err "未知参数: $1"; exit 2 ;;
  esac
done

[[ "$VENDOR" =~ ^(claude|cursor|copilot|codex|all)$ ]] || { err "--vendor 必须是 claude|cursor|copilot|codex|all"; exit 2; }

mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"
if [[ "$TARGET" == "$KIT_ROOT" ]]; then
  err "拒绝就地安装：TARGET ($TARGET) 与 KIT_ROOT ($KIT_ROOT) 相同。请 cd 到消费仓后再跑，或用 --target <其它路径>。"
  exit 3
fi
if [[ -f "$TARGET/VERSION" && -f "$TARGET/scripts/install.sh" ]]; then
  err "TARGET ($TARGET) 看起来是一个 ai-kit 仓本身。拒绝安装。"
  exit 3
fi

cd "$TARGET"
log "目标仓库: $TARGET"
log "Kit 版本: $KIT_VERSION"
log "厂商: $VENDOR"

# --- 工具函数 ----------------------------------------------------
copy_if_absent() {
  local src="$1" dst="$2"
  if [[ -e "$dst" ]]; then
    warn "skip (exists): $dst  → 升级请用 scripts/upgrade.sh"
    return 0
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DRY: copy $src → $dst"; return 0
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  log "+ $dst"
}

render_tmpl() {
  # 简单模板：把 .tmpl 后缀去掉，复制；后续可加 envsubst
  local src="$1" dst="$2"
  copy_if_absent "$src" "${dst%.tmpl}"
}

wants() { [[ "$VENDOR" == "all" || "$VENDOR" == "$1" ]]; }

# --- step 1 · 根 AGENTS.md + CLAUDE.md symlink -------------------
step_root_agents() {
  log "[step 1] 根 AGENTS.md (单一来源)"
  copy_if_absent "$KIT_ROOT/templates/agents-md/root/AGENTS.md.tmpl" "AGENTS.md"
  # CLAUDE.md → AGENTS.md (Claude 优先 CLAUDE.md，做 symlink 实现 SSOT)
  if [[ ! -e CLAUDE.md ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then log "DRY: ln -s AGENTS.md CLAUDE.md"
    else ln -s AGENTS.md CLAUDE.md && log "+ CLAUDE.md → AGENTS.md (symlink)"; fi
  else
    warn "skip CLAUDE.md (exists)"
  fi
}

# --- step 1.5 · 子目录 AGENTS.md (非破坏) -----------------------
step_subdir_agents() {
  log "[step 1.5] 子目录 AGENTS.md (10 处)"
  local map=(
    "apps:apps/AGENTS.md"
    "packages:packages/AGENTS.md"
    "ops:ops/AGENTS.md"
    "testing:testing/AGENTS.md"
    "contracts:contracts/AGENTS.md"
    "specs:specs/AGENTS.md"
    "docs:docs/AGENTS.md"
    "docs/architecture:docs/architecture/AGENTS.md"
    "docs/adr:docs/adr/AGENTS.md"
    "docs/services:docs/services/AGENTS.md"
  )
  for entry in "${map[@]}"; do
    local src_key="${entry%%:*}" dst="${entry#*:}"
    local src="$KIT_ROOT/templates/agents-md/subdirs/${src_key}/AGENTS.md.tmpl"
    [[ -f "$src" ]] || { warn "tmpl missing: $src"; continue; }
    copy_if_absent "$src" "$dst"
  done
}

# --- step 2 · Spec-Kit init -------------------------------------
step_spec_kit() {
  [[ "$WITH_SPEC_KIT" == "true" ]] || { log "[step 2] 跳过 Spec-Kit (--with-spec-kit 未指定)"; return; }
  log "[step 2] Spec-Kit init"
  local integ="$VENDOR"
  [[ "$VENDOR" == "all" ]] && integ="claude"  # all 时主集成走 claude
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DRY: uvx --from git+https://github.com/github/spec-kit.git specify init . --integration $integ --here"
  else
    command -v uvx >/dev/null || { err "需要 uvx (uv 工具集): https://docs.astral.sh/uv/"; return 1; }
    uvx --from git+https://github.com/github/spec-kit.git specify init . --integration "$integ" --here || warn "spec-kit init 非零退出 (可能已初始化)"
  fi
}

# --- step 3 · Skills (agentskills.io) ---------------------------
step_skills() {
  log "[step 3] Skills (12 个)"
  local skills=(tech-intake adr-writing std-writing contract-first gate-checklist task-decomp-fanout bc-impact-map qa-cases release-canary retro-audit data-redline scaffold-agents-md)
  # 本仓内 skills 已就绪；策略：复制到目标仓 .claude/skills、.cursor/skills、.codex/skills；Copilot 走 chatmodes (后续 step 处理)
  for sk in "${skills[@]}"; do
    local src="$KIT_ROOT/skills/$sk"
    [[ -d "$src" ]] || { warn "skill missing: $sk"; continue; }
    wants claude  && copy_skill_dir "$src" ".claude/skills/$sk"
    wants cursor  && copy_skill_dir "$src" ".cursor/skills/$sk"
    wants codex   && copy_skill_dir "$src" ".codex/skills/$sk"
    # Copilot 暂无 skills 等价物；通过 instructions 文件引用
  done
}
copy_skill_dir() {
  local src="$1" dst="$2"
  if [[ -e "$dst" ]]; then warn "skip skill (exists): $dst"; return; fi
  [[ "$DRY_RUN" == "true" ]] && { log "DRY: cp -R $src → $dst"; return; }
  mkdir -p "$(dirname "$dst")" && cp -R "$src" "$dst" && log "+ $dst"
}

# --- step 4 · Rules ---------------------------------------------
step_rules() {
  log "[step 4] Rules"
  # Claude 用 CLAUDE.md 层级，无需额外 rules 文件
  if wants cursor; then
    render_tmpl "$KIT_ROOT/templates/rules/cursor/contracts-first.mdc.tmpl" ".cursor/rules/contracts-first.mdc"
  fi
  if wants copilot; then
    render_tmpl "$KIT_ROOT/templates/rules/copilot/copilot-instructions.md.tmpl" ".github/copilot-instructions.md"
    render_tmpl "$KIT_ROOT/templates/rules/copilot/instructions/contracts-first.instructions.md.tmpl" ".github/instructions/contracts-first.instructions.md"
  fi
  if wants codex && [[ "$CODEX_OVERRIDE" == "true" ]]; then
    render_tmpl "$KIT_ROOT/templates/rules/codex/AGENTS.override.md.tmpl" ".codex/AGENTS.override.md"
  fi
}

# --- step 5 · Agents (sub-agents) -------------------------------
step_agents() {
  log "[step 5] Sub-agents"
  if wants claude; then
    for a in reviewer explorer doc-writer security-auditor; do
      render_tmpl "$KIT_ROOT/templates/agents/claude/$a.md" ".claude/agents/$a.md"
    done
  fi
  wants cursor  && render_tmpl "$KIT_ROOT/templates/agents/cursor/reviewer.md" ".cursor/agents/reviewer.md"
  wants copilot && render_tmpl "$KIT_ROOT/templates/agents/copilot/reviewer.md" ".github/chatmodes/reviewer.chatmode.md"
  wants codex   && render_tmpl "$KIT_ROOT/templates/agents/codex/reviewer.md" ".codex/agents/reviewer.md"
}

# --- step 6 · Hooks ---------------------------------------------
step_hooks() {
  log "[step 6] Hooks"
  # 共享脚本到 .ai-kit/hooks/_shared （所有 vendor 引用此路径）
  mkdir -p .ai-kit/hooks/_shared
  for sh in "$KIT_ROOT"/templates/hooks/_shared/*.sh; do
    local name; name="$(basename "$sh")"
    copy_if_absent "$sh" ".ai-kit/hooks/_shared/$name"
    [[ "$DRY_RUN" == "true" ]] || chmod +x ".ai-kit/hooks/_shared/$name" 2>/dev/null || true
  done
  wants claude  && render_tmpl "$KIT_ROOT/templates/hooks/claude/settings.json.tmpl" ".claude/settings.json"
  wants cursor  && render_tmpl "$KIT_ROOT/templates/hooks/cursor/hooks.json.tmpl" ".cursor/hooks.json"
  # Copilot 走 CI-Actions（见 step 9）
  wants codex   && render_tmpl "$KIT_ROOT/templates/hooks/codex/hooks.toml.tmpl" ".codex/hooks.toml"
}

# --- step 7 · MCP -----------------------------------------------
step_mcp() {
  log "[step 7] MCP"
  wants claude  && render_tmpl "$KIT_ROOT/templates/mcp/claude/.mcp.json.tmpl" ".mcp.json"
  wants cursor  && render_tmpl "$KIT_ROOT/templates/mcp/cursor/.cursor-mcp.json.tmpl" ".cursor/mcp.json"
  wants copilot && render_tmpl "$KIT_ROOT/templates/mcp/copilot/.vscode-mcp.json.tmpl" ".vscode/mcp.json"
  wants codex   && warn "Codex MCP 配置在 ~/.codex/config.toml (用户级)。模板见 templates/mcp/codex/config.toml.tmpl，需手动 merge。"
}

# --- step 8 · Settings ------------------------------------------
step_settings() {
  log "[step 8] Settings"
  wants claude  && render_tmpl "$KIT_ROOT/templates/settings/claude/settings.json.tmpl" ".claude/settings.local.json"
  wants cursor  && render_tmpl "$KIT_ROOT/templates/settings/cursor/settings.json.tmpl" ".cursor/settings.json"
  wants copilot && warn "Copilot 设置需 merge 到 .vscode/settings.json，模板见 templates/settings/copilot/README.md"
  wants codex   && warn "Codex 设置在 ~/.codex/config.toml (用户级)，模板见 templates/settings/codex/config.toml.tmpl"
}

# --- step 9 · CI prompts (SSOT) ---------------------------------
step_ci_prompts() {
  log "[step 9] CI prompts (SSOT)"
  render_tmpl "$KIT_ROOT/templates/ci-prompts/review.md.tmpl" ".github/ci-prompts/review.md"
}

# --- step 10 · Version pin --------------------------------------
step_version() {
  log "[step 10] 写 .ai-kit-version"
  if [[ "$DRY_RUN" == "true" ]]; then log "DRY: echo $KIT_VERSION > .ai-kit-version"; return; fi
  echo "$KIT_VERSION" > .ai-kit-version
  log "+ .ai-kit-version ($KIT_VERSION)"
}

# --- 主流程 -----------------------------------------------------
step_root_agents
step_subdir_agents
step_spec_kit
step_skills
step_rules
step_agents
step_hooks
step_mcp
step_settings
step_ci_prompts
step_version

log "完成。下一步："
log "  1) 审阅各 AGENTS.md / .claude/settings.json 是否符合团队约定"
log "  2) 把 ci-prompts/review.md 接入 GitHub Actions（见 templates/ci-prompts/README.md）"
log "  3) 若已有旧版本，使用 scripts/upgrade.sh 做三方合并升级"
