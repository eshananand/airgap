<!-- v1.0 -->
# Brainstorming Ideas Into Designs

> Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

---

## Hard Gate

**Do NOT write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.**

### Anti-Pattern: "This Is Too Simple To Need A Design"

Every project goes through this process. A todo list, a single-function utility, a config change — all of them. The design can be short (a few sentences per section for trivial work) but you MUST present it and get explicit approval before moving forward. No exceptions.

---

## Checklist

Complete these in order. Do not skip steps.

1. **Explore project context** — check files, docs, recent commits
2. **Ask clarifying questions** — one at a time, prefer multiple choice, understand purpose/constraints/success criteria
3. **Propose 2–3 approaches** — with trade-offs and your recommendation
4. **Present design** — in sections scaled to complexity, get user approval after each section
5. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
6. **Spec review loop** — dispatch `code-reviewer` agent with spec-review context; fix issues and re-dispatch until approved (max 3 iterations, then surface to user)
7. **User reviews written spec** — ask user to review, then hand off to `/plan`

---

## The Process

### Understanding the Idea

Check project state first. Before asking the user anything, look at the codebase:

- Read existing files, docs, and configuration
- Check recent commits for context and momentum
- Look for existing patterns and conventions

Assess scope immediately. If the idea spans multiple independent subsystems, flag it right away:

> "This looks like it has a few independent pieces: [X], [Y], and [Z]. I'd recommend we design each one separately. Want to start with [X]?"

For large projects: help decompose into sub-projects, then brainstorm the first sub-project.

Ask clarifying questions:

- **One question per message.** Do not dump a list of five questions.
- **Prefer multiple choice.** Instead of "What kind of storage do you want?" ask "For storage, which fits best? (a) Local files (b) SQLite (c) External database"
- **Focus on:** purpose (what problem does this solve?), constraints (what must it work with?), success criteria (how do we know it's done?)
- Stop asking when you have enough to propose approaches. Do not over-interrogate.

### Exploring Approaches

Present 2–3 approaches with trade-offs:

- **Lead with your recommendation** and explain why
- For each approach: what it is, key trade-off, when you'd pick it
- Keep it concise — a short paragraph per approach, not a page

Example format:

```
I'd recommend Approach A because [reasoning].

**Approach A: [Name]**
[Description]. Trade-off: [pro] vs [con].

**Approach B: [Name]**
[Description]. Trade-off: [pro] vs [con].

Which direction feels right, or would you like to explore a different angle?
```

### Presenting the Design

Scale sections to complexity:

- **Simple project:** A few sentences per section, 50–100 words total
- **Medium project:** A paragraph per section, 200–300 words total
- **Complex project:** Detailed sections with diagrams or examples as needed

Present the design incrementally and ask after each section if it looks right:

> "Here's the architecture section. Does this match what you're thinking, or should we adjust?"

Cover these areas (skip any that genuinely don't apply):

- **Architecture** — overall structure, how pieces fit together
- **Components** — what the units are and what each one does
- **Data flow** — how data moves through the system
- **Error handling** — what can go wrong and how it's handled
- **Testing** — how we'll verify it works

Be ready to go back and revise earlier sections based on feedback on later ones.

### Design for Isolation and Clarity

Break the design into smaller units with:

- **One purpose** — each unit does one thing
- **Well-defined interfaces** — clear inputs and outputs
- **Independent testability** — can be verified on its own

For each unit, answer:

- What does it do?
- How do you use it?
- What does it depend on?

Smaller, well-bounded units are easier to implement, test, and change later.

### Working in Existing Codebases

- **Follow existing patterns.** Match the style, conventions, and structure already in the project.
- **Include targeted improvements** where existing code has problems that directly affect the work being designed. For example, if a function you need to call has a bug, include fixing it.
- **Do not propose unrelated refactoring.** Stay focused on the task. "While we're here, we should also reorganize the utils folder" is out of scope unless the user asked for it.

---

## After the Design

### Documentation

Once the user approves the full design, write the spec:

- Save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
- Use today's date and a descriptive topic slug
- Commit to git with a message describing the spec

### Spec Review Loop

Dispatch a general-purpose subagent with this prompt:

```
You are a spec document reviewer. Verify this spec is complete and ready for planning.

**Spec to review:** [SPEC_FILE_PATH]

## What to Check

| Category | What to Look For |
|----------|------------------|
| Completeness | TODOs, placeholders, "TBD", incomplete sections |
| Consistency | Internal contradictions, conflicting requirements |
| Clarity | Requirements ambiguous enough to cause building the wrong thing |
| Scope | Focused enough for a single plan — not multiple independent subsystems |
| YAGNI | Unrequested features, over-engineering |

## Calibration
Only flag issues that would cause real problems during implementation planning.
Approve unless there are serious gaps that would lead to a flawed plan.

## Output Format
**Status:** Approved | Issues Found
**Issues (if any):** - [Section X]: [issue] - [why it matters]
**Recommendations (advisory):** - [suggestions]
```

Handle the result:

- **Approved:** Proceed to user review.
- **Issues Found:** Fix the issues in the spec, re-dispatch the reviewer. Maximum 3 iterations. If still not approved after 3 rounds, surface the remaining issues to the user and ask them to decide.

### User Review Gate

After the spec passes review, present it to the user:

> "Spec written and committed to `<path>`. Please review it and let me know if you want changes before we write the implementation plan."

Wait for the user to confirm. Do not proceed until they do.

### Implementation

Hand off to `/plan` to create the implementation plan. Do NOT invoke any other command.

---

## Key Principles

- **One question at a time.** Never dump a wall of questions.
- **Multiple choice preferred.** Reduce cognitive load on the user.
- **YAGNI ruthlessly.** If the user didn't ask for it, don't design it. Fight the urge to add "nice to have" features.
- **Explore alternatives.** Always present options, not just your first idea.
- **Incremental validation.** Get feedback on each section before moving on.
- **Be flexible.** If the user wants to skip ahead, change direction, or simplify, follow their lead. The process serves the user, not the other way around.

---

## Common Mistakes

- **Jumping to implementation.** The hard gate exists for a reason. Even if you know exactly how to build it, present the design first.
- **Asking too many questions.** Stop when you have enough to propose approaches. You can always ask more later.
- **Designing what wasn't asked for.** Stick to the user's stated needs. Suggesting additional features wastes time and adds scope.
- **Skipping the spec review.** The review loop catches real problems. Do not skip it to save time.
- **Monolithic designs.** Break things into smaller units. If a component description is longer than a paragraph, it might be doing too much.

---

## Red Flags

- **Never write code during design.** Not even "just a quick prototype." Design first, code later.
- **Never skip user approval.** Every section of the design needs a thumbs-up before you proceed.
- **Never propose unrelated changes.** Stay in scope. Save refactoring ideas for a separate conversation.
- **Never exceed 3 review iterations.** If the spec reviewer keeps finding issues after 3 rounds, escalate to the user.

---

## Integration

- This command is the entry point for new work. It produces a spec.
- The spec feeds into `/plan` which creates the implementation plan.
- This command is self-contained and can be invoked independently.
