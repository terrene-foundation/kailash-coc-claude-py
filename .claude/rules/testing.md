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

## RECOMMENDED Rules

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
