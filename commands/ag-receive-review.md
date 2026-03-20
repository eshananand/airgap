---
description: Handle incoming review feedback with structured evaluation
---
<!-- v1.0 -->
# Code Review Reception

Core principle: **Verify before implementing. Ask before assuming. Technical correctness over social comfort.**

---

## The Response Pattern

Every piece of review feedback follows this sequence. No skipping steps.

### 1. READ
Read the complete feedback without reacting. Do not start implementing after the first comment. Read all items first.

### 2. UNDERSTAND
Restate the requirement in your own words. If you cannot restate it clearly, you do not understand it. Ask.

### 3. VERIFY
Check the feedback against codebase reality. Does the file exist? Is the function actually unused? Does the behavior match what the reviewer claims? Use `grep`, `read`, `test` — not memory.

### 4. EVALUATE
Is this technically sound for THIS codebase? Not in theory. Not in general. For this specific project, with its constraints, dependencies, and architecture.

### 5. RESPOND
Either a technical acknowledgment or reasoned pushback. Nothing performative. Nothing defensive.

### 6. IMPLEMENT
One item at a time. Test each change individually before moving to the next.

---

## Forbidden Responses

NEVER say:
- "You're absolutely right!"
- "Great point!"
- "Excellent feedback!"
- "Let me implement that now" (before verification)

INSTEAD:
- Restate the technical requirement
- Ask clarifying questions
- Push back if the feedback is wrong
- Just start working — actions speak louder than words

---

## Handling Unclear Feedback

IF any item in the review is unclear:

1. **STOP** — do not implement anything yet
2. **ASK** for clarification on the unclear items

WHY: Review items may be related to each other. Partial understanding leads to wrong implementation.

**Example:** You receive 6 review items. You understand items 1, 2, 3, and 6 clearly, but items 4 and 5 are ambiguous.

- WRONG: Implement 1, 2, 3, 6 now, ask about 4 and 5 later
- RIGHT: Ask about 4 and 5 before implementing any of them

Items may depend on each other. Item 4 might change how you implement item 1. Get full clarity first.

---

## Source-Specific Handling

### From User
- Trusted source — their codebase, their decisions
- Still ask if scope is unclear
- No performative agreement needed
- Skip to action: read, verify, implement

### From External Reviewers
Run a 5-point check before implementing anything:

1. **Technically correct for THIS codebase?** — Not in general. Here, specifically.
2. **Breaks existing functionality?** — Run tests, check callers, trace dependencies.
3. **Reason for current implementation?** — The code may look wrong but exist for a reason. Check git blame, comments, related tests.
4. **Works cross-platform?** — If the project targets multiple platforms, verify the suggestion works on all of them.
5. **Reviewer has full context?** — They may be reviewing one file without seeing the broader architecture.

**If the feedback is wrong:** Push back with technical reasoning.

**If you cannot verify:** Say so explicitly. Do not pretend to know.

**If it conflicts with the user's architectural decisions:** STOP. Do not implement. Discuss with the user first.

---

## YAGNI Check

IF a reviewer suggests "implementing properly" or "adding support for X":

```bash
# Check actual usage in the codebase
grep -r "functionName\|ClassName\|pattern" --include="*.ts" --include="*.js" src/
```

- **Unused** → "This isn't called anywhere in the codebase. Remove it (YAGNI)?"
- **Used** → Implement properly as the reviewer suggests

Do not build abstractions for code that has zero callers. Do not add flexibility that nothing exercises.

---

## Implementation Order

After all items are understood:

1. **Clarify unclear items FIRST** — before touching any code
2. **Blocking issues** — things that break builds, tests, or functionality
3. **Simple fixes** — typos, naming, formatting, small logic fixes
4. **Complex fixes** — refactors, architectural changes, new implementations

For each item:
- Implement the single change
- Test it in isolation
- Verify no regressions against existing tests
- Then move to the next item

---

## When To Push Back

Push back when:
- The suggestion **breaks existing functionality**
- The reviewer **lacks context** about a design decision
- The change violates **YAGNI** — building for hypothetical futures
- The feedback is **technically incorrect** for this codebase
- There are **legacy or compatibility constraints** the reviewer does not see
- The suggestion **conflicts with the user's architecture** decisions

How to push back:
- Use technical reasoning, not defensiveness
- Ask specific questions that expose the gap
- Reference tests, code, or behavior that supports the current approach
- State facts, not opinions

Example:
```
This function handles the legacy v1 API format which is still called by
the migration path in src/migrate.ts:47. Removing it would break migrations
for users upgrading from v1.x. Should we keep it until the v1 deprecation
date, or is there a different approach you had in mind?
```

---

## Acknowledging Correct Feedback

When the reviewer is right:

DO:
- "Fixed. [description of what changed]"
- "Good catch - [the issue]. Fixed in [location]."
- Just fix it in the code. The diff speaks for itself.

DO NOT:
- "You're absolutely right!"
- "Great point!"
- "Thanks for catching!"
- ANY gratitude or performative praise

Why: The fix is the acknowledgment. Actions over words. Just fix it.

---

## Gracefully Correcting Pushback

When you pushed back but the reviewer was actually right:

DO:
- "You were right - I checked [X]. Implementing now."
- State the correction factually and move on.

DO NOT:
- Write a long apology
- Defend why you pushed back
- Over-explain your reasoning

State the correction. Implement. Move on.

---

## Common Mistakes

| Mistake | Problem | Fix |
|---|---|---|
| Performative agreement | "Great point!" wastes tokens, adds no value | Restate the technical requirement or just fix it |
| Blind implementation | Implementing without verifying against the codebase | Always grep/read/test before changing code |
| Batch without testing | Implementing all items then testing once | Test each change individually |
| Assuming reviewer is right | Reviewer may lack context or be wrong | Run the 5-point check for external reviews |
| Avoiding pushback | Implementing wrong changes to avoid conflict | Technical correctness over social comfort |
| Partial implementation | Implementing understood items while unclear ones remain | Clarify ALL items before implementing ANY |
| Cannot verify, proceed anyway | Guessing instead of stating uncertainty | Say "I cannot verify this" explicitly |

---

## GitHub Thread Replies

When responding to review comments on pull requests, reply in the existing comment thread — not as a top-level comment.

```bash
# Reply to a specific review comment thread
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies \
  -f body="Fixed. Renamed the variable to match the convention in src/utils."
```

This keeps the discussion contextual and threaded. Top-level comments lose the connection to the specific code being discussed.
