# Kailash COC Claude (Python)

This repository is the **COC (Cognitive Orchestration for Codegen) setup** for building with the Kailash SDK — providing agents, skills, rules, and hooks for Kailash SDK development. All projects using this setup inherit these capabilities through the `.claude/` directory.

## Absolute Directives

These override ALL other instructions. They govern behavior before any rule file is consulted.

### 0. Foundation Independence — No Commercial Coupling

Kailash Python SDK is a **Terrene Foundation project**. It is fully independent. There is NO relationship between Kailash Python SDK and any commercial product, proprietary codebase, or commercial entity. Do not reference, compare with, or design against any proprietary product. Do not use language like "open-source version of X" or "Python port of Y." Kailash Python SDK IS the product — not a derivative of anything. See `rules/independence.md` for full policy.

### 1. Framework-First

Never write code from scratch before checking whether the Kailash frameworks already handle it.

- Instead of direct SQL/SQLAlchemy/Django ORM → check with **dataflow-specialist**
- Instead of building API endpoints, web services, HTTP servers manually → check with **nexus-specialist**
- Instead of custom MCP server/client → check with **mcp-specialist**
- Instead of custom agentic platform → check with **kaizen-specialist**
- Instead of custom governance/access control → check with **pact-specialist**

### 2. .env Is the Single Source of Truth

All API keys and model names MUST come from `.env`. Never hardcode model strings like `"gpt-4"` or `"claude-3-opus"`. Root `conftest.py` auto-loads `.env` for pytest.

See `rules/env-models.md` for full details.

### 3. Implement, Don't Document

When you discover a missing feature, endpoint, or record — **implement or create it**. Do not note it as a gap and move on. The only acceptable skip is explicit user instruction.

See `rules/e2e-god-mode.md` and `rules/zero-tolerance.md` for enforcement details.

### 4. Zero Tolerance

Pre-existing failures MUST be fixed, not reported. Stubs are BLOCKED. Naive fallbacks are BLOCKED. SDK bugs get GitHub issues, not workarounds. See `rules/zero-tolerance.md`.

### 5. Recommended Reviews

- **Code review** (reviewer) after file changes — RECOMMENDED — see `rules/agents.md`
- **Security review** (security-reviewer) before commits — strongly recommended — see `rules/agents.md`
- **Real infrastructure recommended** in Tier 2/3 tests — see `rules/testing.md`

### 6. LLM-First Agent Reasoning

When building AI agents: **the LLM does ALL reasoning. Tools are dumb data endpoints.** No if-else routing, no keyword matching, no regex classification in agent decision paths. The LLM IS the router, classifier, extractor, and evaluator. Deterministic logic is BLOCKED unless the user explicitly opts in. See `rules/agent-reasoning.md` for the full rule and detection patterns.

## Workspace Commands

Phase commands replace the manual copy-paste workflow. Each loads the corresponding instruction template and checks workspace state.

| Command      | Phase | Purpose                                                    |
| ------------ | ----- | ---------------------------------------------------------- |
| `/analyze`   | 01    | Load analysis phase for current workspace                  |
| `/todos`     | 02    | Load todos phase; stops for human approval                 |
| `/implement` | 03    | Load implementation phase; repeat until todos done         |
| `/redteam`   | 04    | Load validation phase; red team with MCP tools             |
| `/codify`    | 05    | Load codification phase; create agents & skills            |
| `/release`   | —     | SDK release: PyPI publishing, docs deploy, CI (standalone) |
| `/ws`        | —     | Read-only workspace status dashboard                       |
| `/wrapup`    | —     | Write session notes before ending                          |
| `/journal`   | —     | View, create, or search project journal entries            |

**Workspace detection**: Hooks automatically detect the active workspace and inject context. `session-start.js` shows workspace status on session start (human-facing). `user-prompt-rules-reminder.js` injects a 1-line `[WORKSPACE]` summary into Claude's context every turn (survives context compression).

**Session continuity**: Run `/wrapup` before ending a session to write `.session-notes`. The next session's startup reads these notes and shows workspace progress automatically.

## Rules Index

| Concern                                         | Rule File                       | Scope                                                       |
| ----------------------------------------------- | ------------------------------- | ----------------------------------------------------------- |
| **Foundation independence**                     | `rules/independence.md`         | **Global — overrides all**                                  |
| **Autonomous execution model**                  | `rules/autonomous-execution.md` | **Global — 10x multiplier, structural vs execution gates**  |
| **LLM-first agent reasoning**                   | `rules/agent-reasoning.md`      | `**/kaizen/**`, `**/*agent*`                                |
| Agent orchestration & review recommendations    | `rules/agents.md`               | Global                                                      |
| CC artifact quality                             | `rules/cc-artifacts.md`         | `.claude/**`, `scripts/hooks/**`                            |
| Plain-language communication                    | `rules/communication.md`        | Global                                                      |
| Connection pool safety                          | `rules/connection-pool.md`      | Database connection code                                    |
| DataFlow pool configuration                     | `rules/dataflow-pool.md`        | `**/dataflow/**`                                            |
| SDK release & PyPI publishing                   | `rules/deployment.md`           | `deploy/**`, `.github/**`, `pyproject.toml`, `CHANGELOG.md` |
| Documentation standards                         | `rules/documentation.md`        | `README.md`, `docs/**`, `CHANGELOG.md`                      |
| E2E god-mode testing                            | `rules/e2e-god-mode.md`         | `tests/e2e/**`, `**/*e2e*`, `**/*playwright*`               |
| EATP SDK conventions                            | `rules/eatp.md`                 | `**/trust/**`, `**/eatp/**`                                 |
| API keys & model names                          | `rules/env-models.md`           | `**/*.py`, `**/*.ts`, `**/*.js`, `.env*`                    |
| Git commits, branches, PRs                      | `rules/git.md`                  | Global                                                      |
| Infrastructure SQL safety                       | `rules/infrastructure-sql.md`   | `**/db/**`, `**/infrastructure/**`                          |
| Journal knowledge trail                         | `rules/journal.md`              | Global                                                      |
| PACT governance security                        | `rules/pact-governance.md`      | `**/pact/**`, `**/governance/**`                            |
| Kailash SDK execution patterns                  | `rules/patterns.md`             | `**/*.py`, `**/*.ts`, `**/*.js`                             |
| Security (secrets, injection)                   | `rules/security.md`             | Global                                                      |
| Terrene naming & terminology                    | `rules/terrene-naming.md`       | Global                                                      |
| 3-tier testing, real infrastructure recommended | `rules/testing.md`              | `tests/**`, `**/*test*`, `**/*spec*`, `conftest.py`         |
| Trust-plane security                            | `rules/trust-plane-security.md` | `**/trust/**`                                               |
| Zero-tolerance enforcement                      | `rules/zero-tolerance.md`       | **Global — overrides all**                                  |

**Note**: Rules with path scoping are loaded only when editing matching files. Global rules load every session.

## Agents

### Analysis (`agents/analysis/`)

- **analyst** — Failure point analysis, risk assessment, requirements breakdown, ADRs

### Framework Specialists (`agents/frameworks/`)

- **dataflow-specialist** — Database operations, auto-generated nodes
- **nexus-specialist** — Multi-channel platform (API/CLI/MCP)
- **kaizen-specialist** — AI agents, signatures, multi-agent coordination
- **mcp-specialist** — MCP server implementation
- **mcp-platform-specialist** — FastMCP platform server, contributor plugins, security tiers
- **infrastructure-specialist** — Progressive infrastructure, dialect-portable SQL, task queues
- **pact-specialist** — Organizational governance (D/T/R, envelopes, clearance)
- **ml-specialist** — ML lifecycle, feature stores, training, drift monitoring
- **align-specialist** — LLM fine-tuning, LoRA adapters, alignment, model serving

### Implementation (`agents/implementation/`)

- **pattern-expert** — Workflow patterns, nodes, parameters
- **tdd-implementer** — Test-first development
- **build-fix** — Fix build/type errors with minimal changes

### Quality (`agents/quality/`)

- **reviewer** — Code review, doc validation, cross-reference accuracy
- **gold-standards-validator** — Compliance checking
- **security-reviewer** — Security audit before commits

### Frontend (`agents/frontend/`)

- **react-specialist** — React/Next.js frontends
- **flutter-specialist** — Flutter mobile/desktop apps
- **uiux-designer** — Enterprise UI/UX design

### Testing (`agents/testing/`)

- **testing-specialist** — 3-tier strategy with real infrastructure, Playwright E2E

### Release (`agents/release/`)

- **release-specialist** — CI/CD, PyPI publishing, deployment, version management

### Management (`agents/management/`)

- **todo-manager** — Project task tracking
- **gh-manager** — GitHub issue/project management

### Other

- **claude-code-architect** — CC artifact quality auditing
- **open-source-strategist** — Licensing, community building
- **value-auditor** — Enterprise demo QA from buyer perspective

## Skills Navigation

For SDK implementation patterns, see `.claude/skills/` — organized by framework (`01-core-sdk` through `05-kailash-mcp`), enterprise infrastructure (`15-enterprise-infrastructure`), and topic (`06-cheatsheets` through `28-coc-reference`).

## Critical Execution Rules

```python
# ALWAYS: runtime.execute(workflow.build())
# NEVER: workflow.execute(runtime)
runtime = LocalRuntime()
results, run_id = runtime.execute(workflow.build())

# Async (Docker/Nexus):
runtime = AsyncLocalRuntime()
results, run_id = await runtime.execute_workflow_async(workflow.build(), inputs={})

# String-based nodes only
workflow.add_node("NodeType", "node_id", {"param": "value"})

# Return structure is always (results, run_id)
```

## Kailash Platform

| Framework    | Purpose                                | Install                        |
| ------------ | -------------------------------------- | ------------------------------ |
| **Core SDK** | Workflow orchestration, 140+ nodes     | `pip install kailash`          |
| **DataFlow** | Zero-config database operations        | `pip install kailash-dataflow` |
| **Nexus**    | Multi-channel deployment (API+CLI+MCP) | `pip install kailash-nexus`    |
| **Kaizen**   | AI agent framework                     | `pip install kailash-kaizen`   |
| **PACT**     | Organizational governance (D/T/R)      | `pip install kailash-pact`     |

All frameworks are built ON Core SDK — they don't replace it.
