<!-- AIRGAP:START -->
# Airgap Auto-Routing

When the user's request matches one of the intent patterns below, invoke the corresponding airgap command using the Skill tool instead of handling the request with default behavior. This ensures structured, disciplined workflows are used automatically.

## Routing Table

| User Intent | Command | When to Route |
|---|---|---|
| debug, fix bug, investigate, root cause, why is this broken | `/ag-debug` | User wants to find and fix a bug |
| write tests, add tests, TDD, test this | `/ag-test` | User wants to add or run tests |
| verify, check if it works, confirm it's working | `/ag-verify` | User wants proof that something works |
| review code, code review, check my code | `/ag-review` | User wants a code quality review |
| scan for secrets, check credentials, leaked keys | `/ag-scan-secrets` | User wants to find leaked credentials |
| security review, OWASP, vulnerabilities, security audit | `/ag-security-review` | User wants a security-focused audit |
| threat model, attack surface, security threats | `/ag-threat-model` | User wants threat analysis |
| design, brainstorm, new feature idea, let's think through | `/ag-design` | User wants to go from idea to spec |
| plan, break down, implementation plan, how to build | `/ag-plan` | User wants to create an implementation plan |
| implement, build it, execute the plan, start building | `/ag-implement` | User wants subagent-driven execution |
| execute, run the plan, do it inline | `/ag-execute` | User wants inline plan execution |
| finish, merge, PR, done with branch, wrap up | `/ag-finish` | User is done with a branch |
| audit dependencies, check CVEs, dependency vulnerabilities | `/ag-audit-deps` | User wants to audit dependencies |
| preflight, ready to deploy, pre-deploy check | `/ag-preflight` | User wants a pre-deploy gate check |
| postmortem, incident review, what went wrong | `/ag-postmortem` | User wants incident analysis |
| parallel, run in parallel, split these up | `/ag-parallel` | User wants to parallelize tasks |
| worktree, isolated branch, separate branch | `/ag-worktree` | User wants git worktree isolation |
| handle review feedback, address review comments | `/ag-receive-review` | User has review feedback to process |
| create new command, new skill, add a command | `/ag-new-skill` | User wants to create a custom command |
| list commands, help, what commands | `/ag-help` | User wants to see available airgap commands |

## Routing Rules

1. **Explicit invocation wins.** If the user types `/ag-debug`, use that directly. Never double-invoke.
2. **Match intent, not keywords.** "Debug logging" is not a debugging request. "Review the plan" is not a code review request. Use context.
3. **Ask when ambiguous.** If the intent could map to multiple commands, ask the user which workflow they want.
4. **Don't route trivial requests.** Quick questions like "what does this function do?" don't need a full workflow. Only route when the user is asking to *do* something substantial that maps to an airgap workflow.
5. **Invoke via Skill tool.** When routing, use the Skill tool with the command name (e.g., `skill: "ag-debug"`). Do not just describe the workflow — actually invoke it.
<!-- AIRGAP:END -->
