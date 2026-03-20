---
description: Pre-deploy go/no-go gate orchestrating verify, scan-secrets, and audit-deps
---
<!-- v1.0 -->
# Pre-Deployment Preflight Check

> I'm using /preflight to run the go/no-go gate before deployment.

**Core principle:** No deployment proceeds with unresolved blockers. Evidence decides, not confidence.

---

## Process

Execute each step in order. A failure at any step is a potential NO-GO.

```
1. Run /verify           — do all tests pass with fresh evidence?
2. Run /scan-secrets     — any credentials or secrets in the codebase?
3. Run /audit-deps       — any critical CVEs in dependencies?
4. Check breaking changes — are they documented?
5. Check rollback plan   — does one exist and is it viable?
6. Check environment configs — no dev/test values leaking into prod?
```

Do not skip steps. Do not reorder steps. Do not mark a step as passed without executing it.

---

## Preflight Checklist

| # | Check Item | Status | Command / Action | Blocker? |
|---|-----------|--------|-----------------|----------|
| 1 | All tests pass | PENDING | `/verify` — run full suite, read output | YES if any fail |
| 2 | No secrets in codebase | PENDING | `/scan-secrets` — scan all tracked files | YES if any found |
| 3 | No critical dependency CVEs | PENDING | `/audit-deps` — check all dependencies | YES if critical/high CVEs |
| 4 | Breaking changes documented | PENDING | Review changelog, migration guide, API docs | YES if undocumented |
| 5 | Rollback plan exists | PENDING | Verify rollback procedure is written and tested | YES if missing |
| 6 | Environment configs correct | PENDING | Validate prod configs, no dev values present | YES if misconfigured |

Fill in the Status column as each check completes: PASS, FAIL, or WARN.

---

## GO vs NO-GO Conditions

### GO — Safe to Deploy

ALL of the following must be true:

- Every checklist item has status PASS (or WARN with documented justification)
- Zero test failures
- Zero secrets detected
- Zero critical or high CVEs (medium CVEs require documented acceptance)
- All breaking changes have migration documentation
- Rollback plan exists with specific steps
- Environment configs validated against production requirements

### NO-GO — Deployment Blocked

ANY of the following triggers NO-GO:

- Any test failure, regardless of perceived severity
- Any secret or credential detected in tracked files
- Any critical or high CVE without a mitigation plan
- Undocumented breaking changes
- Missing or untested rollback plan
- Development or test values in production configuration
- Inability to complete any checklist item (unknown status is NO-GO)

**Hard gate:** You cannot claim "ready to deploy" with any NO-GO item unresolved. No exceptions. No "we'll fix it after deployment." Resolve every blocker first.

---

## Breaking Change Detection

Check for these indicators of breaking changes:

### API Changes
- Removed or renamed endpoints
- Changed request/response schemas (removed fields, changed types)
- Modified authentication or authorization requirements
- Changed error codes or error response formats

### Database Changes
- Removed or renamed columns/tables
- Changed column types or constraints
- Migrations that cannot be rolled back
- Data transformations that are destructive

### Configuration Changes
- Removed or renamed environment variables
- Changed default values
- New required configuration without fallbacks

### Dependency Changes
- Major version bumps in public-facing libraries
- Removed support for previously supported platforms or runtimes

### Detection Steps
```
1. Review all commits since last deployment tag
2. Check for removed/renamed exports, endpoints, or public interfaces
3. Diff database migration files — look for DROP, ALTER, RENAME
4. Diff configuration templates — look for removed keys
5. Check dependency manifests for major version changes
```

If any breaking change is found, verify that:
- A migration guide exists
- The changelog describes the change and its impact
- Affected consumers have been notified (if applicable)

If documentation is missing, status is FAIL. Write the documentation before proceeding.

---

## Rollback Plan Template

Every deployment must have answers to these questions:

```
ROLLBACK PLAN
=============

1. Trigger conditions:
   - What metrics/errors indicate a rollback is needed?
   - Who has authority to initiate rollback?

2. Rollback procedure:
   - How to revert the deployment (redeploy previous version, feature flag, etc.)?
   - Estimated time to complete rollback?

3. Database considerations:
   - Are migrations reversible?
   - If not, what is the data recovery plan?

4. Dependencies:
   - Do downstream services need to be notified?
   - Are there cache invalidations required?

5. Verification after rollback:
   - How to confirm the rollback succeeded?
   - What tests to run post-rollback?
```

If any answer is "I don't know" or blank, the rollback plan is incomplete. Status is FAIL.

---

## Environment Config Validation

Check for these common misconfigurations before deployment:

### Values That Must Not Appear in Production Config
- `localhost`, `127.0.0.1`, or `0.0.0.0` as service hosts (unless intentional)
- `DEBUG=true`, `NODE_ENV=development`, `RAILS_ENV=test`
- Default passwords: `password`, `admin`, `123456`, `changeme`, `secret`
- Placeholder tokens: `xxx`, `TODO`, `FIXME`, `your-key-here`
- Test database names or connection strings
- Disabled authentication or authorization flags
- Verbose/debug logging levels in production

### Validation Steps
```
1. Diff production config against development config
2. Search production config for known dev/test patterns
3. Verify all required environment variables are set (no empty values)
4. Confirm secrets reference a vault or secret manager, not inline values
5. Check that URLs point to production endpoints
6. Verify TLS/SSL is enabled where required
```

If any dev/test value is found in production config, status is FAIL.

---

## Output Format

After completing all checks, produce a verdict:

### GO Example
```
PREFLIGHT RESULT: GO

| # | Check Item                  | Status |
|---|-----------------------------|--------|
| 1 | All tests pass              | PASS   |
| 2 | No secrets in codebase      | PASS   |
| 3 | No critical dependency CVEs | PASS   |
| 4 | Breaking changes documented | PASS   |
| 5 | Rollback plan exists        | PASS   |
| 6 | Environment configs correct | PASS   |

Deployment is cleared to proceed.
```

### NO-GO Example
```
PREFLIGHT RESULT: NO-GO

| # | Check Item                  | Status | Blocker Detail                          |
|---|-----------------------------|--------|-----------------------------------------|
| 1 | All tests pass              | PASS   |                                         |
| 2 | No secrets in codebase      | FAIL   | AWS key found in config/settings.json   |
| 3 | No critical dependency CVEs | PASS   |                                         |
| 4 | Breaking changes documented | FAIL   | /api/v2/users removed, no migration doc |
| 5 | Rollback plan exists        | PASS   |                                         |
| 6 | Environment configs correct | PASS   |                                         |

BLOCKERS (must resolve before deploy):
1. [CRITICAL] Secret detected: AWS access key in config/settings.json
   → Remediation: Remove key, rotate credential, use secret manager
2. [HIGH] Breaking change undocumented: /api/v2/users endpoint removed
   → Remediation: Write migration guide, update changelog, notify consumers

Deployment is BLOCKED until all items resolved. Re-run /preflight after fixes.
```

---

## Red Flags

- **Skipping a check because "it was fine last time."** Run every check fresh. Every time.
- **Marking PASS without running the command.** If you did not see the output, it is not PASS.
- **Downgrading a FAIL to WARN without justification.** Document why or fix it.
- **"We'll fix it in the next release."** That is a NO-GO. Fix it now.
- **Rushing preflight because of deadline pressure.** Preflight exists precisely for moments of pressure.
- **Trusting a previous preflight run.** Code changes invalidate previous results. Always run fresh.
- **Claiming GO when any check is PENDING.** Every item must have a definitive status.

---

## Integration

- **Depends on:** `/verify` (test verification), `/scan-secrets` (secret detection), `/audit-deps` (dependency audit)
- **Feeds into:** `/finish` — only proceed to finish/deploy after preflight returns GO
- This command is self-contained and can be invoked independently at any time.
- Re-run after any code change, even "small fixes." There are no small fixes before deployment.
