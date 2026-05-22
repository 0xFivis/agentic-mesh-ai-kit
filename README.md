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

## Versioning

`install.sh` writes the kit version into a single file at the target platform root:

```
.ai-kit-version   # e.g. v0.1.0
```

`scripts/upgrade.sh` performs a three-way merge against a newer tag and updates this file.

## Status

`v0.1.0` planned (MVP). See [`CHANGELOG.md`](CHANGELOG.md).

## License

MIT — see [`LICENSE`](LICENSE).
