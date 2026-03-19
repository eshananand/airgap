<!-- v1.0 -->
# STRIDE Threat Modeling

> Perform structured threat modeling for a feature or system using the STRIDE framework.

---

## Hard Gate

**Do NOT skip any STRIDE category.** Every entry point must be evaluated against all six categories, even if the result is "not applicable — [reason]." Shallow analysis misses real threats. Be thorough.

---

## Checklist

Complete these in order. Do not skip steps.

1. **Gather context** — read the spec/design doc, or ask the user to describe the feature
2. **Identify assets, entry points, and trust boundaries**
3. **Walk STRIDE against each entry point** — all six categories, no exceptions
4. **Rate each threat** — likelihood x impact
5. **Propose mitigations** — for all high and critical priority threats
6. **Write threat model** — save to `docs/airgap/threats/YYYY-MM-DD-<topic>-threat-model.md`
7. **Hand off to `/plan`** — with threats as constraints on the implementation

---

## The Process

### Step 1: Gather Context

Check for an existing spec first. Look in `docs/airgap/specs/` for a design document related to the feature. If one exists, read it thoroughly before proceeding.

If no spec exists, ask the user to describe:

- What the feature does
- Who uses it (users, services, admins)
- What data it handles
- What systems it interacts with

One question at a time. Prefer multiple choice where possible.

### Step 2: Identify Assets, Entry Points, and Trust Boundaries

**Assets** — what are we protecting?

List every piece of valuable data or capability in the system:

- User data (credentials, PII, preferences)
- System data (config, secrets, API keys)
- Business logic (authorization decisions, payment flows)
- Availability (uptime, response time)

**Entry points** — how do users and systems interact?

List every interface where data enters or leaves:

- API endpoints (REST, GraphQL, WebSocket)
- UI forms and user inputs
- File uploads and downloads
- Inter-service communication
- Webhooks and callbacks
- CLI commands and arguments
- Background jobs and scheduled tasks

**Trust boundaries** — where do privilege levels change?

Identify every point where trust shifts:

- Client to server
- Public internet to internal network
- Unauthenticated to authenticated
- User role to admin role
- Your service to third-party service
- Application code to database

Present these three lists to the user for validation before proceeding.

### Step 3: Walk STRIDE Against Each Entry Point

For every entry point, evaluate all six STRIDE categories. Use the reference table below.

---

## STRIDE Reference Table

| Category | Question | Example Threats |
|----------|----------|-----------------|
| **S — Spoofing** | Can an attacker impersonate a legitimate user or system? | Stolen session tokens, forged API keys, DNS spoofing, phishing for credentials, replay attacks with captured auth tokens |
| **T — Tampering** | Can data be modified in transit or at rest? | Man-in-the-middle modifying API responses, SQL injection altering records, modifying local storage, tampering with request parameters, unsigned webhook payloads |
| **R — Repudiation** | Can actions be performed without evidence? | Missing audit logs for admin actions, no logging of data deletions, unsigned transactions, no request tracing, inability to prove who made a change |
| **I — Information Disclosure** | Can sensitive data leak to unauthorized parties? | Verbose error messages exposing stack traces, API responses including extra fields, logs containing PII, timing attacks revealing valid usernames, unencrypted data at rest |
| **D — Denial of Service** | Can the system be made unavailable? | Unbounded query results, missing rate limiting, resource-exhaustion via large file uploads, regex denial of service, lock contention from concurrent writes |
| **E — Elevation of Privilege** | Can an attacker gain higher access than intended? | IDOR (accessing other users' resources by changing IDs), missing authorization checks on admin endpoints, JWT manipulation, path traversal to access restricted files, mass assignment vulnerabilities |

---

## Threat Rating Matrix

Rate each identified threat on two axes:

**Likelihood** — how likely is this to be exploited?

| Rating | Criteria |
|--------|----------|
| **Low** | Requires specialized knowledge, insider access, or unlikely conditions |
| **Medium** | Exploitable by a motivated attacker with standard tools |
| **High** | Easily discoverable, automatable, or already a known attack pattern |

**Impact** — how bad is it if exploited?

| Rating | Criteria |
|--------|----------|
| **Low** | Minor inconvenience, no data loss, easily recoverable |
| **Medium** | Partial data exposure, service degradation, reputational damage |
| **High** | Full data breach, complete service outage, financial loss, compliance violation |

**Priority matrix:**

| | Impact: Low | Impact: Medium | Impact: High |
|---|---|---|---|
| **Likelihood: High** | Medium | High | Critical |
| **Likelihood: Medium** | Low | Medium | High |
| **Likelihood: Low** | Info | Low | Medium |

**Action thresholds:**

- **Critical** — must be mitigated before shipping. Block the implementation plan.
- **High** — must be mitigated before shipping. Add as constraints in `/plan`.
- **Medium** — should be mitigated. Add as tasks in `/plan` if feasible.
- **Low** — document and accept, or address opportunistically.
- **Info** — document for awareness only.

### Step 4: Rate Each Threat

For each threat identified in Step 3, assign likelihood, impact, and the resulting priority. Present as a summary table:

```
| # | Entry Point | STRIDE | Threat | Likelihood | Impact | Priority |
|---|-------------|--------|--------|------------|--------|----------|
| 1 | POST /login | S | Credential stuffing | High | High | Critical |
| 2 | GET /users/:id | E | IDOR — accessing other users | Medium | High | High |
| ...
```

### Step 5: Propose Mitigations

For every Critical and High priority threat, propose a specific mitigation:

- **Be concrete.** Not "add authentication" but "add JWT validation middleware that checks token signature, expiry, and issuer on every request to `/api/*`."
- **Reference existing patterns.** If the codebase already has rate limiting or auth middleware, reference those exact files and functions.
- **Estimate effort.** Flag mitigations that are trivial (config change) vs. significant (new subsystem).

For Medium threats, propose mitigations but mark them as "recommended, not blocking."

### Step 6: Write the Threat Model Document

Save to `docs/airgap/threats/YYYY-MM-DD-<topic>-threat-model.md`. Use today's date and a descriptive topic slug. Commit to git.

### Step 7: Hand Off to /plan

Present the threat model to the user, then hand off to `/plan` with this framing:

> "Threat model complete and saved to `<path>`. The following threats are constraints on the implementation plan:"
>
> - [List Critical and High threats with their mitigations]
>
> "Ready to proceed to `/plan`?"

---

## Threat Model Output Template

The saved document must follow this structure:

```markdown
# Threat Model: [Feature Name]

**Date:** YYYY-MM-DD
**Author:** [user + AI-assisted]
**Spec:** [link to spec file if one exists]
**Status:** Draft | Reviewed | Accepted

## Overview

[1-2 sentences: what is being threat-modeled and why]

## Assets

| Asset | Sensitivity | Notes |
|-------|-------------|-------|
| [e.g., User credentials] | High | [Stored hashed, accessed during auth] |

## Entry Points

| ID | Entry Point | Protocol | Authentication | Notes |
|----|-------------|----------|----------------|-------|
| EP1 | [e.g., POST /api/login] | HTTPS | None (this is the auth endpoint) | [Rate limited] |

## Trust Boundaries

| Boundary | From | To | Notes |
|----------|------|----|-------|
| TB1 | [e.g., Browser] | [API Gateway] | [TLS termination] |

## Threat Analysis

### EP1: [Entry Point Name]

| # | STRIDE | Threat | Likelihood | Impact | Priority | Mitigation |
|---|--------|--------|------------|--------|----------|------------|
| T1 | S | [Threat description] | H/M/L | H/M/L | [Priority] | [Mitigation] |

[Repeat for each entry point]

## Summary

| Priority | Count | Action |
|----------|-------|--------|
| Critical | N | Must fix before shipping |
| High | N | Must fix before shipping |
| Medium | N | Fix if feasible |
| Low | N | Accept |
| Info | N | Awareness only |

## Mitigations for /plan

These threats MUST be addressed as constraints in the implementation plan:

1. **T1: [Threat]** — [Specific mitigation to implement]
2. **T2: [Threat]** — [Specific mitigation to implement]

## Accepted Risks

These threats were evaluated and accepted:

- **T5: [Threat]** — [Why accepted, e.g., "Low likelihood, and existing WAF provides partial coverage"]
```

---

## Common Threat Patterns

Use these as a checklist when evaluating entry points. Not every pattern applies to every system, but scanning this list helps avoid blind spots.

### Web Applications

- **Authentication bypass:** default credentials, weak password policies, missing MFA, session fixation
- **Cross-site scripting (XSS):** stored, reflected, DOM-based — anywhere user input is rendered
- **Cross-site request forgery (CSRF):** state-changing operations without anti-CSRF tokens
- **Clickjacking:** sensitive actions in iframeable pages
- **Open redirects:** redirect parameters that accept arbitrary URLs
- **Insecure cookies:** missing Secure, HttpOnly, SameSite flags

### APIs

- **Broken object-level authorization (BOLA/IDOR):** accessing resources by changing IDs in URLs or payloads
- **Broken function-level authorization:** calling admin endpoints without admin privileges
- **Mass assignment:** sending extra fields that get bound to internal model properties
- **Excessive data exposure:** API responses returning more fields than the client needs
- **Missing rate limiting:** no throttling on authentication, search, or expensive operations
- **Injection:** SQL, NoSQL, command injection via unsanitized parameters

### Data Systems

- **Unencrypted data at rest:** PII, credentials, or secrets stored in plaintext
- **Unencrypted data in transit:** internal service communication over plain HTTP
- **Overly broad access:** database users with more permissions than needed
- **Missing backup validation:** backups exist but are never tested for restorability
- **Log injection:** user-controlled data written to logs without sanitization
- **Sensitive data in logs:** PII, tokens, or passwords appearing in application logs

---

## Integration

- **Slots between `/design` and `/plan`.** Run `/threat-model` after the design spec is written and approved, before writing the implementation plan.
- **Input:** a design spec from `/design` (in `docs/airgap/specs/`) or a user-provided feature description.
- **Output:** a threat model document in `docs/airgap/threats/` and a list of constraints for `/plan`.
- **The `/plan` command receives Critical and High threats as hard constraints** that must be addressed in the implementation plan.
- This command can also be invoked independently on any existing system or feature for a standalone security review.

---

## Red Flags

- **Never skip a STRIDE category.** "This doesn't apply" is a valid assessment, but you must explicitly state it for each category on each entry point. Silent omission hides real threats.
- **Never rate all threats as Low.** If everything looks low-risk, you are probably not looking hard enough. Re-examine your assumptions.
- **Never propose vague mitigations.** "Improve security" is not a mitigation. Every mitigation must be specific and actionable.
- **Never ignore the trust boundaries.** Most serious vulnerabilities occur at trust boundaries. If you identified fewer than two boundaries, revisit Step 2.
- **Never skip the handoff to `/plan`.** The whole point of threat modeling is to influence the implementation. A threat model that doesn't feed into the plan is documentation theater.
- **Never treat this as a one-time activity.** When the design changes significantly, re-run `/threat-model` on the affected areas.

---

## Common Mistakes

- **Boiling the ocean.** Focus on the feature being designed, not the entire organization's security posture. Stay scoped.
- **Copy-pasting generic threats.** Every threat must be specific to the system being analyzed. "SQL injection" is only relevant if there is a SQL database and user input reaches queries.
- **Confusing likelihood with impact.** A nuclear meltdown is high impact but low likelihood. A credential stuffing attempt is high likelihood. Rate them separately.
- **Forgetting internal threats.** Not all attackers are external. Consider compromised dependencies, malicious insiders, and misconfigured services.
- **Over-mitigating Low threats.** Accept low-priority risks explicitly rather than designing elaborate defenses for unlikely scenarios. Document the decision and move on.
