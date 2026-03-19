<!-- v1.0 -->
# Dependency Audit for Security and License Risks

Core principle: **Your code is only as secure as your weakest dependency.**

Every dependency is an attack surface. Every transitive dependency is an attack surface you did not choose. Audit them.

---

## Step 1: Detect Package Manager

Scan the project root (and common subdirectories) for lock files. Use this table to identify the ecosystem:

| Package Manager | Lock File              | Manifest File        | Ecosystem |
|----------------|------------------------|----------------------|-----------|
| npm            | `package-lock.json`    | `package.json`       | Node.js   |
| yarn           | `yarn.lock`            | `package.json`       | Node.js   |
| pnpm           | `pnpm-lock.yaml`      | `package.json`       | Node.js   |
| pip            | `requirements.txt`     | `requirements.txt`   | Python    |
| pipenv         | `Pipfile.lock`         | `Pipfile`            | Python    |
| poetry         | `poetry.lock`          | `pyproject.toml`     | Python    |
| cargo          | `Cargo.lock`           | `Cargo.toml`         | Rust      |
| go mod         | `go.sum`               | `go.mod`             | Go        |
| composer       | `composer.lock`        | `composer.json`      | PHP       |
| bundler        | `Gemfile.lock`         | `Gemfile`            | Ruby      |
| maven          | (none — use pom.xml)   | `pom.xml`            | Java      |
| gradle         | `gradle.lockfile`      | `build.gradle`       | Java      |
| swift          | `Package.resolved`     | `Package.swift`      | Swift     |
| cocoapods      | `Podfile.lock`         | `Podfile`            | iOS       |
| nuget          | `packages.lock.json`   | `*.csproj`           | .NET      |

If multiple managers are detected (e.g., monorepo), audit each independently and merge findings.

---

## Step 2: Read Lock Files and Identify Dependencies

1. Read the lock file(s) found in Step 1.
2. Extract every dependency with its **exact pinned version**.
3. Note whether each dependency is direct (in the manifest) or transitive (only in the lock file).
4. Count total dependencies. A high count (>500 for Node, >200 for others) is itself a finding worth noting.

---

## Step 3: Check for Security Risks

For each dependency, evaluate the following:

### 3a: Known Vulnerability Patterns by Ecosystem

| Ecosystem | Common Vulnerability Patterns |
|-----------|-------------------------------|
| Node.js   | Prototype pollution, ReDoS in string/regex libs, arbitrary code execution in build scripts, `postinstall` script abuse |
| Python    | Pickle deserialization, YAML `load()` (not `safe_load`), command injection in subprocess wrappers, path traversal |
| Rust      | Unsafe blocks in "safe" abstractions, memory issues in FFI bindings, panics in `no_std` contexts |
| Go        | Goroutine leaks in HTTP clients, insecure TLS defaults in older libs, path traversal in archive extraction |
| PHP       | SQL injection in ORMs, deserialization attacks, file inclusion via autoloaders |
| Ruby      | Mass assignment, YAML deserialization (Psych), command injection via shell-outs |
| Java      | Log4Shell-style JNDI injection, XML external entity (XXE), deserialization gadget chains |
| .NET      | BinaryFormatter deserialization, SQL injection in raw queries, insecure XML parsing |

### 3b: Outdated and Deprecated Packages

Flag packages that are:
- **Multiple major versions behind** the latest (e.g., lodash 3.x when 4.x exists)
- **Deprecated or abandoned** — look for `deprecated` fields in lock files, packages with no updates in 2+ years
- **Pre-1.0** in production use — semver guarantees do not apply below 1.0

### 3c: Packages with Known Security Histories

Flag these high-profile packages and their forks/alternatives if found:
- `event-stream` (npm) — supply chain attack history
- `ua-parser-js` (npm) — hijacked versions
- `colors` / `faker` (npm) — maintainer sabotage
- `node-ipc` (npm) — protestware
- `PyPI` typosquats of `requests`, `urllib3`, `python-dateutil`
- Any package previously removed from a registry for malicious code

### 3d: Typosquatting Detection

Apply these heuristics to every dependency name:

| Heuristic | Example | Suspicion |
|-----------|---------|-----------|
| Single-character swap | `requets` vs `requests` | High |
| Hyphen/underscore confusion | `python_dateutil` vs `python-dateutil` | Medium |
| Scope/namespace squatting | `@user/react` vs `react` | High |
| Extra/missing prefix | `node-lodash` vs `lodash` | Medium |
| Homoglyph substitution | `c0lors` vs `colors` | High |
| Plural/singular confusion | `request` vs `requests` | Medium |

Compare each dependency name against the top 100 packages in its ecosystem. Flag any name within an edit distance of 1-2 from a popular package, unless it is itself a well-known package.

---

## Step 4: Flag License Incompatibilities

### 4a: Determine Project License

Read the project's `LICENSE` file or license field in the manifest. Classify it:

| Category | Licenses |
|----------|----------|
| Permissive | MIT, BSD-2-Clause, BSD-3-Clause, ISC, Apache-2.0, Unlicense, CC0-1.0, 0BSD |
| Weak copyleft | LGPL-2.1, LGPL-3.0, MPL-2.0, EPL-2.0 |
| Strong copyleft | GPL-2.0, GPL-3.0, AGPL-3.0 |
| Proprietary | No OSS license, custom license, "All rights reserved" |

### 4b: License Compatibility Matrix

The **project license** is on the left. A dependency with the listed license triggers the noted action.

| Project License → | Permissive Dep | LGPL Dep | GPL Dep | AGPL Dep | No License Dep |
|-------------------|---------------|----------|---------|----------|----------------|
| **Permissive**    | OK            | WARN     | BLOCK   | BLOCK    | BLOCK          |
| **LGPL**          | OK            | OK       | WARN    | BLOCK    | BLOCK          |
| **GPL**           | OK            | OK       | OK      | WARN     | BLOCK          |
| **AGPL**          | OK            | OK       | OK      | OK       | BLOCK          |
| **Proprietary**   | OK            | WARN     | BLOCK   | BLOCK    | BLOCK          |

- **OK** — no issue
- **WARN** — review usage; may be fine if dynamically linked or used as a tool only
- **BLOCK** — incompatible; must replace the dependency or change project license

### 4c: Missing License Declarations

Flag any dependency that:
- Has no `license` field in its manifest
- Has a `license` field set to `UNLICENSED`, `SEE LICENSE IN ...`, or a custom string
- Has no LICENSE/COPYING file in its package

Missing license means **all rights reserved** by default. Treat as BLOCK.

---

## Step 5: Produce Findings

For each finding, report:

```
[SEVERITY] package-name@version
  Category: security | license | outdated | typosquat | supply-chain
  Detail: <what was found>
  Action: <what to do>
```

### Severity Classification Guide

| Severity | Criteria | Response |
|----------|----------|----------|
| **CRITICAL** | Known exploited vulnerability, confirmed malicious package, typosquat match with edit distance 1 | Remove or patch immediately |
| **HIGH** | License BLOCK, deprecated package with known CVEs, abandoned package handling auth/crypto | Replace before shipping |
| **MEDIUM** | License WARN, package 2+ major versions behind, pre-1.0 in security-sensitive role | Plan replacement, track in backlog |
| **LOW** | Minor version behind, no license file but well-known package, high dependency count | Note for next maintenance cycle |

### Priority Order

Process and report findings in this order:
1. CRITICAL security findings
2. HIGH security findings
3. License incompatibilities (BLOCK first, then WARN)
4. Outdated packages with known issues
5. Informational notes (dependency count, ecosystem health)

---

## Step 6: Produce Final Output

### If no findings:

```
CLEAN — no dependency issues found.

Audited: <N> direct dependencies, <M> transitive dependencies
Package manager: <name>
Project license: <license>
```

### If findings exist:

```
ISSUES FOUND — <count> findings across <N> dependencies

## Critical
[findings]

## High
[findings]

## Medium
[findings]

## Low
[findings]

---
Summary: <X> critical, <Y> high, <Z> medium, <W> low
Audited: <N> direct, <M> transitive dependencies
Package manager: <name>
Project license: <license>
```

---

## Red Flags and Common Mistakes

- **Do not skip transitive dependencies.** The deepest transitive dep is the most likely attack vector.
- **Do not assume popular means safe.** `event-stream` had millions of weekly downloads when it was compromised.
- **Do not ignore "WARN" license findings.** LGPL in a statically linked binary is a violation.
- **Do not trust `latest` tags.** Always audit the exact pinned version in the lock file.
- **Do not skip audit because "it's an internal tool."** Internal tools get promoted to production. Dependencies stay.
- **Do not assume no lock file means no dependencies.** It means unpinned dependencies, which is worse — flag this as a CRITICAL finding.
- **Do not conflate "outdated" with "vulnerable."** Report them separately. Outdated is a risk factor, not a confirmed vulnerability.

---

## Integration with Other Commands

### /preflight
`/audit-deps` feeds directly into `/preflight`. When `/preflight` runs its pre-merge checks, it should invoke or reference the output of `/audit-deps`. Any CRITICAL or HIGH finding from `/audit-deps` is a `/preflight` blocker.

### /review
License and security findings from `/audit-deps` should inform `/review` when new dependencies are added. If a PR introduces a new dependency, `/audit-deps` findings for that package are review-relevant.

### /implement
During `/implement`, if a new dependency is added, run `/audit-deps` before proceeding to the next task. Catching a bad dependency mid-implementation is cheaper than catching it at merge time.

### Standalone Use
`/audit-deps` can be run at any time, independent of other workflows. Use it:
- Before starting a new project (audit the starter template)
- Periodically on long-running projects (monthly or quarterly)
- After any `npm install` / `pip install` / `cargo add` / equivalent
- During incident response to check if a newly disclosed vulnerability affects you
