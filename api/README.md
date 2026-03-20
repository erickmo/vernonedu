# VernonEdu Entrepreneurship API

REST API backend untuk platform entrepreneurship Vernon Edu. Dibangun dengan Go, PostgreSQL, dan Redis.

**Status:** Phase 1 - Infrastructure & Skeleton ✅
**Module:** `github.com/vernonedu/entrepreneurship-api`
**Go Version:** 1.22+

---

## Quick Start

### 1. Prerequisites
- Go 1.22+
- Docker & Docker Compose
- PostgreSQL 15+ (via Docker)
- Redis 7+ (via Docker)

### 2. Setup Local Development

```bash
# Clone dan navigate ke project
cd /Users/erickmo/Desktop/Project/vernonedu/entrepreneurship-api

# Download dependencies
go mod download

# Start Docker services (Postgres + Redis)
docker-compose up -d

# Verify services running
docker-compose ps
```

### 3. Run API Server

```bash
# Build
go build -o ./bin/api ./cmd/api

# Or run directly
go run ./cmd/api/main.go
```

Server akan listen di `http://localhost:8080`

### 4. Health Check

```bash
curl http://localhost:8080/health
# Expected: {"status":"ok"}
```

---

## Project Structure

```
cmd/api/              ← Entry point
internal/
  domain/             ← Business entities (User, Business, Worksheet, CanvasItem)
  command/            ← Command handlers (Create, Update, Delete)
  query/              ← Query handlers (Get, List, Search)
  delivery/http/      ← HTTP API handlers
infrastructure/
  database/           ← Repository implementations
  config/             ← Configuration management
  telemetry/          ← Observability setup
pkg/
  commandbus/         ← CQRS command dispatcher
  querybus/           ← CQRS query dispatcher
  eventbus/           ← Event pub/sub
  middleware/         ← HTTP middleware
  hooks/              ← Validation & logging hooks
migrations/           ← SQL migration files
```

---

## Phase 1 Deliverables ✅

- [x] Project structure initialized
- [x] go.mod with all essential dependencies
- [x] docker-compose.yml (PostgreSQL + Redis)
- [x] Basic main.go entry point
- [x] Configuration infrastructure
- [x] HTTP router with Chi v5
- [x] Makefile for build/test/migrate
- [x] .env.example configuration template
- [x] CLAUDE.md architecture guide

---

## Next Steps (Phase 2+)

1. **Database Migrations** - Create 4 SQL migrations:
   - `001_create_users.sql`
   - `002_create_businesses.sql`
   - `003_create_worksheets.sql`
   - `004_create_canvas_items.sql`

2. **Domain Layer** - Complete entity definitions:
   - User, Business, Worksheet, CanvasItem
   - Repository interfaces
   - Domain events

3. **HTTP Endpoints** - Implement all 14 API endpoints:
   - Business CRUD (5 endpoints)
   - Worksheet CRUD (5 endpoints)
   - Canvas Item operations (4 endpoints)

4. **Authentication** - JWT + Rate Limiting:
   - JWT token generation & validation
   - Redis-based rate limiting
   - Auth middleware

5. **Testing** - Unit + Integration:
   - Testcontainers for DB tests
   - Handler tests with httptest
   - Target: >=70% coverage

6. **Documentation**:
   - Swagger/OpenAPI specs
   - Postman collection
   - API examples

---

## Configuration

Copy `.env.example` ke `.env`:

```bash
cp .env.example .env
```

Edit sesuai kebutuhan. Default sudah cocok untuk local development.

---

## Development Commands

```bash
# Build binary
make build

# Run with hot reload (requires 'air')
make dev

# Run tests
make test

# Run migrations
make migrate-up

# Start infrastructure
make infra-up
make infra-down

# Clean
make tidy
```

---

## API Endpoints (To Be Implemented)

### Authentication
- `POST /auth/login` - Get JWT token

### Businesses
- `GET /businesses` - List businesses (paginated)
- `POST /businesses` - Create business
- `GET /businesses/{id}` - Get business
- `PUT /businesses/{id}` - Update business
- `DELETE /businesses/{id}` - Delete business

### Worksheets
- `GET /businesses/{id}/worksheets` - List worksheets
- `POST /businesses/{id}/worksheets` - Create worksheet
- `GET /businesses/{id}/worksheets/{ws_id}` - Get worksheet
- `POST /businesses/{id}/worksheets/{ws_id}/submit` - Submit worksheet

### Canvas Items
- `POST /businesses/{id}/worksheets/{ws_id}/items` - Add item
- `PUT /businesses/{id}/worksheets/{ws_id}/items/{item_id}` - Update item
- `DELETE /businesses/{id}/worksheets/{ws_id}/items/{item_id}` - Delete item
- `PATCH /businesses/{id}/worksheets/{ws_id}/items` - Bulk update items

---

## Worksheet Types Supported

1. **Business Model Canvas** (9 sections)
2. **Value Proposition Canvas** (6 sections)
3. **Design Thinking** (5 stages)
4. **PESTEL Analysis** (6 factors)
5. **Flywheel Marketing** (5 stages)

---

## Database Schema (Phase 2)

### Users Table
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'student',
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

### Businesses Table
```sql
CREATE TABLE businesses (
  id UUID PRIMARY KEY,
  owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'draft',
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

### Worksheets Table
```sql
CREATE TABLE worksheets (
  id UUID PRIMARY KEY,
  business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(200) NOT NULL,
  status VARCHAR(50) DEFAULT 'draft',
  sections JSONB,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

### Canvas Items Table
```sql
CREATE TABLE canvas_items (
  id UUID PRIMARY KEY,
  worksheet_id UUID REFERENCES worksheets(id) ON DELETE CASCADE,
  section_id VARCHAR(100),
  text TEXT,
  note TEXT,
  is_expanded BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

---

## Authentication

### JWT Token
- **Algorithm:** HS256
- **Payload:** `{sub: user_id, email, iat, exp}`
- **Expiration:** 1 hour
- **Header:** `Authorization: Bearer {token}`

### Password Hashing
- **Algorithm:** bcrypt
- **Cost:** 12

### Rate Limiting (Phase 2)
- GET: 1000/hour
- POST/PUT: 500/hour
- DELETE: 100/hour
- PATCH: 50/hour

---

## Error Response Format

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message",
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

---

## Troubleshooting

### Port 8080 already in use
```bash
# Find process using port 8080
lsof -i :8080

# Kill process
kill -9 <PID>
```

### Database connection failed
```bash
# Verify Docker container running
docker-compose ps

# Check PostgreSQL logs
docker-compose logs postgres

# Reset and restart
docker-compose down
docker-compose up -d
```

### go mod issues
```bash
# Clean up
go mod tidy
rm go.sum
go mod download
```

---

## Reference Documentation

- **Architecture:** `docs/CLAUDE.md`
- **API Specification:** Check entrepreneurship-ui project `docs/api_dev/v1.0.0.md`
- **Database Schema:** Project `docs/backend/DATABASE_SCHEMA.md`
- **Implementation Guide:** Project `docs/backend/IMPLEMENTATION_SPEC.md`

---

## Support

Untuk bantuan development:
1. Baca `CLAUDE.md` untuk architecture overview
2. Check `PROJECT_STRUCTURE.md` untuk file organization
3. Review test examples di `tests/`
4. Consult API spec untuk endpoint requirements

---

**Last Updated:** 2026-03-17
**Status:** Phase 1 Complete - Skeleton Ready for Phase 2 Development
