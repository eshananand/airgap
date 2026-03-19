<!-- v1.0 -->
# Structured Incident Postmortem

A postmortem is not a blame session. It is a **systematic investigation** into what happened, why it happened, and how to prevent it from happening again. The goal is better systems, not punished people.

---

## Core Principle

```
BLAMELESS. ALWAYS.
Focus on systems and processes, never individuals.
```

If your postmortem contains the phrase "Person X should have..." — stop and rewrite it. The question is always: **why did the system allow this to happen?**

---

## When to Use

- Any production incident that affected users
- Any near-miss that could have been worse
- Any outage, data loss, or security event
- Any incident where the resolution took longer than expected
- Whenever the team says "we should make sure this never happens again"

---

## Process

Follow these phases in order. Do not skip steps.

### Phase 1: Gather Facts

Collect the raw facts before any analysis. Do not theorize yet.

Answer each of these:

1. **What happened?** — Describe the observable symptoms. What broke? What did users see?
2. **When was it detected?** — Timestamp of first alert or report.
3. **Who detected it?** — Automated monitoring? A user report? An engineer who noticed?
4. **How was it detected?** — Which alert, dashboard, or communication channel?
5. **What was the user/business impact?** — Number of affected users, revenue impact, data loss, SLA breach.
6. **What was the duration?** — Time from first symptom to full resolution (not just mitigation).
7. **What was the mitigation?** — What stopped the bleeding? (Rollback, hotfix, feature flag, manual intervention.)

### Phase 2: Build Timeline

Create a strictly chronological list of events. Include everything from the first sign of trouble to full resolution. Use UTC timestamps.

Use this format:

```
## Timeline

| Time (UTC) | Event |
|------------|-------|
| 2024-03-15 14:02 | Deploy of commit abc123 reaches production |
| 2024-03-15 14:07 | Error rate on /api/checkout crosses 5% threshold |
| 2024-03-15 14:08 | PagerDuty alert fires for checkout-error-rate |
| 2024-03-15 14:12 | On-call engineer acknowledges alert |
| 2024-03-15 14:15 | Investigation begins; initial hypothesis: database issue |
| 2024-03-15 14:30 | Root cause identified: null pointer in new payment validation logic |
| 2024-03-15 14:35 | Rollback initiated |
| 2024-03-15 14:38 | Rollback complete, error rate returning to normal |
| 2024-03-15 14:45 | Error rate below 0.1%, incident resolved |
```

Key questions for the timeline:
- Was there a gap between symptom and detection? Why?
- Was there a gap between detection and response? Why?
- Were there any misleading signals that sent investigation down the wrong path?

### Phase 3: Root Cause Analysis — 5 Whys

Use the 5-Whys technique to dig past symptoms to the true root cause. The first "why" is never the root cause.

**Example: Checkout failures during deploy**

```
Why 1: Why did checkout fail?
  → The payment validation function threw a null pointer exception.

Why 2: Why did it throw a null pointer?
  → The new validation logic did not handle the case where a user has no saved payment method.

Why 3: Why was this case not handled?
  → The unit tests only covered users with saved payment methods.

Why 4: Why did tests only cover that case?
  → There was no test plan review, and the test data set did not include users without saved methods.

Why 5: Why was there no test plan review?
  → The team has no standard process for reviewing test coverage before merging payment-related changes.
```

**Root cause:** Missing process for test coverage review on payment-critical code paths.

**How to tell you have gone deep enough:**
- The answer points to a **system or process gap**, not a human mistake
- Fixing the root cause would prevent an entire class of similar incidents, not just this specific one
- You can no longer usefully ask "why?" without leaving the scope of your system

### Phase 4: Separate Root Cause from Contributing Factors

The root cause is the single most important thing that, if fixed, would have prevented the incident. Contributing factors made it worse, harder to detect, or slower to resolve.

```
Root cause:
  Missing test coverage review process for payment-critical paths.

Contributing factors:
  - No integration test environment with realistic user data
  - Alerting threshold was 5% error rate; a lower threshold would have caught it 3 minutes earlier
  - Runbook for checkout errors was outdated and referenced deprecated tooling
  - Deploy happened on Friday at 2pm, reducing available responders
```

### Phase 5: Define Action Items

Every action item must have all five fields. No exceptions.

| # | Description | Owner | Deadline | Priority |
|---|-------------|-------|----------|----------|
| 1 | Add test coverage review step to payment PR checklist | @team-lead | 2024-03-22 | P0 |
| 2 | Create integration test data set including edge-case users | @test-eng | 2024-03-29 | P1 |
| 3 | Lower checkout error rate alert threshold to 2% | @sre-team | 2024-03-20 | P0 |
| 4 | Update checkout runbook with current tooling | @on-call | 2024-04-01 | P1 |
| 5 | Establish deploy freeze policy for Fridays after 1pm | @eng-mgr | 2024-04-15 | P2 |

**Priority definitions:**

| Priority | Meaning | Deadline |
|----------|---------|----------|
| **P0** | Immediate — prevents recurrence of this exact incident | This week |
| **P1** | Important — reduces blast radius or detection time | This sprint |
| **P2** | Improvement — addresses contributing factors or process debt | This quarter |

Every postmortem must have at least one P0 action item. If there is no P0, the root cause analysis is not deep enough.

### Phase 6: Write the Postmortem Document

Write the document to:

```
docs/airgap/postmortems/YYYY-MM-DD-<incident-slug>-postmortem.md
```

Use the template below.

### Phase 7: Hand Off Action Items

If any action items require code changes, hand them off to `/plan` for implementation planning. Reference the postmortem file path so the plan has full context.

---

## Postmortem Document Template

Use this template exactly. Fill in every section.

```markdown
# Postmortem: <Incident Title>

**Date:** YYYY-MM-DD
**Author(s):** <names>
**Status:** Draft | Reviewed | Final
**Severity:** P0 | P1 | P2

## Summary

<2-3 sentences. What happened, how long it lasted, what the impact was.>

## Impact

- **Duration:** <total time from first symptom to resolution>
- **Users affected:** <number or percentage>
- **Revenue impact:** <if applicable>
- **SLA breach:** Yes/No — <details if yes>
- **Data loss:** Yes/No — <details if yes>

## Detection

- **Detected by:** <monitoring/user report/engineer>
- **Detection method:** <alert name, dashboard, support ticket, etc.>
- **Time to detect:** <time from first symptom to detection>

## Timeline

| Time (UTC) | Event |
|------------|-------|
| | |

## Root Cause

<Clear description of the root cause. This should be a system or process failure, not a human error.>

### 5-Whys Analysis

1. Why? →
2. Why? →
3. Why? →
4. Why? →
5. Why? →

## Contributing Factors

- <factor 1>
- <factor 2>
- <factor 3>

## What Went Well

- <things that worked during the response>
- <things that reduced the blast radius>
- <things that sped up detection or resolution>

## What Went Poorly

- <things that slowed down detection>
- <things that slowed down resolution>
- <misleading signals or wrong turns>

## Action Items

| # | Description | Owner | Deadline | Priority |
|---|-------------|-------|----------|----------|
| 1 | | | | |

## Lessons Learned

<Key takeaways for the broader team. What should change about how we build, test, deploy, or monitor?>
```

---

## Common Contributing Factors Checklist

When analyzing an incident, check each of these. Most incidents involve multiple contributing factors.

**Monitoring and alerting:**
- [ ] Missing alerts for the failure mode that occurred
- [ ] Alert thresholds too high (late detection)
- [ ] Alert fatigue causing real alerts to be ignored
- [ ] No dashboard showing the affected metric
- [ ] Monitoring did not cover the specific service or endpoint

**Runbooks and documentation:**
- [ ] No runbook for this failure mode
- [ ] Runbook was outdated or referenced deprecated tools
- [ ] Runbook was unclear or assumed too much context
- [ ] Escalation path was not documented

**Testing:**
- [ ] Missing unit tests for the failure case
- [ ] Missing integration tests
- [ ] Test data did not represent production edge cases
- [ ] No load testing or chaos testing
- [ ] Tests passed but did not cover the actual failure mode

**Deploy and rollback:**
- [ ] No canary or staged rollout
- [ ] Rollback was slow or manual
- [ ] Feature flags were not used for the risky change
- [ ] Deploy happened during a low-coverage window (weekend, holiday, Friday afternoon)

**Communication:**
- [ ] Unclear who was on-call
- [ ] Slow escalation
- [ ] Stakeholders not notified promptly
- [ ] No status page update for users

**Architecture:**
- [ ] No circuit breaker or graceful degradation
- [ ] Single point of failure
- [ ] Missing input validation
- [ ] Insufficient rate limiting
- [ ] No retry with backoff

---

## Blameless Culture Guidelines

The way you write a postmortem sets the tone for your engineering culture.

### Say this (system-focused)

- "The deploy pipeline allowed this change to reach production without sufficient test coverage."
- "The monitoring system did not have an alert for this failure mode."
- "The runbook did not cover this scenario, which slowed resolution."
- "The code review process did not catch the missing null check."
- "There was no automated safeguard against deploying during a low-coverage window."

### Do not say this (blame-focused)

- "The engineer should have written better tests."
- "The reviewer missed the bug."
- "The on-call engineer was too slow to respond."
- "This was a careless mistake."
- "If they had just read the documentation..."

### The test

For every statement in the postmortem, ask: **"Would a different person in the same situation, with the same information, have done the same thing?"** If the answer is yes, the problem is the system, not the person.

---

## Red Flags

Watch for these during the postmortem process. Each one indicates the analysis is incomplete or heading in the wrong direction.

**In the root cause analysis:**
- Root cause is "human error" — dig deeper. Why did the system allow the error?
- Root cause is "the code had a bug" — that is the symptom, not the cause. Why was the bug not caught?
- Only one "why" in the 5-Whys — you stopped too early
- The root cause fix only prevents this exact incident, not the class of incidents

**In the action items:**
- No P0 action items — the root cause analysis is not deep enough
- Action items are vague ("improve testing") — make them specific and measurable
- No deadlines or owners — these will never get done
- All action items are P2 — you are underestimating the risk of recurrence
- Action items only address the immediate cause, not contributing factors

**In the timeline:**
- Large time gaps with no explanation — something happened that is not documented
- Detection happened by luck (user report, someone happened to be looking) — monitoring needs improvement
- Resolution required tribal knowledge — this needs to be in a runbook

**In the culture:**
- People are defensive or unwilling to share details — the environment is not safe
- The postmortem focuses on who rather than why
- Action items are assigned to the person who "caused" the incident — that is punishment, not improvement

---

## Integration with Other Commands

- **Action items requiring code changes** — hand off to `/plan` with the postmortem as context
- **Debugging during incident investigation** — use `/debug` for systematic root cause analysis
- **Implementing fixes** — use `/implement` for the code changes identified in action items
- **Verifying fixes** — use `/verify` to confirm action items are properly addressed
- **Testing improvements** — use `/test` for new test coverage required by action items
