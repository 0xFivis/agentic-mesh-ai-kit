# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [SemVer](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial repository scaffolding (README, LICENSE, CHANGELOG placeholders).

## [0.1.0] — TBD

Planned MVP release. Targets:
- 12 skills under `skills/` (11 reused from internal playbook + `scaffold-agents-md`); each `SKILL.md` carries a worked input/output example
- `templates/agents-md/{root,subdirs/<10 subdirs>}/AGENTS.md.tmpl`
- `templates/{rules,agents,hooks,mcp,settings,ci-prompts}/<vendor>/` with explicit READMEs for vendor-absent combinations
- `templates/ci-prompts/review.md.tmpl` as the single source of truth for CI review prompts (referenced by all four vendor workflows via `prompt-file:`)
- `templates/hooks/_shared/*.sh` cross-vendor hook scripts
- Knowledge base: `playbook/`, `sop/`, `_research/`
- `scripts/install.sh` (10-step installer with non-destructive nested AGENTS.md lay-down at step 1.5)
- `scripts/upgrade.sh` (three-way merge + `.ai-kit-version` pin at platform root)
