<!-- v1.0 -->
# Finishing a Development Branch

> I'm using /finish to complete this work.

**Core principle:** Verify tests -> Present options -> Execute choice -> Clean up.

---

## Step 1: Verify Tests

Run the project test suite before anything else.

```bash
# Use the project's configured test command (e.g., npm test, pytest, cargo test, go test ./...)
<run-project-tests>
```

- **If tests fail:** Show the failures clearly. **STOP.** You cannot proceed with any finish option until tests pass. Tell the user what failed and that they must fix tests before finishing.
- **If tests pass:** Continue to Step 2.

---

## Step 2: Determine Base Branch

Identify the branch this feature was branched from:

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

If neither `main` nor `master` exists as a valid base, ask the user:

> What is the base branch for this work?

Store the result as `<base-branch>` for subsequent steps.

---

## Step 3: Present Options

Present exactly these 4 options. Do not add, remove, or rephrase them.

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

Wait for the user to choose. Do not assume a default.

---

## Step 4: Execute Choice

### Option 1: Merge back to base branch locally

```bash
# Save current branch name
FEATURE_BRANCH=$(git branch --show-current)

# Switch to base and pull latest
git checkout <base-branch>
git pull origin <base-branch>

# Merge the feature branch
git merge "$FEATURE_BRANCH"
```

After merging, run the test suite again on the merged result. If tests fail on the merged code, warn the user and do not delete the feature branch. If tests pass:

```bash
git branch -d "$FEATURE_BRANCH"
```

Report: "Merged `<feature-branch>` into `<base-branch>`. Feature branch deleted."

### Option 2: Push and create a Pull Request

```bash
FEATURE_BRANCH=$(git branch --show-current)

# Push the branch to remote
git push -u origin "$FEATURE_BRANCH"

# Create the PR with structured format
gh pr create --title "<concise title from branch work>" --body "$(cat <<'EOF'
## Summary
- <bullet points describing what was done>

## Test Plan
- [ ] <test verification steps>
EOF
)"
```

Report the PR URL to the user.

### Option 3: Keep the branch as-is

Do nothing. Do not checkout another branch. Do not clean up the worktree.

Report:

```
Keeping branch <branch-name>. Worktree preserved at <worktree-path>.
```

If not in a worktree, report:

```
Keeping branch <branch-name>. No further action taken.
```

### Option 4: Discard this work

**Confirmation is mandatory.** Before doing anything destructive, show the user exactly what will be lost:

```
You are about to discard:

  Branch: <branch-name>
  Commits:
    <short log of all commits on this branch vs base>
  Worktree: <path, if applicable>

Type "discard" to confirm.
```

Wait for the user to type exactly `discard`. Any other response cancels the operation.

If confirmed:

```bash
FEATURE_BRANCH=$(git branch --show-current)

git checkout <base-branch>
git branch -D "$FEATURE_BRANCH"
```

Report: "Branch `<feature-branch>` has been deleted."

If not confirmed, report: "Discard cancelled. Branch is unchanged."

---

## Step 5: Cleanup Worktree

After executing the chosen option, check if the work was done in a worktree:

```bash
git worktree list
```

- **Options 1, 2, 4:** If the feature branch was in a worktree, remove it:

  ```bash
  git worktree remove <worktree-path>
  ```

- **Option 3:** Do **not** remove the worktree. Leave it intact for the user.

---

## Quick Reference

| Option | Merges | Pushes | Keeps Worktree | Cleans Up Branch |
|--------|--------|--------|----------------|------------------|
| 1. Merge locally | Yes | No | No | Yes |
| 2. Push + PR | No | Yes | No | No |
| 3. Keep as-is | No | No | Yes | No |
| 4. Discard | No | No | No | Yes (force) |

---

## Common Mistakes

- **Skipping test verification.** Never skip Step 1. Finishing without passing tests leads to broken merges and bad PRs.
- **Asking open-ended questions.** Do not ask "What should I do?" or "How would you like to proceed?" Present the 4 structured options from Step 3 exactly as written.
- **Automatic worktree cleanup.** Option 3 explicitly preserves the worktree. Do not clean it up just because the command is "finishing."
- **No confirmation for discard.** Option 4 destroys work. Always show what will be lost and require the typed confirmation before deleting anything.

---

## Red Flags

- **Never proceed with failing tests.** If the test suite fails, stop. No merge, no PR, no discard until tests are addressed.
- **Never merge without testing the result.** Option 1 requires running tests again after the merge completes.
- **Never delete without confirmation.** Option 4 requires explicit typed confirmation. A simple "yes" is not sufficient.
- **Never force-push without an explicit user request.** Use normal `git push`, not `git push --force`.

---

## Integration

- Called by `/implement` and `/execute` after all tasks are complete.
- Pairs with `/worktree` for worktree lifecycle management.
- This command is self-contained and can be invoked independently.
