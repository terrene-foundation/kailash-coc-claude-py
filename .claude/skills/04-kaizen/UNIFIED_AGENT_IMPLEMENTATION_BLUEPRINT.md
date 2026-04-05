# Unified Agent API — Implementation Blueprint

Configuration-driven Agent class replacing 16 specialized agent classes. Three layers: zero-config, behavioral configuration, expert override.

## Agent Class (`src/kaizen/core/agents.py`)

```python
from typing import Literal, Optional, List, Dict, Any, Callable, Union
import logging, uuid
from kaizen.core.base_agent import BaseAgent
from kaizen.core.config import BaseAgentConfig
from kaizen.core.presets import AGENT_TYPE_PRESETS, WORKFLOW_PRESETS
from kaizen.signatures import Signature, InputField, OutputField
from kaizen.memory import (
    BaseMemory, BufferMemory, PersistentBufferMemory,
    SummaryMemory, VectorMemory, KnowledgeGraphMemory, SharedMemoryPool,
)
from kaizen.core.autonomy.hooks import HookManager
from kaizen.core.autonomy.state.manager import StateManager
from kaizen.core.autonomy.state.storage import FilesystemStorage
from kaizen.core.autonomy.control import ControlProtocol

logger = logging.getLogger(__name__)
__all__ = ["Agent", "AgentManager"]

class Agent:
    """Universal agent — everything enabled by default, configured via parameters."""

    def __init__(
        self,
        model: str,                         # REQUIRED
        provider: str = "openai",           # Layer 1: Smart defaults
        agent_id: Optional[str] = None,
        # Layer 2: Behavioral configuration
        agent_type: Literal["simple", "cot", "react", "rag", "autonomous", "reflection"] = "simple",
        workflow: Optional[Literal[
            "supervisor_worker", "consensus", "debate", "sequential", "handoff"]] = None,
        multimodal: Optional[List[Literal["vision", "audio", "document"]]] = None,
        memory_turns: int = 10,
        memory_type: Literal["buffer", "persistent", "summary", "vector", "knowledge_graph"] = "buffer",
        memory_backend: Literal["file", "sqlite", "postgresql"] = "file",
        shared_memory: Optional[SharedMemoryPool] = None,
        tools: Union[Literal["all"], List[str], Literal[False]] = "all",
        auto_approve_safe: bool = True,
        require_approval: bool = False,
        max_cycles: int = 10,
        temperature: float = 0.7,
        max_tokens: Optional[int] = None,
        budget_limit_usd: Optional[float] = 1.0,
        checkpoint_frequency: int = 5,
        checkpointing: bool = True,
        observability: bool = True,
        tracing_only: bool = False,
        rich_output: bool = True,
        verbosity: Literal["quiet", "normal", "verbose"] = "normal",
        streaming: bool = False,
        progress_reporting: bool = True,
        show_cost: bool = True,
        workers: Optional[List['Agent']] = None,
        workflow_config: Optional[Dict[str, Any]] = None,
        # Layer 3: Expert overrides (inject custom implementations)
        signature: Optional[Signature] = None,
        memory: Optional[BaseMemory] = None,
        tool_registry: Optional[ToolRegistry] = None,
        hook_manager: Optional[HookManager] = None,
        state_manager: Optional[StateManager] = None,
        control_protocol: Optional[ControlProtocol] = None,
        mcp_client: Optional['MCPClient'] = None,
        approval_callback: Optional[Callable] = None,
        error_handler: Optional[Callable] = None,
        **kwargs
    ):
        self.model, self.provider = model, provider
        self.agent_id = agent_id or f"agent_{uuid.uuid4().hex[:8]}"
        self._agent_type, self._workflow = agent_type, workflow
        self._multimodal = multimodal or []
        self._config = {
            "memory_turns": memory_turns, "memory_type": memory_type,
            "memory_backend": memory_backend, "tools": tools,
            "max_cycles": max_cycles, "temperature": temperature,
            "max_tokens": max_tokens, "budget_limit_usd": budget_limit_usd,
            "checkpoint_frequency": checkpoint_frequency,
            "checkpointing": checkpointing, "observability": observability,
            "tracing_only": tracing_only, "rich_output": rich_output,
            "verbosity": verbosity, "streaming": streaming,
            "progress_reporting": progress_reporting, "show_cost": show_cost,
            "auto_approve_safe": auto_approve_safe, "require_approval": require_approval,
        }
        self._setup_smart_defaults()
        self._apply_agent_type(agent_type)
        if multimodal: self._apply_multimodal(multimodal)
        if workflow: self._apply_workflow(workflow, workers, workflow_config)
        self._setup_infrastructure(memory=memory, tool_registry=tool_registry,
            hook_manager=hook_manager, state_manager=state_manager,
            control_protocol=control_protocol, mcp_client=mcp_client)
        self._base_agent = self._create_base_agent(
            signature=signature, approval_callback=approval_callback,
            error_handler=error_handler, shared_memory=shared_memory, **kwargs)
```

## Setup and Preset Application

```python
    def _setup_smart_defaults(self):
        c = self._config
        self._memory_config = {"type": c["memory_type"], "turns": c["memory_turns"],
            "backend": c["memory_backend"], "enabled": c["memory_type"] != False}
        self._tools_config = {"enabled": c["tools"] != False, "tools": c["tools"],
            "auto_approve_safe": c["auto_approve_safe"], "require_approval": c["require_approval"]}
        tracing = c["tracing_only"]
        self._observability_config = {"enabled": c["observability"],
            "tracing": True if tracing else c["observability"],
            "metrics": False if tracing else c["observability"],
            "logging": False if tracing else c["observability"]}
        self._checkpoint_config = {"enabled": c["checkpointing"],
            "frequency": c["checkpoint_frequency"], "storage": "filesystem", "compress": True}
        self._budget_config = {"limit_usd": c["budget_limit_usd"],
            "warn_at": 0.75, "error_at": 1.0, "show_cost": c["show_cost"]}

    def _apply_agent_type(self, agent_type: str):
        preset = AGENT_TYPE_PRESETS.get(agent_type)
        if not preset:
            raise ValueError(f"Unknown agent_type: {agent_type}. Valid: {list(AGENT_TYPE_PRESETS.keys())}")
        self._preset, self._strategy = preset, preset["strategy"]
        self._max_cycles = preset.get("max_cycles", self._config["max_cycles"])
        if not preset.get("tools_enabled", True): self._tools_config["enabled"] = False
        if preset.get("reasoning_steps"):
            self._reasoning_enabled = True
            self._prompt_modifier = preset.get("prompt_modifier", "")
        if preset.get("convergence"): self._convergence_strategy = preset["convergence"]
        if preset.get("required_tools"):
            self._required_tools = preset["required_tools"]
            if not self._tools_config["enabled"]:
                raise ValueError(f"Agent type '{agent_type}' requires tools but tools are disabled")
        if preset.get("checkpointing_required") and not self._checkpoint_config["enabled"]:
            self._checkpoint_config["enabled"] = True
        if preset.get("reflection_enabled"): self._reflection_enabled = True

    def _apply_multimodal(self, modalities: List[str]):
        self._vision_enabled = "vision" in modalities
        self._audio_enabled = "audio" in modalities
        self._document_enabled = "document" in modalities
        if self.provider not in ["openai", "anthropic", "ollama"]:
            raise ValueError(f"Provider '{self.provider}' does not support multimodal.")

    def _apply_workflow(self, workflow: str, workers, config):
        preset = WORKFLOW_PRESETS.get(workflow)
        if not preset:
            raise ValueError(f"Unknown workflow: {workflow}. Valid: {list(WORKFLOW_PRESETS.keys())}")
        if "workers" in preset.get("required_params", []) and not workers:
            raise ValueError(f"Workflow '{workflow}' requires 'workers' parameter")
        self._workflow_preset, self._workers = preset, workers or []
        self._workflow_config = config or {}
```

## Infrastructure Setup and Memory Factory

Each component follows: expert override > smart default > disabled (None).

```python
    def _setup_infrastructure(self, memory=None, tool_registry=None,
                              hook_manager=None, state_manager=None,
                              control_protocol=None, mcp_client=None):
        self._memory = memory or (self._create_default_memory() if self._memory_config["enabled"] else None)
        self._tool_registry = tool_registry or (self._create_default_tool_registry() if self._tools_config["enabled"] else None)
        self._hook_manager = hook_manager or (self._create_default_hook_manager() if self._observability_config["enabled"] else None)
        self._state_manager = state_manager or (self._create_default_state_manager() if self._checkpoint_config["enabled"] else None)
        self._control_protocol, self._mcp_client = control_protocol, mcp_client

    def _create_default_memory(self) -> BaseMemory:
        t, turns, backend = self._memory_config["type"], self._memory_config["turns"], self._memory_config["backend"]
        if t == "buffer": return BufferMemory(max_turns=turns)
        if t == "persistent":
            if backend == "sqlite":
                return PersistentBufferMemory(db_path=f".kaizen/memory/{self.agent_id}.db", max_turns=turns)
            return PersistentBufferMemory(file_path=f".kaizen/memory/{self.agent_id}.jsonl", max_turns=turns)
        if t == "summary": return SummaryMemory(llm_provider=self.provider, model=self.model, max_turns=turns)
        if t == "vector": return VectorMemory(embedding_provider=self.provider, max_turns=turns)
        if t == "knowledge_graph": return KnowledgeGraphMemory(llm_provider=self.provider, model=self.model, max_turns=turns)
        raise ValueError(f"Unknown memory_type: {t}")

    def _create_default_hook_manager(self) -> HookManager:
        hm = HookManager()
        obs = self._observability_config
        if obs["tracing"]:
            from kaizen.core.autonomy.observability import register_tracing_hooks; register_tracing_hooks(hm)
        if obs["metrics"]:
            from kaizen.core.autonomy.observability import register_metrics_hooks; register_metrics_hooks(hm)
        if obs["logging"]:
            from kaizen.core.autonomy.observability import register_logging_hooks; register_logging_hooks(hm)
        return hm

    def _create_default_state_manager(self) -> StateManager:
        storage = FilesystemStorage(base_dir=f".kaizen/checkpoints/{self.agent_id}",
                                    compress=self._checkpoint_config["compress"])
        return StateManager(storage=storage, checkpoint_frequency=self._checkpoint_config["frequency"], retention_count=10)

    def _create_base_agent(self, signature, approval_callback, error_handler, shared_memory, **kwargs) -> BaseAgent:
        config = BaseAgentConfig(llm_provider=self.provider, model=self.model,
            temperature=self._config["temperature"], max_tokens=self._config["max_tokens"], agent_id=self.agent_id)
        if signature is None:
            class DefaultSignature(Signature):
                input: str = InputField(description="User input")
                output: str = OutputField(description="Agent output")
            signature = DefaultSignature()
        agent = BaseAgent(config=config, signature=signature, memory=self._memory, tools="all",
            hook_manager=self._hook_manager, state_manager=self._state_manager,
            control_protocol=self._control_protocol, mcp_client=self._mcp_client,
            approval_callback=approval_callback, error_handler=error_handler,
            shared_memory=shared_memory, **kwargs)
        if self._workflow:
            pass  # Dynamically import self._workflow_preset["pattern_class"] and wrap
        return agent
```

## Public API

```python
    def run(self, *args, **kwargs) -> Dict[str, Any]:
        """Execute agent. Returns dict: answer, execution_time, total_tokens, cost_usd, trace_id."""
        if self._config["progress_reporting"]: self._show_progress_start()
        try:
            result = self._base_agent.run(*args, **kwargs)
            if self._budget_config["limit_usd"] is not None: self._check_budget(result)
            if self._config["rich_output"]: self._show_completion(result)
            return result
        except Exception as e:
            return self._handle_execution_error(e, *args, **kwargs)

    async def run_async(self, *args, **kwargs) -> Dict[str, Any]:
        """Async version — same flow with await self._base_agent.run_async()."""
        # Identical to run() but awaits base_agent.run_async() and _handle_execution_error_async()

    def _check_budget(self, result: Dict[str, Any]):
        cost, limit = result.get("cost_usd", 0), self._budget_config["limit_usd"]
        if limit is None: return
        if cost >= limit * self._budget_config["error_at"]:
            raise RuntimeError(f"Budget exceeded: ${cost:.3f} >= ${limit:.2f}")
        elif cost >= limit * self._budget_config["warn_at"]:
            logger.warning(f"Approaching budget: ${cost:.3f} / ${limit:.2f} ({cost/limit*100:.0f}%)")

    # Delegated helpers
    def extract_list(self, result, key, default=None): return self._base_agent.extract_list(result, key, default)
    def extract_dict(self, result, key, default=None): return self._base_agent.extract_dict(result, key, default)
    def extract_float(self, result, key, default=0.0): return self._base_agent.extract_float(result, key, default)
    def extract_str(self, result, key, default=""): return self._base_agent.extract_str(result, key, default)
    def write_to_memory(self, content, tags=None, importance=0.5): return self._base_agent.write_to_memory(content, tags, importance)
    def to_a2a_card(self): return self._base_agent.to_a2a_card()

    def get_config(self) -> Dict[str, Any]:
        return {"model": self.model, "provider": self.provider, "agent_id": self.agent_id,
                "agent_type": self._agent_type, "workflow": self._workflow,
                "multimodal": self._multimodal, **self._config}

    def get_features(self) -> Dict[str, bool]:
        return {"memory": self._memory is not None, "tools": self._tool_registry is not None,
            "observability": self._hook_manager is not None, "checkpointing": self._state_manager is not None,
            "control_protocol": self._control_protocol is not None, "mcp": self._mcp_client is not None,
            "vision": getattr(self, "_vision_enabled", False),
            "audio": getattr(self, "_audio_enabled", False),
            "document": getattr(self, "_document_enabled", False)}
```

## AgentManager

```python
class AgentManager:
    """Manage multiple agents with shared memory coordination."""
    def __init__(self, shared_memory: Optional[SharedMemoryPool] = None):
        self.agents: Dict[str, Agent] = {}
        self.shared_memory = shared_memory or SharedMemoryPool()

    def create_agent(self, agent_id: str, **kwargs) -> Agent:
        agent = Agent(agent_id=agent_id, shared_memory=self.shared_memory, **kwargs)
        self.agents[agent_id] = agent
        return agent

    def get_agent(self, agent_id: str) -> Optional[Agent]: return self.agents.get(agent_id)
    def list_agents(self) -> List[str]: return list(self.agents.keys())
```

## Presets (`src/kaizen/core/presets.py`)

```python
AGENT_TYPE_PRESETS: Dict[str, Dict[str, Any]] = {
    "simple":     {"strategy": "single_shot", "max_cycles": 1,   "tools_enabled": False, "memory_type": "buffer"},
    "cot":        {"strategy": "single_shot", "max_cycles": 1,   "tools_enabled": False, "memory_type": "buffer",
                   "reasoning_steps": True, "prompt_modifier": "Think step by step:"},
    "react":      {"strategy": "multi_cycle", "max_cycles": 10,  "tools_enabled": True,  "memory_type": "persistent",
                   "convergence": "satisfaction"},
    "rag":        {"strategy": "single_shot", "max_cycles": 1,   "tools_enabled": True,  "memory_type": "vector",
                   "required_tools": ["vector_search"]},
    "autonomous": {"strategy": "multi_cycle", "max_cycles": 100, "tools_enabled": True,  "memory_type": "persistent",
                   "checkpointing_required": True, "convergence": "goal_achieved"},
    "reflection": {"strategy": "multi_cycle", "max_cycles": 5,   "tools_enabled": False, "memory_type": "persistent",
                   "reflection_enabled": True},
}

WORKFLOW_PRESETS: Dict[str, Dict[str, Any]] = {
    "supervisor_worker": {"required_params": ["workers"], "pattern_class": "SupervisorWorkerPattern"},
    "consensus":         {"required_params": ["agents"],  "pattern_class": "ConsensusPattern"},
    "debate":            {"required_params": ["agents"],  "pattern_class": "DebatePattern"},
    "sequential":        {"required_params": ["agents"],  "pattern_class": "SequentialPattern"},
    "handoff":           {"required_params": ["agents"],  "pattern_class": "HandoffPattern"},
}
```

## Test Patterns

```python
# Layer 1: Zero-config — all features enabled by default
agent = Agent(model=os.environ["LLM_MODEL"])
assert agent.get_features()["memory"] is True

# Layer 2: Configuration — preset overrides defaults
agent = Agent(model=os.environ["LLM_MODEL"], agent_type="react", memory_turns=20)
assert agent._max_cycles == 10

# Layer 3: Expert override — custom implementations injected
agent = Agent(model=os.environ["LLM_MODEL"], memory=BufferMemory(max_turns=50))
assert isinstance(agent._memory, BufferMemory)

# Disable features explicitly
agent = Agent(model=os.environ["LLM_MODEL"], tools=False, observability=False, checkpointing=False)
assert agent.get_features()["tools"] is False
```

## Package Export

```python
from kaizen.core.agents import Agent, AgentManager  # in src/kaizen/__init__.py
```
