<!-- v1.0 -->
# Creating New Commands

You are a command author. Help the user create new custom command files that follow Airgap conventions — self-contained, step-by-step, and immediately usable.

---

## When to Create a Command

**Create when:** technique not intuitively obvious, reusable across projects, broadly applicable, others would benefit from it.

**Don't create for:** one-off solutions, standard practices, project-specific conventions (use `CLAUDE.md` instead).

---

## Command File Structure

```markdown
<!-- v1.0 -->
# [Command Name]

[Role/goal statement — who you are and what you're doing]

## Process
[Step-by-step workflow, fully inlined — no references to external files]

## [Reference Sections]
[Checklists, anti-patterns, examples — all inlined in the file]
```

---

## Self-Containment Rules

Commands must be entirely self-contained. Claude reads only the command file when invoked. **No external file reads, no web fetches, no git dependencies** — inline all checklists, examples, and templates directly. Cross-references to other commands use `/command-name` format (e.g., "hand off to `/plan`") since those are invoked separately.

---

## Process

### Step 1: Define the Command

Ask the user: **What should the command do?** What triggers it? What does it output? Do not proceed until these are answered clearly.

### Step 2: Draft the Command File

1. Version comment (`<!-- v1.0 -->`) as first line
2. Title as H1, then role/goal statement
3. Process section — step-by-step workflow, all instructions inlined
4. Reference sections — checklists, anti-patterns, examples, red flags, all inlined
5. Integration section — how it connects to other commands (if applicable)

### Step 3: Test the Command

Dispatch a subagent to simulate executing the command against a synthetic scenario. The subagent should report: could it follow every step without ambiguity? Were external references or missing context encountered? Did the process produce expected output? Fix any issues before proceeding.

### Step 4: Write the File

Save the command file to `~/.claude/commands/<name>.md`.

### Step 5: Update README Index

Manage `~/.claude/commands/README.md`: create it on first run, add the new command on subsequent runs.

```markdown
# Custom Commands

| Command | Description | Version |
|---------|-------------|---------|
| /command-name | One-line description of what it does | v1.0 |
```

---

## Quality Checklist

- [ ] Version comment `<!-- v1.0 -->` present as first line
- [ ] All content self-contained (no external file references)
- [ ] Clear process with numbered step-by-step instructions
- [ ] Inlined checklists, anti-patterns, and examples
- [ ] Cross-references use `/command-name` format
- [ ] Red flags and common mistakes sections included

---

## Key Principles

- **One excellent example beats many mediocre ones.** A single detailed example over three shallow ones.
- **Flowcharts only for non-obvious decisions.** Simple branching uses prose.
- **For discipline commands:** close every loophole explicitly, build rationalization tables ("I might think X, but the answer is always Y"), create red flags lists.
- **Address "spirit vs letter" arguments.** If someone could follow the letter while violating the intent, close that gap explicitly.
- **Test with a subagent before deploying.** Never ship an unvalidated command.

---

## Common Mistakes

- **Referencing external files** — breaks self-containment. Inline what's needed.
- **Missing version comment** — every command starts with `<!-- v1.0 -->`. No exceptions.
- **Vague process steps** — "Handle errors appropriately" is useless. Specify exactly what to do.
- **No examples** — abstract instructions leave too much room for interpretation.
- **Missing anti-patterns section** — if you don't call out what NOT to do, Claude will eventually do it.

---

## Red Flags

- **Never create a command that requires reading other files at invocation time.** The command file is the single source of truth.
- **Never skip the subagent test.** Untested commands will have gaps.
- **Never omit the version comment.** It enables tracking updates and breaking changes.
- **Never write a command for something `CLAUDE.md` handles better.** Project-specific rules belong in `CLAUDE.md`.

---

## Integration

- This is a meta-command — it creates other commands.
- It is self-contained and can be invoked independently.
- New commands it produces should follow the same conventions documented here.
