---
description: Scan codebase for leaked credentials, API keys, and tokens
---
<!-- v1.0 -->
# Scan for Leaked Secrets

> I'm using /ag-scan-secrets to check for credentials before they reach git.

**Overview:** Scan the working directory for leaked credentials, API keys, tokens, private keys, and other secrets. Flag findings by severity, and hard-gate on definite leaks.

---

## Step 1: Define Detection Patterns

Use the following pattern reference table to guide scanning. Do not shell out to external tools — inspect file contents directly using your read capabilities.

### Pattern Reference Table

| Secret Type | Pattern Description | Confidence | Example (Masked) |
|---|---|---|---|
| **AWS Access Key** | Starts with `AKIA` followed by 16 alphanumeric chars | Definite | `AKIA************XMPL` |
| **AWS Secret Key** | 40-char base64 string near AWS context | Likely | `wJalr***************************XMPL` |
| **GCP Service Account Key** | JSON with `type: service_account` and `private_key` | Definite | `{"type":"service_account","private_key":"-----BEGIN..."}` |
| **GCP API Key** | Starts with `AIza` followed by 35 chars | Definite | `AIza********************************Xmpl` |
| **Azure Storage Key** | 88-char base64 string in Azure config context | Likely | `DefaultEndpointsProtocol=https;AccountKey=abc12...==` |
| **Azure Client Secret** | GUID-like value assigned to client_secret | Likely | `client_secret = "a1b2c3d4-****-****-****-e5f6g7h8i9j0"` |
| **Stripe Secret Key** | Starts with `sk_live_` or `rk_live_` | Definite | `sk_live_****************************Xmpl` |
| **Stripe Publishable Key** | Starts with `pk_live_` | Possible | `pk_live_****************************Xmpl` |
| **GitHub PAT** | Starts with `ghp_`, `gho_`, `ghu_`, `ghs_`, or `ghr_` | Definite | `ghp_************************************` |
| **GitHub OAuth** | Starts with `gho_` | Definite | `gho_************************************` |
| **GitLab PAT** | Starts with `glpat-` | Definite | `glpat-********************` |
| **JWT Token** | `eyJ` followed by base64 with two dots (three segments) | Likely | `eyJhbGciOi***.eyJzdWIiOi***.SflKxw***` |
| **OAuth Bearer Token** | `Bearer ` followed by long alphanumeric/base64 string | Likely | `Bearer eyJhbGciOi***...` |
| **RSA Private Key** | `-----BEGIN RSA PRIVATE KEY-----` | Definite | `-----BEGIN RSA PRIVATE KEY-----\nMIIEow...` |
| **EC Private Key** | `-----BEGIN EC PRIVATE KEY-----` | Definite | `-----BEGIN EC PRIVATE KEY-----\nMHQCAQ...` |
| **Ed25519 Private Key** | `-----BEGIN OPENSSH PRIVATE KEY-----` with ed25519 context | Definite | `-----BEGIN OPENSSH PRIVATE KEY-----\nb3Blbn...` |
| **Generic Private Key** | `-----BEGIN PRIVATE KEY-----` | Definite | `-----BEGIN PRIVATE KEY-----\nMIIEvg...` |
| **Database URL** | `postgres://`, `mysql://`, `mongodb://`, `mongodb+srv://` with password segment | Definite | `postgres://user:p***@host:5432/db` |
| **Redis URL** | `redis://` with password segment | Definite | `redis://:s3cr3t***@host:6379` |
| **AMQP URL** | `amqp://` or `amqps://` with password segment | Definite | `amqp://user:p***@host:5672` |
| **Slack Token** | Starts with `xoxb-`, `xoxp-`, `xoxo-`, or `xoxa-` | Definite | `xoxb-****-****-************` |
| **Slack Webhook** | `https://hooks.slack.com/services/T` followed by path segments | Definite | `https://hooks.slack.com/services/T***/B***/***` |
| **Twilio API Key** | Starts with `SK` followed by 32 hex chars | Likely | `SK********************************` |
| **SendGrid API Key** | Starts with `SG.` | Definite | `SG.****************************.***` |
| **Mailgun API Key** | Starts with `key-` in Mailgun context | Likely | `key-****************************` |
| **NPM Token** | Starts with `npm_` or matches `//registry.npmjs.org/:_authToken=` | Definite | `npm_************************************` |
| **PyPI Token** | Starts with `pypi-` | Definite | `pypi-************************************` |
| **Heroku API Key** | 32-char hex in Heroku context | Likely | `HEROKU_API_KEY=a1b2c3d4************************` |
| **DigitalOcean PAT** | Starts with `dop_v1_` | Definite | `dop_v1_************************************` |
| **OpenAI API Key** | Starts with `sk-` followed by 48+ chars | Likely | `sk-************************************************` |
| **Password in Config** | Keys like `password`, `passwd`, `secret`, `api_key` assigned a literal value | Likely | `DB_PASSWORD="s3cr3t***"` |
| **Hardcoded Secret in Source** | String assigned to variable named `secret`, `token`, `apiKey`, `api_key`, `password` | Possible | `const apiKey = "abc123***"` |
| **`.env` file present** | Any `.env`, `.env.local`, `.env.production` file tracked or staged | Likely | `.env` containing `KEY=value` pairs |

---

## Step 2: Scan Files

### Priority Order

1. **Staged files first** — run `git diff --cached --name-only` to get the list of files about to be committed. These are the highest priority since they are one commit away from the repository.
2. **All tracked files** — run `git ls-files` to get every tracked file. Scan these second.
3. **Untracked `.env` and config files** — check for `.env*`, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `credentials.*`, `secrets.*` files that exist but are not yet tracked.

### What to Scan

- All source files (`.js`, `.ts`, `.py`, `.go`, `.java`, `.rb`, `.rs`, `.cs`, `.php`, `.sh`, `.bash`, etc.)
- Configuration files (`.json`, `.yaml`, `.yml`, `.toml`, `.ini`, `.xml`, `.conf`, `.cfg`, `.properties`)
- Environment files (`.env`, `.env.*`)
- Docker files (`Dockerfile`, `docker-compose*.yml`)
- CI/CD files (`.github/workflows/*`, `.gitlab-ci.yml`, `Jenkinsfile`, `.circleci/*`)
- Documentation (`.md`, `.txt`, `.rst`) — secrets in docs are still secrets
- Test fixtures and seed data

### How to Scan

For each file, read its contents and check against every pattern in the reference table. Record:

- **File path** (relative to repo root)
- **Line number**
- **Secret type** (from the table)
- **Confidence level** (Definite / Likely / Possible)
- **Masked preview** — show enough context to identify the finding, but mask the actual secret value. Never print a full secret.

---

## Step 3: Filter False Positives

### What NOT to Flag

Do not flag the following — they are not real secrets:

| Pattern | Reason |
|---|---|
| `AKIAIOSFODNN7EXAMPLE` | AWS's published example key |
| `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` | AWS's published example secret |
| `example.com`, `localhost`, `127.0.0.1` URLs with passwords | Test/dev fixtures |
| `password123`, `changeme`, `secret`, `test`, `TODO`, `xxx`, `yyy`, `zzz` as values | Obvious placeholders |
| `sk_test_`, `pk_test_`, `rk_test_` prefixed Stripe keys | Stripe test-mode keys (not production) |
| `your-api-key-here`, `INSERT_KEY_HERE`, `<your-key>`, `${VAR}`, `$(VAR)` | Placeholder templates |
| Values that are all one repeated character (`aaaa`, `0000`, `xxxx`) | Dummy values |
| Keys in comments that reference documentation or examples | Instructional, not leaked |
| Strings shorter than 8 characters assigned to secret-like variable names | Too short to be real secrets |
| Environment variable references (`process.env.X`, `os.environ["X"]`, `ENV["X"]`) | Reading from env, not hardcoding |
| Base64 of clearly fake data | Test fixtures |

**Rule of thumb:** If a human reviewer would immediately say "that's obviously fake," do not flag it.

---

## Step 4: Report Findings

### If No Secrets Found

```
CLEAN — no secrets detected.

Scanned: <N> staged files, <M> tracked files.
Checked against <P> secret patterns.
```

### If Secrets Found

```
SECRETS FOUND — <count> finding(s) across <file_count> file(s).

## Definite (must fix before commit)

| # | File:Line | Type | Preview |
|---|-----------|------|---------|
| 1 | src/config.ts:42 | AWS Access Key | `AKIA************XMPL` |
| 2 | .env:3 | Database URL | `postgres://user:p***@prod-host:5432/db` |

## Likely (strongly recommended to fix)

| # | File:Line | Type | Preview |
|---|-----------|------|---------|
| 3 | lib/auth.py:87 | JWT Token | `eyJhbGciOi***.eyJ...` |

## Possible (review manually)

| # | File:Line | Type | Preview |
|---|-----------|------|---------|
| 4 | test/helpers.js:12 | Hardcoded Secret | `const apiKey = "abc1***"` |
```

---

## Step 5: Recommend Actions

For each finding, recommend one or more of:

| Action | When |
|---|---|
| **Rotate the secret immediately** | Secret was committed to history, even if removed in a later commit |
| **Remove from source and add to `.gitignore`** | File like `.env` should never be tracked |
| **Move to environment variables** | Hardcoded value in source code |
| **Use a secrets manager** | Production secrets (Vault, AWS Secrets Manager, GCP Secret Manager, Azure Key Vault, 1Password, Doppler) |
| **Replace with test/mock values** | Secret in test fixture that could use a fake instead |
| **Remove from git history** | Secret already committed — use `git filter-repo` or BFG Repo-Cleaner, then rotate |

---

## Red Flags and Common Mistakes

Watch for these especially dangerous patterns:

1. **`.env` files committed to the repository** — the single most common secret leak. Check both staged and tracked files.
2. **Private keys in the repo** — `*.pem`, `*.key`, `*.p12`, `*.pfx` files. These should never be version-controlled.
3. **Secrets in CI/CD config** — GitHub Actions workflows, Jenkinsfiles, and CI configs should use secret variables, not inline values.
4. **Copy-pasted cURL commands** — developers paste cURL commands with `Authorization: Bearer <real-token>` into code or docs.
5. **Config files with production credentials** — `application.yml`, `config.json`, `settings.py` with real database passwords.
6. **Secrets in comments** — "temporarily" pasted for debugging and forgotten.
7. **Docker Compose with hardcoded passwords** — `POSTGRES_PASSWORD=realpassword` in `docker-compose.yml`.
8. **Terraform state or tfvars with secrets** — `terraform.tfstate` and `*.tfvars` often contain real values.
9. **Jupyter notebooks with output cells** — API responses in cell output may contain tokens.
10. **Package lock files with private registry tokens** — `.npmrc`, `.yarnrc`, `pip.conf` with auth tokens.

---

## Hard Gate

```
IF findings with confidence == "Definite":
    REFUSE to proceed.
    State: "Definite secrets detected. These must be resolved before committing."
    List each definite finding with its recommended action.
    Do NOT continue to commit, push, or any downstream command.
```

This gate cannot be overridden by the user within this command. The secrets must be removed or confirmed false positives with an explanation.

---

## Integration Notes

- **Feeds into `/ag-preflight`** — the `/ag-preflight` command should invoke `/ag-scan-secrets` as one of its checks. A `SECRETS FOUND` result with any Definite findings fails the preflight gate.
- **Can be run standalone** — use `/ag-scan-secrets` at any time to audit the current state of the working directory.
- **Pairs with `/ag-finish`** — run before finalizing a branch to ensure no secrets ship.
- **After rotation** — if a secret was already committed, remind the user that removing it from HEAD is not enough. The secret exists in git history and must be scrubbed with `git filter-repo` or BFG, and the credential must be rotated.
