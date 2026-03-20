---
description: Spec to implementation plan with atomic tasks, file mappings, and dependency ordering
---
<!-- v1.0 -->
# Writing Implementation Plans

> **Announcement:** I'm using /ag-plan to create the implementation plan.

## Overview

Write comprehensive implementation plans assuming the engineer has zero context. Document everything: which files, code, testing, how to test. Bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

---

## Scope Check

Before writing a plan, assess the spec's scope. If the spec covers multiple independent subsystems, suggest breaking into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

Ask yourself:
- Can subsystem A be built and tested without subsystem B?
- Do the subsystems share interfaces, or are they truly independent?
- Would a single plan exceed ~20 tasks?

If the answer points toward multiple independent units, propose a split:

```
This spec covers N independent subsystems:
1. [Subsystem A] — [one-line description]
2. [Subsystem B] — [one-line description]

I recommend separate plans so each produces working, testable software independently.
Shall I proceed with separate plans, or keep everything in one?
```

---

## File Structure

Before defining tasks, map which files will be created or modified. This serves as the blueprint for the entire plan.

**Principles:**
- Design units with clear boundaries and well-defined interfaces.
- Prefer smaller, focused files over large monoliths.
- Files that change together should live together (colocation).
- In existing codebases, follow the patterns already established — match naming conventions, directory structure, and module organization.

**Produce a file map like this before writing tasks:**

```
Files to create:
  src/auth/token.py          — token generation and validation
  src/auth/middleware.py      — request authentication middleware
  tests/auth/test_token.py   — token unit tests
  tests/auth/test_middleware.py — middleware unit tests

Files to modify:
  src/app.py:45-52           — register auth middleware
  src/config.py:12-18        — add auth configuration keys
```

This file map becomes the source of truth for every task's **Files** section.

---

## Bite-Sized Task Granularity

Each step in a task equals one action. An engineer should complete each step in 2-5 minutes. Never combine multiple actions into a single step.

**Each of these is its own step:**
- "Write the failing test" = step
- "Run it to make sure it fails" = step
- "Implement the minimal code" = step
- "Run the tests" = step
- "Commit" = step

**Why this matters:** Small steps keep momentum, reduce debugging surface area, and make it trivial to identify where things went wrong. If a step takes longer than 5 minutes, it should be split further.

---

## Plan Document Header

Every plan document starts with this header template:

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** Use /ag-implement (recommended) or /ag-execute to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** [One sentence describing what this plan delivers]
**Architecture:** [2-3 sentences describing the high-level approach, key design decisions, and how components interact]
**Tech Stack:** [Key technologies, frameworks, and tools involved]
```

---

## Task Structure

Each task follows this template with checkbox syntax for progress tracking:

```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**
[code block with actual test]

- [ ] **Step 2: Run test to verify it fails**
Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**
[code block with actual impl]

- [ ] **Step 4: Run test to verify it passes**
Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**
```

---

## Remember

These rules apply to every task and every step in the plan:

- **Exact file paths always.** Never say "in the auth module" — say `src/auth/token.py`.
- **Complete code in plan.** Never write "add validation" — write the actual validation code.
- **Exact commands with expected output.** Never write "run the tests" — write `pytest tests/auth/test_token.py::test_expired_token -v` with `Expected: FAIL with "TokenExpiredError"`.
- **DRY.** Do not repeat yourself across tasks. If two tasks share a helper, define it once and reference it.
- **YAGNI.** Do not plan features not in the spec. No "future-proofing" abstractions.
- **TDD.** Every implementation step is preceded by a failing test step.
- **Frequent commits.** Every task ends with a commit step. Larger tasks may have intermediate commits.

---

## Plan Document Reviewer

After writing the plan, dispatch a reviewer subagent to verify completeness and quality before presenting it to the user.

```
Dispatch a general-purpose subagent:

You are a plan document reviewer. Verify this plan is complete and ready for implementation.

**Plan to review:** [PLAN_FILE_PATH]
**Spec for reference:** [SPEC_FILE_PATH]

## What to Check
| Category | What to Look For |
|----------|------------------|
| Completeness | TODOs, placeholders, incomplete tasks, missing steps |
| Spec Alignment | Plan covers spec requirements, no major scope creep |
| Task Decomposition | Tasks have clear boundaries, steps are actionable |
| Buildability | Could an engineer follow this plan without getting stuck? |

## Calibration
Only flag issues causing real implementation problems. Approve unless serious gaps.

## Output Format
**Status:** Approved | Issues Found
**Issues (if any):** - [Task X, Step Y]: [issue] - [why it matters]
**Recommendations (advisory):** - [suggestions]
```

---

## Plan Review Loop

The review process follows a fix-and-verify loop:

1. Dispatch the reviewer subagent (using the prompt above).
2. If the reviewer returns **Approved**, proceed to execution handoff.
3. If the reviewer returns **Issues Found**, fix every listed issue in the plan document.
4. Re-dispatch the reviewer to verify fixes.
5. Repeat until approved, up to a maximum of **3 iterations**.
6. If not approved after 3 iterations, surface the remaining issues to the user and ask for guidance.

---

## Execution Handoff

After saving the plan and receiving reviewer approval, present the user with a choice:

```
Plan complete and saved to `docs/airgap/plans/<filename>.md`. Two execution options:

1. **Subagent-Driven (/ag-implement)** — fresh subagent per task, review between tasks, fast iteration (recommended)
2. **Inline Execution (/ag-execute)** — execute tasks in this session with checkpoints

Which approach?
```
