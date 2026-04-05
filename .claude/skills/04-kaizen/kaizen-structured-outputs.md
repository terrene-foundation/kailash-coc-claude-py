# Kaizen Structured Outputs

Multi-provider structured outputs with 100% schema compliance. Requires Kaizen 0.8.2+. Works with `AsyncSingleShotStrategy` and `SingleShotStrategy`.

## Configuration

```python
from kaizen.core.base_agent import BaseAgent
from kaizen.signatures import Signature, InputField, OutputField
from kaizen.core.config import BaseAgentConfig
from kaizen.core.structured_output import create_structured_output_config
from typing import List, Optional, Literal

class QASignature(Signature):
    question: str = InputField(desc="User question")
    answer: str = OutputField(desc="Answer")
    confidence: float = OutputField(desc="Confidence 0-1")
    tags: List[str] = OutputField(desc="Relevant tags")
    category: Literal["tech", "science", "other"] = OutputField(desc="Category")
    notes: Optional[str] = OutputField(desc="Optional notes")

config = BaseAgentConfig(
    llm_provider=os.environ.get("LLM_PROVIDER", "openai"),
    model=os.environ["LLM_MODEL"],
    response_format=create_structured_output_config(
        signature=QASignature(), strict=True, name="qa_response"
    ),
    structured_output_mode="explicit",
)

agent = BaseAgent(config=config, signature=QASignature())
result = agent.run(question="What is AI?")
print(result['answer'])       # Always present, always string
print(result['confidence'])   # Always present, always float
```

### `structured_output_mode`

| Mode         | Behavior                                                            | Status      |
| ------------ | ------------------------------------------------------------------- | ----------- |
| `"explicit"` | Only uses user-provided `response_format` -- nothing auto-generated | Recommended |
| `"auto"`     | Auto-generates config from signature + deprecation warning          | Deprecated  |
| `"off"`      | Never uses structured output, even if `response_format` is set      | Opt-out     |

### Strict vs Legacy Mode

| Feature            | Strict (`strict=True`)                                          | Legacy (`strict=False`)                   |
| ------------------ | --------------------------------------------------------------- | ----------------------------------------- |
| Reliability        | 100% schema compliance                                          | 70-85% best-effort                        |
| Models             | gpt-4o-2024-08-06+                                              | All OpenAI models                         |
| Format             | `json_schema` with strict:true                                  | `json_object` only                        |
| Schema Enforcement | Constrained sampling (API-level)                                | System prompt (LLM-level)                 |
| Compatible Types   | str, int, float, bool, List[T], Optional[T], Literal, TypedDict | All types including Dict[str, Any], Union |

Strict mode generates:

```python
{"type": "json_schema", "json_schema": {
    "name": "my_response", "strict": True,
    "schema": {"type": "object", "properties": {...},
               "required": [...], "additionalProperties": False}
}}
```

Legacy mode generates: `{"type": "json_object"}`

### Manual Response Format

You can pass a raw dict instead of using the helper:

```python
config = BaseAgentConfig(
    llm_provider=os.environ.get("LLM_PROVIDER", "openai"),
    model=os.environ["LLM_MODEL"],
    response_format={
        "type": "json_schema",
        "json_schema": {
            "name": "response", "strict": True,
            "schema": {
                "type": "object",
                "properties": {"answer": {"type": "string"}},
                "required": ["answer"], "additionalProperties": False
            }
        }
    },
    structured_output_mode="explicit",
)
```

## Response Handling

Providers return dict responses (pre-parsed JSON). Strategies auto-detect this -- no code changes needed:

```python
result = agent.run(input_text="...")
print(result['category'])   # Direct dict access, no json.loads()
```

Works with both strict and legacy modes, both string and dict responses.

## Provider Support Matrix

All providers receive OpenAI-style `response_format`. Each auto-translates to native parameters.

| Provider             | `json_schema` (Strict) | `json_object` (Legacy) | Translation                              |
| -------------------- | ---------------------- | ---------------------- | ---------------------------------------- |
| **OpenAI**           | Yes                    | Yes                    | Native                                   |
| **Google/Gemini**    | Yes                    | Yes                    | `response_mime_type` + `response_schema` |
| **Azure AI Foundry** | Yes                    | Yes                    | `JsonSchemaFormat`                       |
| **Ollama**           | No                     | No                     | --                                       |
| **Anthropic**        | No                     | No                     | --                                       |

**Supported models**: OpenAI gpt-4o-2024-08-06+, gpt-4o-mini-2024-07-18+. Gemini 2.0-flash, 1.5-pro, 1.5-flash. Azure gpt-4o, gpt-4o-mini. Legacy (strict=False) works with gpt-4, gpt-3.5-turbo, any JSON mode model.

Azure env vars: `AZURE_ENDPOINT`, `AZURE_API_KEY`, `AZURE_API_VERSION`.

## Type System

### 10 Supported Type Patterns

| Python Type         | JSON Schema                                         | Strict Mode |
| ------------------- | --------------------------------------------------- | ----------- |
| `str`               | `{"type": "string"}`                                | Yes         |
| `int`               | `{"type": "integer"}`                               | Yes         |
| `float`             | `{"type": "number"}`                                | Yes         |
| `bool`              | `{"type": "boolean"}`                               | Yes         |
| `Literal["A", "B"]` | `{"type": "string", "enum": ["A", "B"]}`            | Yes         |
| `Optional[str]`     | `{"type": "string"}` (not in `required`)            | Yes         |
| `List[str]`         | `{"type": "array", "items": {"type": "string"}}`    | Yes         |
| `TypedDict`         | `{"type": "object", "properties": {...}}`           | Yes         |
| `Union[str, int]`   | `{"oneOf": [...]}`                                  | NO          |
| `Dict[str, Any]`    | `{"type": "object", "additionalProperties": {...}}` | NO          |

### TypeIntrospector

```python
from kaizen.core.type_introspector import TypeIntrospector
from typing import Literal

# Check strict mode compatibility
compatible, reason = TypeIntrospector.is_strict_mode_compatible(Literal["A", "B"])

# Validate value against type
is_valid, error = TypeIntrospector.validate_value_against_type("A", Literal["A", "B"])

# Convert type to JSON schema
schema = TypeIntrospector.type_to_json_schema(Literal["A", "B"], "Category field")
# {"type": "string", "enum": ["A", "B"], "description": "Category field"}
```

### Strict Mode Validation & Auto-Fallback

Incompatible types (`Union[str, int]`, `Dict[str, Any]`) trigger auto-fallback by default:

```python
class FlexibleSignature(Signature):
    data: Dict[str, Any] = OutputField(desc="Flexible data")

# Auto-fallback (default): falls back to strict=False with warning
config = create_structured_output_config(
    signature=FlexibleSignature(), strict=True, auto_fallback=True
)

# Strict validation: raises ValueError with recommendations
config = create_structured_output_config(
    signature=FlexibleSignature(), strict=True, auto_fallback=False
)
# ValueError: "Field 'data' (Dict[str, Any]): requires additionalProperties...
#   Recommendations:
#   1. Use strict=False for flexible schemas
#   2. Replace Dict[str, Any] with List[str] or TypedDict
#   3. Replace Union types with separate Optional fields"
```

### Complex Type Example

```python
class ComplexSignature(Signature):
    user_id: str = InputField(desc="User ID")
    tags: List[str] = OutputField(desc="List of tags")
    metadata: dict = OutputField(desc="Nested metadata")
    score: float = OutputField(desc="Numeric score")
    is_valid: bool = OutputField(desc="Validation flag")
    notes: Optional[str] = OutputField(desc="Optional notes")

# Generated schema:
# properties: tags(array[string]), metadata(object), score(number), is_valid(boolean), notes(string)
# required: [tags, metadata, score, is_valid]  -- notes omitted (Optional)
# additionalProperties: false
```

## Signature Inheritance

Child signatures MERGE parent fields (not replace). Multi-level inheritance supported.

```python
class BaseAnalysis(Signature):
    document: str = InputField(desc="Document text")
    summary: str = OutputField(desc="Summary")
    key_points: List[str] = OutputField(desc="Key points")

class FinancialAnalysis(BaseAnalysis):
    revenue: float = OutputField(desc="Revenue")
    expenses: float = OutputField(desc="Expenses")

class QuarterlyReport(FinancialAnalysis):
    quarter: str = OutputField(desc="Q1-Q4")
    growth_rate: float = OutputField(desc="YoY growth %")

sig = QuarterlyReport()
len(sig.output_fields)  # 6 (2 base + 2 financial + 2 quarterly)
```

### Field Overriding

```python
class Parent(Signature):
    input_text: str = InputField(desc="Input")
    result: str = OutputField(desc="Parent result")

class Child(Parent):
    result: str = OutputField(desc="Child result (overridden)")
    extra: str = OutputField(desc="Extra field")

sig = Child()
sig.output_fields["result"]["desc"]  # "Child result (overridden)"
len(sig.output_fields)               # 2 (overridden result + extra)
```

## Extension Points

Override `_generate_system_prompt()` for custom system prompts:

```python
class CustomAgent(BaseAgent):
    def _generate_system_prompt(self) -> str:
        return "You are a medical assistant AI. Always advise consulting a doctor."

agent = CustomAgent(config=config, signature=signature)
# BaseAgent passes _generate_system_prompt as callback to WorkflowGenerator
```

## API Reference

### `create_structured_output_config()`

```python
def create_structured_output_config(
    signature: Any,        # Kaizen Signature instance
    strict: bool = True,   # True=100% compliance, False=best-effort
    name: str = "response",# Schema name for API
    auto_fallback: bool = True  # Fall back to strict=False if types incompatible
) -> Dict[str, Any]
```

Returns provider config dict for `BaseAgentConfig.response_format`.
Raises `ValueError` if `strict=True`, types incompatible, and `auto_fallback=False`.

### `StructuredOutputGenerator.signature_to_json_schema()`

```python
@staticmethod
def signature_to_json_schema(signature: Any) -> Dict[str, Any]
# Returns: {"type": "object", "properties": {...}, "required": [...]}
```

## Troubleshooting

| Error                                                                           | Cause                         | Fix                                                          |
| ------------------------------------------------------------------------------- | ----------------------------- | ------------------------------------------------------------ |
| `TypeError: Subscripted generics cannot be used with class and instance checks` | Kaizen < 0.6.5                | Upgrade: `pip install --upgrade kailash-kaizen`              |
| `Workflow parameters ['provider_config'] not declared`                          | Kaizen < 0.6.3                | Upgrade                                                      |
| `Invalid schema: additionalProperties must be false`                            | Dict[str, Any] in strict mode | Use `auto_fallback=True` (default) or replace with TypedDict |
| Child signature missing parent fields                                           | Kaizen < 0.6.3                | Upgrade                                                      |
| Model returns extra fields                                                      | Legacy mode (strict=False)    | Switch to strict mode with supported model                   |
| Custom system prompt ignored                                                    | Kaizen < 0.6.5                | Upgrade, override `_generate_system_prompt()`                |
| Provider config flattened instead of nested                                     | Kaizen < 0.6.3                | Upgrade                                                      |

### Fix for Dict[str, Any] in Strict Mode

```python
# Replace Dict[str, Any] with TypedDict
class MetadataDict(TypedDict):
    field1: str
    field2: int

class FixedSignature(Signature):
    metadata: MetadataDict = OutputField(desc="Structured metadata")
```
