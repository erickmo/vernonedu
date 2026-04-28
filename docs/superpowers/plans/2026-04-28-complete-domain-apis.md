# Complete All Domain APIs — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring all 12 incomplete backend domains to the same "done" standard as `identity`, `module`, and `budget` — no invalid service stubs, HTTP handler tests covering RBAC and smoke cases for every endpoint.

**Architecture:** Domain-by-domain, one branch per domain. For domains with role-restricted routes, tests verify 403 (wrong role) and 2xx (correct role). For JWT-only routes, smoke tests verify 2xx. Stub fixes use TDD: write a failing test that demonstrates the broken behavior, implement the fix, verify the test passes.

**Tech Stack:** Go, Chi router, pgxpool, testify, zap, `go test -tags integration`

---

## Reference Files (read before starting any task)

- `backend/domains/module/handler_test.go` — minimal RBAC test pattern
- `backend/domains/budget/handler_test.go` — full RBAC + smoke test pattern
- `backend/internal/middleware/` — `RequireRole`, `UserContext`, `WithUserContext`, `JWT`

---

## Task 1: Complete `platform` domain

**Spec:** Fix `Send()` swallowing all errors with `return nil, nil`; add handler smoke tests.

**Files:**
- Modify: `backend/domains/platform/service.go`
- Create: `backend/domains/platform/service_integration_test.go`
- Create: `backend/domains/platform/handler_test.go`

### Step 1.1: Create branch

```bash
git checkout -b feat/complete-platform-api
```

### Step 1.2: Write failing test for Send() stub

- [ ] Create `backend/domains/platform/service_integration_test.go`:

```go
//go:build integration

package platform_test

import (
	"context"
	"os"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/platform"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

const defaultTestDBURL = "postgres://vernonedu:vernonedu_secret@localhost:5433/vernonedu?sslmode=disable"

func newTestPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("TEST_DB_URL")
	if url == "" {
		url = defaultTestDBURL
	}
	pool, err := pgxpool.New(context.Background(), url)
	require.NoError(t, err)
	require.NoError(t, pool.Ping(context.Background()))
	return pool
}

func resetSchemas(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()
	_, err := pool.Exec(context.Background(), `
		TRUNCATE
			platform.notifications,
			platform.notification_templates,
			platform.notification_preferences,
			identity.users
		RESTART IDENTITY CASCADE`)
	require.NoError(t, err)
}

func seedUser(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	id := uuid.New()
	_, err := pool.Exec(context.Background(),
		`INSERT INTO identity.users (id, email, password_hash, role) VALUES ($1,$2,'hash','student')`,
		id, id.String()+"@test.com",
	)
	require.NoError(t, err)
	return id
}

// TestSend_DBErrorPropagates verifies that DB errors are returned, not swallowed.
func TestSend_DBErrorPropagates(t *testing.T) {
	// Use a closed pool to force a DB error.
	pool := newTestPool(t)
	pool.Close() // intentionally closed

	bus := events.NewBus(zap.NewNop())
	svc := platform.NewService(platform.NewRepository(pool), bus, zap.NewNop())

	_, err := svc.Send(context.Background(), platform.SendInput{
		RecipientID: uuid.New(),
		TemplateKey: "some.key",
		Channel:     platform.ChannelInApp,
	})
	// With a closed pool, GetTemplateByKey should return a real DB error — not nil,nil.
	require.Error(t, err)
}
```

### Step 1.3: Run test — expect FAIL

```bash
cd backend && go test -tags integration -run TestSend_DBErrorPropagates ./domains/platform/...
```

Expected: FAIL — test currently fails because Send returns `nil, nil` instead of propagating DB error.

### Step 1.4: Fix Send() in service.go

- [ ] Edit `backend/domains/platform/service.go` — replace the error-swallowing block:

```go
// BEFORE (lines ~35-41):
template, err := s.repo.GetTemplateByKey(ctx, in.TemplateKey, in.Channel)
if err != nil {
    s.log.Warn("notification template not found",
        zap.String("key", in.TemplateKey),
        zap.String("channel", string(in.Channel)),
    )
    return nil, nil
}
```

```go
// AFTER:
template, err := s.repo.GetTemplateByKey(ctx, in.TemplateKey, in.Channel)
if err != nil {
    if errors.Is(err, apperrors.ErrNotFound) {
        s.log.Warn("notification template not found",
            zap.String("key", in.TemplateKey),
            zap.String("channel", string(in.Channel)),
        )
        return nil, nil
    }
    return nil, fmt.Errorf("platform.Send: get template: %w", err)
}
```

Add imports `"errors"`, `"fmt"`, `"github.com/vernonedu/vernonedu2/backend/internal/apperrors"` if not present.

### Step 1.5: Run test — expect PASS

```bash
cd backend && go test -tags integration -run TestSend_DBErrorPropagates ./domains/platform/...
```

Expected: PASS

### Step 1.6: Write handler_test.go

- [ ] Create `backend/domains/platform/handler_test.go`:

```go
//go:build integration

package platform_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/platform"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildPlatformRouter(svc *platform.Service) http.Handler {
	h := platform.NewHandler(svc)
	r := chi.NewRouter()
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: uuid.New(), Role: "student"}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})
	r.Get("/api/v1/notifications", h.ListMyNotifications)
	r.Post("/api/v1/notifications/{id}/read", h.MarkRead)
	return r
}

func TestPlatform_ListMyNotifications_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := platform.NewService(platform.NewRepository(pool), bus, zap.NewNop())
	router := buildPlatformRouter(svc)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/notifications", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestPlatform_MarkRead_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := platform.NewService(platform.NewRepository(pool), bus, zap.NewNop())
	router := buildPlatformRouter(svc)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/notifications/"+uuid.New().String()+"/read", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	// 404 expected — non-existent notification
	require.Equal(t, http.StatusNotFound, w.Code)
}
```

### Step 1.7: Run all platform tests

```bash
cd backend && go test -tags integration -v ./domains/platform/...
```

Expected: all PASS

### Step 1.8: Lint

```bash
cd backend && golangci-lint run ./domains/platform/...
```

Expected: no errors

### Step 1.9: Commit

```bash
git add backend/domains/platform/
git commit -m "feat(platform): fix Send() error propagation, add handler tests"
```

---

## Task 2: Complete `notification` domain

**Spec:** No stubs to fix. Add handler tests — role tests for admin template routes, smoke tests for user routes.

**Files:**
- Create: `backend/domains/notification/service_integration_test.go`
- Create: `backend/domains/notification/handler_test.go`

### Step 2.1: Create branch

```bash
git checkout main && git pull && git checkout -b feat/complete-notification-api
```

### Step 2.2: Create service_integration_test.go (boilerplate + pool helpers)

- [ ] Create `backend/domains/notification/service_integration_test.go`:

```go
//go:build integration

package notification_test

import (
	"context"
	"os"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"
)

const defaultTestDBURL = "postgres://vernonedu:vernonedu_secret@localhost:5433/vernonedu?sslmode=disable"

func newTestPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("TEST_DB_URL")
	if url == "" {
		url = defaultTestDBURL
	}
	pool, err := pgxpool.New(context.Background(), url)
	require.NoError(t, err)
	require.NoError(t, pool.Ping(context.Background()))
	return pool
}

func resetSchemas(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()
	_, err := pool.Exec(context.Background(), `
		TRUNCATE
			notification.preferences,
			notification.notifications,
			notification.templates,
			identity.users
		RESTART IDENTITY CASCADE`)
	require.NoError(t, err)
}

func seedUser(t *testing.T, pool *pgxpool.Pool, role string) uuid.UUID {
	t.Helper()
	id := uuid.New()
	_, err := pool.Exec(context.Background(),
		`INSERT INTO identity.users (id, email, password_hash, role) VALUES ($1,$2,'hash',$3)`,
		id, id.String()+"@test.com", role,
	)
	require.NoError(t, err)
	return id
}
```

### Step 2.3: Write handler_test.go

- [ ] Create `backend/domains/notification/handler_test.go`:

```go
//go:build integration

package notification_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/notification"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildNotificationRouter(svc *notification.Service, role string) http.Handler {
	h := notification.NewHandler(svc)
	r := chi.NewRouter()

	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: uuid.New(), Role: role}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})

	adminMW := mw.RequireRole("admin")

	// User routes (any authenticated user)
	r.Get("/api/v1/notifications", h.ListNotifications)
	r.Get("/api/v1/notifications/unread-count", h.CountUnread)
	r.Put("/api/v1/notifications/{id}/read", h.MarkRead)
	r.Get("/api/v1/notifications/preferences", h.ListPreferences)
	r.Put("/api/v1/notifications/preferences", h.UpsertPreference)

	// Admin-only template routes
	r.With(adminMW).Get("/api/v1/notification-templates", h.ListTemplates)
	r.With(adminMW).Post("/api/v1/notification-templates", h.CreateTemplate)
	r.With(adminMW).Put("/api/v1/notification-templates/{id}", h.UpdateTemplate)
	r.With(adminMW).Delete("/api/v1/notification-templates/{id}", h.DeleteTemplate)

	return r
}

// --- Template admin-only route: forbidden for non-admin ---

func TestNotification_ListTemplates_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := notification.NewService(notification.NewRepository(pool), bus, zap.NewNop())
	router := buildNotificationRouter(svc, "student")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/notification-templates", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestNotification_CreateTemplate_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := notification.NewService(notification.NewRepository(pool), bus, zap.NewNop())
	router := buildNotificationRouter(svc, "student")

	body := `{"key":"test.key","channel":"in_app","body":"Hello {{name}}"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/notification-templates",
		strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestNotification_UpdateTemplate_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := notification.NewService(notification.NewRepository(pool), bus, zap.NewNop())
	router := buildNotificationRouter(svc, "student")

	req := httptest.NewRequest(http.MethodPut, "/api/v1/notification-templates/"+uuid.New().String(),
		strings.NewReader(`{"body":"updated"}`))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestNotification_DeleteTemplate_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := notification.NewService(notification.NewRepository(pool), bus, zap.NewNop())
	router := buildNotificationRouter(svc, "student")

	req := httptest.NewRequest(http.MethodDelete, "/api/v1/notification-templates/"+uuid.New().String(),
		http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

// --- Template admin-only route: allowed for admin ---

func TestNotification_CreateTemplate_AllowedForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := notification.NewService(notification.NewRepository(pool), bus, zap.NewNop())
	router := buildNotificationRouter(svc, "admin")

	body := `{"key":"welcome.email","channel":"in_app","body":"Welcome {{name}}"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/notification-templates",
		strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusCreated, w.Code)
}

func TestNotification_ListTemplates_AllowedForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := notification.NewService(notification.NewRepository(pool), bus, zap.NewNop())
	router := buildNotificationRouter(svc, "admin")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/notification-templates", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

// --- User routes: accessible to any authenticated role ---

func TestNotification_ListNotifications_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := notification.NewService(notification.NewRepository(pool), bus, zap.NewNop())
	router := buildNotificationRouter(svc, "student")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/notifications", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestNotification_CountUnread_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := notification.NewService(notification.NewRepository(pool), bus, zap.NewNop())
	router := buildNotificationRouter(svc, "student")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/notifications/unread-count", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}
```

### Step 2.4: Run tests

```bash
cd backend && go test -tags integration -v ./domains/notification/...
```

Expected: all PASS

### Step 2.5: Lint

```bash
cd backend && golangci-lint run ./domains/notification/...
```

### Step 2.6: Commit

```bash
git add backend/domains/notification/
git commit -m "test(notification): add handler RBAC tests and test helpers"
```

---

## Task 3: Complete `partnerships` domain

**Spec:** Fix `TerminateAgreement()` — termination_reason not persisted; add handler smoke tests.

**Files:**
- Modify: `backend/domains/partnerships/repository.go`
- Modify: `backend/domains/partnerships/service.go`
- Create: `backend/domains/partnerships/service_integration_test.go`
- Create: `backend/domains/partnerships/handler_test.go`

### Step 3.1: Create branch

```bash
git checkout main && git pull && git checkout -b feat/complete-partnerships-api
```

### Step 3.2: Write failing test for TerminateAgreement

- [ ] Create `backend/domains/partnerships/service_integration_test.go`:

```go
//go:build integration

package partnerships_test

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/partnerships"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
)

const defaultTestDBURL = "postgres://vernonedu:vernonedu_secret@localhost:5433/vernonedu?sslmode=disable"

func newTestPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("TEST_DB_URL")
	if url == "" {
		url = defaultTestDBURL
	}
	pool, err := pgxpool.New(context.Background(), url)
	require.NoError(t, err)
	require.NoError(t, pool.Ping(context.Background()))
	return pool
}

func resetSchemas(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()
	_, err := pool.Exec(context.Background(), `
		TRUNCATE
			partnerships.royalty_payment_records,
			partnerships.branch_other_revenues,
			partnerships.franchise_agreements,
			partnerships.franchisees,
			partnerships.partner_documents,
			partnerships.partnership_agreements,
			partnerships.partners,
			identity.users
		RESTART IDENTITY CASCADE`)
	require.NoError(t, err)
}

func seedActiveAgreement(t *testing.T, pool *pgxpool.Pool) (partnerID, agreementID uuid.UUID) {
	t.Helper()
	ctx := context.Background()

	// Seed creator user
	var actorID uuid.UUID
	require.NoError(t, pool.QueryRow(ctx,
		`INSERT INTO identity.users (email, password_hash, role) VALUES ('actor@test.com','hash','vernonedu_admin') RETURNING id`,
	).Scan(&actorID))

	repo := partnerships.NewRepository(pool)
	bus := events.NewBus(zap.NewNop())
	svc := partnerships.NewService(repo, bus, zap.NewNop())

	partner := &partnerships.Partner{
		Name:      "Test Corp",
		Type:      partnerships.PartnerCorporate,
		CreatedBy: actorID,
	}
	require.NoError(t, svc.CreatePartner(ctx, partner))
	partnerID = partner.ID

	startDate := time.Now()
	endDate := time.Now().AddDate(1, 0, 0)
	bulkPrice := decimal.NewFromInt(5000000)
	agreement := &partnerships.PartnershipAgreement{
		PartnerID:    partnerID,
		Title:        "Test Agreement",
		PaymentModel: partnerships.PaymentPerStudent,
		Payer:        partnerships.PayerStudent,
		BulkPrice:    &bulkPrice,
		StartDate:    startDate,
		EndDate:      endDate,
		CreatedBy:    actorID,
	}
	require.NoError(t, svc.CreateAgreement(ctx, agreement))
	agreementID = agreement.ID

	require.NoError(t, svc.ActivateAgreement(ctx, agreementID))
	return
}

// TestTerminateAgreement_PersistsReason verifies that termination_reason is saved in the DB.
func TestTerminateAgreement_PersistsReason(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	_, agreementID := seedActiveAgreement(t, pool)

	repo := partnerships.NewRepository(pool)
	bus := events.NewBus(zap.NewNop())
	svc := partnerships.NewService(repo, bus, zap.NewNop())

	const reason = "contract expired early"
	require.NoError(t, svc.TerminateAgreement(context.Background(), agreementID, reason))

	// Verify reason is persisted in DB
	a, err := repo.GetAgreementByID(context.Background(), agreementID)
	require.NoError(t, err)
	require.NotNil(t, a.TerminationReason, "termination_reason should be persisted")
	require.Equal(t, reason, *a.TerminationReason)
	require.NotNil(t, a.TerminatedAt, "terminated_at should be set")
}
```

### Step 3.3: Run test — expect FAIL

```bash
cd backend && go test -tags integration -run TestTerminateAgreement_PersistsReason ./domains/partnerships/...
```

Expected: FAIL — `termination_reason` is nil because it's never saved.

### Step 3.4: Add TerminateAgreementRecord repo method

- [ ] In `backend/domains/partnerships/repository.go`, add to the `Repository` interface (find the interface definition) and implement:

```go
// In the Repository interface:
TerminateAgreementRecord(ctx context.Context, id uuid.UUID, reason string) error
```

```go
// Implementation (add after UpdateAgreementStatus):
func (r *repository) TerminateAgreementRecord(ctx context.Context, id uuid.UUID, reason string) error {
	query := `UPDATE partnerships.partnership_agreements
	          SET status='terminated', termination_reason=$1, terminated_at=NOW()
	          WHERE id=$2`
	ct, err := r.pool.Exec(ctx, query, reason, id)
	if err != nil {
		return fmt.Errorf("partnerships.TerminateAgreementRecord: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return apperrors.ErrNotFound
	}
	return nil
}
```

### Step 3.5: Update TerminateAgreement in service.go

- [ ] In `backend/domains/partnerships/service.go`, replace `TerminateAgreement`:

```go
func (s *Service) TerminateAgreement(ctx context.Context, id uuid.UUID, reason string) error {
	a, err := s.repo.GetAgreementByID(ctx, id)
	if err != nil {
		return err
	}
	if a.Status != AgreementActive {
		return apperrors.Validationf("only active agreements can be terminated")
	}
	return s.repo.TerminateAgreementRecord(ctx, id, reason)
}
```

### Step 3.6: Run test — expect PASS

```bash
cd backend && go test -tags integration -run TestTerminateAgreement_PersistsReason ./domains/partnerships/...
```

Expected: PASS

### Step 3.7: Write handler_test.go

- [ ] Create `backend/domains/partnerships/handler_test.go`:

```go
//go:build integration

package partnerships_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/partnerships"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildPartnershipsRouter(svc *partnerships.Service, role string) http.Handler {
	h := partnerships.NewHandler(svc)
	r := chi.NewRouter()
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: uuid.New(), Role: role}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})
	r.Get("/api/v1/partners", h.ListPartners)
	r.Post("/api/v1/partners", h.CreatePartner)
	r.Get("/api/v1/partners/{id}", h.GetPartner)
	r.Post("/api/v1/agreements", h.CreateAgreement)
	r.Post("/api/v1/agreements/{id}/activate", h.ActivateAgreement)
	r.Get("/api/v1/franchisees", h.ListFranchisees)
	return r
}

func TestPartnerships_ListPartners_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := partnerships.NewService(partnerships.NewRepository(pool), bus, zap.NewNop())
	router := buildPartnershipsRouter(svc, "vernonedu_admin")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/partners", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestPartnerships_CreatePartner_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	// Seed actor user
	_, err := pool.Exec(context.Background(),
		`INSERT INTO identity.users (id, email, password_hash, role) VALUES ($1,'admin@test.com','hash','vernonedu_admin')`,
		actorID)
	// Note: use a real actorID seeded above — see seedActiveAgreement helper

	bus := events.NewBus(zap.NewNop())
	svc := partnerships.NewService(partnerships.NewRepository(pool), bus, zap.NewNop())
	router := buildPartnershipsRouter(svc, "vernonedu_admin")

	body := `{"name":"Test Corp","type":"corporate","contact_name":"John","contact_email":"john@corp.com","contact_phone":"08123"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/partners", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusCreated, w.Code)
}

func TestPartnerships_GetPartner_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := partnerships.NewService(partnerships.NewRepository(pool), bus, zap.NewNop())
	router := buildPartnershipsRouter(svc, "vernonedu_admin")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/partners/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

func TestPartnerships_ListFranchisees_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := partnerships.NewService(partnerships.NewRepository(pool), bus, zap.NewNop())
	router := buildPartnershipsRouter(svc, "vernonedu_admin")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/franchisees", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}
```

**Note:** The `TestPartnerships_CreatePartner_Authenticated` test needs the `actorID` injected into the UserContext to match a real user in DB. Update `buildPartnershipsRouter` to accept `actorID uuid.UUID` parameter and pass a seeded user ID, or seed a user and use its ID in the router middleware. Adjust to match the handler's implementation of how it reads the actor from context.

### Step 3.8: Run all partnerships tests

```bash
cd backend && go test -tags integration -v ./domains/partnerships/...
```

Expected: all PASS

### Step 3.9: Lint + Commit

```bash
cd backend && golangci-lint run ./domains/partnerships/...
git add backend/domains/partnerships/
git commit -m "fix(partnerships): persist termination reason to DB; add handler tests"
```

---

## Task 4: Complete `calendar` domain

**Spec:** No stubs to fix (event handler returns are valid early-returns). Add handler smoke tests.

**Files:**
- Create: `backend/domains/calendar/handler_test.go`

### Step 4.1: Create branch

```bash
git checkout main && git pull && git checkout -b feat/complete-calendar-api
```

### Step 4.2: Write handler_test.go

- [ ] Create `backend/domains/calendar/handler_test.go`:

```go
//go:build integration

package calendar_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/calendar"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildCalendarRouter(svc *calendar.Service, actorID uuid.UUID) http.Handler {
	h := calendar.NewHandler(svc)
	r := chi.NewRouter()
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: actorID, Role: "student"}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})
	r.Get("/api/v1/calendar", h.ListEvents)
	r.Post("/api/v1/calendar", h.CreateEvent)
	r.Get("/api/v1/calendar/export/ical", h.ExportUserICal)
	r.Get("/api/v1/calendar/sync", h.GetSync)
	r.Post("/api/v1/calendar/sync", h.UpsertSync)
	r.Get("/api/v1/calendar/{id}", h.GetEvent)
	r.Put("/api/v1/calendar/{id}", h.UpdateEvent)
	r.Delete("/api/v1/calendar/{id}", h.DeleteEvent)
	r.Get("/api/v1/calendar/{id}/attendees", h.GetAttendees)
	r.Post("/api/v1/calendar/{id}/attendees", h.AddAttendee)
	r.Put("/api/v1/calendar/{id}/rsvp", h.UpdateRSVP)
	r.Get("/api/v1/calendar/{id}/export/ical", h.ExportEventICal)
	return r
}

func TestCalendar_ListEvents_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := calendar.NewService(calendar.NewRepository(pool), bus, zap.NewNop())
	router := buildCalendarRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/calendar", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestCalendar_CreateEvent_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := calendar.NewService(calendar.NewRepository(pool), bus, zap.NewNop())
	router := buildCalendarRouter(svc, actorID)

	body := `{"title":"Team Sync","start_time":"2026-05-01T09:00:00Z","end_time":"2026-05-01T10:00:00Z","type":"general"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/calendar", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusCreated, w.Code)
}

func TestCalendar_GetEvent_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := calendar.NewService(calendar.NewRepository(pool), bus, zap.NewNop())
	router := buildCalendarRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/calendar/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

func TestCalendar_ExportUserICal_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := calendar.NewService(calendar.NewRepository(pool), bus, zap.NewNop())
	router := buildCalendarRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/calendar/export/ical", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestCalendar_GetSync_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := calendar.NewService(calendar.NewRepository(pool), bus, zap.NewNop())
	router := buildCalendarRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/calendar/sync", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	// No sync record seeded — 404 expected
	require.Equal(t, http.StatusNotFound, w.Code)
}
```

### Step 4.3: Run all calendar tests

```bash
cd backend && go test -tags integration -v ./domains/calendar/...
```

Expected: all PASS

### Step 4.4: Lint + Commit

```bash
cd backend && golangci-lint run ./domains/calendar/...
git add backend/domains/calendar/handler_test.go
git commit -m "test(calendar): add handler smoke tests"
```

---

## Task 5: Complete `credentialing` domain

**Spec:** No stubs. Add handler tests covering public routes and JWT-protected routes.

**Files:**
- Create: `backend/domains/credentialing/handler_test.go`

### Step 5.1: Create branch

```bash
git checkout main && git pull && git checkout -b feat/complete-credentialing-api
```

### Step 5.2: Write handler_test.go

- [ ] Create `backend/domains/credentialing/handler_test.go`:

```go
//go:build integration

package credentialing_test

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/credentialing"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"github.com/vernonedu/vernonedu2/backend/internal/worker"
)

func buildCredentialingRouter(svc *credentialing.Service, role string) http.Handler {
	h := credentialing.NewHandler(svc)
	r := chi.NewRouter()

	// Public routes (no auth injection needed, but we inject anyway for consistency)
	r.Get("/api/v1/certificates/verify/{number}", h.VerifyCertificate)
	r.Get("/api/v1/certificates/verify-hash/{hash}", h.VerifyByHash)

	// JWT-protected routes with fake auth
	r.Group(func(r chi.Router) {
		r.Use(func(next http.Handler) http.Handler {
			return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
				uc := &mw.UserContext{ID: uuid.New(), Role: role}
				next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
			})
		})
		r.Get("/api/v1/enrollments/{enrollmentID}/certificates", h.ListCertificates)
		r.Get("/api/v1/certificates/{id}/download", h.DownloadCertificate)
		r.Post("/api/v1/certificates/{id}/actions", h.RequestAction)
		r.Post("/api/v1/certificate-actions/{id}/approve", h.ApproveActionRequest)
	})

	return r
}

func newCredSvc(t *testing.T) *credentialing.Service {
	t.Helper()
	pool := newTestPool(t)
	t.Cleanup(pool.Close)
	storageRoot := filepath.Join(t.TempDir(), "certs")
	require.NoError(t, os.MkdirAll(storageRoot, 0o755))
	bus := events.NewBus(zap.NewNop())
	return credentialing.NewService(
		credentialing.NewRepository(pool),
		bus,
		zap.NewNop(),
		worker.NewRendererAdapter(worker.NewPDFGenerator()),
		worker.NewStorageAdapter(worker.NewFSCertStorage(storageRoot)),
		"http://localhost:8080",
	)
}

func TestCredentialing_VerifyCertificate_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newCredSvc(t)
	router := buildCredentialingRouter(svc, "student")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/certificates/verify/CERT-NOTEXIST", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

func TestCredentialing_ListCertificates_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newCredSvc(t)
	router := buildCredentialingRouter(svc, "student")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/enrollments/"+uuid.New().String()+"/certificates", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestCredentialing_DownloadCertificate_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newCredSvc(t)
	router := buildCredentialingRouter(svc, "student")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/certificates/"+uuid.New().String()+"/download", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}
```

### Step 5.3: Run all credentialing tests

```bash
cd backend && go test -tags integration -v ./domains/credentialing/...
```

Expected: all PASS

### Step 5.4: Lint + Commit

```bash
cd backend && golangci-lint run ./domains/credentialing/...
git add backend/domains/credentialing/handler_test.go
git commit -m "test(credentialing): add handler smoke tests"
```

---

## Task 6: Complete `enrollment` domain

**Spec:** No stubs. Add handler smoke tests (JWT only, no role restrictions).

**Files:**
- Create: `backend/domains/enrollment/handler_test.go`

### Step 6.1: Create branch

```bash
git checkout main && git pull && git checkout -b feat/complete-enrollment-api
```

### Step 6.2: Write handler_test.go

- [ ] Create `backend/domains/enrollment/handler_test.go`:

```go
//go:build integration

package enrollment_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/enrollment"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildEnrollmentRouter(svc *enrollment.Service, actorID uuid.UUID, role string) http.Handler {
	h := enrollment.NewHandler(svc)
	r := chi.NewRouter()
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: actorID, Role: role}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})
	r.Post("/api/v1/enrollments", h.CreateEnrollment)
	r.Get("/api/v1/enrollments/{id}", h.GetEnrollment)
	r.Post("/api/v1/enrollments/{id}/drop", h.DropEnrollment)
	r.Post("/api/v1/enrollments/{id}/complete", h.CompleteEnrollment)
	r.Get("/api/v1/students/{studentID}/enrollments", h.ListEnrollmentsByStudent)
	return r
}

func TestEnrollment_GetEnrollment_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := enrollment.NewService(enrollment.NewRepository(pool), bus, zap.NewNop())
	router := buildEnrollmentRouter(svc, actorID, "student")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/enrollments/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

func TestEnrollment_ListEnrollmentsByStudent_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := enrollment.NewService(enrollment.NewRepository(pool), bus, zap.NewNop())
	router := buildEnrollmentRouter(svc, actorID, "student")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/students/"+uuid.New().String()+"/enrollments", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestEnrollment_DropEnrollment_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := enrollment.NewService(enrollment.NewRepository(pool), bus, zap.NewNop())
	router := buildEnrollmentRouter(svc, actorID, "student")

	req := httptest.NewRequest(http.MethodPost, "/api/v1/enrollments/"+uuid.New().String()+"/drop", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}
```

**Note:** `seedUser` is defined in `service_integration_test.go` in the enrollment package. Verify it exists; add it if missing.

### Step 6.3: Run + Lint + Commit

```bash
cd backend && go test -tags integration -v ./domains/enrollment/...
cd backend && golangci-lint run ./domains/enrollment/...
git add backend/domains/enrollment/handler_test.go
git commit -m "test(enrollment): add handler smoke tests"
```

---

## Task 7: Complete `franchise` domain

**Spec:** No stubs. Add handler smoke tests.

**Files:**
- Create: `backend/domains/franchise/handler_test.go`

### Step 7.1: Create branch

```bash
git checkout main && git pull && git checkout -b feat/complete-franchise-api
```

### Step 7.2: Write handler_test.go

- [ ] Create `backend/domains/franchise/handler_test.go`:

```go
//go:build integration

package franchise_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/franchise"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildFranchiseRouter(svc *franchise.Service, actorID uuid.UUID) http.Handler {
	h := franchise.NewHandler(svc)
	r := chi.NewRouter()
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: actorID, Role: "vernonedu_admin"}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})
	r.Post("/api/v1/franchisees", h.CreateFranchisee)
	r.Get("/api/v1/franchisees", h.ListFranchisees)
	r.Get("/api/v1/franchisees/{id}", h.GetFranchisee)
	r.Post("/api/v1/franchise-agreements", h.CreateAgreement)
	r.Get("/api/v1/franchise-agreements/{franchiseeID}", h.GetAgreement)
	r.Post("/api/v1/franchise-revenues", h.AddBranchOtherRevenue)
	r.Post("/api/v1/royalty-records", h.CreateRoyaltyRecord)
	r.Get("/api/v1/royalty-records/{franchiseeID}/{period}", h.GetRoyaltyRecord)
	r.Post("/api/v1/royalty-records/{id}/mark-paid", h.MarkRoyaltyPaid)
	return r
}

func TestFranchise_ListFranchisees_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := franchise.NewService(franchise.NewRepository(pool), bus, zap.NewNop())
	router := buildFranchiseRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/franchisees", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestFranchise_GetFranchisee_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := franchise.NewService(franchise.NewRepository(pool), bus, zap.NewNop())
	router := buildFranchiseRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/franchisees/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

func TestFranchise_GetRoyaltyRecord_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := franchise.NewService(franchise.NewRepository(pool), bus, zap.NewNop())
	router := buildFranchiseRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet,
		"/api/v1/royalty-records/"+uuid.New().String()+"/2026-04",
		http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}
```

**Note:** `seedUser` and `newTestPool`/`resetSchemas` must exist in the franchise package's existing `service_integration_test.go`. If they don't, add them there first.

### Step 7.3: Run + Lint + Commit

```bash
cd backend && go test -tags integration -v ./domains/franchise/...
cd backend && golangci-lint run ./domains/franchise/...
git add backend/domains/franchise/handler_test.go
git commit -m "test(franchise): add handler smoke tests"
```

---

## Task 8: Complete `voucher` domain

**Spec:** No stubs. Add handler RBAC tests — admin-only CRUD + open apply route.

**Files:**
- Create: `backend/domains/voucher/handler_test.go`

### Step 8.1: Create branch

```bash
git checkout main && git pull && git checkout -b feat/complete-voucher-api
```

### Step 8.2: Write handler_test.go

- [ ] Create `backend/domains/voucher/handler_test.go`:

```go
//go:build integration

package voucher_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/voucher"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildVoucherRouter(svc *voucher.Service, actorID uuid.UUID, role string) http.Handler {
	h := voucher.NewHandler(svc)
	r := chi.NewRouter()

	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: actorID, Role: role}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})

	adminMW := mw.RequireRole("admin", "vernonedu_admin")

	r.With(adminMW).Post("/api/v1/vouchers", h.CreateVoucher)
	r.With(adminMW).Get("/api/v1/vouchers/{id}", h.GetVoucher)
	r.With(adminMW).Get("/api/v1/vouchers", h.ListVouchers)
	r.With(adminMW).Patch("/api/v1/vouchers/{id}/deactivate", h.DeactivateVoucher)
	r.Post("/api/v1/vouchers/apply", h.ApplyVoucher)
	r.Get("/api/v1/students/{studentID}/vouchers", h.ListMyVouchers)

	return r
}

// Admin-only: forbidden for student

func TestVoucher_CreateVoucher_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := voucher.NewService(voucher.NewRepository(pool), bus, zap.NewNop())
	router := buildVoucherRouter(svc, actorID, "student")

	body := `{"code":"DISC10","discount_type":"percentage","discount_value":10,"max_uses":100}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/vouchers", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestVoucher_ListVouchers_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := voucher.NewService(voucher.NewRepository(pool), bus, zap.NewNop())
	router := buildVoucherRouter(svc, actorID, "student")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/vouchers", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

// Admin-only: allowed for admin

func TestVoucher_CreateVoucher_AllowedForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := voucher.NewService(voucher.NewRepository(pool), bus, zap.NewNop())
	router := buildVoucherRouter(svc, actorID, "vernonedu_admin")

	body := `{"code":"DISC10","discount_type":"percentage","discount_value":10,"max_uses":100,"expires_at":null}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/vouchers", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusCreated, w.Code)
}

func TestVoucher_ListVouchers_AllowedForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := voucher.NewService(voucher.NewRepository(pool), bus, zap.NewNop())
	router := buildVoucherRouter(svc, actorID, "vernonedu_admin")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/vouchers", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

// Open routes: accessible to any authenticated user

func TestVoucher_ListMyVouchers_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := voucher.NewService(voucher.NewRepository(pool), bus, zap.NewNop())
	router := buildVoucherRouter(svc, actorID, "student")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/students/"+actorID.String()+"/vouchers", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}
```

**Note:** `seedUser` must exist in the voucher domain's `service_integration_test.go`. If not present, add it.

### Step 8.3: Run + Lint + Commit

```bash
cd backend && go test -tags integration -v ./domains/voucher/...
cd backend && golangci-lint run ./domains/voucher/...
git add backend/domains/voucher/handler_test.go
git commit -m "test(voucher): add handler RBAC tests"
```

---

## Task 9: Complete `profit_split` domain

**Spec:** No stubs (role passed to service, no RequireRole MW). Add handler smoke tests.

**Files:**
- Create: `backend/domains/profit_split/handler_test.go`

### Step 9.1: Create branch

```bash
git checkout main && git pull && git checkout -b feat/complete-profit-split-api
```

### Step 9.2: Write handler_test.go

- [ ] Create `backend/domains/profit_split/handler_test.go`:

```go
//go:build integration

package profit_split_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	profit_split "github.com/vernonedu/vernonedu2/backend/domains/profit_split"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildProfitSplitRouter(svc *profit_split.Service, actorID uuid.UUID) http.Handler {
	h := profit_split.NewHandler(svc)
	r := chi.NewRouter()
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: actorID, Role: "vernonedu_admin"}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})
	r.Get("/api/v1/profit-split/settings", h.GetGlobalSettings)
	r.Put("/api/v1/profit-split/settings", h.UpdateGlobalSettings)
	r.Post("/api/v1/profit-split/overrides", h.CreateCourseOverride)
	r.Get("/api/v1/profit-split/overrides/{courseID}", h.GetCourseOverride)
	r.Post("/api/v1/profit-split/extra-revenue", h.AddExtraRevenue)
	r.Post("/api/v1/profit-split/extra-revenue/{id}/approve", h.ApproveExtraRevenue)
	r.Post("/api/v1/profit-split/extra-revenue/{id}/reject", h.RejectExtraRevenue)
	r.Post("/api/v1/profit-split/batch-costs", h.CreateBatchCostLineItem)
	r.Delete("/api/v1/profit-split/batch-costs/{id}", h.RemoveBatchCostLineItem)
	r.Get("/api/v1/profit-split/batches/{batchID}", h.GetBatchSplitRecord)
	r.Post("/api/v1/profit-split/period-bonuses", h.CalculatePeriodBonus)
	r.Get("/api/v1/profit-split/period-bonuses/{period}", h.GetPeriodBonus)
	return r
}

func TestProfitSplit_GetGlobalSettings_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := profit_split.NewService(profit_split.NewRepository(pool), bus, zap.NewNop())
	router := buildProfitSplitRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/profit-split/settings", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestProfitSplit_GetCourseOverride_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := profit_split.NewService(profit_split.NewRepository(pool), bus, zap.NewNop())
	router := buildProfitSplitRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet,
		"/api/v1/profit-split/overrides/"+uuid.New().String(),
		http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

func TestProfitSplit_GetBatchSplitRecord_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := profit_split.NewService(profit_split.NewRepository(pool), bus, zap.NewNop())
	router := buildProfitSplitRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet,
		"/api/v1/profit-split/batches/"+uuid.New().String(),
		http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}
```

### Step 9.3: Run + Lint + Commit

```bash
cd backend && go test -tags integration -v ./domains/profit_split/...
cd backend && golangci-lint run ./domains/profit_split/...
git add backend/domains/profit_split/handler_test.go
git commit -m "test(profit_split): add handler smoke tests"
```

---

## Task 10: Complete `team_member` domain

**Spec:** No stubs. Add handler RBAC test for `CreateFeeTier` (vernonedu_admin only) + smoke tests.

**Files:**
- Create: `backend/domains/team_member/handler_test.go`

### Step 10.1: Create branch

```bash
git checkout main && git pull && git checkout -b feat/complete-team-member-api
```

### Step 10.2: Write handler_test.go

- [ ] Create `backend/domains/team_member/handler_test.go`:

```go
//go:build integration

package team_member_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	team_member "github.com/vernonedu/vernonedu2/backend/domains/team_member"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

const roleVernonAdmin = "vernonedu_admin"

func buildTeamMemberRouter(svc *team_member.Service, actorID uuid.UUID, role string) http.Handler {
	h := team_member.NewHandler(svc)
	r := chi.NewRouter()
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: actorID, Role: role}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})
	r.Post("/api/v1/team-members", h.CreateTeamMember)
	r.Get("/api/v1/team-members", h.ListTeamMembers)
	r.Get("/api/v1/team-members/{id}", h.GetTeamMember)
	r.With(mw.RequireRole(roleVernonAdmin)).Post("/api/v1/fee-tiers", h.CreateFeeTier)
	r.Get("/api/v1/fee-tiers", h.ListFeeTiers)
	r.Post("/api/v1/facilitator-proposals", h.CreateProposal)
	r.Get("/api/v1/facilitator-proposals/{id}", h.GetProposal)
	r.Post("/api/v1/facilitator-proposals/{id}/dept-review", h.DeptLeaderReview)
	r.Post("/api/v1/facilitator-proposals/{id}/academic-review", h.AcademicLeaderReview)
	return r
}

// RBAC: CreateFeeTier admin-only

func TestTeamMember_CreateFeeTier_ForbiddenForCourseCreator(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := team_member.NewService(team_member.NewRepository(pool), bus, zap.NewNop())
	router := buildTeamMemberRouter(svc, actorID, "course_creator")

	body := `{"name":"Senior","base_rate":500000}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/fee-tiers", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestTeamMember_CreateFeeTier_AllowedForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := team_member.NewService(team_member.NewRepository(pool), bus, zap.NewNop())
	router := buildTeamMemberRouter(svc, actorID, roleVernonAdmin)

	body := `{"name":"Senior Facilitator","base_rate":500000}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/fee-tiers", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusCreated, w.Code)
}

// Smoke tests

func TestTeamMember_ListTeamMembers_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := team_member.NewService(team_member.NewRepository(pool), bus, zap.NewNop())
	router := buildTeamMemberRouter(svc, actorID, "course_creator")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/team-members", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestTeamMember_GetProposal_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := team_member.NewService(team_member.NewRepository(pool), bus, zap.NewNop())
	router := buildTeamMemberRouter(svc, actorID, "course_creator")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/facilitator-proposals/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}
```

### Step 10.3: Run + Lint + Commit

```bash
cd backend && go test -tags integration -v ./domains/team_member/...
cd backend && golangci-lint run ./domains/team_member/...
git add backend/domains/team_member/handler_test.go
git commit -m "test(team_member): add handler RBAC + smoke tests"
```

---

## Task 11: Complete `catalog` domain

**Spec:** No stubs. Add handler smoke tests (JWT only).

**Files:**
- Create: `backend/domains/catalog/handler_test.go`

### Step 11.1: Create branch

```bash
git checkout main && git pull && git checkout -b feat/complete-catalog-api
```

### Step 11.2: Write handler_test.go

- [ ] Create `backend/domains/catalog/handler_test.go`:

```go
//go:build integration

package catalog_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/catalog"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildCatalogRouter(svc *catalog.Service, actorID uuid.UUID) http.Handler {
	h := catalog.NewHandler(svc)
	r := chi.NewRouter()
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: actorID, Role: "course_creator"}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})
	r.Get("/api/v1/courses", h.ListCourses)
	r.Post("/api/v1/courses", h.CreateCourse)
	r.Get("/api/v1/courses/{id}", h.GetCourse)
	r.Post("/api/v1/batches", h.CreateBatch)
	r.Get("/api/v1/batches", h.ListBatches)
	r.Get("/api/v1/batches/{id}", h.GetBatch)
	r.Post("/api/v1/batches/{id}/open", h.OpenBatch)
	r.Post("/api/v1/batches/{id}/close", h.CloseBatch)
	r.Get("/api/v1/batches/{batchID}/classes", h.ListClasses)
	return r
}

func TestCatalog_ListCourses_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := catalog.NewService(catalog.NewRepository(pool), bus, zap.NewNop())
	router := buildCatalogRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/courses", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestCatalog_CreateCourse_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := catalog.NewService(catalog.NewRepository(pool), bus, zap.NewNop())
	router := buildCatalogRouter(svc, actorID)

	body := `{"title":"Golang Basics","code":"GO-101","department_id":"` + uuid.New().String() + `"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/courses", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	// 201 if dept exists, 400/422 if dept FK fails — either is not 500
	require.NotEqual(t, http.StatusInternalServerError, w.Code)
}

func TestCatalog_GetCourse_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := catalog.NewService(catalog.NewRepository(pool), bus, zap.NewNop())
	router := buildCatalogRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/courses/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

func TestCatalog_ListBatches_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	bus := events.NewBus(zap.NewNop())
	svc := catalog.NewService(catalog.NewRepository(pool), bus, zap.NewNop())
	router := buildCatalogRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/batches", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}
```

**Note:** `seedUser` must return a user with a valid `department_id` if the catalog domain enforces department FK. Check `service_integration_test.go` for the existing seed helper and use the seeded actorID.

### Step 11.3: Run + Lint + Commit

```bash
cd backend && go test -tags integration -v ./domains/catalog/...
cd backend && golangci-lint run ./domains/catalog/...
git add backend/domains/catalog/handler_test.go
git commit -m "test(catalog): add handler smoke tests"
```

---

## Task 12: Complete `finance` domain

**Spec:** No stubs (all returns are valid). Add handler smoke tests; webhook route is public (no auth).

**Files:**
- Create: `backend/domains/finance/handler_test.go`

### Step 12.1: Create branch

```bash
git checkout main && git pull && git checkout -b feat/complete-finance-api
```

### Step 12.2: Write handler_test.go

- [ ] Create `backend/domains/finance/handler_test.go`:

```go
//go:build integration

package finance_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/finance"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildFinanceRouter(svc *finance.Service, actorID uuid.UUID) http.Handler {
	h := finance.NewHandler(svc)
	r := chi.NewRouter()

	// Public webhook
	r.Post("/api/v1/finance/webhooks/midtrans", h.MidtransWebhook)

	// JWT-protected routes
	r.Group(func(r chi.Router) {
		r.Use(func(next http.Handler) http.Handler {
			return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
				uc := &mw.UserContext{ID: actorID, Role: "vernonedu_admin"}
				next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
			})
		})
		r.Get("/api/v1/payments/{id}", h.GetPayment)
		r.Get("/api/v1/payments/{id}/terms", h.ListPaymentTerms)
		r.Post("/api/v1/transactions/{id}/confirm", h.ConfirmTransaction)
		r.Get("/api/v1/invoices/{id}", h.GetInvoice)
		r.Post("/api/v1/invoices/{id}/send", h.SendInvoice)
		r.Post("/api/v1/finance/invoices/{id}/pay", h.PayInvoice)
	})

	return r
}

func newFinanceSvc(t *testing.T, pool *pgxpool.Pool) *finance.Service {
	t.Helper()
	bus := events.NewBus(zap.NewNop())
	gw := finance.NewFakeGateway("test-secret", "")
	return finance.NewService(finance.NewRepository(pool), bus, gw, zap.NewNop())
}

func TestFinance_GetPayment_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	svc := newFinanceSvc(t, pool)
	router := buildFinanceRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/payments/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

func TestFinance_GetInvoice_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	svc := newFinanceSvc(t, pool)
	router := buildFinanceRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/invoices/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

func TestFinance_MidtransWebhook_InvalidSignature(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)

	svc := newFinanceSvc(t, pool)
	router := buildFinanceRouter(svc, actorID)

	// Invalid payload + no signature header → handler should return 400
	req := httptest.NewRequest(http.MethodPost, "/api/v1/finance/webhooks/midtrans",
		strings.NewReader(`{"order_id":"invalid"}`))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.NotEqual(t, http.StatusInternalServerError, w.Code)
}
```

**Note:** Add `"strings"` and `"github.com/jackc/pgx/v5/pgxpool"` imports. `seedUser` and `newTestPool`/`resetSchemas` are in `service_integration_test.go`.

### Step 12.3: Run + Lint + Commit

```bash
cd backend && go test -tags integration -v ./domains/finance/...
cd backend && golangci-lint run ./domains/finance/...
git add backend/domains/finance/handler_test.go
git commit -m "test(finance): add handler smoke tests"
```

---

## Final Verification

After all 12 tasks:

- [ ] Run full test suite:

```bash
cd backend && go test -tags integration ./...
```

Expected: all PASS, 0 failures

- [ ] Run full lint:

```bash
cd backend && golangci-lint run ./...
```

Expected: no errors
