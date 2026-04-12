---
name: dataflow
description: "Kailash DataFlow — MANDATORY for ALL database, data pipeline, fabric, and cache work. Auto-generates workflow nodes from models. Use proactively when work touches schemas, queries, CRUD, bulk ops, migrations, repositories, connection pools, caches, Redis read-through/write-through, memoization, transactions, vector search, RAG, or 'just a quick query'. Raw SQL, SQLAlchemy, psycopg, peewee, MongoDB drivers, redis-py/aioredis/hiredis, hand-rolled cache layers, hand-rolled repositories BLOCKED. DataFlow is not an ORM — it generates workflow nodes per model."
---

# Kailash DataFlow - Zero-Config Database Framework

DataFlow automatically generates workflow nodes from database models. Not an ORM -- generates nodes that integrate with Kailash's workflow execution model.

## Quick Start

### Express API (Simple CRUD -- 23x faster than workflow-based)

```python
db = DataFlow("sqlite:///app.db")

@db.model
class User:
    id: int
    name: str
    email: str

user = await db.express.create("User", {"name": "Alice", "email": "alice@co.com"})
users = await db.express.list("User", filter={"name": "Alice"})
```

### Workflow API (Complex Multi-Step Operations)

```python
db = DataFlow(connection_string="postgresql://user:pass@localhost/db")

@db.model
class User:
    id: str  # String IDs preserved
    name: str
    email: str

workflow = WorkflowBuilder()
workflow.add_node("User_Create", "create_user", {
    "data": {"name": "John", "email": "john@example.com"}
})

with LocalRuntime() as runtime:
    results, run_id = runtime.execute(workflow.build())
    user_id = results["create_user"]["result"]
```

## Generated Nodes (11 per SQL model)

`{Model}_Create`, `{Model}_Read`, `{Model}_Update`, `{Model}_Delete`, `{Model}_List`, `{Model}_Upsert`, `{Model}_Count`, `{Model}_BulkCreate`, `{Model}_BulkUpdate`, `{Model}_BulkDelete`, `{Model}_BulkUpsert`

## Database Support Matrix

| Database   | Type     | Nodes/Model | Driver    |
| ---------- | -------- | ----------- | --------- |
| PostgreSQL | SQL      | 11          | asyncpg   |
| MySQL      | SQL      | 11          | aiomysql  |
| SQLite     | SQL      | 11          | aiosqlite |
| MongoDB    | Document | 8           | Motor     |
| pgvector   | Vector   | 3           | pgvector  |

## Critical Rules

- String IDs preserved (no UUID conversion)
- Deferred schema operations (safe for async/Docker contexts)
- Multi-instance isolation (one DataFlow per database)
- Result access: `results["node_id"]["result"]`
- NEVER use truthiness checks on filter/data parameters (empty dict `{}` is falsy) -- use `if "filter" in kwargs`
- NEVER use direct SQL when DataFlow nodes exist
- NEVER use SQLAlchemy/Django ORM alongside DataFlow

## Reference Documentation

### Getting Started

- **[dataflow-quickstart](dataflow-quickstart.md)** - Quick start guide
- **[dataflow-installation](dataflow-installation.md)** - Installation and setup
- **[dataflow-models](dataflow-models.md)** - Defining models with @db.model
- **[dataflow-connection-config](dataflow-connection-config.md)** - Database connection and pool config

### Core Operations

- **[dataflow-crud-operations](dataflow-crud-operations.md)** - Create, Read, Update, Delete
- **[dataflow-queries](dataflow-queries.md)** - Query patterns and filtering
- **[dataflow-aggregation](dataflow-aggregation.md)** - SQL aggregation (COUNT/SUM/AVG/MIN/MAX GROUP BY)
- **[dataflow-bulk-operations](dataflow-bulk-operations.md)** - Batch operations
- **[dataflow-transactions](dataflow-transactions.md)** - Transaction management
- **[dataflow-connection-isolation](dataflow-connection-isolation.md)** - ACID guarantees

### Advanced Features

- **[dataflow-multi-instance](dataflow-multi-instance.md)** - Multiple database instances
- **[dataflow-multi-tenancy](dataflow-multi-tenancy.md)** - Multi-tenant architectures
- **[dataflow-existing-database](dataflow-existing-database.md)** - Working with existing databases
- **[dataflow-migrations-quick](dataflow-migrations-quick.md)** - Database migrations
- **[dataflow-custom-nodes](dataflow-custom-nodes.md)** - Custom database nodes
- **[dataflow-sqlite-concurrency](dataflow-sqlite-concurrency.md)** - SQLite WAL mode, connection pooling

### Developer Experience

- **[dataflow-strict-mode](dataflow-strict-mode.md)** - Build-time validation (4-layer, OFF/WARN/STRICT)
- **[dataflow-debug-agent](dataflow-debug-agent.md)** - Intelligent error analysis (5-stage pipeline)
- **ErrorEnhancer** - Automatic error enhancement (40+ DF-XXX codes)
- **Inspector API** - Self-service debugging (18 introspection methods)
- **CLI Tools** - dataflow-validate, dataflow-analyze, dataflow-debug

### Data Fabric Engine

- **[dataflow-fabric-engine](dataflow-fabric-engine.md)** - External data sources (`db.source()`), derived products (`@db.product()`), consumer adapters, cache control, MCP integration
- **[dataflow-fabric-cache-consumers](dataflow-fabric-cache-consumers.md)** - Fabric cache control, consumer adapters, MCP tool generation, virtual products, graceful shutdown

### Provenance & Audit

- **[dataflow-provenance-audit](dataflow-provenance-audit.md)** - Provenance[T] field tracking, SourceType enum, audit trail persistence, EventStoreBackend

### Cache Patterns

- **[cache-cas-fail-closed](cache-cas-fail-closed.md)** - CAS (compare-and-swap) fail-closed pattern when primitive can only be satisfied by one backend

### Enterprise Features

- **[dataflow-derived-models](dataflow-derived-models.md)** - Application-layer materialized views (`@db.derived_model`)
- **[dataflow-file-import](dataflow-file-import.md)** - File ingestion (CSV/Excel/Parquet/JSON)
- **[dataflow-validation-dsl](dataflow-validation-dsl.md)** - Declarative validation (`__validation__` dict)
- **[dataflow-express-cache](dataflow-express-cache.md)** - Model-scoped Express caching with TTL
- **[dataflow-read-replicas](dataflow-read-replicas.md)** - Read/write splitting
- **[dataflow-retention](dataflow-retention.md)** - Data retention policies
- **[dataflow-events](dataflow-events.md)** - Write event emission + EventBus integration

### ML Integration

- **[dataflow-ml-integration](dataflow-ml-integration.md)** - kailash-ml FeatureStore integration

### Monitoring & Troubleshooting

- **[dataflow-monitoring](dataflow-monitoring.md)** - Pool utilization, leak detection, health checks
- **[dataflow-gotchas](dataflow-gotchas.md)** - Common pitfalls

## Related Skills

- **[01-core-sdk](../01-core-sdk/SKILL.md)** - Core workflow patterns (canonical node pattern)
- **[03-nexus](../03-nexus/SKILL.md)** - Multi-channel deployment
- **[04-kaizen](../04-kaizen/SKILL.md)** - AI agent integration
- **[17-gold-standards](../17-gold-standards/SKILL.md)** - Best practices

## Support

- `dataflow-specialist` - DataFlow implementation and patterns
- `testing-specialist` - DataFlow testing strategies (Real infrastructure recommended)
- `decide-framework` skill - Choose between Core SDK and DataFlow
