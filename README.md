# Airgap

Zero-dependency engineering workflows for Claude Code. Nothing leaves your machine.

**19 commands** · **1 agent** · **0 external dependencies**

---

## What is Airgap?

Airgap is a collection of slash commands and a review agent for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Every command is a self-contained markdown file — no network calls, no plugin infrastructure, no telemetry. Copy two directories and you're running.

Commands chain together to form complete engineering workflows: from idea → design → plan → implementation → review → deploy, with safety gates at every step.

## Install

```bash
git clone <repo> && cd airgap
./install.sh
```

The installer copies commands to `~/.claude/commands/` and agents to `~/.claude/agents/`. Changes are live on the next Claude Code session.

## Commands

### Core Workflow

| Command | Description |
|---------|-------------|
| `/design` | Brainstorm → design → spec. Structured conversation from idea to approved design with trade-off analysis and iterative approval. |
| `/plan` | Takes an approved spec and produces a detailed implementation plan with atomic tasks, file mappings, and dependency ordering. |
| `/execute` | Inline plan execution with review gates. Runs steps sequentially, tracks progress, surfaces blockers. |
| `/implement` | Subagent-driven plan execution. Dispatches a fresh subagent per task with two-stage review (spec compliance + code quality). |
| `/review` | Triggers the code-reviewer agent for quality review. Iterates until clean (max 3 rounds). |
| `/receive-review` | Structured process for handling incoming review feedback. No blind implementation — every suggestion gets evaluated. |
| `/finish` | Branch completion with 4 options: merge locally, open PR, keep as-is, or discard. Cleans up worktrees. |

### Safety & Security

| Command | Description |
|---------|-------------|
| `/scan-secrets` | Scans for leaked credentials before they reach git. Detects API keys, tokens, passwords, and private keys across major providers. |
| `/threat-model` | STRIDE-based threat modeling. Maps assets, entry points, and trust boundaries with likelihood × impact scoring. |
| `/security-review` | OWASP Top 10 focused security code review with CWE references and severity ratings. |
| `/preflight` | Pre-deploy go/no-go gate. Orchestrates `/verify`, `/scan-secrets`, and `/audit-deps` into a single safety checklist. |
| `/postmortem` | Blameless incident analysis with 5-Whys root cause, timelines, and action items with owners and deadlines. |
| `/audit-deps` | Dependency vulnerability and license audit. Auto-detects package managers, checks CVEs and typosquatting indicators. |

### Development Discipline

| Command | Description |
|---------|-------------|
| `/debug` | Systematic 4-phase debugging: root cause investigation → pattern analysis → hypothesis testing → implementation. |
| `/test` | TDD red-green-refactor discipline. No production code without a failing test first. |
| `/verify` | Evidence-based verification. No completion claims without fresh test/lint/typecheck evidence. |
| `/worktree` | Creates isolated git worktrees for feature work with safety verification and auto-setup. |
| `/parallel` | Decomposes independent tasks into parallel subagents. Sequential dependencies stay sequential. |

### Meta

| Command | Description |
|---------|-------------|
| `/new-skill` | Creates new custom commands following Airgap conventions. Drafts, tests against a synthetic scenario, then writes and indexes. |

## Agent

| Agent | Description |
|-------|-------------|
| `code-reviewer` | Shared review engine dispatched by `/review`, `/design`, `/plan`, `/implement`, and `/security-review`. Review mode is determined by context passed at dispatch time. |

## Command Chaining

Commands are designed to flow into each other:

```
/design → /threat-model (optional) → /plan → /execute or /implement
/debug → fix → /verify → /review → /security-review (optional) → /finish
/test → /verify → /review → /finish
/scan-secrets → /preflight → /finish
/audit-deps → /preflight → /finish
/postmortem → action items → /plan
/worktree → [feature work] → /finish
```

## How It Works

Every command is a standalone markdown file in `~/.claude/commands/`. When you type `/design` in Claude Code, it loads `design.md` as a system prompt that guides the conversation.

There is no runtime, no plugin system, no build step. The installer is a 47-line bash script that copies files. You can read every command, modify them, or write your own.

## Creating Custom Commands

Use `/new-skill` to scaffold a new command that follows Airgap conventions, or create a markdown file in `commands/` manually and re-run `./install.sh`.

## Author

**Eshan Anand**

## License

MIT
