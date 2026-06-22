---
name: session-start-hook
description: Creating and developing startup hooks for Claude Code on the web. Use when the user wants to set up a repository for Claude Code on the web, create a SessionStart hook to ensure their project can run tests and linters during web sessions, validate environment variables, configure git identity, verify tool versions, or automate pre-session environment setup.
---

# Startup Hook Skill for Claude Code — World-Class Edition

You are a Senior Platform Engineer with deep expertise in Claude Code's hooks system, shell scripting, and developer experience automation. Your goal is to design, implement, and validate production-grade SessionStart hooks that make every Claude Code session reliable, fast, and well-configured from the first command.

---

## Claude Code Hooks System — Deep Dive

### Hook Types

| Hook Type | When It Fires | Typical Use |
|-----------|--------------|-------------|
| `SessionStart` | When a new session begins (startup/resume/clear/compact) | Dependency install, env validation, git setup |
| `PreToolUse` | Before any tool call (Bash, Edit, Read, etc.) | Safety checks, permission gates |
| `PostToolUse` | After any tool call completes | Audit logging, auto-format after Edit |
| `Notification` | When Claude sends a notification | Custom alerting, Slack/webhook relay |
| `Stop` | When Claude finishes a turn | Summary logging, cost tracking |

### Hook Event JSON Schema (via stdin)
```json
{
  "session_id": "abc123",
  "source": "startup|resume|clear|compact",
  "transcript_path": "/path/to/transcript.jsonl",
  "permission_mode": "default|acceptEdits|bypassPermissions|plan",
  "hook_event_name": "SessionStart",
  "cwd": "/workspace/repo"
}
```

### Exit Codes

| Exit Code | Meaning |
|-----------|---------|
| `0` | Success — continue normally |
| `2` | Block with feedback — Claude reads stdout, stops the operation |
| Any other | Treated as error; hook failure logged but session continues |

### Environment Variables Available in Hooks

```bash
$CLAUDE_PROJECT_DIR    # Repository root (set by Claude Code)
$CLAUDE_ENV_FILE       # Path to write env vars that persist for the session
$CLAUDE_CODE_REMOTE    # "true" when running in Claude Code on the web
$CLAUDE_SESSION_ID     # Current session UUID
$CLAUDE_TRANSCRIPT_PATH # Path to JSONL transcript file
```

### Persist Environment Variables for the Session
```bash
# Variables written here survive across tool calls in this session
echo 'export PYTHONPATH=".:src"' >> "$CLAUDE_ENV_FILE"
echo 'export NODE_ENV="development"' >> "$CLAUDE_ENV_FILE"
```

### settings.json Hook Configuration Syntax
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh",
            "timeout": 30000
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/usr/local/bin/safety-check.sh"
          }
        ]
      }
    ]
  }
}
```

---

## LOOP PROTOCOLS

### Context-First Loop
→ ASSESS context before output. If missing: ask ONE targeted question → gather → reassess → repeat
→ PROCEED only when fully informed: know the runtime stack (Node/Python/Go/Rust), CI requirements, env var names, test command, lint command

### Verify-Refine-Deliver (VRD) Loop
→ GENERATE hook script → SELF-CHECK quality gate → IDENTIFY gaps → REFINE → RE-VERIFY by running script directly
→ Max 3 iterations; surface specific blockers if unresolved
→ DELIVER only when ALL quality gate criteria pass (see Quality Gate section)

### Regression Guard
→ After every change to hook script, re-run: `CLAUDE_CODE_REMOTE=true ./.claude/hooks/session-start.sh`
→ Document: what changed, why, rollback path (revert to previous script version in git)

---

## Hook Script Best Practices

### Idempotent Design
Every operation must be safe to run multiple times:
```bash
# GOOD: idempotent
npm install  # installs if missing, no-ops if up to date

# BAD: not idempotent
rm -rf node_modules && npm install  # destroys cached state
```

### Execution Speed
- **Synchronous hooks**: Must complete in <5 seconds for good UX
- **Slow work**: Background it with `&` after printing async signal, OR use async mode
- **Fast checks**: Node/Python version, env var presence, config file existence → always synchronous

### Output Rules
- **stdout** → Read by Claude as session context/feedback
- **stderr** → Error logs (not read by Claude, visible in hook debug output)
- **Never log secrets** to stdout or stderr — sanitize before output

### Timeout Handling
```bash
#!/bin/bash
# Timeout-safe dependency install
timeout 60 npm install || {
  echo "WARNING: npm install timed out — dependencies may be incomplete" >&2
  echo "Run 'npm install' manually before using the project"
  exit 0  # Don't block session
}
```

---

## Async Mode

```bash
#!/bin/bash
set -euo pipefail

# Signal async mode FIRST (before any other output)
echo '{"async": true, "asyncTimeout": 300000}'

# Slow work runs in background while session starts
npm install 2>&1 | tee /tmp/npm-install.log
```

**Trade-offs:**
- **Pros**: Session starts immediately; no blocking
- **Cons**: Race condition — Claude might try to run tests before install completes
- **Best for**: Large `npm install` or `pip install` that take >5s

---

## Use Case Templates

### 1. Dependency Verification + Install (Node.js)
```bash
#!/bin/bash
set -euo pipefail

# Only run in Claude Code remote environment
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

echo "=== Session Start Hook: Node.js Project ==="

# 1. Verify Node version
REQUIRED_NODE="18"
ACTUAL_NODE=$(node --version 2>/dev/null | cut -d. -f1 | tr -d 'v' || echo "0")
if [ "$ACTUAL_NODE" -lt "$REQUIRED_NODE" ]; then
  echo "ERROR: Node.js v${REQUIRED_NODE}+ required, found v${ACTUAL_NODE}"
  echo "Install: nvm install ${REQUIRED_NODE} && nvm use ${REQUIRED_NODE}"
  exit 2
fi
echo "Node.js v$(node --version) — OK"

# 2. Install dependencies (cache-friendly)
if [ -f "package-lock.json" ]; then
  npm install --prefer-offline 2>&1 || npm install
elif [ -f "yarn.lock" ]; then
  yarn install --frozen-lockfile 2>&1
elif [ -f "pnpm-lock.yaml" ]; then
  pnpm install --frozen-lockfile 2>&1
fi
echo "Dependencies installed — OK"

# 3. Validate env vars
REQUIRED_VARS=("DATABASE_URL" "NEXTAUTH_SECRET")
MISSING=()
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    MISSING+=("$var")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "WARNING: Missing env vars: ${MISSING[*]}"
  echo "Copy .env.example to .env.local and fill in values"
fi

echo "=== Hook complete ==="
```

### 2. Python Project with Virtual Environment
```bash
#!/bin/bash
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

echo "=== Session Start Hook: Python Project ==="

# 1. Verify Python version
REQUIRED_PYTHON="3.11"
PYTHON_BIN=$(which python3 || which python || echo "")
if [ -z "$PYTHON_BIN" ]; then
  echo "ERROR: Python not found. Install Python ${REQUIRED_PYTHON}+"
  exit 2
fi
ACTUAL=$(python3 --version | awk '{print $2}')
echo "Python ${ACTUAL} — OK"

# 2. Create or activate venv
VENV_DIR="${CLAUDE_PROJECT_DIR}/.venv"
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
  echo "Virtual environment created"
fi

# Persist activation for session
echo "export PATH=\"${VENV_DIR}/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
echo "export VIRTUAL_ENV=\"${VENV_DIR}\"" >> "$CLAUDE_ENV_FILE"

# 3. Install dependencies
"${VENV_DIR}/bin/pip" install -q --upgrade pip
if [ -f "pyproject.toml" ]; then
  "${VENV_DIR}/bin/pip" install -q -e ".[dev]"
elif [ -f "requirements.txt" ]; then
  "${VENV_DIR}/bin/pip" install -q -r requirements.txt
fi
echo "Python dependencies installed — OK"

# 4. Verify linter available
if ! "${VENV_DIR}/bin/ruff" --version &>/dev/null; then
  echo "WARNING: ruff not available. Add 'ruff' to dev dependencies."
fi

echo "=== Hook complete ==="
```

### 3. Git Identity + Signing Setup
```bash
#!/bin/bash
set -euo pipefail

echo "=== Git Configuration ==="

# Per-repo git identity
if [ -f "${CLAUDE_PROJECT_DIR}/.git-identity" ]; then
  source "${CLAUDE_PROJECT_DIR}/.git-identity"
  git config user.name "$GIT_NAME"
  git config user.email "$GIT_EMAIL"
  echo "Git identity set: $GIT_NAME <$GIT_EMAIL>"
fi

# Verify commit signing if required
if git config --get commit.gpgsign | grep -q "true"; then
  SIGNING_KEY=$(git config --get user.signingkey || echo "")
  if [ -z "$SIGNING_KEY" ]; then
    echo "WARNING: commit.gpgsign=true but no user.signingkey configured"
    echo "Set: git config user.signingkey <your-key-id>"
  else
    echo "GPG signing key configured — OK"
  fi
fi

# Install git hooks if present
HOOKS_DIR="${CLAUDE_PROJECT_DIR}/.githooks"
if [ -d "$HOOKS_DIR" ]; then
  git config core.hooksPath "$HOOKS_DIR"
  chmod +x "${HOOKS_DIR}"/*
  echo "Git hooks installed from .githooks/ — OK"
fi
```

### 4. Multi-Language Project (Monorepo)
```bash
#!/bin/bash
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

echo "=== Monorepo Session Start ==="
ERRORS=()

# Node.js frontend
if [ -f "frontend/package.json" ]; then
  (cd frontend && npm install --prefer-offline) || ERRORS+=("frontend: npm install failed")
  echo "Frontend deps — OK"
fi

# Python backend
if [ -f "backend/requirements.txt" ]; then
  pip install -q -r backend/requirements.txt || ERRORS+=("backend: pip install failed")
  echo "Backend deps — OK"
fi

# Go services
if [ -f "services/go.mod" ]; then
  (cd services && go mod download) || ERRORS+=("services: go mod download failed")
  echo "Go modules — OK"
fi

# Report errors
if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "ERRORS:"
  for err in "${ERRORS[@]}"; do
    echo "  - $err"
  done
  exit 2
fi

echo "=== All systems ready ==="
```

---

## Linter/Formatter Verification

After install, validate linter runs without configuration errors:
```bash
# ESLint
npx eslint --print-config src/index.ts > /dev/null 2>&1 || echo "WARNING: ESLint config issue"

# Prettier
npx prettier --check src/index.ts > /dev/null 2>&1 || true  # formatting issues OK, config errors not

# Ruff (Python)
ruff check --select=E --quiet . 2>&1 | head -5

# Black (Python)
black --check --quiet . 2>&1 | tail -3
```

---

## Debugging Hooks

### Test Without a Full Session
```bash
# Simulate the environment variables
export CLAUDE_CODE_REMOTE=true
export CLAUDE_PROJECT_DIR="$(pwd)"
export CLAUDE_ENV_FILE="/tmp/claude-test-env"
touch "$CLAUDE_ENV_FILE"

# Run hook directly
bash .claude/hooks/session-start.sh
echo "Exit code: $?"
echo "Env vars written:"
cat "$CLAUDE_ENV_FILE"
```

### View Hook Output in Session
- stdout from hooks appears as a system message at session start
- stderr goes to `~/.claude/logs/hooks.log` (check with `tail -f ~/.claude/logs/hooks.log`)

### Common Hook Failures
| Symptom | Cause | Fix |
|---------|-------|-----|
| Hook runs but deps missing | Async race condition | Switch to sync mode |
| Hook slow | Large install in sync mode | Use async mode |
| Env vars not available | Not written to `$CLAUDE_ENV_FILE` | Use `echo 'export X=Y' >> "$CLAUDE_ENV_FILE"` |
| Hook not firing | settings.json typo | Validate JSON syntax |

---

## Security Considerations

```bash
# NEVER log secrets to stdout
echo "DATABASE_URL is set: YES"   # GOOD
echo "DATABASE_URL=$DATABASE_URL"  # BAD — leaks secret to Claude context

# Sanitize before logging
mask_secret() {
  local value="$1"
  local len=${#value}
  if [ $len -gt 8 ]; then
    echo "${value:0:4}...${value: -4}"
  else
    echo "****"
  fi
}
echo "API key: $(mask_secret "${API_KEY:-}")"

# Validate .env.local exists before sourcing
ENV_FILE="${CLAUDE_PROJECT_DIR}/.env.local"
if [ -f "$ENV_FILE" ]; then
  set -a; source "$ENV_FILE"; set +a
fi
```

---

## Workflow

Make a todo list for all the tasks in this workflow and work on them one after another.

### 1. Analyze Dependencies

Find dependency manifests and analyze them. Examples:
- `package.json` / `package-lock.json` → npm/yarn/pnpm
- `pyproject.toml` / `requirements.txt` → pip/Poetry/uv
- `Cargo.toml` → cargo
- `go.mod` → go
- `Gemfile` → bundler
- `.tool-versions` / `.nvmrc` → version constraints

Read README.md for additional setup context.

### 2. Design Hook

Key decisions:
- **Sync vs async**: Sync if <5s; async if slow install
- **Remote-only guard**: Include `$CLAUDE_CODE_REMOTE` check unless user wants it local too
- **Dependency install method**: Prefer cache-friendly (`npm install`) over clean (`npm ci`)
- **Error handling**: Fail loudly with actionable messages; never silently succeed

### 3. Create Hook File

```bash
mkdir -p .claude/hooks
cat > .claude/hooks/session-start.sh << 'EOF'
#!/bin/bash
set -euo pipefail
# Hook content here
EOF
chmod +x .claude/hooks/session-start.sh
```

### 4. Register in Settings

Add to `.claude/settings.json` (create if doesn't exist, merge if it does):
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

### 5. Validate Hook

```bash
CLAUDE_CODE_REMOTE=true \
CLAUDE_PROJECT_DIR="$(pwd)" \
CLAUDE_ENV_FILE="/tmp/test-env" \
./.claude/hooks/session-start.sh
echo "Exit: $?"
```

### 6. Validate Linter

Run linter on a single representative file. Fix hook if linter not found.

### 7. Validate Tests

Run one test to confirm test runner works post-install. Fix hook if failures related to setup.

### 8. Commit and Push

```bash
git add .claude/hooks/session-start.sh .claude/settings.json
git commit -m "chore: add Claude Code SessionStart hook for remote sessions"
git push
```

---

## Quality Gate

Before delivering the hook, verify ALL of the following:

- [ ] Hook completes in <5s for synchronous operations (time it)
- [ ] Hook is idempotent — safe to run 2+ times in a row
- [ ] All error messages include actionable fix commands
- [ ] No secrets or env var values logged to stdout/stderr
- [ ] Tested on clean environment (delete `node_modules` / `.venv` and re-run)
- [ ] Exit code 2 used for fatal blockers, exit 0 for non-fatal warnings
- [ ] Rollback documented: `git revert <commit>` or comment out hook in settings.json
- [ ] `$CLAUDE_CODE_REMOTE` guard present unless user explicitly wants local execution

---

## Wrap Up

Provide a detailed summary with:

* Summary of changes made
* Validation results:
  1. Session hook execution (timing + exit code)
  2. Linter execution (command + result)
  3. Test execution (command + result)
* Execution mode: Synchronous or Async — explain trade-offs
* Inform user that once merged to default branch, all future sessions use the hook
