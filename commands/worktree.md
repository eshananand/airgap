<!-- v1.0 -->
# Git Worktree Isolation

> I'm using /worktree to set up an isolated workspace.

**Core principle:** Systematic directory selection + safety verification = reliable isolation.

---

## Directory Selection Process

Select the worktree directory using the following priority order. Stop at the first match.

### 1. Check Existing Directories

```bash
ls -d .worktrees 2>/dev/null
ls -d worktrees 2>/dev/null
```

- If **both** exist, `.worktrees` wins.
- If one exists, use it.

### 2. Check CLAUDE.md for Preference

```bash
grep -i "worktree.*director" CLAUDE.md 2>/dev/null
```

If a preference is found, use the specified directory.

### 3. Ask the User

If no existing directory or preference is found, offer two options:

| Option | Path | Description |
|--------|------|-------------|
| **Project-local (hidden)** | `.worktrees/` | Lives inside the project, hidden from directory listings |
| **Global** | `~/.config/airgap/worktrees/<project-name>/` | Shared location outside the project |

---

## Safety Verification

### Project-local directories

MUST verify the directory is gitignored:

```bash
git check-ignore -q .worktrees
```

If NOT ignored:
1. Add the directory to `.gitignore`.
2. Commit the change.
3. Proceed.

### Global directories

No verification needed. The directory lives outside the repository.

---

## Creation Steps

### Step 1: Detect Project Name

```bash
project=$(basename "$(git rev-parse --show-toplevel)")
```

### Step 2: Create the Worktree

**Project-local:**

```bash
git worktree add ".worktrees/$BRANCH_NAME" -b "$BRANCH_NAME"
```

**Global:**

```bash
git worktree add "$HOME/.config/airgap/worktrees/$project/$BRANCH_NAME" -b "$BRANCH_NAME"
```

### Step 3: Run Project Setup

Auto-detect the project type and run the appropriate setup command:

| Project Type | Detection | Setup Command |
|-------------|-----------|---------------|
| Node.js | `package.json` exists | `npm install` |
| Rust | `Cargo.toml` exists | `cargo build` |
| Python | `requirements.txt`, `pyproject.toml`, or `Pipfile` exists | `pip install -r requirements.txt` / `poetry install` |
| Go | `go.mod` exists | `go mod download` |

### Step 4: Verify Clean Baseline

Run the project's test suite.

- **Tests pass:** Report ready.
- **Tests fail:** Report the failure and ask the user whether to proceed.

### Step 5: Report

> Worktree ready at `<path>`. Tests passing (N tests, 0 failures). Ready to implement `<feature>`.

---

## Quick Reference

| Scenario | Action |
|----------|--------|
| `.worktrees` exists | Use `.worktrees` |
| `worktrees` exists | Use `worktrees` |
| Both exist | Use `.worktrees` |
| Neither exists | Check CLAUDE.md, then ask user |
| Directory not ignored | Add to `.gitignore`, commit, then proceed |
| Tests fail | Report failure, ask whether to proceed |
| No package manager detected | Skip setup step, proceed to test verification |

---

## Common Mistakes

- **Skip ignore verification.** Always verify project-local directories are gitignored before creating worktrees in them.
- **Assume directory location.** Follow the priority order: check existing, check CLAUDE.md, then ask.
- **Proceed with failing tests.** A failing baseline means you cannot distinguish pre-existing failures from new ones. Always ask first.
- **Hardcode setup commands.** Auto-detect the project type. Different projects use different tools.

---

## Red Flags

- **Never** create a worktree without verifying the directory is ignored (for project-local paths).
- **Never** skip baseline tests. They establish the starting state.
- **Never** proceed with failing tests without explicitly asking the user.
- **Never** assume the worktree location. Always follow the selection process.

---

## Safety

- **Never** create a worktree on `main` or `master`. The branch flag (`-b`) should always specify a feature branch.
- **Warn** if there are uncommitted changes in the current working tree before creating the worktree.

---

## Integration

- Called by `/implement` and `/execute` before starting feature work.
- Pairs with `/finish` for worktree cleanup after work is complete.
