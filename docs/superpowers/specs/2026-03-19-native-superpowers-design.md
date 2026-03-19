# Native Superpowers Design Spec

**Date:** 2026-03-19
**Status:** Approved
**Author:** Ritik Sha Srivastava (with Claude)

---

## Overview

A native, self-contained replication of the superpowers plugin for Claude Code, deployable in company environments that restrict external plugins and git repositories.

The system consists of 13 slash command files and 1 agent file — all plain markdown — that live in `~/.claude/commands/` and `~/.claude/agents/`. No plugin system, no internet access, no external dependencies. Copy two directories to any machine and the system is live.

---

## Problem Statement

The superpowers plugin provides structured workflows (brainstorming, planning, debugging, code review, etc.) that significantly improve Claude Code's output quality. However, many corporate environments prohibit:

- External plugin marketplaces
- External git repositories pulled to local machines
- Tools that require internet access at runtime

This project solves that by inlining all skill logic into native Claude Code files that any Claude Code installation can load without plugins.

---

## Goals

- Full feature parity with superpowers v5.0.5 core workflows (all 13 skills + code-reviewer agent listed in the Architecture section; visual companion and MCP integrations are explicitly excluded — see Non-Goals)
- Zero external dependencies at runtime
- Deployable by copying two directories
- Action-based command names (not matching superpowers names, to avoid confusion)
- Commands are explicit — invoked manually, not auto-triggered

---

## Non-Goals

- Visual brainstorming companion (requires local server, not suitable for restricted environments)
- Plugin marketplace integration
- Automatic skill invocation via system prompt triggers
- MCP server integrations

---

## Architecture

### Deployment Layout

```
~/.claude/
├── commands/
│   ├── design.md          # Brainstorming → design → spec workflow
│   ├── plan.md            # Implementation plan writing
│   ├── execute.md         # Plan execution with checkpoints
│   ├── debug.md           # Systematic root-cause debugging
│   ├── test.md            # Test-driven development
│   ├── worktree.md        # Git worktree isolation
│   ├── verify.md          # Evidence-based verification
│   ├── parallel.md        # Parallel agent dispatch
│   ├── implement.md       # Subagent-driven implementation
│   ├── review.md          # Manual code review trigger
│   ├── receive-review.md  # Incoming review handler
│   ├── finish.md          # Branch completion (merge/PR/cleanup)
│   ├── new-skill.md       # Create new custom command
│   └── README.md          # Index of all commands (created by /new-skill on first run)
└── agents/
    └── code-reviewer.md   # Dispatched by /review and other commands
```

### Command File Anatomy

Each command file is a self-contained markdown prompt with this structure:

```markdown
<!-- v1.0 -->
# [Command Name]

[Role/goal statement]

## Process
[Step-by-step workflow logic, fully inlined]

## [Reference sections]
[Checklists, anti-patterns, examples — all inlined, no external reads]
```

No external file reads. No web fetches. No git dependencies. Everything Claude needs is in the file itself.

---

## Command Specifications

### `/design` — Brainstorm & Design
**Replaces:** `superpowers:brainstorming`

Guides a structured conversation from raw idea to approved design spec:
1. Explore project context (files, docs, recent commits)
2. Ask clarifying questions one at a time (multiple choice preferred)
3. Propose 2–3 approaches with trade-offs and a recommendation
4. Present design in sections, get approval after each
5. Write spec to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
6. Dispatch `code-reviewer` agent with spec-review context; fix and re-dispatch until approved (max 3 iterations)
7. Ask user to review the written spec
8. Hand off to `/plan`

**Hard gate:** No implementation action until design is approved by user.

---

### `/plan` — Write Implementation Plan
**Replaces:** `superpowers:writing-plans`

Takes an approved spec and produces a detailed implementation plan:
1. Read the spec document
2. Decompose into ordered, atomic implementation steps
3. Identify dependencies between steps
4. Flag risk areas and propose mitigations
5. Write plan to `docs/superpowers/plans/YYYY-MM-DD-<topic>-implementation.md`
6. Dispatch `code-reviewer` agent with plan-review context; iterate until approved
7. Ask user to review the written plan
8. Hand off to `/execute` or `/implement`

---

### `/execute` — Execute a Plan
**Replaces:** `superpowers:executing-plans`

Executes a written plan with review gates:
1. Read the plan document
2. Confirm scope with user before starting
3. Execute each step sequentially, marking progress
4. After each major step: summarize what was done, what's next, surface blockers
5. On completion: run `/verify` before claiming done
6. Dispatch `code-reviewer` agent for final review

---

### `/debug` — Systematic Debugging
**Replaces:** `superpowers:systematic-debugging`

Forces root-cause analysis before any fix:
1. Reproduce the bug — confirm it's real and consistent
2. Formulate hypotheses (at least 2–3)
3. Design the minimal experiment to distinguish between them
4. Trace to root cause — not symptoms
5. Fix the root cause only
6. Verify the fix didn't introduce regressions
7. Document what was found and why the fix works

**Hard gate:** No fix attempt before root cause is identified.

---

### `/test` — Test-Driven Development
**Replaces:** `superpowers:test-driven-development`

Enforces red → green → refactor cycle:
1. Write failing tests that specify the desired behavior (red)
2. Write minimal implementation to make tests pass (green)
3. Refactor without breaking tests
4. Run `/verify` to confirm all tests pass

**Hard gate:** No implementation code before failing tests exist.

---

### `/worktree` — Git Worktree Isolation
**Replaces:** `superpowers:using-git-worktrees`

Creates an isolated git worktree for the current feature:
1. Verify current repo state is clean (or stash)
2. Select a target directory for the worktree (sibling to current repo)
3. Create worktree on a new branch
4. Confirm isolation is working
5. Provide cleanup instructions for when work is merged

**Safety:** Never creates worktrees on `main`/`master`. Warns if uncommitted changes exist.

---

### `/verify` — Verification Before Completion
**Replaces:** `superpowers:verification-before-completion`

Evidence-based verification — no success claims without proof:
1. Run the relevant test suite and capture output
2. Run linters/type checkers if applicable
3. Manually exercise the feature/fix
4. Confirm all acceptance criteria from the spec/plan are met
5. Only after all checks pass: state that the work is done, with evidence

**Hard gate:** Cannot claim work is complete without showing passing output.

---

### `/parallel` — Dispatch Parallel Agents
**Replaces:** `superpowers:dispatching-parallel-agents`

Decomposes independent tasks into parallel subagents:
1. Identify tasks with no shared state or sequential dependencies
2. Craft precise, self-contained prompts for each subagent
3. Dispatch all independent agents in a single message
4. Collect and integrate results
5. Surface conflicts or merge issues to user

**Constraint:** Only parallelize truly independent tasks. Sequential dependencies must stay sequential.

---

### `/implement` — Subagent-Driven Implementation
**Replaces:** `superpowers:subagent-driven-development`

Implements a plan by dispatching subagents per task:
1. Read the implementation plan
2. Dispatch a spec-reviewer subagent to validate the plan is implementable
3. For each plan step (or group of independent steps): dispatch implementer subagent
4. After each step: dispatch code-quality-reviewer subagent
5. Surface issues; fix and re-dispatch if needed
6. On completion: dispatch `code-reviewer` agent for full review

---

### `/review` — Request Code Review
**Replaces:** `superpowers:requesting-code-review`

Manually triggers the `code-reviewer` agent:
1. Identify the scope of review (files changed, PR diff, or specific area)
2. Provide context: what was built, which plan/spec it implements
3. Dispatch `code-reviewer` agent with full context
4. Present findings to user
5. If issues found: fix and re-dispatch (max 3 iterations)

---

### `/receive-review` — Handle Incoming Review Feedback
**Replaces:** `superpowers:receiving-code-review`

Technical rigor when receiving review feedback:
1. Read all feedback before responding to any of it
2. For each piece of feedback: evaluate technically (is it correct? does it apply here?)
3. Flag feedback that seems incorrect or inapplicable — ask reviewer to clarify
4. For valid feedback: implement changes, then verify they don't break anything
5. Never blindly implement suggestions without technical evaluation

**Hard gate:** No performative agreement. Every suggestion gets technical evaluation first.

---

### `/finish` — Finish a Development Branch
**Replaces:** `superpowers:finishing-a-development-branch`

Structured options for completing work:
1. Run `/verify` to confirm everything passes
2. Present options with trade-offs:
   - **Merge directly** (fast, low ceremony — for solo or trusted branches)
   - **Open a PR** (review gate, audit trail — for team environments)
   - **Cleanup and abandon** (if work is no longer needed)
3. Execute chosen option
4. Clean up worktree if one was used

---

### `/new-skill` — Create a New Custom Command
**Replaces:** `superpowers:writing-skills`

Creates a new command file following this system's conventions:
1. Ask: what should the command do, when is it invoked, what's its output?
2. Draft the command file with correct structure (role, process, references inlined)
3. Test the command in a subagent with a synthetic scenario
4. Write the file to `~/.claude/commands/<name>.md`
5. Add an entry to `~/.claude/commands/README.md` (the index)

---

## Agent Specification

### `code-reviewer` — Code & Spec Reviewer
**Replaces:** `superpowers:code-reviewer` agent

A general-purpose review agent dispatched by `/review`, `/design`, `/plan`, and `/implement`. Context passed at dispatch time determines what it reviews.

**Review modes (determined by caller's context):**
- **Spec review:** Does the spec clearly describe what to build? Are requirements complete, unambiguous, and testable?
- **Plan review:** Is the plan implementable? Are steps atomic? Are dependencies correct? Are risks addressed?
- **Code review:** Does the implementation match the plan? Does it follow project conventions? Are there bugs, security issues, or performance problems?

**Output format:**
- `APPROVED` — no issues, work can proceed
- `ISSUES FOUND` — bulleted list of specific, actionable issues with file/line references where applicable

**Behavior:** Never approve with unresolved blocking issues. Never block on style preferences without a clear project standard to cite.

---

## Command Chaining

```
/design  →  /plan  →  /execute  or  /implement
/debug   →  fix    →  /verify   →  /review
/test    →  /verify →  /review  →  /finish
/worktree → [feature work] → /finish
```

---

## Deployment

### To Your Company Machine

1. Copy `~/.claude/commands/` directory
2. Copy `~/.claude/agents/` directory
3. No other configuration needed — Claude Code loads these automatically

### Versioning

Each file has a version comment at the top (`<!-- v1.0 -->`). Bump when you update a skill so you can track what's deployed where.

### Updating

Edit the relevant `.md` file. Changes are live on next Claude Code session. No restart, no plugin reload.

---

## Implementation Order

Build and validate in this order (each depends on the previous being stable):

1. `code-reviewer` agent — needed by most commands
2. `/verify` — needed by most commands
3. `/design` — core workflow entry point
4. `/plan` — feeds from `/design`
5. `/debug` — standalone, high daily value
6. `/test` — standalone, high daily value
7. `/execute` — feeds from `/plan`
8. `/implement` — feeds from `/plan`
9. `/review` — wraps `code-reviewer` agent
10. `/receive-review` — standalone
11. `/worktree` — standalone
12. `/parallel` — standalone
13. `/finish` — end of workflow
14. `/new-skill` — meta, last

---

## Success Criteria

- All 13 commands and 1 agent file created and self-contained
- Each command can be invoked standalone with no external dependencies
- `code-reviewer` agent can be dispatched by other commands with context
- Files can be copied to a fresh Claude Code installation and work immediately
- Full feature parity with superpowers v5.0.5 core workflows
