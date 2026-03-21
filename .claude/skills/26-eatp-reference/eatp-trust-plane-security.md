# Skill: TrustPlane Security Patterns

13 hardened security patterns validated through 16 rounds of red teaming. MANDATORY for the SDK source and the SDK source. Recommended for any security-sensitive Python project.

For full code examples with DO/DON'T pairs, see the SDK source.

## Quick Checklist

| #   | Pattern                                                | Violation                                               | Found   |
| --- | ------------------------------------------------------ | ------------------------------------------------------- | ------- |
| 1   | `validate_id()` before filesystem paths or SQL         | `f"{user_input}.json"` without validation               | R13     |
| 2   | `O_NOFOLLOW` via `safe_read_json()`/`safe_read_text()` | `open(path)` or `path.read_text()`                      | R3      |
| 3   | `atomic_write()` for all record writes                 | `with open(path, 'w')`                                  | R4      |
| 4   | `safe_read_json()` for JSON deserialization            | `json.loads(path.read_text())`                          | R5      |
| 5   | `math.isfinite()` on numeric constraint fields         | Only checking `< 0` (NaN/Inf bypass)                    | R14     |
| 6   | Bounded collections (`deque(maxlen=)`)                 | Unbounded `list` in long-running processes              | R6      |
| 7   | Monotonic escalation only                              | Any downgrade of trust state                            | R7      |
| 8   | `hmac.compare_digest()` for hash comparison            | `==` on hashes/tokens/signatures                        | R14     |
| 9   | Key material zeroization                               | Private key persisting in scope                         | R12     |
| 10  | `frozen=True` on security-critical dataclasses         | Mutable dataclass bypassing validation                  | R13/R16 |
| 11  | `from_dict()` validates all fields                     | Silent defaults on required fields                      | R8      |
| 12  | `math.isfinite()` on runtime cost values               | NaN in context dict poisons budget accumulator          | R15     |
| 13  | `RecordNotFoundError` (not bare `KeyError`) in except  | `except KeyError` too broad after dual-hierarchy change | R15     |

## Pattern 10 — Frozen Constraint Dataclasses (Extended in R16)

All five EATP constraint sub-dataclasses are `frozen=True`:

- `OperationalConstraints` — blocked/allowed actions
- `DataAccessConstraints` — path restrictions (uses `object.__setattr__` in `__post_init__` for normalization)
- `FinancialConstraints` — budget limits
- `TemporalConstraints` — time boundaries
- `CommunicationConstraints` — channel restrictions

An attacker with an object reference CANNOT bypass budget enforcement via `envelope.financial.max_cost_per_session = None`.

## Pattern 12 — NaN Budget Bypass Prevention (R15)

```python
# DO (in check() and record_action()):
import math
action_cost = float(ctx.get("cost", 0.0))
if not math.isfinite(action_cost) or action_cost < 0:
    return Verdict.BLOCKED  # Fail-closed

# DO NOT:
action_cost = float(ctx.get("cost", 0.0))
if action_cost > limit:  # NaN > limit is False — bypass!
    return Verdict.BLOCKED
```

**7 enforcement points** — Pattern 5 covers construction, Pattern 12 covers runtime:

1. `FinancialConstraints.__post_init__()` — max_cost_per_session, max_cost_per_action
2. `TemporalConstraints.__post_init__()` — max_session_hours
3. `DecisionRecord.__post_init__()` — cost field
4. `DecisionRecord.from_dict()` — cost pre-validation (defense-in-depth)
5. `TrustProject.check()` — action_cost from context dict
6. `AuditSession.record_action()` — cost parameter
7. `AuditSession.from_dict()` — session_cost deserialization

## Pattern 13 — Narrow Exception Handlers After Dual Hierarchy (R15)

`RecordNotFoundError` inherits from both `TrustPlaneStoreError` and `KeyError`. Any `except KeyError` block now catches store errors. Narrow to `except RecordNotFoundError` where intent is store-specific:

```python
# DO:
from kailash.trust.plane.exceptions import RecordNotFoundError
try:
    delegate = store.get_delegate(did)
except RecordNotFoundError:
    pass  # Already gone

# DO NOT:
try:
    delegate = store.get_delegate(did)
except KeyError:  # Too broad — catches unrelated dict lookups
    pass
```

## Store Security Contract (6 Requirements)

Every `TrustPlaneStore` backend MUST satisfy ALL six:

1. **ATOMIC_WRITES** — Crash during write MUST NOT produce partial records
2. **INPUT_VALIDATION** — `validate_id()` on every external ID
3. **BOUNDED_RESULTS** — `limit` parameter on all `list_*()`, default <= 1000, clamp negatives
4. **PERMISSION_ISOLATION** — No cross-project record visibility
5. **CONCURRENT_SAFETY** — No data loss under concurrent writes
6. **NO_SILENT_FAILURES** — `RecordNotFoundError` (not `KeyError` or `None`) for missing records

## Exception Hierarchy (23 classes)

```
TrustPlaneError (base, .details: dict)
  TrustPlaneStoreError
    RecordNotFoundError (+KeyError)
    SchemaTooNewError / SchemaMigrationError
    StoreConnectionError / StoreQueryError / StoreTransactionError
  TrustDecryptionError
  KeyManagerError (provider, key_id)
    KeyNotFoundError / KeyExpiredError / SigningError / VerificationError
  ConstraintViolationError
    BudgetExhaustedError (session_cost, budget_limit, action_cost)
  IdentityError
    TokenVerificationError / JWKSError
  RBACError / ArchiveError / TLSSyslogError
  LockTimeoutError (+TimeoutError)
```

All exceptions accept `details: dict[str, Any]` per EATP convention.

## See Also

- `.claude/skills/project/store-backend-implementation.md` — Store backend guide
- `.claude/skills/project/trust-plane-enterprise-features.md` — Enterprise feature reference
