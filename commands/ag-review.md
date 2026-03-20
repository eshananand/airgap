---
description: Trigger code-reviewer agent for quality review with iterative feedback
---
<!-- v1.0 -->
# Requesting Code Review

Core principle: **Review early, review often.**

Code review is not a gate at the end — it is a continuous practice that catches issues when they are cheap to fix. Every task, every feature, every merge deserves a review.

---

## When to Request Review

### Mandatory

- **After each task in /implement** — review before moving to the next task
- **After completing a major feature** — review the full feature before declaring it done
- **Before merge to main** — no code reaches main without review

### Optional (But Strongly Encouraged)

- **When stuck** — a reviewer can spot what you are missing
- **Before refactoring** — confirm the current state before changing it
- **After a complex bug fix** — verify the fix does not introduce new problems

---

## How to Request

### Step 1: Get Git SHAs

Identify the range of commits to review:

```bash
BASE_SHA=$(git rev-parse HEAD~1)
HEAD_SHA=$(git rev-parse HEAD)
```

For multi-commit reviews, set `BASE_SHA` to the commit before your first change:

```bash
BASE_SHA=$(git merge-base main HEAD)
HEAD_SHA=$(git rev-parse HEAD)
```

### Step 2: Dispatch the Code-Reviewer Agent

Fill in the template below and dispatch the code-reviewer agent with the completed context.

```
Dispatch the code-reviewer agent with this context:

## What Was Implemented
{DESCRIPTION}

## Requirements/Plan
{PLAN_OR_REQUIREMENTS}

## Git Range to Review
Base: {BASE_SHA}
Head: {HEAD_SHA}

git diff --stat {BASE_SHA}..{HEAD_SHA}
git diff {BASE_SHA}..{HEAD_SHA}

## Review Checklist

Code Quality:
- Clean separation of concerns?
- Proper error handling?
- Type safety?
- DRY followed?
- Edge cases?

Architecture:
- Sound design?
- Scalability?
- Performance?
- Security?

Testing:
- Tests test logic (not mocks)?
- Edge cases?
- Integration tests?
- All passing?

Requirements:
- Plan requirements met?
- Spec match?
- No scope creep?
- Breaking changes documented?

Production Readiness:
- Migration strategy?
- Backward compatibility?
- Documentation?
- No obvious bugs?

## Output Format

### Strengths
[Specific, with file:line]

### Issues
#### Critical (Must Fix)
[Bugs, security, data loss, broken functionality]
#### Important (Should Fix)
[Architecture, missing features, error handling, test gaps]
#### Minor (Nice to Have)
[Style, optimization, docs]

For each: file:line, what's wrong, why it matters, how to fix

### Recommendations
### Assessment
**Ready to merge?** [Yes/No/With fixes]
**Reasoning:** [1-2 sentences]
```

### Step 3: Act on Feedback

When the reviewer returns findings, respond appropriately:

| Severity     | Action                                      |
|-------------|---------------------------------------------|
| **Critical** | Fix immediately. Do not proceed until resolved. |
| **Important** | Fix before proceeding to the next task.      |
| **Minor**    | Note it. Fix if time permits, or add to backlog. |
| **Push Back** | If the reviewer is wrong, push back with reasoning, show tests, and request clarification. |

---

## Example Workflow

Here is a typical review cycle after completing a task:

```
1. You just completed Task 3: "Add authentication middleware"

2. Get SHAs:
   BASE_SHA=$(git rev-parse HEAD~3)   # 3 commits in this task
   HEAD_SHA=$(git rev-parse HEAD)

3. Dispatch reviewer:
   "Dispatch the code-reviewer agent with this context:

   ## What Was Implemented
   Authentication middleware using JWT tokens. Added token validation,
   role-based access control, and request context enrichment.

   ## Requirements/Plan
   - Validate JWT on all /api routes
   - Extract user role and attach to request context
   - Return 401 for invalid tokens, 403 for insufficient permissions
   - Skip auth for /api/health and /api/public/*

   ## Git Range to Review
   Base: abc1234
   Head: def5678

   git diff --stat abc1234..def5678
   git diff abc1234..def5678

   [... full checklist as above ...]"

4. Reviewer returns:
   ### Strengths
   - Clean middleware pattern at src/middleware/auth.ts:15
   - Good separation of token validation and role checking

   ### Issues
   #### Critical (Must Fix)
   - src/middleware/auth.ts:42 — token expiry not checked. Expired
     tokens are accepted. Check `exp` claim before proceeding.

   #### Important (Should Fix)
   - src/middleware/auth.ts:67 — missing rate limiting on auth
     failures. Add brute-force protection.

   #### Minor (Nice to Have)
   - src/middleware/auth.ts:12 — consider extracting magic strings
     to constants.

   ### Assessment
   **Ready to merge?** With fixes
   **Reasoning:** Critical token expiry bug must be fixed. Otherwise
   solid implementation.

5. You fix the Critical issue, address the Important issue, note the
   Minor for later, and re-request review on the fixes.
```

---

## Integration with Other Commands

### /implement
Review is built into the /implement loop. After completing each task, request a review before moving to the next task. This catches issues early when context is fresh.

### /execute
When running parallel tasks via /execute, request review after each batch completes. Review the combined output of the batch before starting the next one.

### Ad-hoc
Use /ag-review any time outside of structured workflows:
- **Before merge to main** — final review of the full branch
- **When stuck** — get a second opinion on your approach
- **After complex debugging** — verify the fix is sound

---

## Red Flags — Do Not Do These

- **Never skip review "because it's simple"** — simple changes break production too
- **Never ignore Critical issues** — they are critical for a reason
- **Never proceed with unfixed Important issues** — they compound into bigger problems
- **Never argue with valid feedback** — if the reviewer is right, fix it

### When the Reviewer Is Wrong

It happens. When you believe the reviewer is incorrect:

1. **Push back with reasoning** — explain why you disagree, with specifics
2. **Show tests** — demonstrate that your approach works and handles the concern
3. **Request clarification** — ask the reviewer to elaborate on why they flagged it

Do not silently ignore feedback. Either fix it or have the conversation.
