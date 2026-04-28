# Franchise Portal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the franchise portal — add `user_id` link to franchisees table, expose `GET /api/v1/me/franchisee` and `GET /api/v1/royalty-records/{franchiseeID}/all`, wire Dashboard from mock data to real API, and add four new pages (Royalty, Enrollments, Payments, TeamMembers).

**Architecture:** Backend prerequisite first (migration + two new endpoints in the `franchise` domain), then frontend API layer (`franchise.ts`, `team_member.ts`), then `FranchiseeContext` that resolves the logged-in user's franchisee record on portal mount, then each page consumes that context.

**Tech Stack:** Go 1.22, Chi v5, pgx/v5, testify/require (`//go:build integration`); React 18, TypeScript, TanStack Query v5, Axios, TailwindCSS 3, Radix UI, Lucide React.

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `backend/migrations/000018_franchise_user_link.up.sql` | Add `user_id` column + unique index to `franchise.franchisees` |
| Create | `backend/migrations/000018_franchise_user_link.down.sql` | Reverse migration |
| Modify | `backend/domains/franchise/model.go` | Add `UserID *uuid.UUID` to `Franchisee` struct |
| Modify | `backend/domains/franchise/repository.go` | Add `GetFranchiseeByUserID` + `ListRoyaltyByFranchisee` interface + impl; update all `Franchisee` scans to include `user_id` |
| Modify | `backend/domains/franchise/service.go` | Add `GetMyFranchisee` + `ListRoyaltyRecords` methods |
| Modify | `backend/domains/franchise/handler.go` | Add `GetMyFranchisee` + `ListRoyaltyRecords` handlers |
| Modify | `backend/domains/franchise/module.go` | Register two new routes |
| Modify | `backend/domains/franchise/handler_test.go` | Add RBAC tests for two new endpoints |
| Create | `frontend/src/lib/api/franchise.ts` | Types + hooks for franchisee, royalty, agreement |
| Create | `frontend/src/lib/api/team_member.ts` | Types + hooks for team members |
| Create | `frontend/src/portals/franchise/FranchiseeContext.tsx` | Context that fetches + stores current franchisee |
| Modify | `frontend/src/portals/franchise/FranchisePortal.tsx` | Wrap with `FranchiseeProvider`; add 4 nav items |
| Modify | `frontend/src/App.tsx` | Import + register 4 new franchise page routes |
| Modify | `frontend/src/portals/franchise/pages/Dashboard.tsx` | Replace mock constants with `useFranchisee()` + `useRoyaltyRecords()` |
| Create | `frontend/src/portals/franchise/pages/Royalty.tsx` | Royalty records list with SubNavBar tabs |
| Create | `frontend/src/portals/franchise/pages/Enrollments.tsx` | Enrollments list with SubNavBar tabs |
| Create | `frontend/src/portals/franchise/pages/Payments.tsx` | Payments list with SubNavBar tabs |
| Create | `frontend/src/portals/franchise/pages/TeamMembers.tsx` | Team members read-only list |

---

## Task 1: Backend migration — add `user_id` to franchisees

**Files:**
- Create: `backend/migrations/000018_franchise_user_link.up.sql`
- Create: `backend/migrations/000018_franchise_user_link.down.sql`

- [ ] **Step 1.1: Create up migration**

```sql
-- backend/migrations/000018_franchise_user_link.up.sql
ALTER TABLE franchise.franchisees
  ADD COLUMN user_id UUID REFERENCES identity.users(id) ON DELETE SET NULL;

CREATE UNIQUE INDEX idx_franchisees_user_id ON franchise.franchisees(user_id)
  WHERE user_id IS NOT NULL;
```

- [ ] **Step 1.2: Create down migration**

```sql
-- backend/migrations/000018_franchise_user_link.down.sql
DROP INDEX IF EXISTS franchise.idx_franchisees_user_id;
ALTER TABLE franchise.franchisees DROP COLUMN IF EXISTS user_id;
```

- [ ] **Step 1.3: Run migration**

```bash
cd backend
migrate -path migrations -database "$DATABASE_URL" up
```

Expected: `000018/u franchise_user_link`

- [ ] **Step 1.4: Verify rollback**

```bash
migrate -path migrations -database "$DATABASE_URL" down 1
migrate -path migrations -database "$DATABASE_URL" up
```

Expected: no errors both directions.

- [ ] **Step 1.5: Commit**

```bash
git add backend/migrations/000018_franchise_user_link.up.sql \
        backend/migrations/000018_franchise_user_link.down.sql
git commit -m "feat(franchise): add user_id column to franchisees table"
```

---

## Task 2: Backend — model, repository, service, handler, routes

**Files:**
- Modify: `backend/domains/franchise/model.go`
- Modify: `backend/domains/franchise/repository.go`
- Modify: `backend/domains/franchise/service.go`
- Modify: `backend/domains/franchise/handler.go`
- Modify: `backend/domains/franchise/module.go`

- [ ] **Step 2.1: Add `UserID` field to `Franchisee` struct in model.go**

In `backend/domains/franchise/model.go`, add the field after `CreatedBy`:

```go
// Franchisee represents an investor/location owner in the franchise model.
// VernonEdu retains 100% operational management.
type Franchisee struct {
	ID         uuid.UUID        `json:"id"`
	Name       string           `json:"name"`
	BranchName string           `json:"branch_name"`
	Location   string           `json:"location"`
	Contact    string           `json:"contact"`
	Status     FranchiseeStatus `json:"status"`
	CreatedBy  uuid.UUID        `json:"created_by"`
	UserID     *uuid.UUID       `json:"user_id,omitempty"`
	CreatedAt  time.Time        `json:"created_at"`
	UpdatedAt  time.Time        `json:"updated_at"`
}
```

- [ ] **Step 2.2: Update `Repository` interface in repository.go**

Add two methods to the `Repository` interface (after `ListFranchisees`):

```go
GetFranchiseeByUserID(ctx context.Context, userID uuid.UUID) (*Franchisee, error)
ListRoyaltyByFranchisee(ctx context.Context, franchiseeID uuid.UUID) ([]*RoyaltyPaymentRecord, error)
```

- [ ] **Step 2.3: Update existing Franchisee scan queries in repository.go**

`GetFranchiseeByID` — replace query and Scan to include `user_id`:

```go
func (r *repository) GetFranchiseeByID(ctx context.Context, id uuid.UUID) (*Franchisee, error) {
	query := `
		SELECT id, name, branch_name, location, contact, status, created_by, user_id, created_at, updated_at
		FROM franchise.franchisees WHERE id = $1`

	f := &Franchisee{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&f.ID, &f.Name, &f.BranchName, &f.Location, &f.Contact,
		&f.Status, &f.CreatedBy, &f.UserID, &f.CreatedAt, &f.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("franchise.GetFranchiseeByID: %w", err)
	}
	return f, nil
}
```

`ListFranchisees` — update SELECT and Scan similarly:

```go
func (r *repository) ListFranchisees(ctx context.Context) ([]*Franchisee, error) {
	query := `
		SELECT id, name, branch_name, location, contact, status, created_by, user_id, created_at, updated_at
		FROM franchise.franchisees ORDER BY created_at DESC`

	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("franchise.ListFranchisees: %w", err)
	}
	defer rows.Close()

	var list []*Franchisee
	for rows.Next() {
		f := &Franchisee{}
		if err := rows.Scan(
			&f.ID, &f.Name, &f.BranchName, &f.Location, &f.Contact,
			&f.Status, &f.CreatedBy, &f.UserID, &f.CreatedAt, &f.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("franchise.ListFranchisees scan: %w", err)
		}
		list = append(list, f)
	}
	return list, nil
}
```

- [ ] **Step 2.4: Implement `GetFranchiseeByUserID` in repository.go**

Append after `ListFranchisees`:

```go
func (r *repository) GetFranchiseeByUserID(ctx context.Context, userID uuid.UUID) (*Franchisee, error) {
	query := `
		SELECT id, name, branch_name, location, contact, status, created_by, user_id, created_at, updated_at
		FROM franchise.franchisees WHERE user_id = $1`

	f := &Franchisee{}
	err := r.pool.QueryRow(ctx, query, userID).Scan(
		&f.ID, &f.Name, &f.BranchName, &f.Location, &f.Contact,
		&f.Status, &f.CreatedBy, &f.UserID, &f.CreatedAt, &f.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, apperrors.ErrNotFound
		}
		return nil, fmt.Errorf("franchise.GetFranchiseeByUserID: %w", err)
	}
	return f, nil
}
```

- [ ] **Step 2.5: Implement `ListRoyaltyByFranchisee` in repository.go**

Append after `GetFranchiseeByUserID`:

```go
func (r *repository) ListRoyaltyByFranchisee(ctx context.Context, franchiseeID uuid.UUID) ([]*RoyaltyPaymentRecord, error) {
	query := `
		SELECT rpr.id, rpr.franchise_agreement_id, rpr.period, rpr.gross_revenue,
		       rpr.monthly_royalty, rpr.revenue_royalty, rpr.total_royalty,
		       rpr.status, rpr.created_at, rpr.paid_at, rpr.recorded_by
		FROM franchise.royalty_payment_records rpr
		JOIN franchise.franchise_agreements fa ON fa.id = rpr.franchise_agreement_id
		WHERE fa.franchisee_id = $1
		ORDER BY rpr.period DESC`

	rows, err := r.pool.Query(ctx, query, franchiseeID)
	if err != nil {
		return nil, fmt.Errorf("franchise.ListRoyaltyByFranchisee: %w", err)
	}
	defer rows.Close()

	var list []*RoyaltyPaymentRecord
	for rows.Next() {
		rec := &RoyaltyPaymentRecord{}
		if err := rows.Scan(
			&rec.ID, &rec.FranchiseAgreementID, &rec.Period, &rec.GrossRevenue,
			&rec.MonthlyRoyalty, &rec.RevenueRoyalty, &rec.TotalRoyalty,
			&rec.Status, &rec.CreatedAt, &rec.PaidAt, &rec.RecordedBy,
		); err != nil {
			return nil, fmt.Errorf("franchise.ListRoyaltyByFranchisee scan: %w", err)
		}
		list = append(list, rec)
	}
	return list, nil
}
```

- [ ] **Step 2.6: Add service methods in service.go**

Append after `ListFranchisees`:

```go
// GetMyFranchisee returns the franchisee record linked to the calling user.
func (s *Service) GetMyFranchisee(ctx context.Context, userID uuid.UUID) (*Franchisee, error) {
	return s.repo.GetFranchiseeByUserID(ctx, userID)
}
```

Append after `MarkOverdueRoyalties`:

```go
// ListRoyaltyRecords returns all royalty records for a franchisee ordered by period desc.
func (s *Service) ListRoyaltyRecords(ctx context.Context, franchiseeID uuid.UUID) ([]*RoyaltyPaymentRecord, error) {
	return s.repo.ListRoyaltyByFranchisee(ctx, franchiseeID)
}
```

- [ ] **Step 2.7: Add handler methods in handler.go**

Append at the end of `handler.go`:

```go
// GetMyFranchisee handles GET /api/v1/me/franchisee.
func (h *Handler) GetMyFranchisee(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}
	f, err := h.svc.GetMyFranchisee(r.Context(), uc.ID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(f)
}

// ListRoyaltyRecords handles GET /api/v1/royalty-records/{franchiseeID}/all.
func (h *Handler) ListRoyaltyRecords(w http.ResponseWriter, r *http.Request) {
	franchiseeID, err := uuid.Parse(chi.URLParam(r, "franchiseeID"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid franchisee id"))
		return
	}
	records, err := h.svc.ListRoyaltyRecords(r.Context(), franchiseeID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}
	if records == nil {
		records = []*RoyaltyPaymentRecord{}
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(records)
}
```

- [ ] **Step 2.8: Register new routes in module.go**

In `RegisterRoutes`, add two routes inside the authenticated group:

```go
// Me routes
r.Get("/api/v1/me/franchisee", h.GetMyFranchisee)

// Royalty list
r.Get("/api/v1/royalty-records/{franchiseeID}/all", h.ListRoyaltyRecords)
```

Full `RegisterRoutes` after change:

```go
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		r.Get("/api/v1/me/franchisee", h.GetMyFranchisee)

		r.Post("/api/v1/franchisees", h.CreateFranchisee)
		r.Get("/api/v1/franchisees", h.ListFranchisees)
		r.Get("/api/v1/franchisees/{id}", h.GetFranchisee)

		r.Post("/api/v1/franchise-agreements", h.CreateAgreement)
		r.Get("/api/v1/franchise-agreements/{franchiseeID}", h.GetAgreement)

		r.Post("/api/v1/franchise-revenues", h.AddBranchOtherRevenue)

		r.Post("/api/v1/royalty-records", h.CreateRoyaltyRecord)
		r.Get("/api/v1/royalty-records/{franchiseeID}/{period}", h.GetRoyaltyRecord)
		r.Get("/api/v1/royalty-records/{franchiseeID}/all", h.ListRoyaltyRecords)
		r.Post("/api/v1/royalty-records/{id}/mark-paid", h.MarkRoyaltyPaid)
	})
}
```

- [ ] **Step 2.9: Build to verify no compile errors**

```bash
cd backend
go build ./...
```

Expected: no errors.

- [ ] **Step 2.10: Commit**

```bash
git add backend/domains/franchise/model.go \
        backend/domains/franchise/repository.go \
        backend/domains/franchise/service.go \
        backend/domains/franchise/handler.go \
        backend/domains/franchise/module.go
git commit -m "feat(franchise): add GetMyFranchisee + ListRoyaltyRecords endpoint"
```

---

## Task 3: Backend — handler tests for new endpoints

**Files:**
- Modify: `backend/domains/franchise/handler_test.go`

- [ ] **Step 3.1: Add `GetMyFranchisee` to `buildFranchiseRouter`**

In `buildFranchiseRouter`, add:

```go
r.Get("/api/v1/me/franchisee", h.GetMyFranchisee)
r.Get("/api/v1/royalty-records/{franchiseeID}/all", h.ListRoyaltyRecords)
```

- [ ] **Step 3.2: Add unauthenticated test helper**

Add a router builder without auth middleware for 401 tests:

```go
func buildFranchiseRouterNoAuth(svc *franchise.Service) http.Handler {
	h := franchise.NewHandler(svc)
	r := chi.NewRouter()
	r.Get("/api/v1/me/franchisee", h.GetMyFranchisee)
	r.Get("/api/v1/royalty-records/{franchiseeID}/all", h.ListRoyaltyRecords)
	return r
}
```

- [ ] **Step 3.3: Write test — GetMyFranchisee 401 (no auth)**

```go
func TestFranchise_GetMyFranchisee_Unauthenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	router := buildFranchiseRouterNoAuth(svc)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/me/franchisee", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusUnauthorized, w.Code)
}
```

- [ ] **Step 3.4: Write test — GetMyFranchisee 404 (no franchisee linked)**

```go
func TestFranchise_GetMyFranchisee_NotLinked(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	router := buildFranchiseRouter(svc, "franchisee")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/me/franchisee", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}
```

- [ ] **Step 3.5: Write test — ListRoyaltyRecords 200 (empty)**

```go
func TestFranchise_ListRoyaltyRecords_Empty(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	router := buildFranchiseRouter(svc, "vernonedu_admin")

	id := uuid.New()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/royalty-records/"+id.String()+"/all", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}
```

- [ ] **Step 3.6: Run tests**

```bash
cd backend
go test -tags integration ./domains/franchise/... -v -run TestFranchise_GetMyFranchisee -run TestFranchise_ListRoyaltyRecords
```

Expected: all 3 tests PASS.

- [ ] **Step 3.7: Commit**

```bash
git add backend/domains/franchise/handler_test.go
git commit -m "test(franchise): add handler tests for GetMyFranchisee and ListRoyaltyRecords"
```

---

## Task 4: Frontend — `franchise.ts` API file

**Files:**
- Create: `frontend/src/lib/api/franchise.ts`

- [ ] **Step 4.1: Create `franchise.ts`**

```typescript
// frontend/src/lib/api/franchise.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'

// ── Types ──────────────────────────────────────────────────────────────────

export interface Franchisee {
  id: string
  name: string
  branch_name: string
  location: string
  contact: string
  status: 'active' | 'inactive' | 'terminated'
  created_by: string
  user_id?: string
  created_at: string
  updated_at: string
}

export interface FranchiseAgreement {
  id: string
  franchisee_id: string
  buy_in_fee: number
  monthly_royalty: number
  revenue_royalty_pct: number
  start_date: string
  end_date?: string
  status: 'active' | 'inactive' | 'terminated'
  created_at: string
  updated_at: string
}

export interface RoyaltyRecord {
  id: string
  franchise_agreement_id: string
  period: string
  gross_revenue: number
  monthly_royalty: number
  revenue_royalty: number
  total_royalty: number
  status: 'unpaid' | 'overdue' | 'paid'
  created_at: string
  paid_at?: string
  recorded_by: string
}

// ── Hooks ──────────────────────────────────────────────────────────────────

export function useMyFranchisee() {
  return useQuery({
    queryKey: ['franchisee', 'me'],
    queryFn: () => apiClient.get<Franchisee>('/me/franchisee').then((r) => r.data),
  })
}

export function useFranchisee(id: string) {
  return useQuery({
    queryKey: ['franchisee', id],
    queryFn: () => apiClient.get<Franchisee>(`/franchisees/${id}`).then((r) => r.data),
    enabled: !!id,
  })
}

export function useAgreement(franchiseeId: string) {
  return useQuery({
    queryKey: ['franchise-agreement', franchiseeId],
    queryFn: () =>
      apiClient
        .get<FranchiseAgreement>(`/franchise-agreements/${franchiseeId}`)
        .then((r) => r.data),
    enabled: !!franchiseeId,
  })
}

export function useRoyaltyRecords(franchiseeId: string) {
  return useQuery({
    queryKey: ['royalty-records', franchiseeId],
    queryFn: () =>
      apiClient
        .get<RoyaltyRecord[]>(`/royalty-records/${franchiseeId}/all`)
        .then((r) => r.data),
    enabled: !!franchiseeId,
  })
}

export function useMarkRoyaltyPaid() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.post(`/royalty-records/${id}/mark-paid`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['royalty-records'] }),
  })
}
```

- [ ] **Step 4.2: Commit**

```bash
git add frontend/src/lib/api/franchise.ts
git commit -m "feat(frontend): add franchise API hooks (franchisee, royalty, agreement)"
```

---

## Task 5: Frontend — `team_member.ts` API file

**Files:**
- Create: `frontend/src/lib/api/team_member.ts`

- [ ] **Step 5.1: Create `team_member.ts`**

```typescript
// frontend/src/lib/api/team_member.ts
import { useQuery } from '@tanstack/react-query'
import { apiClient } from './client'

// ── Types ──────────────────────────────────────────────────────────────────

export interface TeamMember {
  id: string
  user_id: string
  full_name: string
  phone: string
  department_id?: string
  employment_status: 'active' | 'inactive' | 'on_leave'
  joined_at: string
  is_facilitator: boolean
  created_at: string
  updated_at: string
}

export interface FeeTier {
  id: string
  name: string
  amount_per_class?: number
  amount_per_course?: number
  is_active: boolean
  created_by: string
  created_at: string
  updated_at: string
}

export interface FacilitatorProposal {
  id: string
  course_id: string
  proposed_by: string
  facilitator_id: string
  fee_tier_id: string
  fee_basis: 'per_class' | 'per_course' | 'both'
  dept_review_status: 'pending' | 'approved' | 'rejected'
  academic_review_status: 'pending' | 'approved' | 'rejected'
  created_at: string
  updated_at: string
}

// ── Hooks ──────────────────────────────────────────────────────────────────

export function useTeamMembers() {
  return useQuery({
    queryKey: ['team-members'],
    queryFn: () =>
      apiClient.get<TeamMember[]>('/team-members').then((r) => r.data),
  })
}

export function useFeeTiers() {
  return useQuery({
    queryKey: ['fee-tiers'],
    queryFn: () =>
      apiClient.get<FeeTier[]>('/fee-tiers').then((r) => r.data),
  })
}
```

- [ ] **Step 5.2: Commit**

```bash
git add frontend/src/lib/api/team_member.ts
git commit -m "feat(frontend): add team_member API hooks"
```

---

## Task 6: Frontend — `FranchiseeContext` + portal wiring

**Files:**
- Create: `frontend/src/portals/franchise/FranchiseeContext.tsx`
- Modify: `frontend/src/portals/franchise/FranchisePortal.tsx`
- Modify: `frontend/src/App.tsx`

- [ ] **Step 6.1: Create `FranchiseeContext.tsx`**

```typescript
// frontend/src/portals/franchise/FranchiseeContext.tsx
import { createContext, useContext } from 'react'
import { useMyFranchisee, type Franchisee } from '@/lib/api/franchise'
import LoadingSpinner from '@/components/shared/LoadingSpinner'

interface FranchiseeContextValue {
  franchisee: Franchisee
}

const FranchiseeContext = createContext<FranchiseeContextValue | null>(null)

export function useFranchiseeCtx(): FranchiseeContextValue {
  const ctx = useContext(FranchiseeContext)
  if (!ctx) throw new Error('useFranchiseeCtx must be used inside FranchiseeProvider')
  return ctx
}

export function FranchiseeProvider({ children }: { children: React.ReactNode }) {
  const { data: franchisee, isLoading, isError } = useMyFranchisee()

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (isError || !franchisee) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <p className="text-lg font-semibold text-neutral-800">No franchise account linked</p>
          <p className="text-sm text-neutral-500 mt-1">Contact your administrator to link your account.</p>
        </div>
      </div>
    )
  }

  return (
    <FranchiseeContext.Provider value={{ franchisee }}>
      {children}
    </FranchiseeContext.Provider>
  )
}
```

- [ ] **Step 6.2: Update `FranchisePortal.tsx`**

Replace the entire file:

```typescript
// frontend/src/portals/franchise/FranchisePortal.tsx
import { Outlet, useNavigate } from 'react-router-dom'
import { useAuth } from '@/lib/auth/useAuth'
import { SubNavProvider, SubNavBar } from '@/components/layout/SubNavContext'
import TopNavBar, { NavItem } from '@/components/layout/TopNavBar'
import { FranchiseeProvider } from './FranchiseeContext'

const NAV_ITEMS: NavItem[] = [
  { to: '/franchise', label: 'Dashboard', end: true },
  { to: '/franchise/royalty', label: 'Royalty' },
  { to: '/franchise/enrollments', label: 'Enrollments' },
  { to: '/franchise/payments', label: 'Payments' },
  { to: '/franchise/team', label: 'Team' },
]

function FranchiseLayout() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-neutral-50">
      <TopNavBar
        mainNav={NAV_ITEMS}
        user={user}
        unreadCount={0}
        onLogout={handleLogout}
        avatarClass="bg-violet-100 text-violet-700"
      />
      <SubNavBar />
      <main className="px-6 md:px-8 lg:px-12 py-6">
        <Outlet />
      </main>
    </div>
  )
}

export default function FranchisePortal() {
  return (
    <FranchiseeProvider>
      <SubNavProvider>
        <FranchiseLayout />
      </SubNavProvider>
    </FranchiseeProvider>
  )
}
```

- [ ] **Step 6.3: Update `App.tsx` — import new pages and add routes**

Add imports after existing franchise import block (after `FranchiseDashboard`):

```typescript
import FranchiseCourses from '@/portals/franchise/pages/Courses'
import FranchiseRoyalty from '@/portals/franchise/pages/Royalty'
import FranchiseEnrollments from '@/portals/franchise/pages/Enrollments'
import FranchisePayments from '@/portals/franchise/pages/Payments'
import FranchiseTeamMembers from '@/portals/franchise/pages/TeamMembers'
```

Replace the franchise `<Route>` block:

```tsx
<Route path="/franchise" element={<FranchisePortal />}>
  <Route index element={<FranchiseDashboard />} />
  <Route path="royalty" element={<FranchiseRoyalty />} />
  <Route path="enrollments" element={<FranchiseEnrollments />} />
  <Route path="payments" element={<FranchisePayments />} />
  <Route path="team" element={<FranchiseTeamMembers />} />
</Route>
```

Note: `FranchiseCourses` exists at `pages/Courses.tsx` — it is NOT added here yet because there is no `/franchise/courses` route currently defined. This is intentional; add only if the user confirms they want it.

Actually, looking at App.tsx, there is currently no `/franchise/courses` route. The `Courses.tsx` in franchise portal exists as a file but has no route. Skip it.

- [ ] **Step 6.4: Run TypeScript check**

```bash
cd frontend
npx tsc --noEmit
```

Expected: no errors (pages don't exist yet but imports will fail — that's OK, continue to create pages in subsequent tasks, then re-check).

- [ ] **Step 6.5: Commit**

```bash
git add frontend/src/portals/franchise/FranchiseeContext.tsx \
        frontend/src/portals/franchise/FranchisePortal.tsx \
        frontend/src/App.tsx
git commit -m "feat(frontend): add FranchiseeContext and wire franchise portal routing"
```

---

## Task 7: Frontend — wire Dashboard from mock to real API

**Files:**
- Modify: `frontend/src/portals/franchise/pages/Dashboard.tsx`

- [ ] **Step 7.1: Replace Dashboard.tsx**

Replace the entire file:

```typescript
// frontend/src/portals/franchise/pages/Dashboard.tsx
import { TrendingUp, DollarSign, Percent, ArrowUpRight } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import { formatCurrency } from '@/lib/utils/format'
import { useFranchiseeCtx } from '../FranchiseeContext'
import { useAgreement, useRoyaltyRecords, type RoyaltyRecord } from '@/lib/api/franchise'
import LoadingSpinner from '@/components/shared/LoadingSpinner'
import StatusBadge from '@/components/shared/StatusBadge'

function SummaryCard({
  title,
  value,
  badge,
  icon: Icon,
  color,
}: {
  title: string
  value: string
  badge?: string
  icon: typeof TrendingUp
  color: string
}) {
  return (
    <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-5">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm text-neutral-500">{title}</p>
          <p className="text-2xl font-bold text-neutral-900 mt-1">{value}</p>
          {badge && (
            <div className="flex items-center gap-1 mt-1.5">
              <ArrowUpRight className="w-3.5 h-3.5 text-emerald-600" />
              <span className="text-xs font-medium text-emerald-600">{badge} vs last month</span>
            </div>
          )}
        </div>
        <div className={`w-11 h-11 rounded-xl flex items-center justify-center ${color}`}>
          <Icon className="w-5 h-5" />
        </div>
      </div>
    </div>
  )
}

function toChartData(records: RoyaltyRecord[]) {
  return records
    .slice(0, 6)
    .reverse()
    .map((r) => ({
      month: r.period,
      revenue: Number(r.gross_revenue),
      royalty: Number(r.total_royalty),
    }))
}

export default function FranchiseDashboard() {
  const { franchisee } = useFranchiseeCtx()
  const { data: agreement, isLoading: loadingAgreement } = useAgreement(franchisee.id)
  const { data: royaltyRecords = [], isLoading: loadingRoyalty } = useRoyaltyRecords(franchisee.id)

  const isLoading = loadingAgreement || loadingRoyalty

  const latest = royaltyRecords[0]
  const prev = royaltyRecords[1]
  const revenueGrowth =
    prev && latest && Number(prev.gross_revenue) > 0
      ? (((Number(latest.gross_revenue) - Number(prev.gross_revenue)) / Number(prev.gross_revenue)) * 100).toFixed(1)
      : null

  const chartData = toChartData(royaltyRecords)

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-20">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-neutral-900">{franchisee.branch_name}</h1>
        <p className="text-neutral-500 mt-1 text-sm">Revenue and royalty overview</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <SummaryCard
          title="Revenue (Latest Period)"
          value={latest ? formatCurrency(Number(latest.gross_revenue)) : '—'}
          badge={revenueGrowth ? `+${revenueGrowth}%` : undefined}
          icon={TrendingUp}
          color="bg-brand-100 text-brand-600"
        />
        <SummaryCard
          title="Royalty Due"
          value={latest ? formatCurrency(Number(latest.total_royalty)) : '—'}
          icon={DollarSign}
          color="bg-amber-100 text-amber-600"
        />
        <SummaryCard
          title="Royalty Rate"
          value={agreement ? `${Number(agreement.revenue_royalty_pct)}%` : '—'}
          icon={Percent}
          color="bg-violet-100 text-violet-600"
        />
      </div>

      {chartData.length > 0 && (
        <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-5">
          <h2 className="font-semibold text-neutral-800 mb-4">Monthly Revenue vs Royalty</h2>
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={chartData} margin={{ top: 0, right: 0, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
              <XAxis dataKey="month" tick={{ fontSize: 12, fill: '#94a3b8' }} axisLine={false} tickLine={false} />
              <YAxis
                tick={{ fontSize: 12, fill: '#94a3b8' }}
                axisLine={false}
                tickLine={false}
                tickFormatter={(v: number) => `${(v / 1_000_000).toFixed(0)}M`}
              />
              <Tooltip
                formatter={(value: number, name: string) => [
                  formatCurrency(value),
                  name === 'revenue' ? 'Revenue' : 'Royalty',
                ]}
                contentStyle={{ borderRadius: '8px', border: '1px solid #e2e8f0', fontSize: '12px' }}
              />
              <Bar dataKey="revenue" fill="#3b82f6" radius={[4, 4, 0, 0]} />
              <Bar dataKey="royalty" fill="#a78bfa" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      )}

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-5">
        <h2 className="font-semibold text-neutral-800 mb-4">Royalty Status</h2>
        {royaltyRecords.length === 0 ? (
          <p className="text-sm text-neutral-500 py-4 text-center">No royalty records yet.</p>
        ) : (
          <div className="space-y-3">
            {royaltyRecords.map((row) => (
              <div key={row.id} className="flex items-center justify-between py-2.5 border-b border-border last:border-0">
                <div>
                  <p className="text-sm font-medium text-neutral-800">{row.period}</p>
                  <p className="text-xs text-neutral-500">{formatCurrency(Number(row.gross_revenue))} revenue</p>
                </div>
                <div className="flex items-center gap-3">
                  <p className="text-sm font-semibold text-neutral-800">{formatCurrency(Number(row.total_royalty))}</p>
                  <StatusBadge status={row.status} variant="royalty" />
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
```

Note: `StatusBadge` `variant="royalty"` may not exist yet. If TypeScript errors on this, use `variant="enrollment"` as a fallback or add `'royalty'` to StatusBadge variants (check `src/components/shared/StatusBadge.tsx` and add if missing).

- [ ] **Step 7.2: Check StatusBadge for royalty variant**

```bash
grep -n "royalty\|variant" frontend/src/components/shared/StatusBadge.tsx | head -20
```

If `royalty` variant is missing, add it:
- Find the variant map in StatusBadge
- Add: `royalty: { unpaid: 'bg-amber-100 text-amber-700', overdue: 'bg-red-100 text-red-700', paid: 'bg-emerald-100 text-emerald-700' }`
- Add `'royalty'` to the `variant` prop type

- [ ] **Step 7.3: Run TypeScript check**

```bash
cd frontend && npx tsc --noEmit
```

Expected: no errors related to Dashboard.tsx.

- [ ] **Step 7.4: Commit**

```bash
git add frontend/src/portals/franchise/pages/Dashboard.tsx \
        frontend/src/components/shared/StatusBadge.tsx
git commit -m "feat(frontend): wire franchise Dashboard to real API; replace mock data"
```

---

## Task 8: Frontend — Royalty page

**Files:**
- Create: `frontend/src/portals/franchise/pages/Royalty.tsx`

- [ ] **Step 8.1: Create `Royalty.tsx`**

```typescript
// frontend/src/portals/franchise/pages/Royalty.tsx
import { useState, useMemo } from 'react'
import { toast } from 'sonner'
import { useRoyaltyRecords, useMarkRoyaltyPaid, type RoyaltyRecord } from '@/lib/api/franchise'
import { useFranchiseeCtx } from '../FranchiseeContext'
import { formatCurrency, formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import ConfirmDialog from '@/components/shared/ConfirmDialog'
import { useSubNav, type SubNavItem } from '@/components/layout/SubNavContext'

const ROYALTY_TABS: SubNavItem[] = [
  { label: 'All', value: '' },
  { label: 'Unpaid', value: 'unpaid' },
  { label: 'Overdue', value: 'overdue' },
  { label: 'Paid', value: 'paid' },
]

export default function Royalty() {
  const { franchisee } = useFranchiseeCtx()
  const [activeTab, setActiveTab] = useState('')
  const [confirmItem, setConfirmItem] = useState<RoyaltyRecord | null>(null)

  const handleTabChange = useMemo(
    () => (v: string) => setActiveTab(v),
    [],
  )

  useSubNav(ROYALTY_TABS, activeTab, handleTabChange)

  const { data: records = [], isLoading } = useRoyaltyRecords(franchisee.id)
  const markPaid = useMarkRoyaltyPaid()

  const filtered = activeTab
    ? records.filter((r) => r.status === activeTab)
    : records

  const handleConfirm = async () => {
    if (!confirmItem) return
    try {
      await markPaid.mutateAsync(confirmItem.id)
      toast.success('Royalty marked as paid')
      setConfirmItem(null)
    } catch {
      toast.error('Failed to mark royalty as paid')
    }
  }

  const columns: Column<RoyaltyRecord>[] = [
    {
      header: 'Period',
      accessor: 'period',
      cell: (row) => <span className="font-mono text-sm font-medium text-neutral-800">{row.period}</span>,
    },
    {
      header: 'Gross Revenue',
      accessor: 'gross_revenue',
      cell: (row) => (
        <span className="font-mono text-sm text-neutral-700">{formatCurrency(Number(row.gross_revenue))}</span>
      ),
    },
    {
      header: 'Monthly Royalty',
      accessor: 'monthly_royalty',
      cell: (row) => (
        <span className="font-mono text-sm text-neutral-700">{formatCurrency(Number(row.monthly_royalty))}</span>
      ),
    },
    {
      header: 'Total Royalty',
      accessor: 'total_royalty',
      cell: (row) => (
        <span className="font-mono text-sm font-semibold text-neutral-800">{formatCurrency(Number(row.total_royalty))}</span>
      ),
    },
    {
      header: 'Status',
      accessor: 'status',
      cell: (row) => <StatusBadge status={row.status} variant="royalty" />,
    },
    {
      header: 'Paid At',
      accessor: 'paid_at',
      cell: (row) => (
        <span className="text-xs text-neutral-500">{row.paid_at ? formatDate(row.paid_at) : '—'}</span>
      ),
    },
    {
      header: '',
      accessor: 'id',
      cell: (row) =>
        row.status !== 'paid' ? (
          <button
            onClick={() => setConfirmItem(row)}
            className="inline-flex items-center px-2.5 py-1 text-xs font-medium text-emerald-700 bg-emerald-50 rounded-lg hover:bg-emerald-100 transition-colors"
          >
            Mark Paid
          </button>
        ) : null,
    },
  ]

  return (
    <div className="space-y-5">
      <PageHeader title="Royalty Records" subtitle="Monthly royalty payments for your franchise" />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <DataTable
          columns={columns}
          data={filtered}
          loading={isLoading}
          rowKey={(row) => row.id}
        />
      </div>

      <ConfirmDialog
        open={!!confirmItem}
        title="Mark Royalty as Paid"
        description={`Mark royalty for period ${confirmItem?.period ?? ''} as paid?`}
        onConfirm={handleConfirm}
        onCancel={() => setConfirmItem(null)}
      />
    </div>
  )
}
```

- [ ] **Step 8.2: Check DataTable signature**

```bash
grep -n "pagination\|rowKey\|DataTable" frontend/src/components/shared/DataTable.tsx | head -10
```

If `DataTable` requires a `pagination` prop, add:
```tsx
pagination={{ page: 1, limit: records.length, total: records.length }}
onPageChange={() => {}}
```

- [ ] **Step 8.3: Run TypeScript check**

```bash
cd frontend && npx tsc --noEmit
```

Expected: no errors from Royalty.tsx.

- [ ] **Step 8.4: Commit**

```bash
git add frontend/src/portals/franchise/pages/Royalty.tsx
git commit -m "feat(frontend): add franchise Royalty page"
```

---

## Task 9: Frontend — Enrollments page

**Files:**
- Create: `frontend/src/portals/franchise/pages/Enrollments.tsx`

- [ ] **Step 9.1: Create `Enrollments.tsx`**

```typescript
// frontend/src/portals/franchise/pages/Enrollments.tsx
import { useState, useMemo } from 'react'
import { useEnrollments, type Enrollment } from '@/lib/api/enrollment'
import { formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import { useSubNav, type SubNavItem } from '@/components/layout/SubNavContext'

const STATUS_TABS: SubNavItem[] = [
  { label: 'All', value: '' },
  { label: 'Pending', value: 'pending' },
  { label: 'Confirmed', value: 'confirmed' },
  { label: 'Completed', value: 'completed' },
]

const LIMIT = 15

const COLUMNS: Column<Enrollment>[] = [
  { header: 'Student', accessor: 'student_id' },
  { header: 'Batch', accessor: 'batch_id' },
  {
    header: 'Status',
    accessor: 'status',
    cell: (row) => <StatusBadge status={row.status} variant="enrollment" />,
  },
  {
    header: 'Payment',
    accessor: 'payment_status',
    cell: (row) => <StatusBadge status={row.payment_status} variant="payment" />,
  },
  {
    header: 'Progress',
    accessor: 'completion_percent',
    cell: (row) => (
      <div className="flex items-center gap-2">
        <div className="w-20 h-1.5 bg-neutral-100 rounded-full overflow-hidden">
          <div
            className="h-full bg-brand-500 rounded-full"
            style={{ width: `${row.completion_percent}%` }}
          />
        </div>
        <span className="text-xs text-neutral-500 font-mono tabular-nums">
          {row.completion_percent}%
        </span>
      </div>
    ),
  },
  {
    header: 'Enrolled',
    accessor: 'enrolled_at',
    cell: (row) => <span className="text-xs text-neutral-500">{formatDate(row.enrolled_at)}</span>,
  },
]

export default function FranchiseEnrollments() {
  const [activeTab, setActiveTab] = useState('')
  const [page, setPage] = useState(1)

  const handleTabChange = useMemo(
    () => (v: string) => { setActiveTab(v); setPage(1) },
    [],
  )

  useSubNav(STATUS_TABS, activeTab, handleTabChange)

  const { data, isLoading } = useEnrollments({
    status: activeTab || undefined,
    page,
    limit: LIMIT,
  })

  return (
    <div className="space-y-5">
      <PageHeader title="Enrollments" subtitle="Students enrolled at your franchise" />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <DataTable
          columns={COLUMNS}
          data={data?.data ?? []}
          loading={isLoading}
          pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
          onPageChange={setPage}
          rowKey={(row) => row.id}
        />
      </div>
    </div>
  )
}
```

- [ ] **Step 9.2: Run TypeScript check**

```bash
cd frontend && npx tsc --noEmit
```

Expected: no errors from Enrollments.tsx.

- [ ] **Step 9.3: Commit**

```bash
git add frontend/src/portals/franchise/pages/Enrollments.tsx
git commit -m "feat(frontend): add franchise Enrollments page"
```

---

## Task 10: Frontend — Payments page

**Files:**
- Create: `frontend/src/portals/franchise/pages/Payments.tsx`

- [ ] **Step 10.1: Create `Payments.tsx`**

```typescript
// frontend/src/portals/franchise/pages/Payments.tsx
import { useState, useMemo } from 'react'
import { useInvoices, type Invoice } from '@/lib/api/finance'
import { formatCurrency, formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import { useSubNav, type SubNavItem } from '@/components/layout/SubNavContext'

const PAYMENT_TABS: SubNavItem[] = [
  { label: 'All', value: '' },
  { label: 'Pending', value: 'sent' },
  { label: 'Paid', value: 'paid' },
  { label: 'Overdue', value: 'overdue' },
]

const LIMIT = 15

const COLUMNS: Column<Invoice>[] = [
  {
    header: 'Invoice #',
    accessor: 'number',
    cell: (row) => <span className="font-mono text-xs text-neutral-700">{row.number}</span>,
  },
  {
    header: 'Amount',
    accessor: 'total',
    cell: (row) => (
      <span className="font-semibold text-neutral-800 font-mono">{formatCurrency(row.total)}</span>
    ),
  },
  {
    header: 'Status',
    accessor: 'status',
    cell: (row) => <StatusBadge status={row.status} variant="invoice" />,
  },
  {
    header: 'Due Date',
    accessor: 'due_date',
    cell: (row) => <span className="text-xs text-neutral-500">{formatDate(row.due_date)}</span>,
  },
  {
    header: 'Issued',
    accessor: 'issued_date',
    cell: (row) => <span className="text-xs text-neutral-500">{formatDate(row.issued_date)}</span>,
  },
  {
    header: 'Paid At',
    accessor: 'paid_date',
    cell: (row) => (
      <span className="text-xs text-neutral-500">{row.paid_date ? formatDate(row.paid_date) : '—'}</span>
    ),
  },
]

export default function FranchisePayments() {
  const [activeTab, setActiveTab] = useState('')
  const [page, setPage] = useState(1)

  const handleTabChange = useMemo(
    () => (v: string) => { setActiveTab(v); setPage(1) },
    [],
  )

  useSubNav(PAYMENT_TABS, activeTab, handleTabChange)

  const { data, isLoading } = useInvoices({
    status: activeTab || undefined,
    page,
    limit: LIMIT,
  })

  return (
    <div className="space-y-5">
      <PageHeader title="Payments" subtitle="Invoice and payment history" />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <DataTable
          columns={COLUMNS}
          data={data?.data ?? []}
          loading={isLoading}
          pagination={{ page, limit: LIMIT, total: data?.total ?? 0 }}
          onPageChange={setPage}
          rowKey={(row) => row.id}
        />
      </div>
    </div>
  )
}
```

- [ ] **Step 10.2: Run TypeScript check**

```bash
cd frontend && npx tsc --noEmit
```

Expected: no errors from Payments.tsx.

- [ ] **Step 10.3: Commit**

```bash
git add frontend/src/portals/franchise/pages/Payments.tsx
git commit -m "feat(frontend): add franchise Payments page"
```

---

## Task 11: Frontend — TeamMembers page

**Files:**
- Create: `frontend/src/portals/franchise/pages/TeamMembers.tsx`

- [ ] **Step 11.1: Create `TeamMembers.tsx`**

```typescript
// frontend/src/portals/franchise/pages/TeamMembers.tsx
import { useState, useMemo } from 'react'
import { useTeamMembers, type TeamMember } from '@/lib/api/team_member'
import { formatDate } from '@/lib/utils/format'
import StatusBadge from '@/components/shared/StatusBadge'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import { useSubNav, type SubNavItem } from '@/components/layout/SubNavContext'

const TEAM_TABS: SubNavItem[] = [
  { label: 'All', value: '' },
  { label: 'Facilitators', value: 'facilitator' },
  { label: 'Staff', value: 'staff' },
]

const COLUMNS: Column<TeamMember>[] = [
  {
    header: '',
    accessor: 'full_name',
    className: 'w-10',
    cell: (row) => (
      <div className="w-8 h-8 rounded-full bg-violet-100 flex items-center justify-center text-xs font-bold text-violet-700">
        {row.full_name.charAt(0).toUpperCase()}
      </div>
    ),
  },
  { header: 'Name', accessor: 'full_name' },
  { header: 'Phone', accessor: 'phone' },
  {
    header: 'Role',
    accessor: 'is_facilitator',
    cell: (row) => (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
        row.is_facilitator
          ? 'bg-violet-100 text-violet-700'
          : 'bg-neutral-100 text-neutral-600'
      }`}>
        {row.is_facilitator ? 'Facilitator' : 'Staff'}
      </span>
    ),
  },
  {
    header: 'Status',
    accessor: 'employment_status',
    cell: (row) => <StatusBadge status={row.employment_status} variant="team" />,
  },
  {
    header: 'Joined',
    accessor: 'joined_at',
    cell: (row) => <span className="text-xs text-neutral-500">{formatDate(row.joined_at)}</span>,
  },
]

export default function TeamMembers() {
  const [activeTab, setActiveTab] = useState('')

  const handleTabChange = useMemo(() => (v: string) => setActiveTab(v), [])

  useSubNav(TEAM_TABS, activeTab, handleTabChange)

  const { data: members = [], isLoading } = useTeamMembers()

  const filtered =
    activeTab === 'facilitator'
      ? members.filter((m) => m.is_facilitator)
      : activeTab === 'staff'
        ? members.filter((m) => !m.is_facilitator)
        : members

  return (
    <div className="space-y-5">
      <PageHeader title="Team Members" subtitle="VernonEdu staff and facilitators" />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] overflow-hidden">
        <DataTable
          columns={COLUMNS}
          data={filtered}
          loading={isLoading}
          rowKey={(row) => row.id}
        />
      </div>
    </div>
  )
}
```

Note: `StatusBadge` `variant="team"` may not exist. If so, check `StatusBadge.tsx` and add:
```
team: { active: 'bg-emerald-100 text-emerald-700', inactive: 'bg-neutral-100 text-neutral-500', on_leave: 'bg-amber-100 text-amber-700' }
```
Add `'team'` to the variant type as well.

- [ ] **Step 11.2: Check and update StatusBadge for `team` variant (if missing)**

```bash
grep -n "team\|variant" frontend/src/components/shared/StatusBadge.tsx | head -20
```

- [ ] **Step 11.3: Run full TypeScript check**

```bash
cd frontend && npx tsc --noEmit
```

Expected: no errors across all new files.

- [ ] **Step 11.4: Commit**

```bash
git add frontend/src/portals/franchise/pages/TeamMembers.tsx \
        frontend/src/components/shared/StatusBadge.tsx
git commit -m "feat(frontend): add franchise TeamMembers page; add team StatusBadge variant"
```

---

## Task 12: Smoke test + final check

- [ ] **Step 12.1: Run backend tests**

```bash
cd backend
go test -tags integration ./domains/franchise/... -v
```

Expected: all tests PASS.

- [ ] **Step 12.2: Run frontend build**

```bash
cd frontend
npm run build
```

Expected: build succeeds with no errors.

- [ ] **Step 12.3: Start dev server and verify each route**

```bash
cd frontend && npm run dev
```

Open browser, log in as a franchisee user (or use a test account linked to a franchisee record), and verify:
- `/franchise` — Dashboard shows branch name, real royalty data (or empty state)
- `/franchise/royalty` — Royalty page loads, SubNavBar tabs work
- `/franchise/enrollments` — Enrollments page loads, SubNavBar tabs work
- `/franchise/payments` — Payments page loads, SubNavBar tabs work
- `/franchise/team` — TeamMembers page loads, filter tabs work

- [ ] **Step 12.4: Final commit**

```bash
git add -p
git commit -m "feat(franchise): complete franchise portal — 4 new pages, real API integration"
```
