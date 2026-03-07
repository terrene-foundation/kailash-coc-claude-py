# No Stubs, TODOs, or Simulated Data

## Scope

These rules apply to production code (non-test files).

## RECOMMENDED Rules

### 1. Avoid Stubs or Placeholders

Production code SHOULD NOT contain:

- `raise NotImplementedError` (implement the method)
- `pass # placeholder` or `pass # stub`
- `return None # not implemented`
- Empty function/method bodies that should have logic

**Note**: `TODO` and `FIXME` markers are acceptable during development but should be tracked and resolved before release.

### 2. Avoid Simulated or Fake Data

Production code SHOULD NOT contain:

- `simulated_data`, `fake_response`, `dummy_value`
- Hardcoded mock responses pretending to be real API calls
- `return {"status": "ok"}` as a placeholder for real logic
- Test fixtures masquerading as production defaults

### 3. Avoid Silent Fallbacks

Production code SHOULD NOT silently swallow errors:

- `except: pass` (bare except with pass)
- `catch(e) {}` (empty catch block)
- `except Exception: return None` without logging

**Acceptable**: `except: pass` in hooks/cleanup code where failure is expected.

### 4. Prefer Complete Implementation

When implementing a feature:

- Implement methods fully, not just the happy path
- If an endpoint exists, it should return real data
- If a service is referenced, it should be functional

**Note**: Iterative development is fine — incomplete implementations are acceptable when tracked as follow-up work.

## Why This Matters

Stubs and TODOs accumulate silently. Each one is a potential failure point:

- Users encounter `NotImplementedError` in production
- Silent fallbacks mask real bugs
- Simulated data gives false confidence in demos

## Exceptions

Test files (`test_*`, `*_test.*`, `*.test.*`, `*.spec.*`, `__tests__/`) are excluded.
