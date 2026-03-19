# Airgap Auto-Activation Design

**Date:** 2026-03-20
**Status:** Approved

---

## Problem

Airgap's 19 slash commands are only triggered when users explicitly type `/command-name`. After installation, there is no mechanism for airgap workflows to automatically apply to relevant tasks. A user who says "debug this bug" gets Claude's default unstructured approach instead of airgap's disciplined `/debug` workflow.

## Solution

Add `/activate` and `/deactivate` commands that enable per-project auto-routing. When a user runs `/activate` inside a Claude Code session, it creates a `.claude/CLAUDE.md` file in that project containing intent-routing rules. Claude reads this file at session start and automatically invokes the appropriate airgap command via the Skill tool when it detects matching user intent.

## User Flow

```
1. git clone <repo> && cd airgap
2. ./install.sh                    # copies commands + agents to ~/.claude/
3. cd /path/to/my-project && claude
4. /activate                       # creates .claude/CLAUDE.md with routing rules
5. "debug this bug"                # Claude auto-invokes /debug workflow
```

## Architecture

```
User says "debug this bug"
    |
    v
Claude loads project .claude/CLAUDE.md at session start
    |
    v
CLAUDE.md contains routing table: "debug" intent -> invoke /debug
    |
    v
Claude calls Skill tool with skill: "debug"
    |
    v
Full /debug workflow loads from ~/.claude/commands/debug.md
```

## Components

### 1. `/activate` command (`commands/activate.md`)

A new slash command that:

1. Checks if `.claude/CLAUDE.md` exists in the current project
2. If it does NOT exist: creates it with the airgap routing section
3. If it DOES exist: appends the airgap routing section between `<!-- AIRGAP:START -->` and `<!-- AIRGAP:END -->` markers, preserving existing content
4. Confirms activation to the user

### 2. `/deactivate` command (`commands/deactivate.md`)

A new slash command that:

1. Checks if `.claude/CLAUDE.md` exists in the current project
2. If the file contains the `<!-- AIRGAP:START -->` / `<!-- AIRGAP:END -->` markers: removes only that section
3. If the file is now empty: deletes it
4. If no markers found: informs user that airgap is not activated in this project
5. Confirms deactivation to the user

### 3. Routing content (embedded in `/activate`)

The routing section written into CLAUDE.md contains:

- A preamble explaining that airgap workflows are active
- A routing table mapping natural language intents to commands
- Priority rules (explicit `/command` invocation always wins)
- Instructions to invoke via the Skill tool

## Routing Table

| User Intent Patterns | Routes To | Description |
|---|---|---|
| debug, fix bug, investigate, root cause, why is this broken | `/debug` | Systematic 4-phase debugging |
| write tests, add tests, TDD, test this | `/test` | Red-green-refactor TDD |
| verify, check if it works, confirm it's working, does this work | `/verify` | Evidence-based verification |
| review code, code review, review this, check my code | `/review` | Code reviewer agent dispatch |
| scan for secrets, check credentials, leaked keys | `/scan-secrets` | Credential detection |
| security review, OWASP, vulnerabilities, security audit | `/security-review` | OWASP Top 10 audit |
| threat model, attack surface, security threats | `/threat-model` | STRIDE threat modeling |
| design, brainstorm, new feature idea, let's think through | `/design` | Idea to spec |
| plan, break down, implementation plan, how to build | `/plan` | Spec to implementation plan |
| implement, build it, execute the plan, start building | `/implement` | Subagent-driven execution |
| execute, run the plan, do it inline | `/execute` | Inline plan execution |
| finish, merge, PR, done with branch, wrap up | `/finish` | Branch completion |
| audit dependencies, check CVEs, dependency vulnerabilities | `/audit-deps` | Dependency audit |
| preflight, ready to deploy, pre-deploy check | `/preflight` | Pre-deploy gate |
| postmortem, incident review, what went wrong | `/postmortem` | Blameless incident analysis |
| parallel, run in parallel, split these up | `/parallel` | Parallel subagent dispatch |
| worktree, isolated branch, separate branch | `/worktree` | Git worktree creation |
| handle review feedback, address review comments | `/receive-review` | Review feedback handler |
| create new command, new skill, add a command | `/new-skill` | Command creation |

## Routing Rules

The CLAUDE.md will instruct Claude to follow these priority rules:

1. **Explicit invocation wins.** If the user types `/debug`, use that directly. Never double-invoke.
2. **Match intent, not keywords.** "Debug" in "debug logging" is not a debugging request. Use context.
3. **Ask when ambiguous.** If the intent could map to multiple commands, ask the user which workflow they want.
4. **Don't route trivial requests.** Quick questions like "what does this function do?" don't need a full workflow. Only route when the user is asking to *do* something that maps to an airgap workflow.

## Marker Format

```markdown
<!-- AIRGAP:START -->
[routing content here]
<!-- AIRGAP:END -->
```

This allows:
- Clean append to existing CLAUDE.md files
- Surgical removal via `/deactivate`
- Detection of whether airgap is already activated
- Future updates (remove old section, write new one)

## Error Handling

- `/activate` when already activated: informs user, offers to re-activate (replace with latest routing rules)
- `/deactivate` when not activated: informs user, no-op
- Missing `.claude/` directory: creates it
- CLAUDE.md with content but no markers: appends markers at the end, preserves existing content

## Files to Create

| File | Purpose |
|---|---|
| `commands/activate.md` | The /activate slash command |
| `commands/deactivate.md` | The /deactivate slash command |

## Files to Modify

| File | Change |
|---|---|
| `install.sh` | Add activate/deactivate to the list of installed commands (automatic — they're .md files in commands/) |
| `README.md` | Document the auto-activation feature and /activate command |

## What This Does NOT Change

- No changes to `settings.json`
- No changes to existing commands
- No new dependencies
- No hooks or background processes
- No network calls
