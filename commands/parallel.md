<!-- v1.0 -->
# Dispatching Parallel Agents

## Overview

Dispatch one agent per independent problem domain for concurrent work. When you face multiple unrelated failures or tasks, splitting them across parallel agents dramatically reduces wall-clock time. The key is precisely crafting instructions so each agent stays focused on its own domain and does not interfere with the others.

**Core principle**: Dispatch one agent per independent problem domain. Let them work concurrently. Each agent gets a narrow scope, clear goal, explicit constraints, and a defined output format.

---

## When to Use

Follow this decision logic:

1. **Multiple failures or tasks?** If only one, use a single agent.
2. **Are they independent?** If the failures are related or share a root cause, use a single agent to investigate holistically.
3. **Can they work in parallel?** If there is no shared state between the problem domains, dispatch in parallel. If there is shared state (same file, same module, same database), work sequentially.

**Use when:**
- 3+ test files failing with different errors from different causes
- Multiple subsystems broken independently (e.g., auth, rendering, and CLI parsing)
- Tasks that touch completely separate files and modules
- No shared mutable state between the problem domains

**Don't use when:**
- Failures are related or stem from a common root cause
- You need full system state or cross-module context to diagnose the issue
- You are doing exploratory debugging and don't yet understand the problem
- Agents would need to edit the same files or shared state

---

## The Pattern

### Step 1: Identify Independent Domains

Group failures by what is broken, not by where they appear. Look at error messages and stack traces to determine whether problems are truly independent.

Example grouping:
- **File A** (`agent-tool-approval.test.ts`): Tool approval flow times out waiting for user confirmation
- **File B** (`batch-completion.test.ts`): Batch completion callback fires with wrong structure
- **File C** (`agent-abort.test.ts`): Abort signal not propagated to child processes

These are three separate subsystems. No shared state. Perfect candidates for parallel dispatch.

### Step 2: Create Focused Agent Tasks

Each agent gets exactly four things:

1. **Specific scope** — which files and tests to look at
2. **Clear goal** — what "done" looks like
3. **Constraints** — what they must not touch
4. **Expected output** — what to report back

### Step 3: Dispatch in Parallel

Send all agent tasks in a single message using the Agent tool. Each agent call is independent and runs concurrently. Do not wait for one to finish before dispatching the next.

### Step 4: Review and Integrate

Once all agents return:
1. Read each agent's summary
2. Verify no conflicts (no overlapping file edits)
3. Run the full test suite to confirm everything passes together
4. Spot check the changes for quality

---

## Agent Prompt Structure

Each agent prompt should be focused, self-contained, and request specific output. Here is a full example:

```
Fix the 3 failing tests in `src/tests/agent-tool-abort.test.ts`.

The failing tests are:
- "should abort agent when user sends abort signal"
- "should clean up child processes on abort"
- "should return partial results after abort"

Expected behavior: When an abort signal is sent, the agent should stop
execution, terminate any child processes, and return whatever partial
results have been collected so far.

Current errors: All three tests time out after 10 seconds. The abort
signal appears to be sent but the agent continues running.

Instructions:
- Find the root cause of why the abort signal is not stopping execution.
  Do NOT just increase timeouts — that masks the real problem.
- Only modify files under `src/agent/abort/` and the test file itself.
- Do not change any production code outside the abort module.
- Run the 3 failing tests after your fix to confirm they pass.

Return a summary of:
1. The root cause you identified
2. What changes you made and why
3. Whether all 3 tests now pass
```

---

## Common Mistakes

| Mistake | Problem | Better Approach |
|---------|---------|-----------------|
| "Fix all tests" | Too broad; agent wanders across unrelated failures | "Fix the 3 failing tests in `agent-tool-abort.test.ts`" |
| No error context | Agent wastes time reproducing errors you already have | Paste the actual error messages and stack traces |
| No constraints | Agent refactors production code or edits shared files | "Don't change production code outside `src/abort/`" |
| Vague output request | You get a wall of text with no actionable summary | "Return summary of root cause and changes made" |

---

## When NOT to Use

Parallel dispatch is counterproductive in these situations:

- **Related failures**: If test A fails because of the same bug as test B, two agents will find the same root cause and may make conflicting fixes. Use one agent.
- **Need full context**: If understanding the problem requires reading across many modules and tracing data flow end-to-end, a single agent with full context will be more effective.
- **Exploratory debugging**: If you do not yet know what is wrong, start with a single agent to investigate. Parallelize only after you understand the problem domains.
- **Shared state**: If the failing tests touch the same files, same database tables, or same global configuration, parallel agents will create merge conflicts or race conditions in their fixes.

---

## Real Example

**Situation**: After refactoring the event system, 6 tests fail across 3 files.

**Analysis**: The failures group into three independent domains:
- `event-timing.test.ts` (2 failures) — tests rely on setTimeout-based waiting that is now flaky after the refactor
- `event-structure.test.ts` (2 failures) — tests expect the old event payload shape
- `async-cleanup.test.ts` (2 failures) — tests don't wait for async cleanup to finish

**Dispatch**: 3 agents sent in parallel, one per file.

**Results**:
- **Agent 1** (`event-timing.test.ts`): Replaced setTimeout-based waiting with event-based waiting using the new `waitForEvent` helper. Root cause was that the refactor made event delivery async, so fixed-delay waits were unreliable.
- **Agent 2** (`event-structure.test.ts`): Fixed the event structure assertions to match the new payload format. Root cause was that the refactor wrapped payloads in an envelope `{ type, data, timestamp }` but tests expected the raw data.
- **Agent 3** (`async-cleanup.test.ts`): Added `await` for the async cleanup step that the refactor introduced. Root cause was that cleanup became async but the test teardown did not await it.

**Outcome**: All three agents worked independently. No file conflicts. Full test suite green after integrating all changes.

---

## Verification

After all agents return, follow this checklist:

1. **Review each summary** — Read what each agent found and changed. Confirm the root causes make sense.
2. **Check for conflicts** — Verify no two agents edited the same file. If they did, manually review for compatibility.
3. **Run the full suite** — Execute the complete test suite, not just the previously failing tests. Parallel fixes can have unexpected interactions.
4. **Spot check** — Read through a sample of the actual code changes. Confirm agents followed constraints and did not introduce shortcuts like disabling tests or increasing timeouts.

---

## Key Benefits

- **Parallelization**: Multiple problems solved simultaneously, reducing total wall-clock time proportional to the number of agents.
- **Focus**: Each agent has a narrow scope and clear objective, leading to more precise fixes.
- **Independence**: Agents cannot interfere with each other when problem domains are truly separate.
- **Speed**: What would take one agent working serially N rounds takes N agents working in parallel roughly 1 round.
