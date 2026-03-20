---
description: Subagent-driven plan execution with two-stage review per task
---
<!-- v1.0 -->
# Subagent-Driven Development

> **Announcement:** I'm using /implement to execute this plan with subagent-driven development.

**Overview:** Execute an implementation plan by dispatching a fresh subagent for each task. Every task goes through a two-stage review gate — spec compliance first, then code quality — before moving on. This produces high-quality, well-tested code with natural checkpoints.

**Core principle:** Fresh subagent per task + two-stage review = high quality, fast iteration.

---

## When to Use

Follow this decision logic:

1. **Do you have an implementation plan?** → If no, use `/ag-plan` first.
2. **Are tasks mostly independent?** → If tightly coupled (each task deeply depends on the previous task's internal decisions), consider manual implementation instead.
3. **Staying in this session?** → Use `/implement`. If you want parallel sessions across worktrees, use `/execute` in each.

```
Have plan? ──no──→ /ag-plan first
  │yes
  ▼
Tasks mostly independent? ──no──→ Manual implementation
  │yes
  ▼
Stay in this session? ──no──→ /execute (in parallel worktrees)
  │yes
  ▼
/implement
```

---

## The Process

### Stage 1: Load and Prepare

1. Read the plan file in full.
2. Extract every task with its complete text — task number, name, description, steps, verification criteria.
3. Create task tracking: list all tasks with status (pending, in_progress, done, blocked).
4. Review the plan critically. If you have concerns or questions, raise them before dispatching any subagent.

### Stage 2: Per-Task Cycle

For each task, in order:

1. **Dispatch implementer subagent** — use the Implementer Prompt Template below. Paste the full task text into the prompt. Do not make the subagent read the plan file.
2. **Handle questions** — if the implementer asks questions before starting, answer them. Provide additional context if needed.
3. **Implementer works** — implements, tests, commits, self-reviews.
4. **Handle implementer status** — see Status Handling below.
5. **Spec compliance review** — dispatch spec reviewer subagent. Must pass before proceeding.
6. **Code quality review** — dispatch quality reviewer subagent. Must pass before proceeding.
7. **Mark task complete** — update tracking, move to next task.

### Stage 3: Final Review

After all tasks are complete:

1. Dispatch a final code-reviewer for the entire implementation — all commits across all tasks.
2. Address any issues found.
3. Use `/finish` to complete the branch.

---

## Model Selection

Choose the model for each subagent dispatch based on task complexity:

| Task Type | Model | Examples |
|---|---|---|
| Mechanical (1-2 files, clear spec) | Cheapest available | Config files, simple utilities, boilerplate |
| Integration (multiple files, some judgment) | Standard | API endpoints, service wiring, test suites |
| Architecture / Review | Most capable | Design decisions, complex logic, all review passes |

When in doubt, use the more capable model. Bad output costs more than the model price difference.

---

## Handling Implementer Status

### DONE
Proceed directly to spec compliance review.

### DONE_WITH_CONCERNS
1. Read the concerns carefully.
2. **Correctness or scope concerns** — address them before proceeding. Re-dispatch if needed.
3. **Observations or style notes** — note them, proceed to spec review.
4. The distinction matters: correctness issues must be fixed, observations can be deferred.

### NEEDS_CONTEXT
1. Read what context is missing.
2. Provide the context — code snippets, architectural decisions, dependency information.
3. Re-dispatch the implementer with the additional context included in the prompt.

### BLOCKED
Assess the root cause:

| Root Cause | Action |
|---|---|
| Missing context | Re-dispatch with the needed context added to the prompt |
| Needs more reasoning power | Re-dispatch with a more capable model |
| Task too large | Break the task into subtasks, dispatch each separately |
| Plan is wrong | **STOP.** Escalate to the user. Do not guess or improvise around a broken plan. |

---

## Implementer Subagent Prompt Template

Dispatch each implementer with this prompt, filling in all bracketed sections:

```
You are implementing Task N: [task name]

## Task Description
[FULL TEXT of task from plan — paste here, don't make subagent read file]

## Context
[Scene-setting: where this fits in the overall system, what came before,
what depends on this, architectural patterns in use, relevant conventions]

## Before You Begin
If you have questions about requirements, approach, dependencies, anything
unclear — ask them now. Raise concerns before starting.

## Your Job
Once clear on requirements:
1. Implement exactly what the task specifies
2. Write tests (following TDD if task says to)
3. Verify implementation works
4. Commit your work
5. Self-review (see below)
6. Report back

Work from: [directory]

While you work: if something unexpected or unclear, ask questions. Don't guess.

## Code Organization
- Follow file structure from plan
- Each file: one clear responsibility, well-defined interface
- If file growing beyond plan intent: STOP, report DONE_WITH_CONCERNS
- In existing codebases: follow patterns, improve code you touch, don't
  restructure outside task

## When You're in Over Your Head
It is always OK to stop and say "this is too hard for me." Bad work is
worse than no work.

STOP and escalate when:
- Task requires architectural decisions with multiple valid approaches
- Need code beyond what was provided
- Uncertain about approach
- Task involves restructuring plan didn't anticipate
- Reading file after file without progress

Report with BLOCKED or NEEDS_CONTEXT. Describe what you're stuck on, what
you tried, what help you need.

## Self-Review Before Reporting
Completeness: fully implemented? missed requirements? edge cases?
Quality: best work? clear names? clean/maintainable?
Discipline: YAGNI? only what requested? followed patterns?
Testing: verify behavior not mocks? TDD if required? comprehensive?

Fix issues found during self-review before reporting.

## Report Format
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- What you implemented (or attempted if blocked)
- What you tested and results
- Files changed
- Self-review findings
- Any concerns
```

---

## Spec Compliance Reviewer Prompt Template

Dispatch after the implementer reports DONE or DONE_WITH_CONCERNS (with concerns addressed):

```
You are reviewing whether an implementation matches its specification.

## What Was Requested
[FULL TEXT of task requirements]

## What Implementer Claims They Built
[From implementer's report]

## CRITICAL: Do Not Trust the Report
Verify everything independently. Read actual code, compare to requirements
line by line.

DO NOT: take their word, trust completeness claims, accept their interpretation
DO: read actual code, compare to requirements, check for missing pieces,
look for extras

## Your Job
Check: Missing requirements? Extra/unneeded work? Misunderstandings?
Verify by reading code, not trusting report.

Report:
- ✅ Spec compliant
- ❌ Issues found: [what's missing or extra, with file:line]
```

If the spec reviewer reports issues:
1. Fix the issues (re-dispatch implementer or fix directly if trivial).
2. Re-run spec compliance review.
3. Repeat until spec review passes.

**Do not proceed to code quality review until spec compliance passes.**

---

## Code Quality Reviewer Prompt Template

Only dispatch after spec compliance passes.

```
Dispatch the code-reviewer agent with:
- WHAT_WAS_IMPLEMENTED: [from implementer report]
- PLAN_OR_REQUIREMENTS: Task N from [plan-file]
- BASE_SHA: [commit before this task started]
- HEAD_SHA: [current commit after task]
- DESCRIPTION: [summary of what was built and why]

Additional checks beyond standard review:
- Does each file have one clear responsibility?
- Are units independently testable?
- Following plan's file structure?
- Did implementation create large new files or significantly grow existing ones?
```

If the quality reviewer reports issues:
1. Fix the issues.
2. Re-run quality review.
3. Repeat until quality review passes.

---

## Example Workflow

Here is an abbreviated walkthrough showing the rhythm of `/implement`:

```
── Load plan (5 tasks) ──

Task 1: Create data model
  → Dispatch implementer (standard model)
  → Implementer asks: "Should the ID field be UUID or auto-increment?"
  → Answer: "UUID, see spec section 3.2"
  → Implementer: DONE
  → Spec review: ✅ Spec compliant
  → Quality review: ✅ Clean
  → Task 1 COMPLETE

Task 2: Build API endpoints
  → Dispatch implementer (standard model)
  → Implementer: DONE
  → Spec review: ❌ Missing pagination on list endpoint, added
    extra --verbose flag not in spec
  → Fix: re-dispatch implementer with specific instructions
  → Spec review: ✅ Spec compliant
  → Quality review: "Magic number 50 on line 42, extract to constant"
  → Fix directly (trivial)
  → Quality review: ✅ Clean
  → Task 2 COMPLETE

Task 3: Configuration loader
  → Dispatch implementer (cheap model — mechanical, single file)
  → Implementer: DONE
  → Spec review: ✅ Spec compliant
  → Quality review: ✅ Clean
  → Task 3 COMPLETE

Task 4: Integration wiring
  → Dispatch implementer (standard model)
  → Implementer: BLOCKED — "Service A and Service B have circular
    dependency, plan doesn't account for this"
  → Assess: plan issue → escalate to user
  → User decides on approach
  → Re-dispatch implementer with resolution
  → Implementer: DONE
  → Spec review: ✅ Spec compliant
  → Quality review: ✅ Clean
  → Task 4 COMPLETE

Task 5: CLI entry point
  → Dispatch implementer (cheap model)
  → Implementer: DONE_WITH_CONCERNS — "Help text could be more
    descriptive but meets spec"
  → Concern is observation, not correctness → proceed
  → Spec review: ✅ Spec compliant
  → Quality review: ✅ Clean
  → Task 5 COMPLETE

── Final review: dispatch code-reviewer across all 5 tasks ──
── /finish ──
```

---

## Advantages

### vs. Manual Implementation
- **TDD is natural** — subagents follow the process without fatigue.
- **Fresh context per task** — no accumulated confusion or shortcuts.
- **Parallel-safe** — each subagent works on a clean, scoped unit.
- **Questions are OK** — subagents ask instead of guessing, catching ambiguity early.
- **Two-stage review catches different bugs** — spec drift and code quality are separate concerns.

### vs. /execute
- **Same session** — you stay in control, no worktree setup needed.
- **Continuous oversight** — you see every status report and review result.
- **Automatic checkpoints** — every task has a commit and two review gates.
- **Model flexibility** — cheap models for easy tasks, capable models for hard ones.

---

## Red Flags

Never do any of the following:

1. **Start work on main/master without user consent** — always confirm branch strategy first.
2. **Skip spec compliance review** — every task gets reviewed, no exceptions.
3. **Skip code quality review** — every task gets reviewed, no exceptions.
4. **Proceed with unfixed spec issues** — spec must pass before quality review.
5. **Proceed with unfixed quality issues** — quality must pass before marking complete.
6. **Dispatch parallel implementers** — one task at a time, in order. Parallel execution is what `/execute` across worktrees is for.
7. **Make the subagent read the plan file** — paste the full task text into the prompt. The subagent should not need to find or interpret the plan.
8. **Skip scene-setting context** — the Context section of the implementer prompt is not optional. The subagent needs to understand where this task fits.
9. **Ignore implementer questions** — if they ask, answer. Do not tell them to figure it out.
10. **Accept "close enough" on spec compliance** — the spec says what it says. Missing requirements are missing.
11. **Let self-review replace actual review** — self-review is step 5 of the implementer's job. It does not replace the two-stage review gate.
12. **Start quality review before spec compliance passes** — always spec first, quality second.
13. **Move to the next task with open issues** — every issue must be resolved before proceeding.
14. **Guess when blocked** — if the plan is wrong or context is missing, stop and get the right answer.

---

## Integration with Other Commands

| Command | Relationship |
|---|---|
| `/worktree` | Create an isolated worktree before starting, so implementation happens on a clean branch. |
| `/ag-plan` | Creates the implementation plan that `/implement` executes. |
| `/ag-review` | Provides the code review template used by the quality reviewer subagent. |
| `/finish` | Called after all tasks pass review to complete the branch (tests, PR, cleanup). |
