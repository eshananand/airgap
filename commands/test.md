<!-- v1.0 -->
# Test-Driven Development (TDD)

## Overview

Write the test first. Watch it fail. Write minimal code to pass.

Core principle: **If you didn't watch the test fail, you don't know if it tests the right thing.**

Every test you write without first seeing it fail is a test you cannot trust. A passing test only means something if you know it *can* fail. The red-green-refactor cycle is not ceremony — it is the minimum viable process for producing code you can trust.

> Violating the letter of the rules is violating the spirit of the rules.

---

## When to Use

**Always.** TDD applies to:

- New features
- Bug fixes
- Refactoring (characterization tests first)
- Any behavior change

**Exceptions** — only with explicit user permission:

- Throwaway prototypes (that will be deleted, not "evolved")
- Generated code (scaffolding, codegen output)
- Configuration files (non-behavioral)

> Thinking "skip TDD just this once"? **Stop.** That's rationalization.

Every "just this once" becomes "just this habit." The moment you feel the urge to skip is exactly when TDD matters most — you're about to write code you don't fully understand.

---

## Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Wrote code before the test? **Delete it. Start over.**

No exceptions:

- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- **Delete means delete**

Code written without a failing test is code you cannot trust. It doesn't matter how good it looks. It doesn't matter how long it took. You have no evidence it works, no evidence the test catches regressions, and no evidence it does what you think it does.

---

## Red-Green-Refactor

The cycle has three phases. Each is mandatory. Each has a verification step. Do not skip steps.

### RED — Write a Failing Test

Write **one** minimal test. Just one.

Rules:

- Clear, descriptive name that states expected behavior
- Test real code — no mocks unless absolutely unavoidable (external services, hardware)
- Test one thing only
- Write the test as if the production code already exists with the ideal API

**Good example:**

```typescript
test('retry sends request again after transient failure', async () => {
  const server = createTestServer();
  server.failNextRequest({ status: 503 });

  const client = new HttpClient({ retries: 1 });
  const response = await client.get(server.url('/data'));

  expect(response.status).toBe(200);
  expect(server.requestCount).toBe(2);
});
```

Why it's good: clear name states behavior, tests real HTTP client against a real test server, asserts on observable behavior.

**Bad example:**

```typescript
test('retry works', async () => {
  const mockFetch = jest.fn()
    .mockRejectedValueOnce(new Error('fail'))
    .mockResolvedValueOnce({ status: 200 });

  const client = new HttpClient({ fetch: mockFetch });
  await client.get('/data');

  expect(mockFetch).toHaveBeenCalledTimes(2);
});
```

Why it's bad: vague name ("works" means nothing), tests mock behavior not real behavior, asserts on implementation detail (call count of a mock), would pass even if the real fetch integration is broken.

---

### Verify RED

**MANDATORY.** Run the test command. Do not proceed until you confirm:

1. **Test fails** — not errors, *fails*. A compilation error or import error is not a valid red. Fix the error, then re-run.
2. **Failure message matches expectation** — the assertion that fails should be the one you wrote. If a different assertion fails, something is wrong.
3. **Fails because the feature is missing** — the test should fail because the production code doesn't implement the behavior yet, not because of a typo or misconfiguration.

**If the test passes immediately:**
You are testing existing behavior, not new behavior. Your test proves nothing new. Fix the test so it targets the actual change you're about to make.

**If the test errors instead of failing:**
Fix the error (missing import, syntax issue, wrong path). Re-run. You need a clean *failure*, not an *error*.

---

### GREEN — Write Minimal Code

Write the **simplest** code that makes the failing test pass. Nothing more.

**Good example:**

```typescript
// Test expects: retry after 503
async get(url: string): Promise<Response> {
  const response = await fetch(url);
  if (response.status === 503 && this.retries > 0) {
    return fetch(url);
  }
  return response;
}
```

Just enough to pass the test. One retry. No exponential backoff. No configurable delay. No retry-on-other-status-codes. Just exactly what the test demands.

**Bad example:**

```typescript
// Test expects: retry after 503
async get(url: string, options?: RequestOptions): Promise<Response> {
  let lastError: Error | undefined;
  for (let attempt = 0; attempt <= (options?.maxRetries ?? this.retries); attempt++) {
    try {
      const response = await fetch(url, {
        timeout: options?.timeout ?? this.timeout,
        signal: options?.signal,
      });
      if (this.retryableStatuses.has(response.status) && attempt < this.maxRetries) {
        await this.delay(this.backoffMs * Math.pow(2, attempt));
        continue;
      }
      return response;
    } catch (e) {
      lastError = e as Error;
      if (!this.isRetryable(e)) throw e;
    }
  }
  throw lastError ?? new Error('Request failed');
}
```

Why it's bad: exponential backoff nobody asked for, configurable options nobody asked for, retryable status set nobody asked for, timeout handling nobody asked for. All untested. All untrustworthy.

**During GREEN, do NOT:**

- Add features the test doesn't require
- Refactor existing code
- "Improve" code beyond what the test demands
- Optimize for performance
- Add error handling for cases the test doesn't cover

---

### Verify GREEN

**MANDATORY.** Run the test. Confirm:

1. **New test passes** — if it fails, fix the production code, not the test. The test defined the requirement. The code must meet it.
2. **All other tests still pass** — if other tests broke, fix them now. Do not proceed with broken tests. Do not "come back to it later."
3. **Output is pristine** — no warnings, no deprecation notices, no console noise. Clean output means clean code.

**If the new test fails:**
Fix the code. Do not change the test. The test was written first and verified to fail for the right reason. It defines correctness.

**If other tests fail:**
You introduced a regression. Fix it immediately. Regressions caught during GREEN are trivial to fix — you just wrote the code. Regressions caught later are nightmares.

---

### REFACTOR

Only after GREEN. Only with all tests passing.

You may:

- Remove duplication
- Improve variable and function names
- Extract helper functions or methods
- Simplify conditionals
- Restructure for clarity

You must:

- Keep all tests green after every change
- Run tests frequently during refactoring
- Make small changes, verify, repeat

You must NOT:

- Add new behavior (that requires a new test — start a new RED)
- Change what the code does, only how it's structured
- "Improve" the API beyond what tests cover

---

## Good Tests

| Property | Meaning | Guideline |
|----------|---------|-----------|
| **Minimal** | Tests one thing | If the test name contains "and", split it into two tests |
| **Clear** | Describes behavior | Name should read like a specification: "rejects empty email address" |
| **Shows intent** | Demonstrates desired API | The test is the first consumer of your API — design the API through the test |

A good test is a specification. Someone reading only your tests should understand exactly what the system does, without reading any production code.

---

## Why Order Matters

### "I'll write tests after"

Tests that pass immediately prove nothing. You never saw them fail, so you don't know they *can* fail. You might be testing the wrong thing entirely. You never saw the test catch the bug — because the bug was already fixed when you wrote the test. Tests-after are documentation at best, safety net at worst. They are not proof of correctness.

### "I already manually tested it"

Manual testing is ad-hoc. There is no record of what you tested. You cannot re-run it automatically. You cannot prove you tested edge cases. "It worked when I tried it" is not the same as comprehensive verification. Manual testing is a single point-in-time check. Automated tests run every commit, forever.

### "Deleting X hours of work is wasteful"

Sunk cost fallacy. The time is already spent whether you keep the code or not. Keeping code you can't trust is the real waste — it will cost more time debugging, more time fixing regressions, more time wondering "does this actually work?" Delete it. Rewrite it with tests. It will be better the second time, and you can trust it.

### "TDD is dogmatic"

TDD **is** pragmatic. It finds bugs before commit — when they're cheap to fix. It prevents regressions — tests run forever. It documents behavior — tests are executable specifications. It enables confident refactoring — change structure without fear. What's dogmatic is doing the same thing that doesn't work and expecting different results.

### "Tests after achieve the same goals"

Tests-after answer: "What does this code do?" Tests-first answer: "What *should* this code do?" Tests-after are biased by the implementation — you unconsciously write tests that confirm what the code already does, including its bugs. Tests-first are biased by the requirement — you write tests that define what correctness means *before* you know how to achieve it.

---

## Common Rationalizations

| Rationalization | Rebuttal |
|----------------|----------|
| "It's too simple to need a test" | Simple code becomes complex code. The test takes 30 seconds. Write it. |
| "I'll test it after" | You won't. And if you do, you'll test what the code does, not what it should do. |
| "Tests after achieve the same goals" | Tests-after are biased by implementation. Tests-first define correctness independently. |
| "I already manually tested it" | Manual tests evaporate. Automated tests compound. Write the automated test. |
| "Deleting X hours of work is wasteful" | Sunk cost fallacy. Untrusted code costs more to keep than to rewrite. |
| "I'll keep it as reference" | Reference code becomes production code. Delete it. If the logic is sound, you'll write it again — better — with tests. |
| "Let me explore/prototype first" | Explore in a scratch file. Delete it when done. Then start TDD with what you learned. Never promote a prototype. |
| "This is hard to test" | Hard to test means hard to maintain. Refactor for testability. If you can't test it, you can't trust it. |
| "TDD slows me down" | TDD slows you down today. Bugs, regressions, and fear of refactoring slow you down every day forever. |
| "Manual testing is faster" | Faster once. Slower across the lifetime of the project. Every manual test is debt you pay on every change. |
| "The existing code has no tests" | Then write a characterization test for the behavior you're about to change. You don't need 100% coverage to start. You need one failing test for the next change. |

---

## Red Flags — STOP and Start Over

If any of these are true, you have left the TDD path. Stop. Delete untested code. Write a failing test.

1. **You wrote production code before a test** — Delete it. No exceptions.
2. **You wrote a test after the implementation** — The test is untrustworthy. Delete both. Start with the test.
3. **A test passes immediately on first run** — You're not testing new behavior. Fix the test.
4. **You can't explain why a test failed** — You don't understand the system. Stop and investigate before writing code.
5. **You plan to write tests "later"** — Later never comes. Write the test now.
6. **You're thinking "just this once"** — That's the rationalization talking. Follow the process.
7. **You say "I already manually tested it"** — Manual tests are not tests. Write the automated test.
8. **You say "tests after serve the same purpose"** — They don't. Tests-after are biased by implementation.
9. **You invoke "spirit not ritual"** — The ritual exists because humans are bad at remembering the spirit. Follow the ritual.
10. **You want to "keep as reference"** — Reference becomes production. Delete it.
11. **You argue "I already spent X hours"** — Sunk cost. The hours are gone whether you keep the code or not.
12. **You say TDD is "dogmatic" not "pragmatic"** — TDD is the most pragmatic development practice that exists. It catches bugs before users do.
13. **You say "this is different because..."** — It's not different. Write the failing test first.

---

## Example: Bug Fix — Empty Email Accepted

**Reported bug:** The system accepts an empty string as a valid email address.

### RED

```typescript
test('rejects empty string as email address', () => {
  const result = validateEmail('');

  expect(result.valid).toBe(false);
  expect(result.error).toBe('Email address cannot be empty');
});
```

### Verify RED

```bash
$ npm test -- --grep "rejects empty string"

FAIL  validateEmail
  x rejects empty string as email address
    Expected: false
    Received: true
```

Confirmed: test fails. Fails because `validateEmail('')` currently returns `{ valid: true }`. The failure is for the right reason — the missing validation.

### GREEN

```typescript
function validateEmail(email: string): ValidationResult {
  if (email === '') {
    return { valid: false, error: 'Email address cannot be empty' };
  }
  // ... existing validation
}
```

Minimal. Just check for empty string. Don't add whitespace trimming, don't add null checks, don't refactor the whole function. Just make the test pass.

### Verify GREEN

```bash
$ npm test

PASS  validateEmail
  ✓ rejects empty string as email address
  ✓ accepts valid email address
  ✓ rejects email without @ symbol
  ... all other tests pass
```

All tests pass. No warnings. No regressions.

### REFACTOR

```typescript
function validateEmail(email: string): ValidationResult {
  if (!email) {
    return { valid: false, error: 'Email address cannot be empty' };
  }
  // ... existing validation
}
```

Small improvement: `!email` instead of `email === ''` to also handle `undefined`/`null` if the type system allows it. Tests still pass. Done.

---

## Verification Checklist

Before considering any feature, fix, or change complete, confirm:

- [ ] Every function/method has at least one test
- [ ] You watched each test fail before writing production code
- [ ] Each test failed for the expected reason (missing feature, not error/typo)
- [ ] Production code is minimal — only what the tests require
- [ ] All tests pass
- [ ] Test output is pristine (no warnings, no noise)
- [ ] Tests use real code, not mocks (unless external dependencies require it)
- [ ] Edge cases are covered (empty input, null, boundaries, error conditions)

Use `/verify` to confirm the full cycle was followed correctly.

---

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test it | Write the test as if the ideal API already exists. Let the test define the interface. The test is the first user of your code — design for that user. |
| Test is too complicated | The code under test is doing too much. Break it into smaller units. If you can't write a simple test, you can't write simple code. |
| Must mock everything | Too many dependencies. Refactor to reduce coupling. Inject dependencies. Use real implementations with test configurations. Mocks hide integration bugs. |
| Test setup is huge | The class/function has too many responsibilities. Extract smaller components. If setup requires 20 lines, the unit is too large. |

---

## Debugging Integration

When a bug is found:

1. **Write a failing test that reproduces the bug** — before touching any production code
2. **Verify the test fails** — confirm it captures the exact buggy behavior
3. **Enter the TDD cycle** — GREEN: fix the bug with minimal code, verify, then REFACTOR
4. **The test now prevents regression** — this bug can never silently return

**Never fix a bug without a test.** A bug fix without a test is a bug waiting to recur. The test is proof the bug existed, proof it's fixed, and a guardrail against regression.

---

## Testing Anti-Patterns

**Testing mock behavior instead of real behavior:**
If your assertions are on mock call counts, mock arguments, or mock return values, you're testing your test setup, not your code. Mocks should be the exception for true external boundaries (network, filesystem, hardware), not the default.

**Adding test-only methods to production classes:**
If you added a method like `_getInternalState()` or `exposeForTesting()` to make testing possible, your design is wrong. Test through the public API. If you can't, the public API is insufficient or the class is doing too much.

**Mocking without understanding dependencies:**
Every mock is an assumption about how a dependency behaves. If that assumption is wrong, your tests pass but your code is broken. Prefer real dependencies. When you must mock, verify your mock matches reality.

---

## Final Rule

```
Production code exists → a test exists that failed first.
Otherwise → it's not TDD.
```

No exceptions without explicit user permission. The test comes first. The failure comes first. The understanding comes first. Then — and only then — the code.
