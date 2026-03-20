---
description: List all airgap commands with descriptions
---
# Airgap Commands

Print the table below. Do not modify it.

## Build

| Command | Description |
|---------|-------------|
| `/ag-design` | Brainstorm ideas into approved design specs through structured dialogue |
| `/ag-plan` | Spec to implementation plan with atomic tasks, file mappings, and dependency ordering |
| `/ag-execute` | Inline plan execution with review gates and progress tracking |
| `/ag-implement` | Subagent-driven plan execution with two-stage review per task |
| `/ag-parallel` | Decompose independent tasks into parallel subagents |

## Quality

| Command | Description |
|---------|-------------|
| `/ag-test` | TDD red-green-refactor discipline — no code without a failing test first |
| `/ag-verify` | Evidence-based verification — no completion claims without proof |
| `/ag-review` | Trigger code-reviewer agent for quality review with iterative feedback |
| `/ag-security-review` | OWASP Top 10 security audit with CWE references and severity ratings |
| `/ag-receive-review` | Handle incoming review feedback with structured evaluation |

## Security

| Command | Description |
|---------|-------------|
| `/ag-scan-secrets` | Scan codebase for leaked credentials, API keys, and tokens |
| `/ag-audit-deps` | Dependency vulnerability and license audit across package managers |
| `/ag-threat-model` | STRIDE-based threat modeling with likelihood and impact scoring |
| `/ag-preflight` | Pre-deploy go/no-go gate orchestrating verify, scan-secrets, and audit-deps |

## Operations

| Command | Description |
|---------|-------------|
| `/ag-debug` | Systematic 4-phase debugging with root cause analysis before fixes |
| `/ag-postmortem` | Blameless incident analysis with 5-Whys root cause and action items |
| `/ag-finish` | Branch completion with merge, PR, keep, or discard options |
| `/ag-worktree` | Create isolated git worktrees for safe parallel feature work |

## Meta

| Command | Description |
|---------|-------------|
| `/ag-activate` | Enable auto-activation so airgap workflows trigger from natural language |
| `/ag-deactivate` | Remove airgap auto-activation from the current project |
| `/ag-new-skill` | Create new custom commands following Airgap conventions |
| `/ag-help` | List all airgap commands with descriptions |
