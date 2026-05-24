# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [SemVer](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] — 2026-05-24

### Added
- 3 new skills under `skills/`:
  - `task-plan-drafting` — T4.1 single-task implementation plan drafting
  - `self-review-agent` — T4.2 author self-review (lint+, non-mandatory)
  - `new-service-bootstrap` — T4 special lane: 3-step new-service guidance
- `sop/README.md`, `templates/README.md`, `templates/specs/`, additional `_research/` notes
- `templates/settings/copilot/settings.json.tmpl`, `templates/mcp/codex/`, `templates/rules/claude/contracts-first.md.tmpl`

### Changed
- **SOP & playbook alignment**:
  - Replaced `PM-Tech` with `PO + TL` across all role definitions and approval matrix (T0, T4.5)
  - Removed "唯一审批人 / 不可委托 / 不可缺席" hard rule → now "指定审批角色 (可一个或多个, 多个时全签生效)"
  - Playbook §3.6 T2 approver tightened from `TL approve` to `架构师 + 服务 Owner 全签` (matches SOP)
  - Audit checklist "9 项 / 12 项" hardcoded counts removed; now "示例 · 随实践迭代"
  - Skill registry table expanded from 12 to 15 entries; `contract-first` and `task-decomp-fanout` marked as paused (superseded by spec-kit)
- `templates/settings/codex/config.toml.tmpl` (moved from `templates/codex/`)

### Fixed
- `scripts/install.sh` step_skills enumeration was missing the 3 new skills; fixed to include all 15

## [0.1.0] — 2026-05-22

Planned MVP release. Targets:
- 12 skills under `skills/` (11 reused from internal playbook + `scaffold-agents-md`); each `SKILL.md` carries a worked input/output example
- `templates/agents-md/{root,subdirs/<10 subdirs>}/AGENTS.md.tmpl`
- `templates/{rules,agents,hooks,mcp,settings,ci-prompts}/<vendor>/` with explicit READMEs for vendor-absent combinations
- `templates/ci-prompts/review.md.tmpl` as the single source of truth for CI review prompts (referenced by all four vendor workflows via `prompt-file:`)
- `templates/hooks/_shared/*.sh` cross-vendor hook scripts
- Knowledge base: `playbook/`, `sop/`, `_research/`
- `scripts/install.sh` (10-step installer with non-destructive nested AGENTS.md lay-down at step 1.5)
- `scripts/upgrade.sh` (three-way merge + `.ai-kit-version` pin at platform root)
