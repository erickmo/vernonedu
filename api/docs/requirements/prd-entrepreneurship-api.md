# PRD: Entrepreneurship API

**Versi:** 1.0.0
**Tanggal:** March 2026
**Status:** Production Ready
**Stack:** Go / Clean Architecture + CQRS + Event-Driven Architecture
**Module:** `github.com/erickmo/vernonedu-entrepreneurship-api`
**Author:** AI-Generated (Go Project Init Skill)

---

## 1. Overview

### 1.1 Latar Belakang

Entrepreneurship API adalah backend service untuk platform Vernon Edu yang fokus pada entrepreneurship education. Service ini menyediakan REST API untuk mengelola entities utama dalam entrepreneurial journey: Users, Businesses, Value Proposition Canvases, Design Thinking exercises, dan Items.

### 1.2 Tujuan

1. **Provide scalable REST API** untuk entrepreneurship platform
2. **Maintain data consistency** melalui event-driven architecture
3. **Enable real-time observability** dengan OpenTelemetry + Prometheus
4. **Support concurrent operations** dengan CQRS pattern
5. **Ensure code quality** melalui clean architecture principles

### 1.3 Success Metrics

- API latency (p95) < 50ms
- Uptime > 99.9%
- Test coverage ≥ 80%
- Zero security vulnerabilities
- <10ms database query time (with caching)

---

## 2. Domain Model

### 2.1 Entities

| Entity | Purpose | Key Attributes |
|--------|---------|-----------------|
| **User** | Platform users/entrepreneurs | ID, Name, CreatedAt, UpdatedAt |
| **Business** | Business entities being developed | ID, Name, CreatedAt, UpdatedAt |
| **Value Proposition Canvas** | Business canvas tool | ID, Name, CreatedAt, UpdatedAt |
| **Design Thinking** | Design thinking exercise | ID, Name, CreatedAt, UpdatedAt |
| **Item** | Generic item for various purposes | ID, Name, CreatedAt, UpdatedAt |

### 2.2 Data Model

```
User {
  id: UUID (PK)
  name: String (required, unique: false)
  created_at: Timestamp
  updated_at: Timestamp
}

Business {
  id: UUID (PK)
  name: String (required)
  created_at: Timestamp
  updated_at: Timestamp
}

ValuePropositionCanvas {
  id: UUID (PK)
  name: String (required)
  created_at: Timestamp
  updated_at: Timestamp
}

DesignThinking {
  id: UUID (PK)
  name: String (required)
  created_at: Timestamp
  updated_at: Timestamp
}

Item {
  id: UUID (PK)
  name: String (required)
  created_at: Timestamp
  updated_at: Timestamp
}
```

---

## 3. Commands & Queries

### 3.1 Commands (Write Operations)

| Command | Handler | Domain Event | Use Case |
|---------|---------|--------------|----------|
| **CreateUser** | create_user/ | UserCreated | Register new user |
| **UpdateUser** | update_user/ | UserUpdated | Modify user info |
| **DeleteUser** | delete_user/ | UserDeleted | Remove user account |
| **CreateBusiness** | create_business/ | BusinessCreated | Register new business |
| **UpdateBusiness** | update_business/ | BusinessUpdated | Update business info |
| **DeleteBusiness** | delete_business/ | BusinessDeleted | Delete business |
| **CreateCanvas** | create_canvas/ | ValuePropositionCanvasCreated | Create business canvas |
| **UpdateCanvas** | update_canvas/ | ValuePropositionCanvasUpdated | Modify canvas |
| **DeleteCanvas** | delete_canvas/ | ValuePropositionCanvasDeleted | Remove canvas |
| **CreateDesignThinking** | create_designthinking/ | DesignThinkingCreated | Create design exercise |
| **UpdateDesignThinking** | update_designthinking/ | DesignThinkingUpdated | Modify design exercise |
| **DeleteDesignThinking** | delete_designthinking/ | DesignThinkingDeleted | Delete design exercise |
| **CreateItem** | create_item/ | ItemCreated | Create generic item |
| **UpdateItem** | update_item/ | ItemUpdated | Update item |
| **DeleteItem** | delete_item/ | ItemDeleted | Delete item |

### 3.2 Queries (Read Operations)

| Query | Handler | Read Model | Use Case |
|-------|---------|------------|----------|
| **GetUser** | get_user/ | UserReadModel | Fetch user details |
| **ListUser** | list_user/ | UserReadModel[] | List all users (paginated) |
| **SearchUser** | search_user/ | UserReadModel[] | Search users by name |
| **GetBusiness** | get_business/ | BusinessReadModel | Fetch business details |
| **ListBusiness** | list_business/ | BusinessReadModel[] | List all businesses |
| **SearchBusiness** | search_business/ | BusinessReadModel[] | Search businesses |
| **GetCanvas** | get_canvas/ | CanvasReadModel | Fetch canvas details |
| **ListCanvas** | list_canvas/ | CanvasReadModel[] | List all canvases |
| **SearchCanvas** | search_canvas/ | CanvasReadModel[] | Search canvases |
| **GetDesignThinking** | get_designthinking/ | DesignThinkingReadModel | Fetch design thinking |
| **ListDesignThinking** | list_designthinking/ | DesignThinkingReadModel[] | List design exercises |
| **SearchDesignThinking** | search_designthinking/ | DesignThinkingReadModel[] | Search design exercises |
| **GetItem** | get_item/ | ItemReadModel | Fetch item details |
| **ListItem** | list_item/ | ItemReadModel[] | List all items |
| **SearchItem** | search_item/ | ItemReadModel[] | Search items |

### 3.3 Domain Events

Events published setelah command berhasil diexecute:

```
UserCreated {
  user_id: UUID
  name: String
  timestamp: Unix timestamp
}

UserUpdated {
  user_id: UUID
  name: String
  timestamp: Unix timestamp
}

UserDeleted {
  user_id: UUID
  timestamp: Unix timestamp
}

[Similar structure untuk Business, Canvas, DesignThinking, Item]
```

### 3.4 Event Handlers (Side Effects)

Saat ini: No configured side effects (minimal handlers).

Future side effects dapat ditambahkan:
- Email notifications (UserCreated → send welcome email)
- Webhooks (BusinessCreated → notify external systems)
- Cache invalidation (UserUpdated → clear Redis)
- Audit logging (all events → append to audit log)

---

## 4. API Endpoints & Contracts

### 4.1 Response Format

**Success Response:**
```json
{
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "John Doe",
    "created_at": 1234567890,
    "updated_at": 1234567890
  }
}
```

**List Response:**
```json
{
  "data": {
    "data": [{ ... }, { ... }],
    "total": 100,
    "offset": 0,
    "limit": 10
  }
}
```

**Error Response:**
```json
{
  "error": "error message"
}
```

### 4.2 HTTP Status Codes

| Code | Scenario |
|------|----------|
| 200 | Success (GET, PUT) |
| 201 | Created (POST) |
| 400 | Bad request / validation error |
| 404 | Not found |
| 500 | Internal server error |

### 4.3 Users API

```
POST /api/v1/users
Body: { "name": "John Doe" }
Response: 201, { "data": { "id": "...", "name": "John Doe", ... } }

GET /api/v1/users?offset=0&limit=10
Response: 200, { "data": { "data": [...], "total": 100, ... } }

GET /api/v1/users/search?name=john&offset=0&limit=10
Response: 200, { "data": { "data": [...], "total": 5, ... } }

GET /api/v1/users/{id}
Response: 200, { "data": { "id": "...", "name": "John Doe", ... } }

PUT /api/v1/users/{id}
Body: { "name": "Jane Doe" }
Response: 200, { "message": "user updated successfully" }

DELETE /api/v1/users/{id}
Response: 200, { "message": "user deleted successfully" }
```

### 4.4 Other Entities

Same pattern as Users API, dengan endpoint paths:
- `/api/v1/businesses` → Businesses
- `/api/v1/canvases` → Value Proposition Canvases
- `/api/v1/design-thinkings` → Design Thinkings
- `/api/v1/items` → Items

---

## 5. Non-Functional Requirements

### 5.1 Performance

| Metric | Target |
|--------|--------|
| API Latency (p95) | < 50ms |
| DB Query Time | < 10ms (with cache) |
| Cache Hit Ratio | > 80% |
| Throughput | > 1000 req/s per instance |

### 5.2 Availability & Reliability

| Requirement | Target |
|-------------|--------|
| Uptime | > 99.9% |
| Database Replication | RTO < 5min, RPO < 1min |
| Disaster Recovery | Backup every 24h, testable |
| Max Request Time | 30s (timeout) |

### 5.3 Security

- Input validation on all endpoints
- UUID for resource identification (not sequential IDs)
- HTTPS only (enforced via reverse proxy)
- CORS configured for trusted origins
- Rate limiting per IP (future implementation)
- Request logging without sensitive data

### 5.4 Scalability

- Stateless API servers (horizontal scaling)
- Read replicas for PostgreSQL (if needed)
- Redis for caching layer
- NATS for event distribution
- Load balancing support

### 5.5 Testing

| Type | Coverage | Tool |
|------|----------|------|
| Unit | > 70% | testify |
| Integration | > 60% | testcontainers-go |
| E2E | Core flows | Manual/Postman |

### 5.6 Observability

- Structured logging (zerolog) → JSON stdout
- Distributed tracing (OpenTelemetry) → Jaeger
- Metrics (Prometheus) → Request count/latency/errors
- Health checks → `/health` endpoint

---

## 6. Technical Design

### 6.1 Architecture Pattern

**Clean Architecture + CQRS + Event-Driven**

```
┌─────────────────────────────────────────┐
│           HTTP Request                   │
└────────────────────┬────────────────────┘
                     │
┌────────────────────▼────────────────────┐
│      Delivery Layer (HTTP Handler)       │
│  - Request validation                    │
│  - Dispatch to CommandBus/QueryBus       │
└────────────────────┬────────────────────┘
                     │
        ┌────────────┴───────────┐
        │                        │
┌───────▼────────┐      ┌───────▼─────────┐
│  CommandBus    │      │   QueryBus      │
│ (with hooks)   │      │  (read-only)    │
└───────┬────────┘      └───────┬─────────┘
        │                       │
┌───────▼────────┐      ┌───────▼─────────┐
│    Command     │      │     Query       │
│   Handlers     │      │    Handlers     │
└───────┬────────┘      └───────┬─────────┘
        │                       │
┌───────▼────────────────────────▼─────────┐
│          Domain Layer                     │
│  - Entities (User, Business, ...)         │
│  - Domain Events (UserCreated, ...)       │
│  - Repository Interfaces                  │
└───────┬────────────────────────┬──────────┘
        │                        │
        │                    ┌───▼──────────┐
        │                    │   EventBus   │
        │                    │  (NATS/IM)   │
        │                    └───┬──────────┘
        │                        │
┌───────▼────────────────────────▼──────────┐
│      Infrastructure Layer                  │
│  - PostgreSQL Repository (write)           │
│  - PostgreSQL Read (queries)               │
│  - Redis Cache                             │
│  - Event Handlers                          │
└──────────────────────────────────────────┘
```

### 6.2 Technology Stack

**Runtime & DI:**
- Go 1.23+
- Uber FX (dependency injection)

**Web Framework:**
- Chi v5 (HTTP router)

**Database:**
- PostgreSQL 16 (write path)
- sqlx (query builder)
- Migrations (auto on startup)
- Redis 7 (caching)

**Events & Messaging:**
- Watermill (event framework)
- NATS JetStream (production)
- In-Memory (development fallback)

**Observability:**
- OpenTelemetry (tracing)
- Prometheus (metrics)
- Jaeger (tracing backend)
- zerolog (logging)

**Validation & Utilities:**
- go-playground/validator
- google/uuid
- spf13/viper (config)

**Testing:**
- testcontainers-go
- testify (assertions)

---

## 7. Implementation Roadmap

### Phase 1: MVP (Current - Week 1)
- ✅ 5 domain entities (User, Business, Canvas, DesignThinking, Item)
- ✅ CRUD operations (Create, Read, Update, Delete)
- ✅ Basic REST API
- ✅ PostgreSQL integration
- ✅ OTel tracing
- ✅ Event publishing

### Phase 2: Enhancement (Week 2-3)
- [ ] Caching layer optimization
- [ ] Webhook support for events
- [ ] Email notifications (UserCreated)
- [ ] Rate limiting
- [ ] Advanced search/filtering

### Phase 3: Advanced (Week 4+)
- [ ] JWT authentication
- [ ] Role-based access control (RBAC)
- [ ] API versioning
- [ ] GraphQL API (optional)
- [ ] Batch operations
- [ ] Audit logging

---

## 8. Deployment

### 8.1 Docker

```bash
# Build image
docker build -t entrepreneurship-api:latest .

# Run container
docker run -p 8080:8080 \
  --env-file .env \
  entrepreneurship-api:latest
```

### 8.2 Kubernetes (Future)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: entrepreneurship-api
spec:
  replicas: 3
  # ... (standard k8s manifest)
```

### 8.3 Monitoring Setup

```bash
# Prometheus targets
# - localhost:9090/metrics

# Jaeger UI
# - http://localhost:16686

# Alert rules
# - > 1000 request errors/min → page oncall
```

---

## 9. Data Migration & Compliance

### 9.1 Database Migration

- Migrations stored in `migrations/` folder
- Auto-run on application startup
- Rollback support via `migrate down`
- Tested in CI/CD

### 9.2 Compliance

- GDPR ready (data export, deletion)
- Audit logging (future phase)
- Encryption at rest (future phase)

---

## 10. Open Questions & Future Decisions

- [ ] Multi-tenancy support? (Currently single-tenant)
- [ ] Relationship between entities? (Currently independent)
- [ ] User authentication method? (JWT, OAuth2, API keys?)
- [ ] Payment integration? (For premium features)
- [ ] File uploads? (For design materials)
- [ ] Real-time collaboration? (WebSockets)

---

## Appendix: Command Examples

### Create User
```bash
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Entrepreneur"}'
```

### List Users
```bash
curl http://localhost:8080/api/v1/users?offset=0&limit=10
```

### Search Users
```bash
curl "http://localhost:8080/api/v1/users/search?name=john&limit=5"
```

### Update User
```bash
curl -X PUT http://localhost:8080/api/v1/users/{id} \
  -H "Content-Type: application/json" \
  -d '{"name":"Jane Entrepreneur"}'
```

### Delete User
```bash
curl -X DELETE http://localhost:8080/api/v1/users/{id}
```

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | March 2026 | AI-Generated | Initial PRD |

---

**Generated with Go Project Init Skill**
**Next Update Recommended:** After Phase 1 implementation complete (Week 2)
