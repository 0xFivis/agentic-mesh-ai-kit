# agentic-mesh-ai-kit

> **AI-collaboration distribution kit** — a single installable repo bundling **four asset classes** for AI-assisted development across Claude Code, Cursor, GitHub Copilot, and Codex CLI. Pairs with (but does **not** depend on) [`agentic-mesh-arch-kit`](https://github.com/fivis/agentic-mesh-arch-kit).

## What lives here (the 4 asset classes)

| Asset class | Path | Purpose |
|---|---|---|
| **Skills** | `skills/` | [agentskills.io](https://agentskills.io) compliant, distributed via [`vercel-labs/skills`](https://github.com/vercel-labs/skills) CLI; cross-vendor reusable capabilities |
| **Templates** | `templates/<type>/<vendor>/` | Native config templates per vendor: `agents-md/ rules/ agents/ hooks/ mcp/ settings/ ci-prompts/` |
| **Knowledge base** | `playbook/ sop/ _research/` | The AI agent playbook, SOPs, and research notes that templates and skills reference |
| **Scripts** | `scripts/` | `install.sh` (10-step installer) and `upgrade.sh` (three-way merge + version pinning) |

This split is intentional: **agentskills.io is just one property of the `skills/` class** — the kit is not "a skill registry". It is a kit *containing* skills among other AI assets.

## L1 `AGENTS.md` — three placement modes

The `AGENTS.md` file is the universal L1 entry point read by all four vendors (Claude Code reaches it through a `CLAUDE.md → AGENTS.md` symlink created by `install.sh`). There are **three modes** of placement, handled differently:

### (a) Repository root — automatic
`install.sh` copies `templates/agents-md/root/AGENTS.md.tmpl` to `<platform>/AGENTS.md` and creates `<platform>/CLAUDE.md` as a symlink. Always runs.

### (b) Nested generic subdirectories — non-destructive bulk lay-down
`install.sh` **step 1.5** copies from `templates/agents-md/subdirs/<subdir>/AGENTS.md.tmpl` into **10 fixed locations** *if they exist* and *if no `AGENTS.md` is already present*:

```
apps/  packages/  ops/  testing/  contracts/  specs/
docs/  docs/architecture/  docs/adr/  docs/services/
```

> `infra/` is intentionally **excluded** (the arch-kit does not pre-ship it; see arch-kit ADR D23).
> Existing `AGENTS.md` files are **never overwritten** — the step is purely additive.

### (c) Business sub-domains (e.g. `apps/<svc>/`) — on-demand via skill
**Not in `install.sh`. Not pre-shipped in `templates/`.** Run the skill `scaffold-agents-md` (manual invocation):

```
claude skill scaffold-agents-md         # or the equivalent in cursor / copilot / codex
```

The skill scans `apps/* packages/*` etc., and for each business sub-directory **missing** an `AGENTS.md`, generates one tailored to that sub-domain. Already-present files are skipped (never overwritten). v0.1 ships this as a manual call only; auto-hook into IDE/CLI events is deferred to v0.2.

## Zero coupling with `arch-kit`

This repo never depends on `agentic-mesh-arch-kit`, never invokes its scripts, and is not a submodule of any platform. You can install it into:
- a platform derived from `arch-kit`, **or**
- any other empty / existing repository.

## Install

### Prerequisites

- `git` ≥ 2.30
- `bash` ≥ 3.2 (macOS stock works; Linux/WSL fine)
- `npx` (for `skills add` distribution)
- `uvx` (only if you pass `--with-spec-kit`; install via [uv](https://docs.astral.sh/uv/))

### 1 · Get the kit

```bash
git clone https://github.com/fivis/agentic-mesh-ai-kit.git ~/.agentic-mesh-ai-kit
```

> Pin a version (recommended for reproducibility):
> ```bash
> git -C ~/.agentic-mesh-ai-kit checkout v0.1.0
> ```

### 2 · Install into your target platform

```bash
cd /path/to/your/platform   # must be a git repo
bash ~/.agentic-mesh-ai-kit/scripts/install.sh --vendor all
```

Flags:

| Flag | Effect |
|---|---|
| `--vendor <claude\|cursor\|copilot\|codex\|all>` | which AI vendor(s) to wire up (default `all`) |
| `--codex-override` | also lay down `.codex/AGENTS.override.md` for Codex-specific divergence |
| `--with-spec-kit` | also run `uvx specify init . --integration <vendor> --here` (Spec-Kit) |
| `--dry-run` | show what would happen; write nothing |
| `--target <dir>` | install into a different directory than `$PWD` |

### 3 · What lands where

After `install.sh --vendor all` your platform gains:

```
AGENTS.md                            # root L1 (single source)
CLAUDE.md → AGENTS.md                # symlink for Claude Code
apps/AGENTS.md   packages/AGENTS.md   ops/AGENTS.md   ...   # 10 subdir L1s (non-destructive)
.claude/{skills,agents,settings.json,settings.local.json}
.cursor/{skills,agents,rules,hooks.json,mcp.json,settings.json}
.codex/{skills,agents,hooks.toml}    # config.toml stays at ~/.codex/
.github/{copilot-instructions.md,instructions/,chatmodes/,ci-prompts/review.md}
.vscode/mcp.json                     # Copilot MCP
.mcp.json                            # Claude MCP
.ai-kit/hooks/_shared/*.sh           # shared hook scripts (chmod +x)
.ai-kit-version                      # version pin (e.g. v0.1.0)
```

Existing files are **never overwritten** — you'll see `skip (exists)` warnings. Use `upgrade.sh` for true upgrades.

### 4 · (Optional) Generate `AGENTS.md` for business sub-domains

`install.sh` lays down the 10 generic subdir `AGENTS.md`s. For per-service ones (`apps/<svc>/AGENTS.md`), invoke the skill manually inside the vendor of your choice:

```
claude skill scaffold-agents-md      # or the equivalent in cursor / copilot / codex
```

### 5 · Upgrade later

```bash
git -C ~/.agentic-mesh-ai-kit fetch --tags
git -C ~/.agentic-mesh-ai-kit checkout v0.2.0
bash ~/.agentic-mesh-ai-kit/scripts/upgrade.sh
# review git diff; resolve any *.local backups or merge conflict markers
```

The upgrade script reads `.ai-kit-version`, fetches that tag as the merge base, and performs a three-way merge against your modified files. New skills/agents in the new version are added; existing ones are diff-merged.

## Status

`v0.1.0` planned (MVP). See [`CHANGELOG.md`](CHANGELOG.md).

## License

MIT — see [`LICENSE`](LICENSE).
