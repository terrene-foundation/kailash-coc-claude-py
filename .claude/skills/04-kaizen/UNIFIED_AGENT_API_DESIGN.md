# Unified Agent API

One `Agent` class replaces 16 specialized classes. Configuration-driven behavior, progressive disclosure, everything enabled by default.

## Entry Point

```python
from kaizen import Agent

# Zero-config (everything just works)
agent = Agent(model=os.environ["LLM_MODEL"])
result = agent.run("What is AI?")

# Specialized via configuration
agent = Agent(model=os.environ["LLM_MODEL"], agent_type="react")
agent = Agent(model=os.environ["LLM_MODEL"], workflow="supervisor_worker", workers=[a, b, c])
```

## Agent Types

| `agent_type`   | Strategy    | Cycles | Tools                          | Memory     | Use Case                                           |
| -------------- | ----------- | ------ | ------------------------------ | ---------- | -------------------------------------------------- |
| `"simple"`     | single_shot | 1      | No                             | buffer     | Q&A, fact retrieval                                |
| `"cot"`        | single_shot | 1      | No                             | buffer     | Math, logic, reasoning (adds "Think step by step") |
| `"react"`      | multi_cycle | 10     | Yes                            | persistent | Research, data gathering, API interactions         |
| `"rag"`        | single_shot | 1      | Yes (`vector_search` required) | vector     | Document Q&A, knowledge base                       |
| `"autonomous"` | multi_cycle | 100    | Yes                            | persistent | Long-running tasks (checkpointing required)        |
| `"reflection"` | multi_cycle | 5      | No                             | persistent | Self-improvement, iterative quality refinement     |

## Smart Defaults (ON by default)

| Feature        | Default                           | Disable With              |
| -------------- | --------------------------------- | ------------------------- |
| Memory         | 10 turns, buffer, file backend    | `memory=False`            |
| Tools          | All 12 builtin via MCP            | `tools=False`             |
| Observability  | Tracing + metrics + logging       | `observability=False`     |
| Checkpointing  | Every 5 steps, filesystem         | `checkpointing=False`     |
| Cost tracking  | $1.00 USD limit, warns at 75%/90% | `budget_limit_usd=None`   |
| Rich output    | Startup banner, progress, metrics | `rich_output=False`       |
| Error handling | 3 retries, exponential backoff    | `retry_count=0`           |
| Google A2A     | Auto capability card generation   | Always on                 |
| Tool approval  | Danger-level based                | `auto_approve_safe=False` |

**Opt-in features**: `streaming=True`, `interactive=True` (control protocol), `mcp_servers=[...]`, `batch_mode=True`, `require_approval=True`

## Configuration Parameters

### Agent Behavior

- `agent_type`: `"simple"` | `"cot"` | `"react"` | `"rag"` | `"autonomous"` | `"reflection"`
- `workflow`: `"supervisor_worker"` | `"consensus"` | `"debate"` | `"sequential"` | `"handoff"`
- `multimodal`: `["vision"]` | `["audio"]` | `["vision", "audio", "document"]`
- `max_cycles`: int -- `temperature`: float

### Memory

- `memory_turns`: int -- `memory_type`: `"buffer"` | `"persistent"` | `"summary"` | `"vector"` | `"knowledge_graph"`
- `memory_backend`: `"file"` | `"sqlite"` | `"postgresql"` -- `shared_memory`: `SharedMemoryPool`

### Tools

- `tools`: `"all"` | `List[str]` | `False` -- `auto_approve_safe`: bool -- `require_approval`: bool

### Infrastructure

- `budget_limit_usd`: float | None -- `checkpoint_frequency`: int -- `checkpointing`: bool
- `observability`: bool -- `tracing_only`: bool

### UX

- `rich_output`: bool -- `verbosity`: `"quiet"` | `"normal"` | `"verbose"` -- `streaming`: bool -- `progress_reporting`: bool

### Expert Overrides

Replace any component with a custom implementation:

| Parameter           | Replaces                |
| ------------------- | ----------------------- |
| `memory`            | Default memory system   |
| `tool_registry`     | Default tool registry   |
| `hook_manager`      | Default observability   |
| `state_manager`     | Default checkpointing   |
| `control_protocol`  | Default interaction     |
| `mcp_client`        | Default MCP integration |
| `approval_callback` | Default approval logic  |
| `error_handler`     | Default error handling  |

## Workflow Patterns

```python
# Create workers
researcher = Agent(model=os.environ["LLM_MODEL"], agent_type="react", agent_id="researcher")
analyst = Agent(model=os.environ["LLM_MODEL"], agent_type="cot", agent_id="analyst")
writer = Agent(model=os.environ["LLM_MODEL"], agent_type="simple", agent_id="writer")

# Supervisor delegates to workers
supervisor = Agent(
    model=os.environ["LLM_MODEL"],
    workflow="supervisor_worker",
    workers=[researcher, analyst, writer],
    workflow_config={"selection_strategy": "semantic", "parallel_execution": True}
)
result = supervisor.run("Research AI trends, analyze data, write report")
```

| `workflow`            | Required  | Optional                                   | Use Case                               |
| --------------------- | --------- | ------------------------------------------ | -------------------------------------- |
| `"supervisor_worker"` | `workers` | `selection_strategy`, `parallel_execution` | Complex tasks with specialization      |
| `"consensus"`         | `agents`  | `consensus_threshold`, `max_rounds`        | Critical decisions requiring agreement |
| `"debate"`            | `agents`  | `max_rounds`, `judge_agent`                | Exploring multiple perspectives        |
| `"sequential"`        | `agents`  | `allow_backtrack`                          | Multi-stage processing pipelines       |
| `"handoff"`           | `agents`  | `handoff_criteria`                         | Adaptive task routing                  |

## Agent Class Signature

```python
class Agent:
    def __init__(
        self,
        model: str,                    # REQUIRED
        provider: str = "openai",
        agent_id: Optional[str] = None,
        # Behavior
        agent_type: Literal["simple", "cot", "react", "rag", "autonomous", "reflection"] = "simple",
        workflow: Optional[Literal["supervisor_worker", "consensus", "debate", "sequential", "handoff"]] = None,
        multimodal: Optional[List[Literal["vision", "audio", "document"]]] = None,
        # Memory
        memory_turns: int = 10,
        memory_type: Literal["buffer", "persistent", "summary", "vector", "knowledge_graph"] = "buffer",
        memory_backend: Literal["file", "sqlite", "postgresql"] = "file",
        shared_memory: Optional[SharedMemoryPool] = None,
        # Tools
        tools: Union[Literal["all"], List[str], Literal[False]] = "all",
        auto_approve_safe: bool = True,
        require_approval: bool = False,
        # Execution
        max_cycles: int = 10,
        temperature: float = 0.7,
        # Infrastructure
        budget_limit_usd: Optional[float] = 1.0,
        checkpoint_frequency: int = 5,
        checkpointing: bool = True,
        observability: bool = True,
        tracing_only: bool = False,
        # UX
        rich_output: bool = True,
        verbosity: Literal["quiet", "normal", "verbose"] = "normal",
        streaming: bool = False,
        progress_reporting: bool = True,
        # Workflow
        workers: Optional[List[Agent]] = None,
        workflow_config: Optional[Dict[str, Any]] = None,
        # Expert overrides
        signature: Optional[Signature] = None,
        memory: Optional[BaseMemory] = None,
        tool_registry: Optional[ToolRegistry] = None,
        hook_manager: Optional[HookManager] = None,
        state_manager: Optional[StateManager] = None,
        control_protocol: Optional[ControlProtocol] = None,
        mcp_client: Optional[MCPClient] = None,
        approval_callback: Optional[Callable] = None,
        error_handler: Optional[Callable] = None,
        **kwargs
    ): ...

    def run(self, *args, **kwargs) -> Dict[str, Any]: ...
    async def run_async(self, *args, **kwargs) -> Dict[str, Any]: ...
```

## Internal Architecture

Initialization flow: `_setup_smart_defaults()` -> `_apply_agent_type(preset)` -> `_apply_multimodal(modalities)` -> `_apply_workflow(pattern, workers, config)` -> `_setup_infrastructure(overrides)` -> `_create_base_agent()`

`run()` wraps `BaseAgent.run()` with: progress reporting, cost/budget checking, rich output, error handling with retries.

Agent type presets override defaults (e.g., `"react"` enables tools and sets `persistent` memory; `"simple"` disables tools and sets `max_cycles=1`). Expert overrides take precedence over presets.

## Usage Examples

### Layer 1: Zero-Config

```python
from kaizen import Agent
agent = Agent(model=os.environ["LLM_MODEL"])
result = agent.run("Explain quantum computing")
```

### Layer 2: Configured

```python
agent = Agent(
    model=os.environ["LLM_MODEL"],
    agent_type="react",
    memory_turns=20, memory_type="persistent",
    tools=["read_file", "http_get"],
    budget_limit_usd=5.0, max_cycles=15,
    verbosity="verbose"
)
result = agent.run("Research latest AI papers and summarize")
```

### Layer 3: Expert Override

```python
agent = Agent(
    model=os.environ["LLM_MODEL"],
    agent_type="autonomous",
    memory=RedisMemorySystem(cluster=["node1", "node2"], replication_factor=3),
    hook_manager=DatadogHookManager(api_key=os.getenv("DD_API_KEY"), sampling_rate=0.1),
    state_manager=S3StateManager(bucket="agent-checkpoints", compression="lz4"),
)
result = agent.run("Build complete data pipeline")
```

### Multimodal

```python
agent = Agent(model=os.environ["LLM_MODEL"], multimodal=["vision", "audio"])
result = agent.run(image="frame.png", audio="clip.mp3", question="What is happening?")
```

### Minimal (everything disabled)

```python
agent = Agent(
    model=os.environ["LLM_MODEL"],
    memory=False, tools=False, observability=False,
    checkpointing=False, rich_output=False, budget_limit_usd=None
)
```

## Migration (Backward Compatible)

Legacy classes remain as thin wrappers. Existing code continues to work.

```python
# Legacy (still works)
from kaizen_agents.agents import SimpleQAAgent
agent = SimpleQAAgent(llm_provider=os.environ.get("LLM_PROVIDER", "openai"), model=os.environ["LLM_MODEL"])
result = agent.ask("What is AI?")

# Unified (recommended)
from kaizen import Agent
agent = Agent(model=os.environ["LLM_MODEL"])
result = agent.run("What is AI?")
```

| Legacy Class              | Unified Equivalent                                   |
| ------------------------- | ---------------------------------------------------- |
| `SimpleQAAgent`           | `Agent(agent_type="simple")`                         |
| `ChainOfThoughtAgent`     | `Agent(agent_type="cot")`                            |
| `ReActAgent`              | `Agent(agent_type="react")`                          |
| `RAGResearchAgent`        | `Agent(agent_type="rag")`                            |
| `BaseAutonomousAgent`     | `Agent(agent_type="autonomous")`                     |
| `SelfReflectionAgent`     | `Agent(agent_type="reflection")`                     |
| `VisionAgent`             | `Agent(multimodal=["vision"])`                       |
| `TranscriptionAgent`      | `Agent(multimodal=["audio"])`                        |
| `MultiModalAgent`         | `Agent(multimodal=["vision", "audio"])`              |
| `MemoryAgent`             | `Agent()` (memory on by default)                     |
| `StreamingChatAgent`      | `Agent(streaming=True)`                              |
| `BatchProcessingAgent`    | `Agent(batch_mode=True)`                             |
| `HumanApprovalAgent`      | `Agent(require_approval=True)`                       |
| `ResilientAgent`          | `Agent()` (resilience on by default)                 |
| `SupervisorWorkerPattern` | `Agent(workflow="supervisor_worker", workers=[...])` |
