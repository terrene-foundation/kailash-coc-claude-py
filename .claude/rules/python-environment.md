---
paths:
  - "**/*.py"
  - "pyproject.toml"
  - "conftest.py"
  - "tests/**"
---

# Python Environment Isolation Rules

## Scope

These rules apply to ALL Python projects. Every project MUST use an isolated virtual environment. Using the system or global Python is BLOCKED.

## MUST Rules

### 1. Project Virtual Environment Required

Every Python project MUST have a `.venv` directory at the project root, created and managed by `uv`.

```bash
# DO: First thing in any new project or after clone
uv venv
uv sync

# DO NOT:
pip install -e .          # Installs into global Python
python -m pytest tests/   # Runs with global Python
pytest                    # Uses whatever Python is on PATH
```

**Why**: Global Python accumulates conflicting dependencies across projects. A test passing with global Python may fail in CI (clean environment) or on another machine. Virtual environments are the only reliable way to ensure reproducible builds and test results.

### 2. Use `uv` for Environment Management

`uv` is the standard tool for virtual environment creation and dependency resolution. Do NOT use `pip`, `pip-tools`, `poetry`, or `conda` for dependency management.

```bash
# DO:
uv venv                   # Create .venv
uv sync                   # Install all dependencies from pyproject.toml + uv.lock
uv pip install foo        # Add a dependency via uv (if needed ad-hoc)
uv run pytest tests/      # Run commands in the venv

# DO NOT:
python -m venv .venv      # Use uv venv instead (faster, more reliable)
pip install -r requirements.txt  # Use uv sync instead
pip install -e ".[dev]"   # Use uv sync instead
```

**Why**: `uv` is 10-100x faster than pip, resolves dependencies correctly, and produces a lockfile (`uv.lock`) for reproducible installs. It is the modern standard (2024+).

### 3. Always Activate or Use `uv run`

Before running any Python command (pytest, python, scripts), either activate the venv or use `uv run`.

```bash
# Option A: Activate
source .venv/bin/activate
pytest tests/ -x

# Option B: uv run (preferred — no activation needed)
uv run pytest tests/ -x
uv run python scripts/migrate.py

# DO NOT:
pytest tests/             # Which Python? Which packages? Unknown.
python -c "import kailash"  # Global Python — wrong environment
```

**Why**: Running without activation uses the global Python interpreter, which may have different package versions, missing dependencies, or conflicting installs.

### 4. Verify Environment Before Testing

Before running any test suite, verify you are in the project's virtual environment.

```bash
# Quick check
which python    # Should show .venv/bin/python, NOT /usr/bin/python or pyenv shim
python -c "import sys; print(sys.prefix)"  # Should contain .venv

# If wrong:
uv venv && uv sync  # Fix it
```

**Why**: Tests running against the wrong environment produce unreliable results. A passing test in global Python means nothing if CI uses an isolated environment.

### 5. `.venv` in `.gitignore`

The `.venv` directory MUST be in `.gitignore`. Virtual environments are not committed.

```gitignore
# DO:
.venv/
```

**Why**: Virtual environments are machine-specific (platform, Python version, compiled extensions). They must be recreated per-machine.

### 6. `uv.lock` in Version Control

The `uv.lock` file MUST be committed to version control for applications. For libraries (SDK packages), `uv.lock` may be gitignored.

**Why**: The lockfile ensures every developer and CI runner installs identical dependency versions. Without it, "works on my machine" failures are inevitable.

## Session Start Protocol

When starting a new session in any Python project:

```bash
# 1. Check for .venv
ls .venv/bin/python 2>/dev/null || echo "NO VENV — create one"

# 2. If missing, create it
uv venv
uv sync

# 3. If present, ensure it's current
uv sync  # Fast no-op if already synced
```

This should be automated by the session-start hook.

## MUST NOT Rules

### 1. No Global Python for Project Work

MUST NOT use the system Python (`/usr/bin/python3`), Homebrew Python (`/opt/homebrew/bin/python3`), or pyenv global shim for project testing or development.

### 2. No `pip install` in Project Context

MUST NOT use bare `pip install` in a project directory. Always use `uv sync` (from pyproject.toml) or `uv pip install` (if uv-managed venv).

**Why**: `pip install` in a project context may install into the global Python if the venv is not activated. `uv` always operates on the project's venv.

### 3. No Multiple Virtual Environments

MUST NOT maintain multiple `.venv` directories or alternative names (`.env`, `venv`, `.virtualenv`). One project, one `.venv`.

## Enforcement

- **session-start hook**: Check for `.venv/bin/python`. If missing, emit WARNING with instructions to run `uv venv && uv sync`.
- **validate-workflow hook**: Check `sys.prefix` contains `.venv` before running tests. BLOCK if using global Python.
- **CI**: All CI jobs create fresh `uv venv && uv sync` environments. No global Python.

## Cross-References

- `rules/testing.md` — Test execution rules (tests must run in isolated environment)
- `rules/env-models.md` — .env file rules (environment variables loaded after venv activation)
- `rules/patterns.md` — SDK execution patterns
