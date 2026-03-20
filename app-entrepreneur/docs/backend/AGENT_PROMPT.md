# VernonEdu Entrepreneurship API — Agent Implementation Prompt

**Copy-paste this prompt ke agent Go untuk build API backend**

---

## 📝 FULL PROMPT

```
Anda ditugaskan untuk membangun production-grade Go REST API untuk VernonEdu Entrepreneurship Platform.

CONTEXT:
- Frontend Flutter dengan Canvas-based worksheet UI sudah selesai
- Ada 5 jenis worksheet: BMC, VPC, DT, PESTEL, Flywheel
- API spec lengkap sudah ada di docs/api_dev/v1.0.0.md
- Database schema + migrations sudah di docs/backend/DATABASE_SCHEMA.md
- Deployment guide ada di docs/backend/DEPLOYMENT_GUIDE.md
- Implementation spec ada di docs/backend/IMPLEMENTATION_SPEC.md

TARGET STACK:
- Language: Go 1.22+
- Web Framework: Chi + Uber FX DI
- Database: PostgreSQL 15+
- Cache: Redis 7+
- Auth: JWT (HS256)
- Testing: testify + testcontainers

PROJECT REPOSITORY STRUCTURE:
```
vernonedu-entrepreneurship-api/
├── cmd/server/main.go
├── internal/
│   ├── config/
│   ├── domain/
│   ├── repository/
│   ├── usecase/
│   ├── handler/
│   ├── middleware/
│   ├── database/migrations/
│   └── utils/
├── pkg/
├── test/
├── deployments/docker/
├── Makefile
├── go.mod
└── docs/
```

DELIVERABLES (Implementation Phases):

PHASE 1: Setup & Infrastructure
- Create Go project structure as specified
- Setup go.mod with all dependencies (Chi, PGX, Redis, JWT, Zap, etc)
- Create docker-compose.yml for local PostgreSQL + Redis
- Create Dockerfile untuk API server
- Create Makefile dengan targets: build, run, test, migrate, seed, lint

PHASE 2: Domain & Database
- Create domain models (User, Business, Worksheet, CanvasItem)
- Implement all 4 PostgreSQL migrations di internal/database/migrations/
- Create migration runner di internal/database/migration.go
- Create seed data
- Verify migrations work dengan `make migrate-up`

PHASE 3: Repository Layer
- Implement UserRepository dengan CRUD + FindByEmail
- Implement BusinessRepository dengan CRUD + ListByOwner + pagination
- Implement WorksheetRepository dengan CRUD + ListByBusiness
- Implement CanvasItemRepository dengan CRUD + ListByWorksheet + BulkUpdate
- Write unit tests untuk setiap repository (mock database)

PHASE 4: Business Logic (Usecases)
- Implement UserUsecase: Login, Register, GetUser
- Implement BusinessUsecase: CRUD operations
- Implement WorksheetUsecase: CRUD + Submit
- Implement CanvasItemUsecase: CRUD + Bulk operations
- Write unit tests untuk logic

PHASE 5: HTTP Handlers & Middleware
- Implement AuthHandler (POST /auth/login)
- Implement BusinessHandler (GET/POST/PUT/DELETE /businesses)
- Implement WorksheetHandler (GET/POST /businesses/{id}/worksheets)
- Implement CanvasItemHandler (POST/PUT/DELETE/PATCH items)
- Implement middleware:
  - AuthMiddleware (JWT verification)
  - ErrorMiddleware (global error handler)
  - RateLimitMiddleware (Redis-based)
  - LoggingMiddleware
- Write integration tests untuk setiap endpoint (testcontainers)

PHASE 6: Configuration & Dependency Injection
- Create config loader dari environment variables
- Setup Uber FX DI container
- Wire dependencies: repos, usecases, handlers, middleware

PHASE 7: Testing & Documentation
- Achieve >=70% code coverage
- Run `go test -v -coverprofile=coverage.out ./...`
- Generate OpenAPI/Swagger documentation
- Create Postman collection
- Document setup + deployment

REQUIREMENTS:

API Endpoints (13 total):
1. POST /auth/login                                  [200/401]
2. GET /businesses                                   [200 + pagination]
3. POST /businesses                                  [201/400/409]
4. GET /businesses/{business_id}                     [200/404]
5. PUT /businesses/{business_id}                     [200/400/404]
6. DELETE /businesses/{business_id}                  [204/404]
7. GET /businesses/{business_id}/worksheets          [200]
8. POST /businesses/{business_id}/worksheets         [201/400]
9. GET /businesses/{business_id}/worksheets/{ws_id}  [200/404]
10. POST /businesses/{business_id}/worksheets/{ws_id}/items        [201/400]
11. PUT /businesses/{business_id}/worksheets/{ws_id}/items/{id}    [200/400/404]
12. DELETE /businesses/{business_id}/worksheets/{ws_id}/items/{id} [204/404]
13. PATCH /businesses/{business_id}/worksheets/{ws_id}/items       [200/400]
14. POST /businesses/{business_id}/worksheets/{ws_id}/submit       [200/400]

Response Format:
```json
{
  "data": { /* actual response */ },
  "pagination": { /* if applicable */ },
  "error": { /* if error */ }
}
```

Error Response Format:
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message",
    "details": [ /* validation errors */ ],
    "request_id": "req_xxx",
    "timestamp": "2026-03-17T..."
  }
}
```

Validation Rules:
- Business: name (1-100), description (optional, max 500)
- Worksheet: type (required, valid enum), title (1-200)
- CanvasItem: text (1-500), note (optional, max 1000), section_id (must exist)

Database:
- 4 tables: users, businesses, worksheets, canvas_items
- Foreign keys dengan CASCADE DELETE
- Proper indexes untuk common queries
- Triggers untuk updated_at timestamps

Authentication:
- JWT dengan HS256 signature
- Header: Authorization: Bearer {token}
- Payload: {sub: user_id, email, iat, exp}
- Expiration: 1 hour
- Password hashing: bcrypt

Rate Limiting:
- GET: 1000/hour
- POST/PUT: 500/hour
- DELETE: 100/hour
- PATCH: 50/hour
- Use Redis untuk tracking
- Return X-RateLimit-* headers

Error Codes (HTTP Status + Code):
- 200 OK
- 201 Created
- 204 No Content
- 400 Bad Request (VALIDATION_ERROR)
- 401 Unauthorized (UNAUTHORIZED)
- 403 Forbidden (FORBIDDEN)
- 404 Not Found (NOT_FOUND)
- 409 Conflict (DUPLICATE_ENTRY)
- 429 Too Many Requests (RATE_LIMIT_EXCEEDED)
- 500 Internal Server Error (INTERNAL_ERROR)

Testing:
- Unit tests untuk semua layers (mocked dependencies)
- Integration tests dengan testcontainers (real DB)
- Handler tests dengan httptest
- Minimum coverage: 70%
- All endpoints tested

Documentation:
- API documentation (OpenAPI/Swagger)
- README dengan setup instructions
- Makefile targets clear
- Environment variables documented
- Example requests (curl, Postman)

Code Quality:
- Run `go vet ./...` — no issues
- Run `golangci-lint ./...` — no issues
- Run `gosec ./...` — no security issues
- Idiomatic Go code
- Proper error handling
- Structured logging dengan Zap

EXAMPLE USAGE (after implementation):

Local Development:
```
# Start postgres + redis
docker-compose -f deployments/docker/docker-compose.yml up -d

# Run migrations
make migrate-up

# Start API
make run

# Test login
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"student@vernonedu.local","password":"password123"}'

# Response:
# {
#   "data": {
#     "access_token": "eyJ...",
#     "token_type": "Bearer",
#     "expires_in": 3600
#   }
# }
```

REFERENCE FILES:
- Full API spec: docs/api_dev/v1.0.0.md
- Database schema: docs/backend/DATABASE_SCHEMA.md
- Implementation guide: docs/backend/IMPLEMENTATION_SPEC.md
- Deployment guide: docs/backend/DEPLOYMENT_GUIDE.md

DELIVERABLE CRITERIA:

✅ Done when:
1. All 13+ endpoints implemented + working
2. Code coverage >= 70% (go test -coverprofile)
3. `go vet ./...` clean
4. `golangci-lint ./...` clean
5. `gosec ./...` clean
6. Docker compose works locally
7. Migrations run successfully
8. All tests pass
9. Integration tests with testcontainers pass
10. Error handling matches spec
11. Rate limiting working
12. JWT auth working
13. Pagination working
14. OpenAPI docs generated + valid
15. README + setup guide complete

TIMELINE ESTIMATE:
- Phase 1-2 (Setup + DB): 1-2 days
- Phase 3-4 (Repos + Usecases): 2-3 days
- Phase 5 (Handlers + Middleware): 2-3 days
- Phase 6-7 (DI + Testing + Docs): 1-2 days
Total: ~7-10 days for complete implementation

START WITH:
1. Initialize Go project + dependencies
2. Create docker-compose.yml
3. Implement database layer (migrations + repos)
4. Implement business logic (usecases)
5. Implement HTTP handlers
6. Add tests + documentation
7. Verify everything works end-to-end

Good luck! If you need clarification on any spec detail, refer to docs/api_dev/v1.0.0.md
```

---

## 📁 Supporting Files Ready

All documentation files are prepared in:
```
docs/backend/
├── IMPLEMENTATION_SPEC.md     ← Full implementation guide
├── DATABASE_SCHEMA.md         ← Schema + migrations detail
├── DEPLOYMENT_GUIDE.md        ← Docker + K8s deployment
├── API_EXAMPLES.md            ← curl + Postman examples
└── AGENT_PROMPT.md            ← This file
```

Plus main API spec:
```
docs/api_dev/v1.0.0.md         ← Complete endpoint reference
```

---

## 🚀 How to Send to Agent

### Option 1: Send Full Prompt
Copy-paste the prompt above dan kirim ke agent.

### Option 2: Send as Document Package
Sediakan links/files:
- `docs/backend/IMPLEMENTATION_SPEC.md`
- `docs/backend/DATABASE_SCHEMA.md`
- `docs/backend/DEPLOYMENT_GUIDE.md`
- `docs/api_dev/v1.0.0.md`

### Option 3: Interactive Setup
1. Share repository dengan agent
2. Agent baca docs/
3. Agent start dari Phase 1
4. Regular check-ins untuk progress

---

## ✅ Verification After Implementation

```bash
# 1. Code quality
go vet ./...
golangci-lint run
gosec ./...

# 2. Tests
go test -v -race -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# 3. Build
make build

# 4. Docker
docker-compose -f deployments/docker/docker-compose.yml up -d
docker-compose logs -f api

# 5. Test endpoints
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"student@vernonedu.local","password":"password123"}'

# 6. Coverage check
coverage=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | sed 's/%//')
echo "Coverage: $coverage%"
```

---

**Ready to hand off to agent! 🎯**
