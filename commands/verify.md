---
description: Evidence-based verification — no completion claims without proof
---
<!-- v1.0 -->
# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

Violating the letter of this rule is violating the spirit of this rule.

## Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: state actual status with evidence
   - If YES: state claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!")
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- ANY wording implying success without verification

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

### Tests

✅ Correct:
```
[Run test command]
[See: 34/34 pass]
"All tests pass"
```

❌ Incorrect:
```
"Should pass now"
```

### Regression Tests (TDD Red-Green)

✅ Correct:
```
Write test → Run (pass) → Revert fix → Run (MUST FAIL) → Restore fix → Run (pass)
```

❌ Incorrect:
```
"I've written a regression test"
```

### Build

✅ Correct:
```
[Run build command]
[See: exit 0]
"Build succeeds"
```

❌ Incorrect:
```
"Linter passed"
```

### Requirements

✅ Correct:
```
Re-read plan → Create checklist → Verify each item
```

❌ Incorrect:
```
"Tests pass, phase complete"
```

### Agent Delegation

✅ Correct:
```
Agent reports → Check VCS diff → Verify changes
```

❌ Incorrect:
```
Trust agent report
```

## When To Apply

ALWAYS before:

- Any success/completion claims
- Any satisfaction expressions
- Any positive statements about work state
- Committing/PR/task completion
- Moving to next task
- Delegating to agents

This rule applies to exact phrases, paraphrases, and implications of success.

## The Bottom Line

Run the command. Read the output. THEN claim the result. This is non-negotiable.
