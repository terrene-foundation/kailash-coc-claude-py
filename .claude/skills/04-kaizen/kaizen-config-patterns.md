# Kaizen Configuration Patterns

Domain configs with BaseAgent auto-extraction. Define domain-specific dataclasses; BaseAgent extracts LLM fields automatically.

## Domain Config Pattern (Recommended)

```python
from kaizen.core.base_agent import BaseAgent
from dataclasses import dataclass

@dataclass
class QAConfig:
    # BaseAgent extracts these automatically:
    llm_provider: str = os.environ.get("LLM_PROVIDER", "openai")
    model: str = os.environ.get("LLM_MODEL", "")
    temperature: float = 0.7
    max_tokens: int = 1000

    # Domain-specific fields (BaseAgent ignores these):
    enable_fact_checking: bool = True
    min_confidence_threshold: float = 0.7
    max_retries: int = 3

class QAAgent(BaseAgent):
    def __init__(self, config: QAConfig):
        super().__init__(config=config, signature=QASignature())
        self.qa_config = config  # Keep reference for domain fields

    def ask(self, question: str) -> dict:
        result = self.run(question=question)
        if result.get("confidence", 0) < self.qa_config.min_confidence_threshold:
            if self.qa_config.enable_fact_checking:
                result = self._recheck_with_facts(result)
        return result
```

## Auto-Extracted Fields

BaseAgent extracts these from any domain config:

| Field                    | Type    | Description                                                                                                                |
| ------------------------ | ------- | -------------------------------------------------------------------------------------------------------------------------- |
| `llm_provider`           | `str`   | `"openai"`, `"anthropic"`, `"azure"`, `"google"`/`"gemini"`, `"ollama"`, `"docker"`, `"cohere"`, `"huggingface"`, `"mock"` |
| `model`                  | `str`   | Model name (from `LLM_MODEL` env var)                                                                                      |
| `temperature`            | `float` | Sampling temperature (0.0-2.0)                                                                                             |
| `max_tokens`             | `int`   | Maximum tokens to generate                                                                                                 |
| `timeout`                | `int`   | Request timeout in seconds                                                                                                 |
| `retry_attempts`         | `int`   | Number of retries on failure                                                                                               |
| `max_turns`              | `int`   | Enable BufferMemory if > 0                                                                                                 |
| `provider_config`        | `dict`  | Provider-specific operational settings (api_version, deployment)                                                           |
| `response_format`        | `dict`  | Structured output config (v2.5.0+) — `json_schema` or `json_object`                                                        |
| `structured_output_mode` | `str`   | `"explicit"` (recommended), `"auto"` (deprecated), `"off"`                                                                 |
| `api_key`                | `str`   | Per-request API key override (BYOK)                                                                                        |
| `base_url`               | `str`   | Per-request base URL override                                                                                              |

All other fields are ignored by BaseAgent and available for domain logic.

**response_format vs provider_config**: `response_format` is for structured output sent to the LLM API. `provider_config` is for provider operational settings. Never put structured output keys in `provider_config`.

## Production Config Example

```python
@dataclass
class ProductionConfig:
    llm_provider: str = os.environ.get("LLM_PROVIDER", "openai")
    model: str = os.environ.get("LLM_MODEL", "")
    temperature: float = 0.3  # Lower for consistency
    max_tokens: int = 2000
    timeout: int = 60
    retry_attempts: int = 3
    max_turns: int = 50  # Enable BufferMemory with limit

    # Domain settings
    enable_logging: bool = True
    log_level: str = "INFO"
    enable_metrics: bool = True
```

## Config Inheritance

```python
@dataclass
class BaseConfig:
    llm_provider: str = os.environ.get("LLM_PROVIDER", "openai")
    model: str = os.environ.get("LLM_MODEL", "")
    temperature: float = 0.7
    max_tokens: int = 1000

@dataclass
class ResearchConfig(BaseConfig):
    enable_web_search: bool = True
    max_sources: int = 5
    citation_style: str = "APA"

@dataclass
class CodeGenConfig(BaseConfig):
    target_language: str = "python"
    style_guide: str = "PEP8"
    include_tests: bool = True
```

## Config Validation

```python
@dataclass
class ValidatedConfig:
    llm_provider: str = os.environ.get("LLM_PROVIDER", "openai")
    model: str = os.environ.get("LLM_MODEL", "")
    temperature: float = 0.7
    max_tokens: int = 1000

    def __post_init__(self):
        if not 0.0 <= self.temperature <= 1.0:
            raise ValueError("temperature must be between 0.0 and 1.0")
        if self.max_tokens <= 0:
            raise ValueError("max_tokens must be positive")
        valid_providers = ["openai", "azure", "anthropic", "google", "gemini", "ollama", "docker", "cohere", "huggingface", "mock"]
        if self.llm_provider not in valid_providers:
            raise ValueError(f"Invalid provider: {self.llm_provider}")
```

## Provider-Specific Configs

All providers use the same domain config pattern. Differences are in `provider_config`:

### OpenAI / Anthropic / Ollama

```python
# OpenAI
provider_config = {"api_version": "2024-01-01", "organization": "org-xyz", "seed": 42, "top_p": 0.9}

# Anthropic
provider_config = {"api_version": "2023-06-01", "max_retries": 3}

# Ollama (local)
# Set llm_provider="ollama", model="llama2"
provider_config = {"base_url": "http://localhost:11434", "num_gpu": 1}
```

### Azure (v2.5.0)

```python
@dataclass
class AzureConfig:
    """Env vars: AZURE_ENDPOINT, AZURE_API_KEY, AZURE_API_VERSION.
    Legacy vars (deprecated): AZURE_OPENAI_ENDPOINT, AZURE_OPENAI_API_KEY, AZURE_OPENAI_API_VERSION."""
    llm_provider: str = "azure"
    model: str = os.environ.get("LLM_MODEL", "")
    temperature: float = 0.7
    max_tokens: int = 1000
    provider_config: dict = None

    def __post_init__(self):
        self.provider_config = {"api_version": "2024-10-21"}
```

Azure with structured output — use `response_format`, not `provider_config`:

```python
from kaizen.core.structured_output import create_structured_output_config

config = BaseAgentConfig(
    llm_provider="azure",
    model=os.environ["LLM_MODEL"],
    response_format=create_structured_output_config(MySignature(), strict=True),
    provider_config={"api_version": "2024-10-21"},
    structured_output_mode="explicit",
)
```

### Docker Model Runner (v0.7.1)

```python
# Prerequisites: Docker Desktop 4.40+, enable TCP: docker desktop enable model-runner --tcp 12434
# Pull model: docker model pull ai/llama3.2
@dataclass
class DockerConfig:
    llm_provider: str = "docker"
    model: str = "ai/llama3.2"  # Or ai/qwen3, ai/gemma3, ai/mxbai-embed-large
    temperature: float = 0.7
    max_tokens: int = 1000
    provider_config: dict = None

    def __post_init__(self):
        self.provider_config = {"base_url": "http://localhost:12434/engines/llama.cpp/v1"}
```

Tool-capable models: `ai/qwen3`, `ai/llama3.3`, `ai/gemma3` (check with `provider.supports_tools(model)`).

### Google Gemini (v0.8.2)

```python
# Env: GOOGLE_API_KEY or GEMINI_API_KEY. Install: pip install kailash-kaizen[google]
@dataclass
class GoogleGeminiConfig:
    llm_provider: str = "google"  # Or "gemini" (alias)
    model: str = os.environ.get("LLM_MODEL", "")
    temperature: float = 0.7
    max_tokens: int = 1000
    provider_config: dict = None

    def __post_init__(self):
        self.provider_config = {"top_p": 0.9, "top_k": 40}
```

Models: `gemini-2.0-flash`, `gemini-1.5-pro`, `gemini-1.5-flash`. Embeddings: `text-embedding-004` (768-dim).

## FallbackRouter

```python
from kaizen.llm.routing.fallback import FallbackRouter, FallbackRejectedError

router = FallbackRouter(
    primary_model=os.environ["LLM_MODEL"],
    fallback_chain=[os.environ.get("LLM_FALLBACK_MODEL", "")],
)

# Safety: on_fallback fires BEFORE each fallback attempt
def check_fallback(event):
    if event.fallback_model in SMALL_MODELS:
        raise FallbackRejectedError("Cannot downgrade for critical task")

router = FallbackRouter(
    primary_model=os.environ["LLM_MODEL"],
    fallback_chain=[os.environ.get("LLM_FALLBACK_MODEL", "")],
    on_fallback=check_fallback,
)
```

## Memory

```python
@dataclass
class MemoryEnabledConfig:
    llm_provider: str = os.environ.get("LLM_PROVIDER", "openai")
    model: str = os.environ.get("LLM_MODEL", "")
    max_turns: int = 10  # Enable BufferMemory, keep last 10 turns

agent = MemoryAgent(MemoryEnabledConfig())
result1 = agent.ask("My name is Alice", session_id="user123")
result2 = agent.ask("What's my name?", session_id="user123")  # "Your name is Alice"
```

Set `max_turns: int = 0` to disable memory (default).

## DO / DON'T

```python
# DON'T: Manual BaseAgentConfig creation
agent_config = BaseAgentConfig(llm_provider=config.llm_provider, model=config.model, ...)
super().__init__(config=agent_config, ...)

# DO: Let BaseAgent auto-extract
super().__init__(config=config, ...)

# DON'T: Structured output in provider_config (deprecated)
config = BaseAgentConfig(provider_config={"type": "json_schema", "json_schema": {...}})

# DO: Use response_format
config = BaseAgentConfig(
    response_format=create_structured_output_config(MySignature(), strict=True),
    structured_output_mode="explicit",
)

# DON'T: Implicit auto mode (deprecated)
config = BaseAgentConfig(llm_provider="openai", model=os.environ["LLM_MODEL"])
# structured_output_mode defaults to "auto" — generates config you never see

# DO: Explicit mode
config = BaseAgentConfig(
    llm_provider="openai",
    model=os.environ["LLM_MODEL"],
    response_format=create_structured_output_config(MySignature(), strict=True),
    structured_output_mode="explicit",
)
```

## Rules

- **ALWAYS**: Use domain configs, let BaseAgent auto-extract, load `.env` before creating configs
- **NEVER**: Create BaseAgentConfig manually, hardcode API keys, put structured output in `provider_config`

## Related

- **kaizen-baseagent-quick** — Using configs with BaseAgent
- **kaizen-agent-execution** — Config-based execution patterns
- **Source**: `kaizen/core/config.py`
