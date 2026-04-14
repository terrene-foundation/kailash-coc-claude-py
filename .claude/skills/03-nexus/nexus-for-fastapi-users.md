---
skill: nexus-for-fastapi-users
description: Nexus pattern translation for developers familiar with route-first HTTP frameworks
priority: HIGH
tags: [nexus, translation, onboarding, routes, handlers, api]
---

# Nexus for Route-First Developers

Nexus is workflow-first: register once, get API + CLI + MCP. This guide translates common route-first patterns into Nexus equivalents.

## Route Definition

```python
# Route-first: one decorator per endpoint
@app.get("/items/{id}")
async def get_item(id: int): ...

@app.post("/items")
async def create_item(item: ItemModel): ...

# Nexus: one handler, all channels
@app.handler("get_item")
async def get_item(id: int) -> dict:
    return {"item": await db.express.read("Item", id)}

# Result: POST /workflows/get_item/execute + CLI + MCP
```

## Request Validation

```python
# Route-first: Pydantic model as parameter
class OrderRequest(BaseModel):
    user_id: str
    amount: float
    items: list[str]

@app.post("/orders")
async def create_order(order: OrderRequest): ...

# Nexus: type annotations on handler function
@app.handler("create_order")
async def create_order(user_id: str, amount: float, items: list[str]) -> dict:
    return {"status": "created"}

# Request: POST /workflows/create_order/execute
# Body: {"inputs": {"user_id": "123", "amount": 99.99, "items": ["a", "b"]}}
```

## Dependency Injection

```python
# Route-first: Depends() for request-scoped dependencies
def get_current_user(token: str = Depends(oauth2_scheme)):
    return verify_token(token)

@app.get("/profile")
async def get_profile(user=Depends(get_current_user)): ...

# Nexus: session context via X-Session-ID header
@app.handler("get_profile")
async def get_profile(session_id: str) -> dict:
    session = app.session_manager.get(session_id)
    user = session.metadata.get("user")
    return {"user": user}
```

## Middleware

```python
# Route-first
from starlette.middleware.cors import CORSMiddleware
app.add_middleware(CORSMiddleware, allow_origins=["*"])

# Nexus: identical API
app = Nexus()
app.add_middleware(CORSMiddleware, allow_origins=["*"])
```

## Authentication (JWT + RBAC)

```python
# Route-first: manual JWT setup across multiple files
# security.py, dependencies.py, middleware.py ...

# Nexus: single plugin
from nexus.auth import create_auth_plugin

auth_plugin = create_auth_plugin(
    jwt_secret="your-secret-key",
    algorithm="HS256",
    roles={
        "admin": ["read:*", "write:*"],
        "user": ["read:posts"],
    },
)
app = Nexus()
app.add_plugin(auth_plugin)

# Request: curl -H "Authorization: Bearer eyJ..." ...
```

## Streaming / SSE

```python
# Route-first: StreamingResponse
from starlette.responses import StreamingResponse

@app.get("/stream")
async def stream():
    return StreamingResponse(generate(), media_type="text/event-stream")

# Nexus: SSE via event system
# See nexus-eventbus-phase2.md for /events/stream endpoint
```

## DataFlow Auto-CRUD

```python
# Route-first: write 5 CRUD endpoints per model manually

# Nexus: zero endpoints written
app = Nexus(auto_discovery=False)
db = DataFlow("postgresql://...", models=[User, Post, Comment])
app.register_dataflow(db)
# Result: /api/User/create, /api/User/read, /api/User/list, etc.
```

## Key Mental Model Shift

| Concept      | Route-first         | Nexus                    |
| ------------ | ------------------- | ------------------------ |
| Unit of work | HTTP endpoint       | Handler or workflow      |
| Registration | Per-verb, per-path  | Once, all channels       |
| Channels     | HTTP only           | API + CLI + MCP          |
| Auth         | Manual per-route    | Plugin, applied globally |
| Sessions     | External store      | Built-in, cross-channel  |
| CRUD         | Write each endpoint | DataFlow auto-generates  |
