---
paths:
  - "tests/**"
  - "**/*test*"
  - "**/*spec*"
  - "conftest.py"
---

# Testing Rules

## Scope

These rules apply to all test files and test-related code.

## MUST Rules

### 0. Test-Once Protocol (MANDATORY)

Tests run ONCE per code change, not once per phase. This eliminates redundant test execution across `/implement`, `/redteam`, and pre-commit.

**The Protocol:**

1. `/implement` runs the full test suite ONCE per todo and writes `.test-results` to the workspace
2. `/redteam` READS `.test-results` — does NOT re-run existing tests
3. `/redteam` runs only NEW tests it creates (E2E user flows, Playwright, Marionette)
4. Pre-commit hooks (if configured) run unit tests as a fast safety net
5. CI runs the full matrix as the final gate

**`.test-results` artifact:**

Written to `workspaces/<project>/.test-results` after each `/implement` todo completion. Contains commit hash, pass/fail counts, and regression count. Red team and deploy phases read this file instead of re-running.

**Re-run exceptions:**

- Code changed since `.test-results` was written (commit hash mismatch)
- Infrastructure-specific tests needing real database verification
- Red team suspects a specific test is wrong (re-run THAT test only)

**Enforced by**: `/implement` and `/redteam` command templates
**Violation**: Wasted compute, context window bloat, slower iteration

### 0b. Regression Testing (MANDATORY)

Every bug fix MUST include a regression test BEFORE the fix is merged.

**The Rule:**

1. When a bug is found, the FIRST step is writing a test that REPRODUCES the bug
2. The test MUST fail before the fix and pass after
3. Regression tests go in the project's `tests/regression/` directory
4. The test name includes the issue number (e.g., `test_issue_42_user_creation_drops_pk`)
5. Regression tests are NEVER deleted — they are permanent guards

**Why:** Without regression tests, the same bugs keep coming back. A fix verified only by code review is not verified at all.

**Enforcement:**

- Pre-merge: regression test suite must pass
- Code review: reviewer verifies regression test exists for every bug fix
- Pre-release: regression suite is a mandatory checklist item

**Applies to**: All bug fixes
**Violation**: BLOCK merge — a fix without a regression test is not a fix

### 1. Test-First Development

Tests SHOULD be written before implementation for new features.

**Process**:

1. Write failing test that describes expected behavior
2. Implement minimum code to pass test
3. Refactor while keeping tests green

**Applies to**: New features, bug fixes

### 2. Coverage Requirements

Code changes SHOULD maintain or improve test coverage.

| Code Type         | Recommended Coverage |
| ----------------- | -------------------- |
| General           | 80%                  |
| Financial         | 100%                 |
| Authentication    | 100%                 |
| Security-critical | 100%                 |

### 3. Real Infrastructure in Tiers 2-3

Integration and E2E tests SHOULD use real infrastructure where practical.

**Tier 1 (Unit Tests)**:

- Mocking allowed
- Test isolated functions
- Fast execution (<1s per test)

**Tier 2 (Integration Tests)**:

- Real infrastructure recommended (real database, real API calls)
- Mocking is permitted when real infrastructure is impractical
- Test component interactions

**Tier 3 (E2E Tests)**:

- Real infrastructure recommended
- Test full user journeys
- Real browser, real database preferred

## Best Practices

### 1. Prefer Real Infrastructure

Mocking is permitted at all tiers, but real infrastructure catches more bugs:

- Real databases catch schema issues
- Real API calls catch contract changes
- Real infrastructure gives higher confidence

**When mocking makes sense**:

- External third-party APIs with rate limits
- Paid services in CI
- Flaky network dependencies

### 2. No Test Pollution

Tests SHOULD NOT affect other tests.

**Recommended**:

- Clean setup/teardown
- Isolated test databases
- No shared mutable state

### 3. No Flaky Tests

Tests SHOULD be deterministic.

**Avoid**:

- Random data without seeds
- Time-dependent assertions
- Network calls to external services (Tier 1)

## Test Organization

### Directory Structure

```
tests/
├── regression/     # Tier 0: Permanent bug reproduction tests
├── unit/           # Tier 1: Mocking allowed
├── integration/    # Tier 2: Real infrastructure recommended
└── e2e/           # Tier 3: Real infrastructure recommended
```

### Naming Convention

```
test_[feature]_[scenario]_[expected_result].py
```

Example: `test_user_login_with_valid_credentials_succeeds.py`

## Kailash-Specific Testing

### DataFlow Testing

```python
# Tier 2: Use real database
@pytest.fixture
def db():
    db = DataFlow("sqlite:///:memory:")  # Real SQLite
    yield db
    db.close()

def test_user_creation(db):
    # Real database operations
    result = db.execute(CreateUser(name="test"))
    assert result.id is not None
```

### Workflow Testing

```python
# Tier 2: Use real runtime
def test_workflow_execution():
    runtime = LocalRuntime()
    workflow = build_workflow()
    results, run_id = runtime.execute(workflow.build())
    assert results is not None
```

## Exceptions

Testing exceptions are acceptable when:

1. Real infrastructure is genuinely impractical (paid APIs, rate limits)
2. Tests document why mocking was chosen
3. Integration coverage exists elsewhere for the same functionality
