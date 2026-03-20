# VernonEdu Entrepreneurship API — Go Backend Implementation Spec

**Version:** 1.0.0
**Status:** Ready for Implementation
**Last Updated:** 2026-03-17
**Target Stack:** Go (Chi/Uber FX), PostgreSQL, Redis, JWT Auth

---

## 📋 Executive Summary

Implementasi backend API untuk VernonEdu Entrepreneurship Platform. Frontend Flutter sudah jadi dengan canvas-based worksheet UI untuk 5 jenis business planning tools:
- Business Model Canvas (BMC)
- Value Proposition Canvas (VPC)
- Design Thinking (DT)
- PESTEL Analysis
- Flywheel Marketing

Tugas Anda: **Build production-grade Go API yang mengimplementasikan spec lengkap di `docs/api_dev/v1.0.0.md`**.

---

## 🎯 Deliverables

### Core Requirements
- ✅ 13 REST endpoints (CRUD untuk Business, Worksheet, CanvasItem)
- ✅ PostgreSQL dengan proper migration system
- ✅ JWT authentication + role-based access
- ✅ Error handling sesuai spec
- ✅ Rate limiting (per spec di v1.0.0.md)
- ✅ Request validation
- ✅ Comprehensive logging
- ✅ Docker + docker-compose untuk local dev
- ✅ Database migrations dengan seed data
- ✅ Unit tests + integration tests untuk semua handler

### Quality Gates
- ✅ `go test -cover` minimum 70% coverage
- ✅ `go vet ./...` no issues
- ✅ `golangci-lint` clean
- ✅ All endpoints tested dengan Postman collection

---

## 🏗️ Architecture

### Tech Stack
```
Language:       Go 1.22+
Web Framework:  Chi + Uber FX DI
Database:       PostgreSQL 15+
Cache:          Redis 7+
ORM:            sqlc (compile-time type safety)
Auth:           JWT (HS256)
Validation:     Validator v10
Logging:        Zap or zerolog
Testing:        testify + testcontainers
```

### Why These Choices
- **Go:** Fast, concurrent, production-proven for APIs
- **Chi:** Lightweight, composable middleware, idiomatic Go
- **sqlc:** Type-safe SQL without ORM overhead
- **JWT:** Stateless auth, scalable, standard
- **Testcontainers:** Real DB for integration tests
- **Zap:** Structured logging, high performance

---

## 📁 Project Structure

```
vernonedu-entrepreneurship-api/
│
├── cmd/
│   └── server/
│       └── main.go                 # Entry point, wire dependencies
│
├── internal/
│   ├── config/
│   │   └── config.go               # Load config from env
│   │
│   ├── domain/
│   │   ├── user.go                 # User domain model
│   │   ├── business.go             # Business domain model
│   │   ├── worksheet.go            # Worksheet domain model
│   │   ├── canvas_item.go          # CanvasItem domain model
│   │   └── errors.go               # Domain-specific errors
│   │
│   ├── repository/
│   │   ├── user_repository.go      # User CRUD interface + impl
│   │   ├── business_repository.go  # Business CRUD interface + impl
│   │   ├── worksheet_repository.go # Worksheet CRUD interface + impl
│   │   └── canvas_item_repository.go # CanvasItem CRUD interface + impl
│   │
│   ├── usecase/
│   │   ├── user_usecase.go         # Auth logic
│   │   ├── business_usecase.go     # Business logic
│   │   ├── worksheet_usecase.go    # Worksheet logic
│   │   └── canvas_item_usecase.go  # Canvas item logic
│   │
│   ├── handler/
│   │   ├── auth_handler.go         # POST /auth/login
│   │   ├── business_handler.go     # Business endpoints
│   │   ├── worksheet_handler.go    # Worksheet endpoints
│   │   └── canvas_item_handler.go  # Canvas item endpoints
│   │
│   ├── middleware/
│   │   ├── auth_middleware.go      # JWT verification
│   │   ├── error_middleware.go     # Global error handler
│   │   └── rate_limit_middleware.go # Rate limiting (Redis)
│   │
│   ├── database/
│   │   ├── postgres.go             # DB connection pool
│   │   ├── migration.go            # Run migrations
│   │   ├── migrations/
│   │   │   ├── 001_create_users.sql
│   │   │   ├── 002_create_businesses.sql
│   │   │   ├── 003_create_worksheets.sql
│   │   │   └── 004_create_canvas_items.sql
│   │   └── seeds/
│   │       └── initial_data.sql
│   │
│   └── utils/
│       ├── jwt.go                  # JWT generation/verification
│       ├── response.go             # HTTP response helpers
│       ├── validator.go            # Request validation
│       └── constants.go            # App constants
│
├── pkg/
│   ├── errors/
│   │   └── errors.go               # Custom error types
│   ├── logger/
│   │   └── logger.go               # Zap logger wrapper
│   └── pagination/
│       └── pagination.go           # Pagination helpers
│
├── test/
│   ├── fixtures/
│   │   └── factories.go           # Test data factories
│   └── integration/
│       ├── business_test.go
│       ├── worksheet_test.go
│       └── canvas_item_test.go
│
├── deployments/
│   ├── docker/
│   │   ├── Dockerfile
│   │   └── docker-compose.yml
│   └── k8s/
│       ├── deployment.yaml
│       └── service.yaml
│
├── docs/
│   ├── api.swagger.json
│   ├── SETUP.md
│   └── API_EXAMPLES.md
│
├── Makefile
├── go.mod
├── go.sum
├── .env.example
└── .gitignore
```

---

## 🗄️ Database Schema

### Schema Overview
```sql
-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Businesses
CREATE TABLE businesses (
  id VARCHAR(20) PRIMARY KEY,  -- Format: "bus_" + random
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  status VARCHAR(20) DEFAULT 'draft',  -- draft, submitted, approved
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Worksheets
CREATE TABLE worksheets (
  id VARCHAR(20) PRIMARY KEY,  -- Format: "ws_" + random
  business_id VARCHAR(20) NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,  -- business-model-canvas, value-proposition, etc
  title VARCHAR(200) NOT NULL,
  status VARCHAR(20) DEFAULT 'draft',  -- draft, submitted, approved
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Canvas Items
CREATE TABLE canvas_items (
  id VARCHAR(20) PRIMARY KEY,  -- Format: "item_" + random
  worksheet_id VARCHAR(20) NOT NULL REFERENCES worksheets(id) ON DELETE CASCADE,
  section_id VARCHAR(50) NOT NULL,  -- customer-segments, value-propositions, etc
  text VARCHAR(500) NOT NULL,
  note TEXT,
  is_expanded BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_businesses_owner ON businesses(owner_id);
CREATE INDEX idx_worksheets_business ON worksheets(business_id);
CREATE INDEX idx_canvas_items_worksheet ON canvas_items(worksheet_id);
CREATE INDEX idx_canvas_items_section ON canvas_items(section_id);
CREATE INDEX idx_users_email ON users(email);
```

**Lihat detail lengkap di:** `docs/backend/DATABASE_SCHEMA.md`

---

## 🔐 Authentication

### JWT Flow
```
1. User POST /auth/login dengan email + password
2. Server: hash password, compare dengan stored hash
3. Generate JWT (HS256, secret dari env var)
4. Return: { access_token, token_type: "Bearer", expires_in }
5. Client: attach ke Authorization header untuk request berikutnya

JWT Payload:
{
  "sub": "user_id",
  "email": "user@example.com",
  "iat": 1234567890,
  "exp": 1234571490  // 1 jam
}
```

### Middleware
```go
// Setiap request ke endpoint yang require auth:
// 1. Check Authorization header
// 2. Extract + verify JWT
// 3. Inject user_id ke context
// 4. Proceed atau return 401
```

---

## 📡 API Endpoints

### Reference Lengkap
**Lihat file:** `docs/api_dev/v1.0.0.md`

### Quick Summary
```
POST   /auth/login                                    # Login
GET    /businesses                                   # List
POST   /businesses                                   # Create
GET    /businesses/{business_id}                     # Get
PUT    /businesses/{business_id}                     # Update
DELETE /businesses/{business_id}                     # Delete

GET    /businesses/{business_id}/worksheets          # List worksheets
POST   /businesses/{business_id}/worksheets          # Create worksheet
GET    /businesses/{business_id}/worksheets/{ws_id}  # Get worksheet

POST   /businesses/{business_id}/worksheets/{ws_id}/items           # Add item
PUT    /businesses/{business_id}/worksheets/{ws_id}/items/{item_id} # Update
DELETE /businesses/{business_id}/worksheets/{ws_id}/items/{item_id} # Delete
PATCH  /businesses/{business_id}/worksheets/{ws_id}/items           # Bulk update

POST   /businesses/{business_id}/worksheets/{ws_id}/submit          # Submit worksheet
```

---

## ✅ Validation Rules

### Business
- `name`: Required, 1-100 chars
- `description`: Optional, max 500 chars

### Worksheet
- `type`: Required, valid type (business-model-canvas, value-proposition, design-thinking, pestel, flywheel-marketing)
- `title`: Required, 1-200 chars

### CanvasItem
- `text`: Required, 1-500 chars
- `note`: Optional, max 1000 chars
- `section_id`: Must exist in worksheet sections

**Implementasi:** Gunakan `validator` package untuk tag-based validation.

---

## 🚨 Error Handling

### Error Response Format
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "name",
        "message": "Name is required"
      }
    ],
    "request_id": "req_abc123",
    "timestamp": "2026-03-17T14:20:30Z"
  }
}
```

### Error Codes (HTTP Status + Code)
| HTTP | Code | Meaning |
|------|------|---------|
| 200 | OK | Success |
| 201 | CREATED | Resource created |
| 400 | VALIDATION_ERROR | Invalid input |
| 401 | UNAUTHORIZED | Missing/invalid token |
| 403 | FORBIDDEN | No permission |
| 404 | NOT_FOUND | Resource not found |
| 409 | DUPLICATE_ENTRY | Already exists |
| 429 | RATE_LIMIT_EXCEEDED | Too many requests |
| 500 | INTERNAL_ERROR | Server error |

**Implementasi:** Custom error types dengan HTTP status mapping.

---

## 🔄 Rate Limiting

Dari spec v1.0.0.md:
```
Per hour limits:
- GET: 1000
- POST/PUT: 500
- DELETE: 100
- PATCH: 50

Response headers:
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1642435200 (unix timestamp)
```

**Implementasi:** Redis dengan sliding window counter atau token bucket.

---

## 🧪 Testing

### Coverage Target
- **Overall:** Minimum 70%
- **Handlers:** 90%+
- **Repositories:** 85%+
- **Usecases:** 80%+

### Test Types

#### 1. Unit Tests (testify)
```go
// Contoh: repository/business_repository_test.go
func TestCreateBusiness(t *testing.T) {
  // Arrange
  repo := NewMockRepository()

  // Act
  result, err := repo.Create(...)

  // Assert
  assert.NoError(t, err)
  assert.NotNil(t, result)
}
```

#### 2. Integration Tests (testcontainers)
```go
// Contoh: test/integration/business_test.go
func TestCreateBusinessE2E(t *testing.T) {
  // Spin up PostgreSQL container
  // Run actual queries
  // Verify data persisted
}
```

#### 3. HTTP Handler Tests
```go
// Contoh: handler/business_handler_test.go
func TestCreateBusinessHandler(t *testing.T) {
  req := httptest.NewRequest("POST", "/businesses", body)
  resp := httptest.NewRecorder()

  handler(resp, req)

  assert.Equal(t, http.StatusCreated, resp.Code)
}
```

---

## 🚀 Setup Instructions

### Prerequisites
- Go 1.22+
- PostgreSQL 15+
- Redis 7+
- Docker + Docker Compose (untuk local dev)

### Local Development
```bash
# 1. Clone + setup
git clone <repo>
cd vernonedu-entrepreneurship-api
cp .env.example .env

# 2. Docker stack (Postgres + Redis)
docker-compose up -d

# 3. Install dependencies
go mod download

# 4. Run migrations
make migrate-up

# 5. Seed data (optional)
make seed

# 6. Run server
make run

# 7. Run tests
make test
```

### Environment Variables
```env
# Server
PORT=8080
ENV=development
LOG_LEVEL=debug

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=vernonedu_entrepreneurship
DB_MAX_CONNECTIONS=25

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0

# JWT
JWT_SECRET=your-secret-key-min-32-chars-long
JWT_EXPIRATION=3600

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

---

## 📦 Dependencies (go.mod)

```go
require (
    github.com/go-chi/chi/v5 v5.0.x           // Web framework
    github.com/google/uuid v1.x                // UUID generation
    github.com/golang-jwt/jwt/v5 v5.x          // JWT
    github.com/jackc/pgx/v5 v5.x               // PostgreSQL driver
    github.com/redis/go-redis/v9 v9.x          // Redis client
    github.com/go-playground/validator/v10 v10.x // Validation
    go.uber.org/zap v1.x                       // Logging
    github.com/stretchr/testify v1.x           // Testing
    github.com/testcontainers/testcontainers-go v0.x // Integration tests
)
```

---

## ✨ Implementation Checklist

### Phase 1: Setup & Infrastructure
- [ ] Create Go project structure
- [ ] Setup dependencies (go mod)
- [ ] Create PostgreSQL schema + migrations
- [ ] Setup Redis
- [ ] Docker Compose setup
- [ ] Environment config loading
- [ ] Logger setup (zap)

### Phase 2: Domain & Repository
- [ ] Define domain models (User, Business, Worksheet, CanvasItem)
- [ ] Implement PostgreSQL repositories (CRUD)
- [ ] Add indexes untuk query performance
- [ ] Write repository tests

### Phase 3: Business Logic & Handlers
- [ ] Implement usecases (business logic)
- [ ] Create HTTP handlers untuk semua endpoints
- [ ] Add request validation
- [ ] Add error handling middleware
- [ ] Write handler tests

### Phase 4: Auth & Security
- [ ] Implement JWT generation/verification
- [ ] Add auth middleware
- [ ] Hash passwords (bcrypt)
- [ ] Add rate limiting middleware

### Phase 5: Testing & Docs
- [ ] Write integration tests (testcontainers)
- [ ] Achieve 70%+ code coverage
- [ ] Generate OpenAPI docs
- [ ] Create API examples (curl, Postman)

### Phase 6: Deployment
- [ ] Create Dockerfile
- [ ] Setup docker-compose production config
- [ ] Create Kubernetes manifests (optional)
- [ ] Document deployment process

---

## 📚 Reference Files

| File | Purpose |
|------|---------|
| `docs/api_dev/v1.0.0.md` | Complete API specification |
| `docs/backend/DATABASE_SCHEMA.md` | Detailed DB schema + migrations |
| `docs/backend/DEPLOYMENT_GUIDE.md` | Production deployment checklist |
| `docs/backend/API_EXAMPLES.md` | curl + Postman examples |

---

## 🤝 Integration Points

### With Flutter Frontend
1. **Base URL:** `https://api.vernonedu.local/v1` (or production URL)
2. **Auth Flow:**
   - Flutter sends email+password → get JWT
   - Store JWT in secure storage
   - Attach to every request
3. **Error Handling:** Return same error format as spec
4. **Timestamps:** Always use ISO 8601 UTC

### Postman Collection
- Will be generated from OpenAPI spec
- Share dengan Flutter team untuk integration testing

---

## 📞 Communication

Untuk questions/blockers:
- Create issues di repository
- Jika butuh clarification tentang requirements
- Share progress updates weekly

---

## 🎯 Definition of Done

API dianggap selesai jika:
1. ✅ Semua 13 endpoints implemented + tested
2. ✅ Code coverage ≥ 70%
3. ✅ `go vet` + `golangci-lint` clean
4. ✅ Docker Compose berjalan di local
5. ✅ Database migrations tested
6. ✅ Auth middleware working
7. ✅ Rate limiting implemented
8. ✅ Error handling sesuai spec
9. ✅ Integration tests pass (testcontainers)
10. ✅ OpenAPI docs generated + valid

---

**Ready to build! Tanya jika ada yang unclear.** 🚀
