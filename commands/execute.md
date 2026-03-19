<!-- v1.0 -->
# Executing Plans

> I'm using /execute to implement this plan.

**Note:** If subagent support is available, prefer `/implement` for higher quality output — it dispatches fresh subagents per task with review gates between them.

**Overview:** Load the plan, review it critically, execute all tasks in sequence, and report when complete.

---

## Step 1: Load and Review Plan

1. Read the plan file in full.
2. Review it critically — identify any questions, concerns, or gaps.
3. **If concerns exist:** Raise them with the user before starting any work. Do not proceed until resolved.
4. **If no concerns:** Create task tracking (note which tasks exist and their status) and proceed to Step 2.

---

## Step 2: Execute Tasks

For each task in the plan, in order:

1. **Mark as in_progress** — note that you are starting this task.
2. **Follow each step exactly** — the plan contains bite-sized steps; execute them one at a time as written. Do not skip steps, reorder them, or combine them.
3. **Run verifications as specified** — every verification command in the plan must be run. Check that actual output matches expected output.
4. **Mark as completed** — only after all steps and verifications pass.

Then move to the next task. Repeat until all tasks are done.

---

## Step 3: Complete Development

After all tasks are verified complete:

- Use `/finish` to complete the branch.
- Follow that command's process: verify tests, present options, execute the user's choice.

---

## When to Stop and Ask

Stop execution and ask the user for clarification when:

- **Blocker encountered** — missing dependency, environment issue, or prerequisite not met.
- **Test fails unexpectedly** — a verification step fails and the cause is not obvious.
- **Unclear instruction** — a plan step is ambiguous or could be interpreted multiple ways.
- **Verification fails repeatedly** — you have attempted a fix and the verification still does not pass.
- **Critical gap in the plan** — a step references something that does not exist or was never defined.

Ask for clarification rather than guessing. Guessing compounds errors across subsequent tasks.

---

## When to Revisit the Plan

- **User updates the plan** — re-read the plan and adjust remaining work accordingly.
- **Fundamental approach needs rethinking** — if early tasks reveal that the plan's architecture will not work, stop and discuss with the user before continuing.

Do not force through blockers. If the plan is wrong, fix the plan first.

---

## Remember

- **Review the plan critically first.** Do not blindly execute a flawed plan.
- **Follow plan steps exactly.** The plan was written with specific ordering and granularity for a reason.
- **Do not skip verifications.** Every test run and expected output check exists to catch problems early.
- **Stop when blocked — do not guess.** A wrong guess in task 3 can invalidate tasks 4 through 10.
- **Never start work on main/master without explicit user consent.** Use `/worktree` to create an isolated branch first.

---

## Integration

- **Requires `/worktree`** — create an isolated workspace before starting execution.
- **Requires `/plan`** — this command executes plans created by `/plan`.
- **Calls `/finish`** — after all tasks are complete, hand off to `/finish` for branch completion.
