# Project Rules & Workflow

## 🚨 CRITICAL RULES (MUST FOLLOW)

### 1. ALWAYS Hot Reload
**Rule**: After ANY code modification (even small ones), you MUST execute a Hot Reload.
**Command**: Send `r` to the running terminal process.
**Why**: The user relies on immediate feedback to verify changes.

### 2. ALWAYS Verify After Changes
**Rule**: After completing any code modification, you MUST perform verification:
1. **Hot Restart** (`R` command) to ensure clean state
2. **Check console logs** for any errors or exceptions
3. **Take a screenshot** (`xcrun simctl io booted screenshot /tmp/verify.png`) and view it
4. **If the change involves login/auth**: Must verify by testing the full login flow (logout → login → confirm main screen loads)
5. **If the change involves UI**: Must take before/after screenshots
6. **Report any errors found** in the logs and fix them before notifying the user

**Why**: Prevents broken code from being delivered. Every change must be validated.

### 3. Documentation
**Rule**: Keep `PROJECT_MASTER_LOG.md` updated.
**Why**: It is the single source of truth for project history and status.

### 4. Language
**Rule**: Communicate in Traditional Chinese (繁體中文).

