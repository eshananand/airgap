# Design Spec: Add `ag-` Prefix to All Airgap Commands

**Date:** 2026-03-20
**Status:** Approved

---

## Summary

Rename all airgap commands to use the `ag-` prefix for consistent namespacing. Add a new `/ag-help` command that lists all commands with descriptions.

## Motivation

Currently 3 of 21 commands have the `ag-` prefix while 18 don't. This creates an inconsistent namespace. All airgap-related commands should be clearly identified with the `ag-` prefix.

## Scope

### File Renames (18 files)

| Current | New |
|---|---|
| `commands/activate.md` | `commands/ag-activate.md` |
| `commands/audit-deps.md` | `commands/ag-audit-deps.md` |
| `commands/deactivate.md` | `commands/ag-deactivate.md` |
| `commands/debug.md` | `commands/ag-debug.md` |
| `commands/design.md` | `commands/ag-design.md` |
| `commands/execute.md` | `commands/ag-execute.md` |
| `commands/finish.md` | `commands/ag-finish.md` |
| `commands/implement.md` | `commands/ag-implement.md` |
| `commands/new-skill.md` | `commands/ag-new-skill.md` |
| `commands/parallel.md` | `commands/ag-parallel.md` |
| `commands/postmortem.md` | `commands/ag-postmortem.md` |
| `commands/preflight.md` | `commands/ag-preflight.md` |
| `commands/receive-review.md` | `commands/ag-receive-review.md` |
| `commands/scan-secrets.md` | `commands/ag-scan-secrets.md` |
| `commands/test.md` | `commands/ag-test.md` |
| `commands/threat-model.md` | `commands/ag-threat-model.md` |
| `commands/verify.md` | `commands/ag-verify.md` |
| `commands/worktree.md` | `commands/ag-worktree.md` |

Already prefixed (no change): `ag-plan.md`, `ag-review.md`, `ag-security-review.md`

### New Command: `ag-help.md`

- **Description frontmatter:** "List all airgap commands with descriptions"
- Outputs a formatted table of all airgap commands grouped by workflow phase:
  - **Build:** ag-design, ag-plan, ag-execute, ag-implement, ag-parallel
  - **Quality:** ag-test, ag-verify, ag-review, ag-security-review, ag-receive-review
  - **Security:** ag-scan-secrets, ag-audit-deps, ag-threat-model, ag-preflight
  - **Operations:** ag-debug, ag-postmortem, ag-finish, ag-worktree
  - **Meta:** ag-activate, ag-deactivate, ag-new-skill, ag-help

### Cross-Reference Updates

#### Command files with internal references

| File (new name) | References to update |
|---|---|
| `ag-plan.md` | `/implement` → `/ag-implement`, `/execute` → `/ag-execute` |
| `ag-review.md` | `/implement` → `/ag-implement`, `/execute` → `/ag-execute` |
| `ag-debug.md` | `/test` → `/ag-test`, `/verify` → `/ag-verify` |
| `ag-test.md` | `/verify` → `/ag-verify` |
| `ag-design.md` | (no changes needed — already references `/ag-plan`) |
| `ag-execute.md` | `/worktree` → `/ag-worktree`, `/finish` → `/ag-finish` |
| `ag-implement.md` | `/worktree` → `/ag-worktree`, `/finish` → `/ag-finish` |
| `ag-finish.md` | `/worktree` → `/ag-worktree` |
| `ag-preflight.md` | `/verify` → `/ag-verify`, `/scan-secrets` → `/ag-scan-secrets`, `/audit-deps` → `/ag-audit-deps`, `/finish` → `/ag-finish` |
| `ag-postmortem.md` | `/debug` → `/ag-debug`, `/implement` → `/ag-implement`, `/verify` → `/ag-verify`, `/test` → `/ag-test` |
| `ag-audit-deps.md` | `/preflight` → `/ag-preflight`, `/implement` → `/ag-implement` |
| `ag-security-review.md` | `/verify` → `/ag-verify` |
| `ag-threat-model.md` | (no changes needed — already references `/ag-plan`) |
| `ag-worktree.md` | `/implement` → `/ag-implement`, `/execute` → `/ag-execute`, `/finish` → `/ag-finish` |
| `ag-scan-secrets.md` | `/preflight` → `/ag-preflight`, `/finish` → `/ag-finish` |
| `ag-activate.md` | Full routing table — all command references updated to `ag-` prefix |
| `ag-deactivate.md` | `/debug` → `/ag-debug`, `/test` → `/ag-test`, `/activate` → `/ag-activate` (in confirmation message) |

#### Non-command files

- `README.md` — all command references updated
- `.claude/CLAUDE.md` — full routing table updated
- `docs/airgap/specs/2026-03-20-auto-activation-design.md` — all references updated

#### No changes needed

- `ag-receive-review.md`, `ag-parallel.md`, `ag-verify.md`, `ag-new-skill.md` — no cross-references
- `agents/code-reviewer.md`, `install.sh` — no command references

## Verification

1. **File existence** — all 22 `ag-*.md` files exist, no old unprefixed files remain
2. **Cross-reference integrity** — no remaining unprefixed command references (excluding prose)
3. **Frontmatter intact** — every command file has valid `description` frontmatter
4. **ag-help content** — lists all commands with correct descriptions
