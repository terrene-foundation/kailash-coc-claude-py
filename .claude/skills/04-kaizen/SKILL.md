---
name: kaizen
description: "Kailash Kaizen - production-ready AI agent framework with signature-based programming, multi-agent coordination, and enterprise features. Use when asking about 'AI agents', 'agent framework', 'BaseAgent', 'multi-agent systems', 'agent coordination', 'signatures', 'agent signatures', 'RAG agents', 'vision agents', 'audio agents', 'multimodal agents', 'agent prompts', 'prompt optimization', 'chain of thought', 'ReAct pattern', 'Planning agent', 'PEV agent', 'Tree-of-Thoughts', 'pipeline patterns', 'supervisor-worker', 'router pattern', 'ensemble pattern', 'blackboard pattern', 'parallel execution', 'agent-to-agent communication', 'A2A protocol', 'streaming agents', 'agent testing', 'agent memory', 'agentic workflows', 'AgentRegistry', 'OrchestrationRuntime', 'distributed agents', 'agent registry', '100+ agents', 'capability discovery', 'fault tolerance', 'health monitoring', 'trust protocol', 'EATP', 'TrustedAgent', 'trust chains', 'secure messaging', 'enterprise trust', 'credential rotation', 'trust verification', 'cross-organization agents', 'agent manifest', 'TOML manifest', 'GovernanceManifest', 'deploy agent', 'FileRegistry', 'introspect agent', 'DAG validation', 'validate_dag', 'schema compatibility', 'cost estimation', 'composition validation', 'catalog server', 'CatalogMCPServer', 'MCP catalog', 'budget tracking', 'BudgetTracker', 'PostureBudgetIntegration', 'posture budget', 'budget threshold', 'L3 autonomy', 'L3 primitives', 'EnvelopeTracker', 'EnvelopeSplitter', 'EnvelopeEnforcer', 'ScopedContext', 'ContextScope', 'ScopeProjection', 'DataClassification', 'MessageRouter', 'MessageChannel', 'DeadLetterStore', 'AgentFactory', 'AgentInstance', 'AgentInstanceRegistry', 'AgentSpec', 'PlanExecutor', 'PlanValidator', 'PlanModification', 'Plan DAG', 'gradient zone', 'agent spawning', 'cascade termination', 'scoped context', 'envelope enforcement', 'plan execution', or 'agent lifecycle'. Also covers L3 integration: 'L3Runtime', 'L3EventBus', 'L3EventType', 'EatpTranslator', 'L3 event system', 'EATP audit events', or 'governance events'. Also covers kaizen-agents governance layer: 'GovernedSupervisor', 'governed agent', 'progressive disclosure', 'governance modules', 'AccountabilityTracker', 'CascadeManager', 'ClearanceEnforcer', 'DerelictionDetector', 'BypassManager', 'VacancyManager', 'kaizen-agents', 'governed multi-agent', 'PACT governance', 'anti-self-modification', 'ReadOnlyView', 'governance security', 'NaN defense', or 'bounded collections'. Also covers kaizen-agents Delegate system: 'Delegate', 'delegate facade', 'typed events', 'TextDelta', 'ToolCallStart', 'DelegateEvent', 'progressive disclosure API', 'run_sync', 'budget tracking', 'multi-provider', 'StreamingChatAdapter', 'adapter registry', 'OpenAI adapter', 'Anthropic adapter', 'Google adapter', 'Ollama adapter', 'tool hydration', 'ToolHydrator', 'search_tools', 'BM25 search', 'incremental streaming', or 'token streaming'."
---

# Kailash Kaizen - AI Agent Framework

Production-ready AI agent framework: signature-based programming, multi-agent coordination, 9 orchestration patterns, 6 autonomy subsystems, distributed coordination, enterprise trust.

## Quick Start

```python
from kaizen.core.base_agent import BaseAgent
from kaizen.signatures import Signature, InputField, OutputField
from dataclasses import dataclass

class SummarizeSignature(Signature):
    text: str = InputField(description="Text to summarize")
    summary: str = OutputField(description="Generated summary")

@dataclass
class SummaryConfig:
    llm_provider: str = os.environ.get("LLM_PROVIDER", "openai")
    model: str = os.environ["LLM_MODEL"]
    temperature: float = 0.7

class SummaryAgent(BaseAgent):
    def __init__(self, config: SummaryConfig):
        super().__init__(config=config, signature=SummarizeSignature())

result = SummaryAgent(SummaryConfig()).run(text="Long text here...")
```

### Pipeline Patterns

```python
from kaizen_agents.patterns.pipeline import Pipeline

pipeline = Pipeline.ensemble(agents=[code, data, writing, research], synthesizer=synth, discovery_mode="a2a", top_k=3)
router = Pipeline.router(agents=[code, data, writing], routing_strategy="semantic")
blackboard = Pipeline.blackboard(agents=[solver, analyzer, optimizer], controller=ctrl, max_iterations=10)
```

9 patterns: Ensemble, Blackboard, Router, Parallel, Sequential, Supervisor-Worker, Handoff, Consensus, Debate.

## Skill Files

**Quick Start**: [kaizen-quickstart-template](kaizen-quickstart-template.md), [kaizen-baseagent-quick](kaizen-baseagent-quick.md), [kaizen-signatures](kaizen-signatures.md), [kaizen-agent-execution](kaizen-agent-execution.md)

**Agent Patterns**: [kaizen-agent-patterns](kaizen-agent-patterns.md), [kaizen-chain-of-thought](kaizen-chain-of-thought.md), [kaizen-react-pattern](kaizen-react-pattern.md), [kaizen-rag-agent](kaizen-rag-agent.md), [kaizen-config-patterns](kaizen-config-patterns.md)

**Multi-Agent & Orchestration**: [kaizen-multi-agent-setup](kaizen-multi-agent-setup.md), [kaizen-supervisor-worker](kaizen-supervisor-worker.md), [kaizen-a2a-protocol](kaizen-a2a-protocol.md), [kaizen-shared-memory](kaizen-shared-memory.md), [kaizen-agent-registry](kaizen-agent-registry.md)

**Multimodal**: [kaizen-multimodal-orchestration](kaizen-multimodal-orchestration.md), [kaizen-vision-processing](kaizen-vision-processing.md), [kaizen-audio-processing](kaizen-audio-processing.md), [kaizen-multimodal-pitfalls](kaizen-multimodal-pitfalls.md)

**Advanced**: [kaizen-control-protocol](kaizen-control-protocol.md), [kaizen-tool-calling](kaizen-tool-calling.md), [kaizen-memory-system](kaizen-memory-system.md), [kaizen-checkpoint-resume](kaizen-checkpoint-resume.md), [kaizen-interrupt-mechanism](kaizen-interrupt-mechanism.md), [kaizen-persistent-memory](kaizen-persistent-memory.md), [kaizen-streaming](kaizen-streaming.md), [kaizen-cost-tracking](kaizen-cost-tracking.md)

**Observability**: [kaizen-observability-hooks](kaizen-observability-hooks.md), [kaizen-observability-tracing](kaizen-observability-tracing.md), [kaizen-observability-metrics](kaizen-observability-metrics.md), [kaizen-observability-logging](kaizen-observability-logging.md), [kaizen-observability-audit](kaizen-observability-audit.md)

**Enterprise Trust (v0.8.0)**: [kaizen-trust-eatp](kaizen-trust-eatp.md) -- Cryptographic trust chains, TrustedAgent, secure messaging, credential rotation, cross-org trust

**Agent Manifest & Deploy (v1.3)**: [kaizen-agent-manifest](kaizen-agent-manifest.md) -- TOML manifests, GovernanceManifest, FileRegistry, introspect_agent()

**Composition Validation (v1.3)**: [kaizen-composition](kaizen-composition.md) -- validate_dag(), schema compatibility, cost estimation

**MCP Catalog (v1.3)**: [kaizen-catalog-server](kaizen-catalog-server.md) -- CatalogMCPServer with 11 tools, 14 built-in agents

**Budget Tracking (v1.3)**: [kaizen-budget-tracking](kaizen-budget-tracking.md) -- BudgetTracker, PostureBudgetIntegration, threshold callbacks

**L3 Autonomy**: [kaizen-l3-overview](kaizen-l3-overview.md), [kaizen-l3-envelope](kaizen-l3-envelope.md), [kaizen-l3-context](kaizen-l3-context.md), [kaizen-l3-messaging](kaizen-l3-messaging.md), [kaizen-l3-factory](kaizen-l3-factory.md), [kaizen-l3-plan-dag](kaizen-l3-plan-dag.md)

**Governance**: [kaizen-agents-governance](kaizen-agents-governance.md), [kaizen-agents-security](kaizen-agents-security.md)

**Testing**: [kaizen-testing-patterns](kaizen-testing-patterns.md)

## Key Architecture

**Signature-Based Programming**: Type-safe interfaces with automatic validation, optimization, and prompt generation.

**BaseAgent**: Error handling, audit trails, cost tracking, streaming, memory, hooks.

**Autonomy (6 Subsystems)**:

1. **Hooks** -- PRE/POST lifecycle events, 6 builtins, RBAC + Ed25519 + isolation (<0.01ms overhead)
2. **Checkpoint** -- Save/load/fork state, 4 backends (FS/Redis/PG/S3), incremental + compressed
3. **Interrupt** -- 3 sources (USER/SYSTEM/PROGRAMMATIC), graceful vs immediate shutdown
4. **Memory** -- 3-tier: Hot (<1ms, in-memory) / Warm (10-50ms, DB) / Cold (100ms+, S3)
5. **Planning** -- PlanningAgent, PEVAgent, Tree-of-Thoughts
6. **Meta-Controller** -- A2A semantic routing, auto-discovery, fallback strategies

**AgentRegistry**: O(1) capability discovery, 6 event types, heartbeat health, status management (ACTIVE/UNHEALTHY/DEGRADED/OFFLINE), multi-runtime coordination.

## Provider Configuration (v2.5.0)

```python
from kaizen.core.config import BaseAgentConfig
from kaizen.core.structured_output import create_structured_output_config

config = BaseAgentConfig(
    llm_provider="openai",
    model=os.environ["LLM_MODEL"],
    response_format=create_structured_output_config(MySignature(), strict=True),
    structured_output_mode="explicit",
)

# Azure
config = BaseAgentConfig(
    llm_provider="azure", model=os.environ["LLM_MODEL"],
    response_format={"type": "json_object"},
    provider_config={"api_version": "2024-10-21"},
    structured_output_mode="explicit",
)
```

Azure env vars: `AZURE_ENDPOINT`, `AZURE_API_KEY`, `AZURE_API_VERSION` (legacy names emit DeprecationWarning).

Prompt utils: `generate_prompt_from_signature()`, `json_prompt_suffix()` from `kaizen.core.prompt_utils`.

## Integration Patterns

```python
# With DataFlow
class DataAgent(BaseAgent):
    def __init__(self, config, db: DataFlow):
        self.db = db
        super().__init__(config=config, signature=MySignature())

# With Nexus
app = Nexus()
app.register("agent", agent_workflow.build())
app.start()

# With Core SDK
workflow = WorkflowBuilder()
workflow.add_node("KaizenAgent", "agent1", {"agent": my_agent, "input": "..."})
```

## Critical Rules

- Define signatures before agents; use `response_format` (not `provider_config`) for structured output
- Set `structured_output_mode="explicit"` for new agents
- Extend BaseAgent, track costs, enable hooks in production
- Use AgentRegistry for distributed coordination (100+ agents)
- Never skip signatures, never put structured output in `provider_config`

## Related Skills

[01-core-sdk](../../01-core-sdk/SKILL.md), [02-dataflow](../dataflow/SKILL.md), [03-nexus](../nexus/SKILL.md), [05-kailash-mcp](../05-kailash-mcp/SKILL.md), [17-gold-standards](../../17-gold-standards/SKILL.md)
