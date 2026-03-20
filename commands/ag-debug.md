---
description: Systematic 4-phase debugging with root cause analysis before fixes
---
<!-- v1.0 -->
# Systematic Debugging

Random fixes waste time and create new bugs. The core principle of this workflow is simple: **ALWAYS find the root cause before attempting fixes.**

Violating the letter of this process is violating the spirit of debugging.

---

## Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes. No exceptions.

---

## When to Use

**Use for ANY technical issue:**
- Test failures
- Bugs and unexpected behavior
- Performance problems
- Build failures
- Integration issues

**ESPECIALLY use when:**
- You're under time pressure
- The "quick fix" seems obvious
- You've already tried multiple fixes that didn't work

**DON'T SKIP this process when:**
- The issue seems simple
- You're in a hurry
- A manager wants it fixed NOW

The simpler it seems, the more likely you'll waste time on the wrong fix without this process.

---

## The Four Phases

You MUST complete each phase before moving to the next.

---

### Phase 1: Root Cause Investigation

**Complete this BEFORE proposing any fix.**

#### 1. Read Error Messages Carefully

Don't skip them. Don't skim them.

- Read stack traces completely, top to bottom
- Note exact line numbers and file paths
- Read the actual message text — it usually tells you exactly what's wrong
- If there are multiple errors, start with the first one

#### 2. Reproduce Consistently

The issue must be triggered reliably before you can fix it.

- Document the exact steps to reproduce
- Can you trigger it every time?
- If it's intermittent, note what percentage of the time it occurs
- **If not reproducible**: gather more data. Add logging. Check different environments. Do NOT guess at causes for issues you cannot reproduce.

#### 3. Check Recent Changes

Most bugs are caused by recent changes.

- Run `git diff` against the last known working state
- Review recent commits in the affected area
- Check for new dependencies or version bumps
- Look for config changes
- Compare environmental differences (dev vs staging vs prod)

#### 4. Gather Evidence in Multi-Component Systems

WHEN the system has multiple components, you must add diagnostic instrumentation at each component boundary.

- Log entries and exits at every layer
- Verify environment variables and config propagation between components
- Check state at each layer before assuming where the problem is

**Example — 4-layer system (Workflow → Build script → Signing script → Actual signing):**

```bash
# Layer 1: Workflow
echo "=== WORKFLOW: Starting build process ==="
echo "=== WORKFLOW: SIGNING_ENABLED=$SIGNING_ENABLED ==="
echo "=== WORKFLOW: CERT_PATH=$CERT_PATH ==="

# Layer 2: Build script
echo "=== BUILD: Received SIGNING_ENABLED=$SIGNING_ENABLED ==="
echo "=== BUILD: Calling signing script ==="

# Layer 3: Signing script
echo "=== SIGNING: Entry point ==="
echo "=== SIGNING: SIGNING_ENABLED=$SIGNING_ENABLED ==="
echo "=== SIGNING: CERT_PATH=$CERT_PATH, exists=$(test -f "$CERT_PATH" && echo yes || echo no) ==="

# Layer 4: Actual signing
echo "=== SIGN_EXEC: Running codesign with identity=$IDENTITY ==="
echo "=== SIGN_EXEC: Exit code=$? ==="
```

This immediately reveals which layer drops the value, misconfigures the path, or silently fails.

#### 5. Trace Data Flow

Use **backward tracing**: start from the bad output and work backward.

- Where does the bad value originate?
- What function or component passed in the bad value?
- What called *that* with the bad value?
- Keep tracing upstream until you find the source

**Fix at the source, not the symptom.** If a function receives a bad argument, the bug is in the caller, not the function.

---

### Phase 2: Pattern Analysis

#### 1. Find Working Examples

Look for similar working code in the same codebase. If feature X works but feature Y doesn't, and they follow the same pattern, that comparison is gold.

#### 2. Compare Against References

When there's a reference implementation or documentation:

- Read it COMPLETELY — do not skim
- Follow the exact steps, not your interpretation of the steps
- Note every requirement, not just the ones you think matter

#### 3. Identify Differences

Between working and broken code:

- List every difference, no matter how small
- Don't assume any difference "can't matter"
- A one-character difference can cause a complete failure

#### 4. Understand Dependencies

Map out what the broken code depends on:

- What components are needed?
- What settings or config does it require?
- What assumptions does it make about its environment?
- Are all prerequisites actually met?

---

### Phase 3: Hypothesis and Testing

#### 1. Form a Single Hypothesis

- State it clearly: "I think X is happening because Y"
- Write it down — don't keep it vague in your head
- Be specific: "The signing fails because CERT_PATH is empty at layer 3" not "something is wrong with signing"

#### 2. Test Minimally

- Make the SMALLEST change that would confirm or refute your hypothesis
- Change ONE variable at a time
- If you change multiple things, you won't know which one mattered

#### 3. Verify

- Did the minimal test work? → Move to Phase 4
- Didn't work? → Formulate a NEW hypothesis. Do NOT pile on more fixes to the same attempt.

#### 4. When You Don't Know

- Say so. Don't pretend to understand something you don't.
- Ask for help. Describe what you've tried and what you've found.
- "I don't know yet" is always better than a guess dressed up as a diagnosis.

---

### Phase 4: Implementation

#### 1. Create a Failing Test Case

- Write the simplest reproduction of the bug
- Automate it if possible
- You MUST have a failing test before writing the fix — this proves the fix actually fixes the problem

#### 2. Implement a Single Fix

- Make ONE change that addresses the root cause
- No "while I'm here" side changes
- No bundled refactoring
- The diff should be reviewable and obvious

#### 3. Verify the Fix

- The failing test now passes
- No regressions in existing tests
- The original issue is resolved end-to-end

#### 4. If the Fix Doesn't Work

Count your fix attempts:

- **Fewer than 3 attempts**: Return to Phase 1. You missed something in the investigation. Gather more evidence.
- **3 or more attempts**: STOP. Move to step 5.

#### 5. If 3+ Fixes Have Failed: Question the Architecture

A pattern of failed fixes indicates an architectural problem. Recognize the signs:

- Each fix reveals new coupling or a new problem
- Fixes require massive refactoring to implement
- Each fix creates new symptoms elsewhere

When you see this pattern, **STOP trying to fix**. Step back and question the fundamentals:

- Is the overall approach sound?
- Is this component doing too much?
- Is there a simpler design that avoids the problem entirely?

**Discuss with the user before attempting more fixes.** Explain what you've tried, what pattern you're seeing, and why you think the architecture may need rethinking.

---

## Red Flags — STOP If You Catch Yourself Doing These

If any of these apply, you are off-process. Stop and return to Phase 1.

1. "Quick fix for now, we'll do it properly later"
2. "Just try changing X and see what happens"
3. "Let me add multiple changes and run the tests"
4. "Skip the test, just ship the fix"
5. "It's probably X" (without evidence)
6. "I don't fully understand the issue but this might work"
7. "The pattern says X but I'll adapt it my own way"
8. "Here are the main problems: [lists fixes without any investigation]"
9. Proposing solutions before tracing the data flow
10. "One more fix attempt should do it" (after 2+ failures)
11. Each fix attempt reveals a new, different problem
12. Changing code you don't fully understand
13. Treating symptoms instead of causes (e.g., adding a null check instead of figuring out why it's null)

---

## User Signals You're Doing It Wrong

When the user says any of these, it means you have left the process. STOP what you're doing and return to Phase 1 immediately.

| User Says | What It Means |
|---|---|
| "Is that not happening?" | You're not checking your assumptions |
| "Will it show us...?" | You're not gathering enough evidence |
| "Stop guessing" | You skipped Phase 1 |
| "Ultrathink this" | You're moving too fast without analysis |
| "We're stuck?" | You've been looping without progress |

ALL of these mean the same thing: **STOP. Return to Phase 1. Investigate before fixing.**

---

## Common Rationalizations

| Rationalization | Rebuttal |
|---|---|
| "This is a simple issue, I don't need the full process" | Simple issues have simple investigations. If it's truly simple, Phase 1 takes 30 seconds. Skip it and you risk spending 30 minutes on the wrong fix. |
| "This is an emergency, no time for process" | Emergencies are exactly when you can't afford to waste time on wrong fixes. The process is fastest path to resolution. |
| "Let me just try this one thing first" | That's how "one quick fix" becomes five wrong fixes. Investigate first, fix once. |
| "I'll write the test after the fix" | Without a failing test, you can't prove the fix works. You'll "verify" by eyeballing it and miss edge cases. |
| "I need to fix multiple things at once" | If you change multiple things, you won't know which one fixed it — or which one broke something else. One change at a time. |
| "The reference is too long to read completely" | Skimming the reference is how you miss the one critical requirement that's causing the failure. Read it all. |
| "I can see the problem, I don't need to trace it" | If you could see the problem, you'd have fixed it already. What you see is a symptom. Trace to the cause. |
| "One more attempt, I'm close" | You said that last time. After 2 failed fixes, more attempts without new investigation are just guessing. Return to Phase 1. |

---

## Quick Reference

| Phase | Key Activities | Success Criteria |
|---|---|---|
| **Phase 1: Root Cause Investigation** | Read errors, reproduce, check changes, instrument boundaries, trace data flow | You can explain WHY the bug happens, not just WHERE |
| **Phase 2: Pattern Analysis** | Find working examples, compare references, identify differences, map dependencies | You understand what correct behavior looks like and how it differs from current |
| **Phase 3: Hypothesis and Testing** | Form single hypothesis, test minimally, verify, ask for help if stuck | One specific, tested hypothesis confirmed by evidence |
| **Phase 4: Implementation** | Failing test, single fix, verify, escalate if 3+ failures | Test passes, no regressions, root cause eliminated |

---

## When the Process Reveals "No Root Cause"

Sometimes investigation points to factors outside the code: environmental issues, timing-dependent behavior, external service flakiness.

When this happens:

1. **Document** what you found and what you ruled out
2. **Implement handling** — make the code resilient to the external factor (retry logic, fallback behavior, input validation)
3. **Add monitoring** — ensure you'll have data next time it occurs

But be honest with yourself: **95% of "no root cause found" means the investigation was incomplete.** Before concluding the cause is external, make sure you've exhausted Phase 1 thoroughly.

---

## Supporting Techniques

### Root-Cause Tracing

Trace bugs backward through the call stack. Start from the error, identify the immediate cause, then ask "what caused that?" repeatedly until you reach the origin. The fix belongs at the origin, not at any intermediate symptom.

### Defense-in-Depth

Add validation at multiple layers. Don't rely on a single check. Validate inputs at the API boundary, validate state before critical operations, and validate outputs before returning. This catches bugs earlier and makes debugging faster when they occur.

### Condition-Based Waiting

Replace arbitrary timeouts (`sleep 5`) with condition polling. Instead of hoping 5 seconds is enough, check for the actual condition you're waiting for (file exists, service responds, port is open). This eliminates an entire class of intermittent failures.

---

## Related Commands

- `/test` — Use for creating the failing test case required in Phase 4
- `/verify` — Use for confirming the fix resolves the issue without regressions
