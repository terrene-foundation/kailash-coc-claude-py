---
name: decide-framework
description: "Choose between Core SDK, DataFlow, Nexus, and Kaizen frameworks for your Kailash project. Use when asking 'which framework', 'should I use Core SDK or DataFlow', 'Nexus vs Core', 'framework selection', or 'what's the difference between frameworks'."
---

# Framework Selection Guide

## Four-Layer Hierarchy

```
Entrypoints  →  Applications (aegis, aether), CLI (cli-rs), others (kz-engage)
Engines      →  DataFlowEngine, NexusEngine, DelegateEngine/SupervisorAgent, GovernanceEngine
Primitives   →  DataFlow, @db.model, db.express, Nexus(), BaseAgent, Signature, envelopes
Specs        →  CARE, EATP, CO, COC, PACT
```

See `rules/framework-first.md` for the canonical rule. Default to **Engines**. Drop to Primitives only when Engines can't express the behavior.

## Quick Decision Matrix

| Your Primary Need                        | Framework    | Engine Class                         |
| ---------------------------------------- | ------------ | ------------------------------------ |
| **Custom workflows, integrations**       | **Core SDK** | `LocalRuntime` / `AsyncLocalRuntime` |
| **Database operations**                  | **DataFlow** | `DataFlowEngine.builder()`           |
| **Multi-channel platform** (API+CLI+MCP) | **Nexus**    | `NexusEngine`                        |
| **AI agents, multi-agent systems**       | **Kaizen**   | `DelegateEngine`, `SupervisorAgent`  |
| **Organizational governance**            | **PACT**     | `GovernanceEngine`                   |

## Framework Comparison

### Core SDK (`pip install kailash` / `kailash-core` crate)

- 140+ workflow nodes, WorkflowBuilder API, dual runtime (async/sync)
- Use when: custom workflows, fine-grained control, domain-specific solutions

### DataFlow (`pip install kailash-dataflow` / `kailash-dataflow` crate)

- `@db.model` generates 11 CRUD/bulk nodes per model, MongoDB-style queries
- **Primitives**: `DataFlow`, `@db.model`, `db.express` (lightweight CRUD convenience)
- **Engine**: `DataFlowEngine` wraps DataFlow with validation, classification, query tracking, retention
- Use when: database-first applications, zero-config DB setup, enterprise data management

### Nexus (`pip install kailash-nexus` / `kailash-nexus` crate)

- Register handler once → API + CLI + MCP simultaneously
- **Primitives**: `Nexus()`, handlers, channels
- **Engine**: `NexusEngine` adds middleware stack, auth, K8s probes, OpenAPI
- Use when: multi-channel deployment, unified sessions, platform-style apps

### Kaizen (`pip install kailash-kaizen` / `kailash-kaizen` + `kaizen-agents` crates)

- Signature-based programming, A2A protocol, multi-modal
- **Primitives**: `BaseAgent`, `Signature`, LLM clients
- **Engine**: `DelegateEngine` (autonomous TAOD loop), `SupervisorAgent` (governed teams)
- Use when: AI agents, multi-agent coordination, governed autonomy

### PACT (`pip install kailash-pact` / `kailash-pact` + `kailash-governance` crates)

- D/T/R addressing, constraint envelopes, fail-closed verification
- **Primitives**: Envelopes, D/T/R addressing, clearance
- **Engine**: `GovernanceEngine` (thread-safe, RBAC matrix export)
- Use when: organizational governance, agent access control, budget enforcement

## Layer Selection (After Choosing Framework)

| Framework | Engine (default ✅)                 | Primitives (when Engine can't express it)                              |
| --------- | ----------------------------------- | ---------------------------------------------------------------------- |
| DataFlow  | `DataFlowEngine.builder()`          | `db.express` for simple CRUD, `WorkflowBuilder` + nodes for multi-step |
| Nexus     | `NexusEngine`                       | `Nexus()` for simple handlers, manual channels for custom protocols    |
| Kaizen    | `DelegateEngine`, `SupervisorAgent` | `BaseAgent` for custom execution loops                                 |
| PACT      | `GovernanceEngine`                  | Manual envelope construction for custom patterns                       |

## Framework Combinations

### DataFlow + Nexus (Multi-Channel Database App)

DataFlow handles database operations, Nexus provides multi-channel access. Use `DataFlowEngine` for production DB, `NexusEngine` for deployment.

### Core SDK + Kaizen (AI-Powered Workflows)

Core SDK provides workflow orchestration, Kaizen provides AI agent integration. Use `DelegateEngine` for autonomous agents within workflows.

### Full Stack (DataFlow + Nexus + Kaizen + PACT)

Complete enterprise AI platform: DataFlow for data, Nexus for deployment, Kaizen for agents, PACT for governance. Each framework's Engine layer handles its domain.

## Migration Paths

### Core SDK → DataFlow

1. Identify database operations in existing workflows
2. Replace custom database nodes with `@db.model` generated nodes
3. Upgrade from `DataFlow` primitive to `DataFlowEngine` for enterprise features

### Core SDK → Nexus

1. Wrap existing workflows in Nexus handlers
2. Register with `nexus.register()` for multi-channel access
3. Upgrade to `NexusEngine` for middleware, auth, monitoring

### Primitives → Engine (Any Framework)

1. Identify which primitive you're using
2. Check if the Engine layer covers your use case
3. Migrate to Engine — keeps the same semantics with added enterprise features

## Decision Flowchart

```
START: What's your primary use case?
  ├─ Database-heavy? → DataFlow (DataFlowEngine)
  │    └─ Need multi-channel access? → + Nexus (NexusEngine)
  ├─ Multi-channel platform? → Nexus (NexusEngine)
  │    └─ Need database? → + DataFlow (DataFlowEngine)
  ├─ AI agent system? → Kaizen (DelegateEngine/SupervisorAgent)
  │    └─ Need governance? → + PACT (GovernanceEngine)
  └─ Custom workflows? → Core SDK
       └─ Unsure? Start here, add frameworks as needed
```

## Critical Rules

- ✅ Default to Engine layer for each framework
- ✅ Use Primitives only when Engine can't express the behavior
- ✅ Combine frameworks as needed — they stack on Core SDK
- ❌ NEVER use Raw (SQL, FastAPI, raw LLM calls) when a framework exists
- ❌ NEVER build custom agents when Kaizen exists
- ❌ NEVER build custom governance when PACT exists
