<!-- v1.0 -->
# OWASP-Focused Security Code Review

Core principle: **Security is not optional, and it is not the same as code quality.**

`/security-review` performs a dedicated security audit against the OWASP Top 10. It is independent of `/review` (which focuses on code quality, architecture, and correctness). You can and should run both.

---

## When to Use

### Mandatory

- **Before deploying to production** — every release gets a security review
- **When handling user input** — forms, APIs, file uploads, query parameters
- **When touching auth/session logic** — login, token handling, permissions
- **When adding dependencies** — new packages can introduce known vulnerabilities
- **When handling sensitive data** — PII, credentials, payment info, health records

### Optional (But Strongly Encouraged)

- **After any refactor of security-sensitive code** — verify nothing was weakened
- **When integrating third-party services** — APIs, SDKs, webhooks
- **Periodic audit of existing code** — security degrades as contexts change

---

## OWASP Top 10 Reference Table

| #   | Category                                    | CWE References             | Description                                                              | What to Look For in Code                                                                                       |
|-----|---------------------------------------------|----------------------------|--------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------|
| A01 | Broken Access Control                       | CWE-200, CWE-284, CWE-639 | Users act outside intended permissions                                   | Missing auth checks on endpoints, IDOR (direct object references without ownership validation), privilege escalation paths, CORS misconfig |
| A02 | Cryptographic Failures                      | CWE-259, CWE-327, CWE-331 | Failures related to cryptography that lead to sensitive data exposure     | Hardcoded secrets, weak hashing (MD5/SHA1 for passwords), missing encryption at rest/transit, sensitive data in logs or error messages     |
| A03 | Injection                                   | CWE-79, CWE-89, CWE-78    | Untrusted data sent to an interpreter as part of a command or query      | String concatenation in SQL/commands, missing parameterized queries, unsanitized user input in shell commands, LDAP injection, XPath injection |
| A04 | Insecure Design                             | CWE-209, CWE-256, CWE-501 | Missing or ineffective security controls by design                       | No rate limiting, no account lockout, missing CSRF tokens, trust boundaries not enforced, no threat modeling                                |
| A05 | Security Misconfiguration                   | CWE-16, CWE-611           | Missing hardening, default configs, verbose errors, unnecessary features | Debug mode in production, default credentials, directory listing enabled, verbose stack traces, unnecessary HTTP methods, permissive CORS   |
| A06 | Vulnerable and Outdated Components          | CWE-1035                   | Using components with known vulnerabilities                              | Outdated dependencies, unpatched frameworks, no dependency scanning, using deprecated APIs                                                  |
| A07 | Identification and Authentication Failures  | CWE-287, CWE-384, CWE-798 | Weak authentication and session management                               | Weak password requirements, missing MFA, session fixation, token leakage in URLs, credentials in source code                                |
| A08 | Software and Data Integrity Failures        | CWE-345, CWE-502, CWE-829 | Code/infrastructure without integrity verification, insecure deser       | Deserialization of untrusted data, missing integrity checks on updates, CI/CD pipeline injection, unsigned artifacts                         |
| A09 | Security Logging and Monitoring Failures    | CWE-778                    | Insufficient logging, detection, monitoring, and active response         | No audit logs for auth events, no alerting on failures, sensitive data in logs, logs not tamper-proof                                        |
| A10 | Server-Side Request Forgery (SSRF)          | CWE-918                    | Fetching a remote resource without validating the user-supplied URL      | User-controlled URLs passed to HTTP clients, no allowlist for outbound requests, internal network access via SSRF                            |

---

## How to Run a Security Review

### Step 1: Identify Scope

Determine what code to review:

```bash
# For recent changes
BASE_SHA=$(git merge-base main HEAD)
HEAD_SHA=$(git rev-parse HEAD)

# For a specific PR
gh pr diff <PR_NUMBER>

# For a specific area
# Just identify the directories/files manually
```

### Step 2: Dispatch the Code-Reviewer Agent

Fill in the template below and dispatch the code-reviewer agent with the completed security context.

```
Dispatch the code-reviewer agent with this context:

## Security Review — OWASP Top 10 Audit

### Scope
{SCOPE_DESCRIPTION — what area, feature, or change is being reviewed}

### Git Range (if applicable)
Base: {BASE_SHA}
Head: {HEAD_SHA}

git diff --stat {BASE_SHA}..{HEAD_SHA}
git diff {BASE_SHA}..{HEAD_SHA}

### Files/Directories to Review (if no git range)
{LIST_OF_FILES_OR_DIRECTORIES}

### Review Instructions

You are performing a **security-focused code review** against the OWASP Top 10.
This is NOT a general code quality review. Focus exclusively on security.

For every file in scope, systematically check for:

**A01 — Broken Access Control (CWE-200, CWE-284, CWE-639):**
- Are all endpoints protected with appropriate auth checks?
- Can a user access or modify another user's data (IDOR)?
- Are role/permission checks enforced server-side, not just client-side?
- Is CORS configured restrictively?
- Are there any path traversal vulnerabilities?

**A02 — Cryptographic Failures (CWE-259, CWE-327, CWE-331):**
- Are secrets hardcoded anywhere (API keys, passwords, tokens)?
- Is password hashing using bcrypt/scrypt/argon2 (not MD5/SHA1)?
- Is sensitive data encrypted at rest and in transit?
- Are sensitive values logged or included in error responses?
- Are cryptographic keys of sufficient length?

**A03 — Injection (CWE-79, CWE-89, CWE-78):**
- Is user input used in SQL queries without parameterization?
- Is user input passed to shell commands without sanitization?
- Is user input interpolated into LDAP, XPath, or NoSQL queries?
- Is user input rendered in HTML without escaping (XSS)?
- Is user input used in file paths without validation?

**A04 — Insecure Design (CWE-209, CWE-256, CWE-501):**
- Is there rate limiting on sensitive endpoints (login, signup, password reset)?
- Are CSRF protections in place for state-changing operations?
- Are trust boundaries clearly defined and enforced?
- Is there account lockout after failed attempts?

**A05 — Security Misconfiguration (CWE-16, CWE-611):**
- Is debug mode disabled for production?
- Are default credentials changed?
- Are unnecessary features/endpoints/methods disabled?
- Are error messages generic (no stack traces to users)?
- Are security headers set (CSP, X-Frame-Options, HSTS)?

**A06 — Vulnerable and Outdated Components (CWE-1035):**
- Are there known vulnerabilities in dependencies?
- Are deprecated or unmaintained libraries used?
- Are dependency versions pinned?

**A07 — Identification and Authentication Failures (CWE-287, CWE-384, CWE-798):**
- Are sessions invalidated on logout?
- Are tokens transmitted securely (not in URLs or logs)?
- Are password requirements enforced?
- Is session fixation prevented?
- Are credentials stored securely (not in source code)?

**A08 — Software and Data Integrity Failures (CWE-345, CWE-502, CWE-829):**
- Is deserialization of untrusted data avoided or protected?
- Are file uploads validated (type, size, content)?
- Are CI/CD pipelines secured against injection?

**A09 — Security Logging and Monitoring Failures (CWE-778):**
- Are authentication events (login, failure, lockout) logged?
- Are authorization failures logged?
- Are logs free of sensitive data (passwords, tokens, PII)?
- Is there alerting for suspicious patterns?

**A10 — Server-Side Request Forgery (CWE-918):**
- Are user-supplied URLs validated against an allowlist?
- Are internal network addresses blocked in outbound requests?
- Is URL redirection validated?

### Output Format

If no security issues found:
**SECURE** — No security vulnerabilities identified in the reviewed scope.

If issues found:
**VULNERABILITIES FOUND**

For each finding, use this format:

#### [SEVERITY] — Short Description
- **OWASP Category:** A0X — Category Name
- **CWE:** CWE-XXX
- **File:** path/to/file.ext:LINE
- **Code:**
  ```
  <vulnerable code snippet>
  ```
- **Risk:** What can an attacker do? What is the impact?
- **Fix:**
  ```
  <corrected code snippet>
  ```

Group findings by severity: Critical, High, Medium, Low.

### Summary Table

| Severity | Count | Findings |
|----------|-------|----------|
| Critical |       |          |
| High     |       |          |
| Medium   |       |          |
| Low      |       |          |

### Assessment
**Secure enough to deploy?** [Yes / No / With fixes]
**Reasoning:** [1-2 sentences]
```

### Step 3: Act on Findings

| Severity     | Action                                                   |
|-------------|----------------------------------------------------------|
| **Critical** | Stop everything. Fix immediately. Re-review before proceeding. |
| **High**     | Fix before merge. No exceptions.                         |
| **Medium**   | Fix before merge if feasible. Otherwise, create a tracked issue with a deadline. |
| **Low**      | Track and fix in the next sprint. Do not ignore indefinitely. |

### Step 4: Re-Review (Max 3 Iterations)

After fixing findings, re-dispatch the reviewer with the updated code. Focus the re-review on:
- The specific findings from the previous round
- Any new code introduced by the fixes (fixes can introduce new vulnerabilities)

Repeat until the reviewer returns **SECURE** or you have completed 3 iterations. If issues persist after 3 iterations, escalate to a human security reviewer.

---

## Severity Classification Guide

### Critical

Directly exploitable. Immediate risk of data breach, system compromise, or unauthorized access.

- SQL injection with no parameterization on a public endpoint
- Hardcoded admin credentials in source code
- Authentication bypass (missing auth check on a sensitive endpoint)
- Remote code execution via unsanitized input to `eval` or shell commands
- Exposed secrets in client-side code or public repositories

### High

Exploitable with moderate effort. Significant risk if discovered by an attacker.

- Stored XSS in user-generated content
- IDOR allowing access to other users' data
- Insecure deserialization of user-controlled data
- Missing CSRF protection on state-changing operations
- Weak password hashing (MD5, SHA1, unsalted)

### Medium

Exploitable under specific conditions. Contributes to an attack chain.

- Reflected XSS requiring social engineering
- Verbose error messages leaking internal paths or versions
- Missing rate limiting on login endpoints
- Overly permissive CORS configuration
- Session tokens in URL parameters

### Low

Minor weakness. Unlikely to be exploited alone but indicates poor security posture.

- Missing security headers (CSP, X-Frame-Options)
- Autocomplete enabled on sensitive form fields
- Cookie missing Secure or HttpOnly flag
- Outdated dependencies without known exploits
- Insufficient logging of security events

---

## Language-Specific Vulnerability Patterns

### Python

```python
# BAD — SQL Injection (CWE-89)
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
cursor.execute("SELECT * FROM users WHERE id = " + user_id)
cursor.execute("SELECT * FROM users WHERE id = %s" % user_id)

# GOOD — Parameterized query
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))

# BAD — Command Injection (CWE-78)
os.system(f"convert {filename} output.png")
subprocess.call(f"ls {user_input}", shell=True)

# GOOD — No shell, list arguments
subprocess.run(["convert", filename, "output.png"], shell=False)

# BAD — Insecure Deserialization (CWE-502)
data = pickle.loads(user_supplied_bytes)
data = yaml.load(user_input)  # yaml.load is unsafe by default

# GOOD
data = json.loads(user_supplied_string)
data = yaml.safe_load(user_input)

# BAD — Path Traversal (CWE-22)
file_path = os.path.join("/uploads", user_filename)

# GOOD
file_path = os.path.join("/uploads", os.path.basename(user_filename))
```

### JavaScript / TypeScript

```javascript
// BAD — SQL Injection (CWE-89)
db.query(`SELECT * FROM users WHERE id = ${userId}`);
db.query("SELECT * FROM users WHERE id = " + userId);

// GOOD — Parameterized query
db.query("SELECT * FROM users WHERE id = $1", [userId]);

// BAD — XSS via innerHTML (CWE-79)
element.innerHTML = userInput;
document.write(userInput);

// GOOD
element.textContent = userInput;

// BAD — Prototype Pollution
const merged = Object.assign({}, JSON.parse(userInput));
// If userInput contains {"__proto__": {"admin": true}}

// GOOD — Validate or freeze prototype
const merged = Object.assign(Object.create(null), JSON.parse(userInput));

// BAD — eval / Function constructor (CWE-95)
eval(userInput);
new Function(userInput)();
setTimeout(userInput, 0);

// BAD — Open Redirect (CWE-601)
res.redirect(req.query.returnUrl);

// GOOD
const allowedHosts = ["example.com"];
const url = new URL(req.query.returnUrl, "https://example.com");
if (allowedHosts.includes(url.hostname)) res.redirect(url.toString());
```

### React / Vue

```jsx
// BAD — XSS in React (CWE-79)
<div dangerouslySetInnerHTML={{ __html: userInput }} />

// GOOD — React auto-escapes by default
<div>{userInput}</div>

// BAD — XSS in Vue
<div v-html="userInput"></div>

// GOOD
<div>{{ userInput }}</div>

// BAD — href with user input (javascript: protocol)
<a href={userInput}>Click</a>

// GOOD — validate protocol
const safeHref = userInput.startsWith("https://") ? userInput : "#";
<a href={safeHref}>Click</a>
```

### Go

```go
// BAD — SQL Injection (CWE-89)
db.Query("SELECT * FROM users WHERE id = " + userID)
db.Query(fmt.Sprintf("SELECT * FROM users WHERE id = %s", userID))

// GOOD — Parameterized query
db.Query("SELECT * FROM users WHERE id = $1", userID)

// BAD — Command Injection (CWE-78)
exec.Command("sh", "-c", "echo " + userInput).Run()

// GOOD
exec.Command("echo", userInput).Run()

// BAD — Path Traversal (CWE-22)
http.ServeFile(w, r, filepath.Join("./uploads", r.URL.Path))

// GOOD
cleanPath := filepath.Clean(r.URL.Path)
if strings.Contains(cleanPath, "..") {
    http.Error(w, "Forbidden", http.StatusForbidden)
    return
}

// BAD — SSRF (CWE-918)
resp, err := http.Get(userSuppliedURL)

// GOOD — validate against allowlist
parsedURL, _ := url.Parse(userSuppliedURL)
if !isAllowedHost(parsedURL.Hostname()) {
    return errors.New("host not allowed")
}
```

### SQL (Generic)

```sql
-- BAD — Dynamic SQL without parameterization
EXECUTE('SELECT * FROM users WHERE name = ''' + @username + '''')

-- GOOD — Parameterized
EXECUTE sp_executesql N'SELECT * FROM users WHERE name = @name',
    N'@name NVARCHAR(100)', @name = @username
```

---

## Red Flags and Common Mistakes

### Immediate Red Flags (Stop and Fix)

- `eval()`, `exec()`, `Function()` with user input
- SQL strings built via concatenation or interpolation
- `shell=True` in Python subprocess calls with user input
- Hardcoded API keys, passwords, tokens, or secrets anywhere in source
- `dangerouslySetInnerHTML` or `v-html` with unsanitized user content
- `pickle.loads()` or `yaml.load()` with untrusted data
- `fs.readFile(userInput)` or similar without path validation
- `http.Get(userInput)` or equivalent without URL validation
- Disabled CSRF protection
- JWT secret set to a weak or default value

### Common Mistakes

- **Checking auth client-side only** — always enforce server-side
- **Logging request bodies that contain passwords or tokens**
- **Returning full error stacks to the client** — use generic messages
- **Storing sessions in localStorage** — vulnerable to XSS; use httpOnly cookies
- **Using `Math.random()` for security tokens** — use `crypto.randomUUID()` or equivalent
- **Trusting HTTP headers** (`X-Forwarded-For`, `Referer`) without validation
- **Missing `Content-Type` validation** on file uploads — check magic bytes, not just extension
- **CORS with `Access-Control-Allow-Origin: *`** on authenticated endpoints
- **Not invalidating sessions on password change**
- **Using symmetric encryption (AES) where asymmetric (RSA/ECDSA) is needed**

---

## Integration with Other Commands

### Independent of /review

`/security-review` is a separate, focused audit. It does not replace `/review` and `/review` does not replace it. Run both:

- `/review` checks code quality, architecture, correctness, and tests
- `/security-review` checks for vulnerabilities against OWASP Top 10

There is no conflict in running them on the same code. They look for different things.

### With /implement

During `/implement`, consider running `/security-review` after tasks that touch:
- Authentication or authorization logic
- User input handling
- Database queries
- File operations
- External API integrations

### With /plan

When creating a plan with `/plan`, include security requirements in the plan itself. This makes security part of the design rather than an afterthought.

### With /verify

After fixing security findings, use `/verify` to confirm the fixes pass tests and do not break functionality before re-running `/security-review`.

---

## Example Workflow

```
1. You completed a feature that adds a user search API endpoint.

2. Get SHAs:
   BASE_SHA=$(git merge-base main HEAD)
   HEAD_SHA=$(git rev-parse HEAD)

3. Dispatch security reviewer with the template above, filling in:
   - Scope: "User search API endpoint — accepts query string, returns user records"
   - Git range: the SHAs

4. Reviewer returns:
   VULNERABILITIES FOUND

   #### [CRITICAL] — SQL Injection in user search
   - OWASP Category: A03 — Injection
   - CWE: CWE-89
   - File: src/api/users.ts:47
   - Code: db.query(`SELECT * FROM users WHERE name LIKE '%${query}%'`)
   - Risk: Attacker can extract entire database, modify data, or execute commands.
   - Fix: db.query("SELECT * FROM users WHERE name LIKE $1", [`%${query}%`])

   #### [HIGH] — IDOR in user profile endpoint
   - OWASP Category: A01 — Broken Access Control
   - CWE: CWE-639
   - File: src/api/users.ts:62
   - Code: const user = await getUser(req.params.id)
   - Risk: Any authenticated user can access any other user's profile by changing the ID.
   - Fix: Validate that req.user.id === req.params.id or req.user.role === "admin"

   #### [MEDIUM] — Verbose error response
   - OWASP Category: A05 — Security Misconfiguration
   - CWE: CWE-209
   - File: src/api/users.ts:78
   - Code: res.status(500).json({ error: err.stack })
   - Risk: Stack traces reveal internal paths, framework versions, and query structure.
   - Fix: res.status(500).json({ error: "Internal server error" })

   | Severity | Count | Findings        |
   |----------|-------|-----------------|
   | Critical | 1     | SQL Injection   |
   | High     | 1     | IDOR            |
   | Medium   | 1     | Verbose errors  |
   | Low      | 0     |                 |

   Secure enough to deploy? No
   Reasoning: Critical SQL injection must be fixed before any deployment.

5. Fix all three issues, commit, re-dispatch reviewer.

6. Reviewer returns: SECURE

7. Proceed with /review for code quality, then merge.
```
