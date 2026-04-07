---
name: kailash-ml
description: "Kailash ML — classical + deep learning lifecycle with polars-native engines, AutoML, ONNX serving. Use for feature stores, model training, drift monitoring, inference."
---

# Kailash ML - Classical & Deep Learning Lifecycle

Production ML lifecycle framework built on Kailash Core SDK — polars-native engines, schema-driven pipelines, agent-augmented AutoML, and cross-language ONNX serving.

## Install

```
pip install kailash-ml            # Core (polars, numpy, scipy, sklearn, lightgbm, onnx)
pip install kailash-ml[dl]        # + PyTorch, Lightning, transformers
pip install kailash-ml[dl-gpu]    # + onnxruntime-gpu
pip install kailash-ml[rl]        # + Stable-Baselines3, Gymnasium
pip install kailash-ml[agents]    # + kailash-kaizen (agent integration)
pip install kailash-ml[xgb]       # + XGBoost
pip install kailash-ml[catboost]  # + CatBoost
pip install kailash-ml[explain]    # + SHAP (model explainability)
pip install kailash-ml[imbalance]  # + imbalanced-learn (SMOTE, ADASYN)
pip install kailash-ml[full]      # Everything
```

## 6 Core Engines

| Engine               | Purpose                                   | Key Pattern                                     |
| -------------------- | ----------------------------------------- | ----------------------------------------------- |
| **FeatureStore**     | Feature ingestion + point-in-time queries | ConnectionManager-backed, polars-native         |
| **ModelRegistry**    | Model versioning + lifecycle              | staging → shadow → production → archived        |
| **TrainingPipeline** | Schema-driven training + eval + calibrate | FeatureStore + ModelRegistry integration        |
| **InferenceServer**  | Model serving + batch inference           | Nexus HTTP exposure, ONNX runtime, caching      |
| **DriftMonitor**     | Statistical drift detection               | KS, chi-squared, PSI, Jensen-Shannon divergence |
| **ModelExplainer**   | SHAP-based model explainability           | Global/local/dependence explanations, plotly    |

## Quick Start

### Feature Ingestion

```python
from kailash.db.connection import ConnectionManager
from kailash_ml import FeatureStore
from kailash_ml.types import FeatureSchema, FeatureField
import polars as pl

conn = ConnectionManager("sqlite:///ml.db")
await conn.initialize()

schema = FeatureSchema(
    name="user_churn",
    features=[
        FeatureField(name="age", dtype="float"),
        FeatureField(name="tenure_months", dtype="float"),
    ],
    target=FeatureField(name="churned", dtype="int"),
)

fs = FeatureStore(conn, table_prefix="kml_feat_")
await fs.initialize()

df = pl.read_csv("data.csv")
await fs.ingest("user_features", schema, df)
```

### Training

```python
from kailash_ml import TrainingPipeline, ModelRegistry, ModelSpec, EvalSpec
from kailash_ml.engines import LocalFileArtifactStore

registry = ModelRegistry(conn, artifact_store=LocalFileArtifactStore("./artifacts"))
await registry.initialize()

pipeline = TrainingPipeline(feature_store=fs, model_registry=registry)
result = await pipeline.train(
    schema=schema,
    model_spec=ModelSpec(model_class="sklearn.ensemble.RandomForestClassifier"),
    eval_spec=EvalSpec(metrics=["accuracy", "f1"]),
)
```

### Drift Monitoring

```python
from kailash_ml import DriftMonitor

monitor = DriftMonitor(conn)
await monitor.initialize()
await monitor.set_reference("model_v1", reference_df)
report = await monitor.check_drift("model_v1", current_df)
# report.overall_drift, report.feature_results, report.recommendations
```

### Model Explainability (requires `[explain]`)

```python
from kailash_ml import ModelExplainer

explainer = ModelExplainer(model=fitted_model, X=train_df, feature_names=schema.feature_names)
global_report = explainer.explain_global(max_display=10)
# global_report["feature_importance"]: sorted feature → mean |SHAP| dict
local_report = explainer.explain_local(X=test_df, index=0)
# local_report["feature_contributions"]: per-feature SHAP for one prediction
fig = explainer.to_plotly("summary")  # "summary", "beeswarm", "dependence"
```

### Preprocessing Pipeline

```python
from kailash_ml.engines import PreprocessingPipeline

pipeline = PreprocessingPipeline()
result = pipeline.setup(
    data=df, target="churned",
    normalize=True, normalize_method="zscore",       # zscore, minmax, robust, maxabs
    imputation="knn", impute_n_neighbors=5,           # knn, iterative, or default (median/mode)
    remove_multicollinearity=True, multicollinearity_threshold=0.9,
    fix_imbalance=True, imbalance_method="smote",     # smote, adasyn (requires [imbalance])
)
# result.X_train, result.X_test, result.y_train, result.y_test
```

### Model Calibration

```python
result = await pipeline.calibrate(
    model_name="churn_v1",
    method="isotonic",  # "platt" (sigmoid) or "isotonic"
    cv=5,
)
# Returns calibrated model with CalibratedClassifierCV
```

### Nested Runs & Auto-Logging

```python
from kailash_ml import ExperimentTracker

tracker = ExperimentTracker(conn)
await tracker.initialize()

# Nested runs — group trials under a parent
async with tracker.run("hyperopt-sweep") as parent:
    for params in param_grid:
        async with tracker.run("trial", parent_run_id=parent.run_id) as child:
            await child.log_params(params)

# Auto-logging — TrainingPipeline and HyperparameterSearch log automatically
pipeline = TrainingPipeline(feature_store=fs, model_registry=registry, experiment_tracker=tracker)
result = await pipeline.train(schema=schema, model_spec=spec, eval_spec=eval_spec)
# Metrics, params, and artifacts logged to tracker automatically
```

### Inference Validation

```python
server = InferenceServer(model_registry=registry)
# Raises ValueError if input DataFrame is missing required features
prediction = await server.predict("model_v1", input_df)
```

## Decision Tree: kailash-ml vs kailash-align vs kailash-kaizen

| You Want To...                        | Use                                                 |
| ------------------------------------- | --------------------------------------------------- |
| Train sklearn/LightGBM/XGBoost models | **kailash-ml**                                      |
| Manage feature pipelines              | **kailash-ml**                                      |
| Monitor model drift                   | **kailash-ml**                                      |
| Export models to ONNX                 | **kailash-ml**                                      |
| Fine-tune an LLM (LoRA, DPO, RLHF)    | **kailash-align**                                   |
| Serve a fine-tuned LLM via Ollama     | **kailash-align**                                   |
| Build an AI agent with tools          | **kailash-kaizen**                                  |
| Add agent intelligence to ML engines  | **kailash-ml[agents]** (uses Kaizen under the hood) |
| Train RL policies (Gymnasium)         | **kailash-ml[rl]**                                  |

## Architecture

```
kailash-ml/
  engines/
    _shared.py              <- Numeric dtypes, model class validation
    _feature_sql.py         <- ALL raw SQL (zero SQL in engine files)
    _guardrails.py          <- AgentGuardrailMixin (5 mandatory guardrails)
    feature_store.py        <- FeatureStore (ConnectionManager, polars-native)
    model_registry.py       <- ModelRegistry (lifecycle, SHA256 integrity)
    training_pipeline.py    <- TrainingPipeline (schema-driven)
    inference_server.py     <- InferenceServer (Nexus, ONNX, caching)
    drift_monitor.py        <- DriftMonitor (KS/chi2/PSI/JS)
    model_explainer.py      <- ModelExplainer (SHAP, requires [explain])
    experiment_tracker.py   <- MLflow-compatible run tracking (nested runs, auto-logging)
    hyperparameter_search.py <- Grid/random/bayesian/successive halving
    automl_engine.py        <- Agent-infused AutoML
    ensemble.py             <- Blend/stack/bag/boost
    preprocessing.py        <- Auto-setup from FeatureSchema
  agents/                   <- 6 Kaizen agents (requires kailash-ml[agents])
    tools.py                <- Dumb data endpoints (LLM-first)
  rl/                       <- RLTrainer, EnvironmentRegistry, PolicyRegistry
  interop.py                <- SOLE conversion point (polars <-> sklearn/pandas/arrow)
  bridge/                   <- OnnxBridge (export + verification)
```

## Polars-Native Rule (ABSOLUTE)

Every engine accepts and returns `polars.DataFrame`. Conversion to numpy/pandas/LightGBM Dataset happens ONLY in `interop.py` at sklearn/framework boundaries.

```python
# DO: Work in polars throughout
df = pl.read_csv("data.csv")
await fs.ingest("features", schema, df)

# DO NOT: Convert to pandas first
df_pd = pd.read_csv("data.csv")  # WRONG -- polars is the native format
```

## 6 ML Agents (kailash-ml[agents])

Agents require both `agent=True` AND the agents extra installed. All follow LLM-first rule.

| Agent                      | Purpose                        |
| -------------------------- | ------------------------------ |
| DataScientistAgent         | Data profiling recommendations |
| FeatureEngineerAgent       | Feature generation guidance    |
| ModelSelectorAgent         | Model selection reasoning      |
| ExperimentInterpreterAgent | Trial result analysis          |
| DriftAnalystAgent          | Drift report interpretation    |
| RetrainingDecisionAgent    | Retrain/rollback decisions     |

See [ml-agent-guardrails](ml-agent-guardrails.md) for the 5 mandatory guardrails.

## RL Module (kailash-ml[rl])

```python
from kailash_ml.rl import RLTrainer, EnvironmentRegistry, PolicyRegistry

env_reg = EnvironmentRegistry()
env_reg.register("CartPole-v1")

trainer = RLTrainer(env_registry=env_reg, policy_registry=PolicyRegistry())
result = await trainer.train(env_id="CartPole-v1", algorithm="PPO", total_timesteps=100_000)
```

## Security

- **SQL safety**: `_feature_sql.py` is the sole SQL touchpoint. `_validate_identifier()` on all interpolated identifiers.
- **Model class allowlist**: `validate_model_class()` restricts imports to: `sklearn.`, `lightgbm.`, `xgboost.`, `catboost.`, `kailash_ml.`, `torch.`, `lightning.`
- **Financial validation**: `math.isfinite()` on all budget/cost fields (NaN bypasses comparisons, Inf defeats bounds).
- **Bounded collections**: `deque(maxlen=N)` for audit trails, cost logs, trial history.

## Skill Files

- [ml-feature-pipelines](ml-feature-pipelines.md) — FeatureStore, polars-only engineering, schema-driven ingestion
- [ml-model-registry](ml-model-registry.md) — ModelRegistry CRUD, lifecycle stages, MLflow compatibility
- [ml-training-pipeline](ml-training-pipeline.md) — TrainingPipeline, hyperparameter search, experiment tracking
- [ml-inference-server](ml-inference-server.md) — InferenceServer, Nexus exposure, ONNX serving, batch inference
- [ml-agent-guardrails](ml-agent-guardrails.md) — 5 mandatory guardrails, AutoML, agent integration
- [ml-onnx-export](ml-onnx-export.md) — PyTorch/sklearn to ONNX, verification, cross-language serving
- [ml-drift-monitoring](ml-drift-monitoring.md) — DriftMonitor, statistical tests, alert thresholds, retraining triggers

## Critical Rules

- All engines are polars-native — no pandas/numpy in pipeline code
- sklearn interop only at boundary via `interop.py`
- FeatureStore uses ConnectionManager, not Express (needs window functions)
- Zero raw SQL outside `_feature_sql.py`
- Agent-augmented engines require double opt-in (`agent=True` + extras installed)
- All agents follow LLM-first rule — tools are dumb data endpoints

## Related Skills

- [01-core-sdk](../01-core-sdk/SKILL.md) — Core workflow patterns
- [02-dataflow](../02-dataflow/SKILL.md) — Database integration (ConnectionManager)
- [03-nexus](../03-nexus/SKILL.md) — Multi-channel deployment (InferenceServer)
- [04-kaizen](../04-kaizen/SKILL.md) — AI agent framework (ML agents)
- [35-kailash-align](../35-kailash-align/SKILL.md) — LLM fine-tuning and alignment
