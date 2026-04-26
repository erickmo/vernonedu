# Identity Domain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring `backend/domains/identity` to full alignment with `docs/domains/auth/spec.md`, `docs/domains/student/spec.md`, `docs/domains/team-member/spec.md`.

**Architecture:** Single `identity` Go package owns User/Auth/Student/StudentProfile/TeamMember/FacilitatorProfile/FacilitatorProposal/FeeTier. Layered: model → repository (sqlc) → service (business rules) → handler (chi) → events (bus). RBAC middleware in `internal/middleware/rbac.go` enforces role policy.

**Tech Stack:** Go 1.22, chi v5, pgx/v5, sqlc, uber/fx, zap, jwt/v5, bcrypt (golang.org/x/crypto), shopspring/decimal, uuid.

---

## Source-of-truth Spec Files

- `docs/domains/auth/spec.md`
- `docs/domains/student/spec.md`
- `docs/domains/team-member/spec.md`
- `backend/migrations/000001_init_identity.up.sql`
- `backend/sqlc/identity.sql`

## File Structure

| File | Responsibility |
|---|---|
| `backend/domains/identity/model.go` | Role enum, EmploymentStatus, FeeBasis, ApprovalStage, ApprovalStatus types; DTO structs |
| `backend/domains/identity/repository.go` | sqlc-backed CRUD + queries for users, students, profiles, team_members, facilitator_profiles, facilitator_proposals, fee_tiers |
| `backend/domains/identity/service.go` | Business rules: registration, login, password hashing, profile completion, facilitator approval flow, tier rules |
| `backend/domains/identity/handler.go` | HTTP: `/auth/register`, `/auth/login`, `/students/me`, `/students/me/profile`, `/team-members`, `/facilitator-proposals`, `/fee-tiers` |
| `backend/domains/identity/events.go` | Triggers `auth.user.created`, `auth.user.deactivated`, `student.profile_completed`, `team_member.created`, `team_member.status_changed`, `facilitator.proposed/approved/rejected` |
| `backend/domains/identity/module.go` | fx wiring + chi route mount |
| `backend/internal/middleware/rbac.go` | RBAC enforcement + helper `RequireRoles(roles ...Role)` |
| `backend/sqlc/identity.sql` | Add missing queries (see Task list) |

---

## Task 1: Audit existing identity package vs spec

**Files:**
- Read: `backend/domains/identity/*.go`
- Read: `backend/migrations/000001_init_identity.up.sql`
- Read: `backend/sqlc/identity.sql`

- [ ] **Step 1: Inventory existing entities**

Run: `grep -n "^type " backend/domains/identity/model.go`
List entities present. Compare with spec entity list:
- Auth: User, Role
- Student: Student, StudentProfile
- TeamMember: TeamMember, FacilitatorProfile, FacilitatorProposal, FeeTier

- [ ] **Step 2: Inventory existing service methods**

Run: `grep -n "^func (s \*Service)" backend/domains/identity/service.go`
List methods present. Compare with spec required actions:
- Register, Login, GetCurrentUser, Logout
- UpdateStudentProfile (sets profile_complete when all fields set)
- CreateTeamMember, UpdateTeamMemberStatus, DeactivateTeamMember
- ProposeFacilitator, ApproveProposalDeptLeader, ApproveProposalAcademicLeader, RejectProposal
- CreateFeeTier, ListFeeTiers (active only filter)

- [ ] **Step 3: Write gap report**

Create `backend/domains/identity/GAPS.md` listing entities/methods missing or incomplete. Use as todo guide for subsequent tasks. Delete file at end.

- [ ] **Step 4: Commit gap report**

```bash
git add backend/domains/identity/GAPS.md
git commit -m "chore(identity): audit gaps vs spec"
```

---

## Task 2: Password hashing utility

**Files:**
- Create: `backend/domains/identity/password.go`
- Create: `backend/domains/identity/password_test.go`

- [ ] **Step 1: Write failing test**

```go
package identity

import "testing"

func TestHashPassword_Verifies(t *testing.T) {
	hash, err := HashPassword("supersecret123")
	if err != nil {
		t.Fatalf("hash: %v", err)
	}
	if !VerifyPassword(hash, "supersecret123") {
		t.Fatal("verify failed for correct password")
	}
	if VerifyPassword(hash, "wrong") {
		t.Fatal("verify accepted wrong password")
	}
}

func TestHashPassword_RejectsTooShort(t *testing.T) {
	if _, err := HashPassword("short"); err == nil {
		t.Fatal("expected error for short password")
	}
}
```

- [ ] **Step 2: Run test, expect FAIL**

Run: `cd backend && go test ./domains/identity -run TestHashPassword`
Expected: undefined HashPassword/VerifyPassword

- [ ] **Step 3: Implement password.go**

```go
package identity

import (
	"errors"

	"golang.org/x/crypto/bcrypt"
)

const minPasswordLen = 8

var ErrPasswordTooShort = errors.New("password must be at least 8 characters")

func HashPassword(plain string) (string, error) {
	if len(plain) < minPasswordLen {
		return "", ErrPasswordTooShort
	}
	h, err := bcrypt.GenerateFromPassword([]byte(plain), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(h), nil
}

func VerifyPassword(hash, plain string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(plain)) == nil
}
```

- [ ] **Step 4: Run test, expect PASS**

Run: `cd backend && go test ./domains/identity -run TestHashPassword -v`

- [ ] **Step 5: Commit**

```bash
git add backend/domains/identity/password.go backend/domains/identity/password_test.go
git commit -m "feat(identity): add password hashing utility"
```

---

## Task 3: Student registration service method

**Files:**
- Modify: `backend/domains/identity/service.go`
- Create: `backend/domains/identity/service_register_test.go`

- [ ] **Step 1: Write failing test**

```go
package identity

import (
	"context"
	"testing"

	"github.com/google/uuid"
)

func TestRegisterStudent_CreatesUserAndStudent(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	bus := newFakeBus()
	svc := NewService(repo, bus, testLogger())

	out, err := svc.RegisterStudent(ctx, RegisterInput{
		Name: "Alice", Email: "a@example.com", Phone: "+62800", Password: "supersecret",
		Source: SourceB2C,
	})
	if err != nil {
		t.Fatalf("register: %v", err)
	}
	if out.Student.ID == uuid.Nil {
		t.Fatal("expected student ID")
	}
	if !bus.Fired("auth.user.created") {
		t.Fatal("expected auth.user.created event")
	}
}

func TestRegisterStudent_RejectsDuplicateEmail(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	repo.SeedUserEmail("a@example.com")
	svc := NewService(repo, newFakeBus(), testLogger())
	_, err := svc.RegisterStudent(ctx, RegisterInput{
		Name: "Alice", Email: "a@example.com", Phone: "+62800", Password: "supersecret",
		Source: SourceB2C,
	})
	if err == nil {
		t.Fatal("expected duplicate-email error")
	}
}
```

(Helpers `newFakeRepo`, `newFakeBus`, `testLogger`, `Fired` defined in `service_test_helpers.go` — see Task 4.)

- [ ] **Step 2: Run test, expect FAIL** (`RegisterStudent` undefined)

- [ ] **Step 3: Implement RegisterStudent**

```go
type RegisterInput struct {
	Name, Email, Phone, Password string
	Source                       Source
	Partner                      *uuid.UUID
}

type RegisterOutput struct {
	User    User
	Student Student
}

func (s *Service) RegisterStudent(ctx context.Context, in RegisterInput) (*RegisterOutput, error) {
	if exists, _ := s.repo.UserExistsByEmail(ctx, in.Email); exists {
		return nil, apperrors.Validationf("email already registered")
	}
	hash, err := HashPassword(in.Password)
	if err != nil {
		return nil, apperrors.Validationf("%v", err)
	}
	user, err := s.repo.CreateUser(ctx, CreateUserParams{
		Email: in.Email, PasswordHash: hash, Role: RoleStudent,
	})
	if err != nil {
		return nil, err
	}
	stu, err := s.repo.CreateStudent(ctx, CreateStudentParams{
		UserID: user.ID, Name: in.Name, Phone: in.Phone, Source: in.Source, PartnerID: in.Partner,
	})
	if err != nil {
		return nil, err
	}
	s.bus.Publish(ctx, events.Event{
		Name: "auth.user.created",
		Payload: map[string]any{"user_id": user.ID, "email": user.Email, "role": user.Role},
	})
	return &RegisterOutput{User: user, Student: stu}, nil
}
```

- [ ] **Step 4: Run test, expect PASS**

- [ ] **Step 5: Commit**

```bash
git add backend/domains/identity/service.go backend/domains/identity/service_register_test.go
git commit -m "feat(identity): implement student registration service"
```

---

## Task 4: Login service method

**Files:**
- Modify: `backend/domains/identity/service.go`
- Create: `backend/domains/identity/service_login_test.go`

- [ ] **Step 1: Write failing test**

```go
func TestLogin_ValidCredentialsReturnsToken(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	hash, _ := HashPassword("supersecret")
	repo.SeedUser("a@example.com", hash, RoleStudent)
	svc := NewService(repo, newFakeBus(), testLogger())
	out, err := svc.Login(ctx, "a@example.com", "supersecret")
	if err != nil {
		t.Fatalf("login: %v", err)
	}
	if out.Token == "" {
		t.Fatal("expected token")
	}
}

func TestLogin_WrongPasswordRejected(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	hash, _ := HashPassword("supersecret")
	repo.SeedUser("a@example.com", hash, RoleStudent)
	svc := NewService(repo, newFakeBus(), testLogger())
	if _, err := svc.Login(ctx, "a@example.com", "wrong"); err == nil {
		t.Fatal("expected unauthorized")
	}
}
```

- [ ] **Step 2: Run test, expect FAIL**

- [ ] **Step 3: Implement Login + JWT issuance**

```go
func (s *Service) Login(ctx context.Context, email, password string) (*LoginOutput, error) {
	u, err := s.repo.GetUserByEmail(ctx, email)
	if err != nil || u == nil {
		return nil, apperrors.ErrUnauthorized
	}
	if !VerifyPassword(u.PasswordHash, password) {
		return nil, apperrors.ErrUnauthorized
	}
	tok, err := s.issueJWT(u)
	if err != nil {
		return nil, err
	}
	return &LoginOutput{User: *u, Token: tok}, nil
}
```

`issueJWT` signs `{user_id, role, exp}` using `jwt/v5` with HMAC secret from config.

- [ ] **Step 4: Run test, expect PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(identity): implement login and JWT issuance"
```

---

## Task 5: Student profile completion

**Files:**
- Modify: `backend/domains/identity/service.go`
- Create: `backend/domains/identity/service_profile_test.go`

- [ ] **Step 1: Write failing test**

```go
func TestUpdateProfile_SetsCompleteFlag(t *testing.T) {
	ctx := context.Background()
	repo := newFakeRepo()
	stu := repo.SeedStudent("a@example.com", SourceB2C)
	bus := newFakeBus()
	svc := NewService(repo, bus, testLogger())
	_, err := svc.UpdateStudentProfile(ctx, stu.ID, ProfileInput{
		DateOfBirth: dateMust("2000-01-01"), Gender: GenderMale, IDType: IDTypeKTP,
		IDNumber: "320123", Address: "Jl 1", City: "Jkt", Province: "DKI", PostalCode: "12000",
	})
	if err != nil {
		t.Fatalf("update: %v", err)
	}
	if !repo.GetProfile(stu.ID).ProfileComplete {
		t.Fatal("expected profile_complete = true")
	}
	if !bus.Fired("student.profile_completed") {
		t.Fatal("expected student.profile_completed event")
	}
}
```

- [ ] **Step 2: Run test, expect FAIL**

- [ ] **Step 3: Implement UpdateStudentProfile**

Required fields: date_of_birth, gender, id_type, id_number, address, city, province, postal_code. Set `profile_complete = true` only if all set; fire `student.profile_completed` only on `false → true` transition.

```go
func (s *Service) UpdateStudentProfile(ctx context.Context, studentID uuid.UUID, in ProfileInput) (*StudentProfile, error) {
	prev, _ := s.repo.GetStudentProfile(ctx, studentID)
	complete := in.HasAllRequired()
	p, err := s.repo.UpsertStudentProfile(ctx, studentID, in, complete)
	if err != nil {
		return nil, err
	}
	if complete && (prev == nil || !prev.ProfileComplete) {
		s.bus.Publish(ctx, events.Event{
			Name:    "student.profile_completed",
			Payload: map[string]any{"student_id": studentID},
		})
	}
	return p, nil
}
```

- [ ] **Step 4: Run test, expect PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(identity): student profile completion with event"
```

---

## Task 6: TeamMember CRUD + status_changed event

**Files:**
- Modify: `backend/domains/identity/service.go`
- Create: `backend/domains/identity/service_teammember_test.go`

- [ ] **Step 1: Write failing test for CreateTeamMember**

Test: creating TeamMember fires `team_member.created`. Status change `active → on_leave` fires `team_member.status_changed`.

```go
func TestCreateTeamMember_FiresEvent(t *testing.T) { /* ... */ }
func TestUpdateTeamMemberStatus_FiresEvent(t *testing.T) { /* ... */ }
```

- [ ] **Step 2: Run test, expect FAIL**

- [ ] **Step 3: Implement CreateTeamMember + UpdateTeamMemberStatus**

```go
func (s *Service) CreateTeamMember(ctx context.Context, in CreateTeamMemberInput) (*TeamMember, error) {
	tm, err := s.repo.CreateTeamMember(ctx, in)
	if err != nil {
		return nil, err
	}
	s.bus.Publish(ctx, events.Event{Name: "team_member.created", Payload: map[string]any{"team_member_id": tm.ID, "role": tm.Role}})
	return tm, nil
}

func (s *Service) UpdateTeamMemberStatus(ctx context.Context, id uuid.UUID, newStatus EmploymentStatus) error {
	prev, err := s.repo.GetTeamMember(ctx, id)
	if err != nil {
		return err
	}
	if prev.EmploymentStatus == newStatus {
		return nil
	}
	if err := s.repo.UpdateTeamMemberStatus(ctx, id, newStatus); err != nil {
		return err
	}
	s.bus.Publish(ctx, events.Event{Name: "team_member.status_changed", Payload: map[string]any{
		"team_member_id": id, "old_status": prev.EmploymentStatus, "new_status": newStatus,
	}})
	return nil
}
```

- [ ] **Step 4: Run test, expect PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(identity): team-member CRUD and status events"
```

---

## Task 7: Facilitator proposal approval flow

**Files:**
- Modify: `backend/domains/identity/service.go`
- Create: `backend/domains/identity/service_facilitator_test.go`

Spec: `docs/domains/team-member/spec.md` Approval Flow.

- [ ] **Step 1: Write failing tests**

```go
// 1. ProposeFacilitator → final_status=pending, dept_leader_status=pending, fires facilitator.proposed
// 2. ApproveByDeptLeader on pending → dept_leader_status=approved, academic_leader_status=pending
// 3. ApproveByDeptLeader twice → error: already reviewed
// 4. ApproveByAcademicLeader before dept leader approval → error
// 5. ApproveByAcademicLeader after dept leader approved → final_status=approved, fires facilitator.approved
// 6. RejectByDeptLeader → final_status=rejected, fires facilitator.rejected with stage=dept_leader
// 7. RejectByAcademicLeader (after dept approval) → final_status=rejected, stage=academic_leader
// 8. ProposeFacilitator with proposed_by who isn't course_creator → error
// 9. ProposeFacilitator with facilitator missing is_facilitator=true → error
```

- [ ] **Step 2: Run tests, expect FAIL**

- [ ] **Step 3: Implement ProposeFacilitator**

Validate proposer role + facilitator flag. Insert proposal with `final_status = pending`, `dept_leader_status = pending`, `academic_leader_status = pending`. Fire `facilitator.proposed`.

- [ ] **Step 4: Implement ApproveByDeptLeader / RejectByDeptLeader**

Reject if `dept_leader_status != pending`. On approve: dept_leader_status=approved, set reviewed_at, leave academic_leader_status=pending. On reject: final_status=rejected, fire `facilitator.rejected` (stage=dept_leader).

- [ ] **Step 5: Implement ApproveByAcademicLeader / RejectByAcademicLeader**

Require `dept_leader_status = approved`. On approve: academic_leader_status=approved, final_status=approved, fire `facilitator.approved`. On reject: final_status=rejected, fire `facilitator.rejected` (stage=academic_leader).

- [ ] **Step 6: Run all tests, expect PASS**

- [ ] **Step 7: Commit**

```bash
git commit -m "feat(identity): facilitator proposal two-stage approval"
```

---

## Task 8: FeeTier management

**Files:**
- Modify: `backend/domains/identity/service.go`
- Create: `backend/domains/identity/service_feetier_test.go`

- [ ] **Step 1: Write failing tests**

- CreateFeeTier requires role `vernonedu_admin` (validated at handler layer; service trusts caller)
- ListFeeTiers default returns active only; `includeInactive=true` returns all
- DeactivateFeeTier sets `is_active=false`; existing proposals using it remain valid

- [ ] **Step 2: Run tests, expect FAIL**

- [ ] **Step 3: Implement Create/List/Deactivate FeeTier**

- [ ] **Step 4: Run tests, expect PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(identity): fee tier management"
```

---

## Task 9: RBAC middleware enforcement

**Files:**
- Modify: `backend/internal/middleware/rbac.go`
- Create: `backend/internal/middleware/rbac_test.go`

Spec: `docs/domains/auth/spec.md` permission matrix.

- [ ] **Step 1: Write failing test**

```go
func TestRequireRoles_AllowsMatchingRole(t *testing.T) {
	h := middleware.RequireRoles("admin", "ceo")(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))
	req := httptest.NewRequest("GET", "/", nil)
	ctx := middleware.WithUserContext(req.Context(), &middleware.UserContext{ID: uuid.New(), Role: "admin"})
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req.WithContext(ctx))
	if rec.Code != 200 {
		t.Fatalf("expected 200, got %d", rec.Code)
	}
}

func TestRequireRoles_RejectsWrongRole(t *testing.T) { /* expects 403 */ }
func TestRequireRoles_RejectsAnonymous(t *testing.T) { /* expects 401 */ }
```

- [ ] **Step 2: Run test, expect FAIL**

- [ ] **Step 3: Implement RequireRoles**

```go
func RequireRoles(allowed ...string) func(http.Handler) http.Handler {
	allowedSet := make(map[string]struct{}, len(allowed))
	for _, r := range allowed {
		allowedSet[r] = struct{}{}
	}
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			uc := GetUserContext(r.Context())
			if uc == nil {
				apperrors.Render(w, apperrors.ErrUnauthorized)
				return
			}
			if _, ok := allowedSet[uc.Role]; !ok {
				apperrors.Render(w, apperrors.ErrForbidden)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}
```

- [ ] **Step 4: Run test, expect PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(rbac): RequireRoles middleware"
```

---

## Task 10: Wire HTTP routes with RBAC

**Files:**
- Modify: `backend/domains/identity/handler.go`
- Modify: `backend/domains/identity/module.go`

- [ ] **Step 1: Mount routes per spec permission matrix**

```go
func (h *Handler) Mount(r chi.Router) {
	r.Post("/auth/register", h.Register)
	r.Post("/auth/login", h.Login)

	r.Group(func(pr chi.Router) {
		pr.Use(mw.RequireAuth) // student or any logged-in user
		pr.Get("/students/me", h.GetCurrentStudent)
		pr.Put("/students/me/profile", h.UpdateOwnProfile)
	})

	r.Group(func(pr chi.Router) {
		pr.Use(mw.RequireAuth, mw.RequireRoles("vernonedu_admin", "admin"))
		pr.Post("/team-members", h.CreateTeamMember)
		pr.Patch("/team-members/{id}/status", h.UpdateTeamMemberStatus)
		pr.Post("/fee-tiers", h.CreateFeeTier)
		pr.Get("/fee-tiers", h.ListFeeTiers)
	})

	r.Group(func(pr chi.Router) {
		pr.Use(mw.RequireAuth, mw.RequireRoles("course_creator"))
		pr.Post("/facilitator-proposals", h.ProposeFacilitator)
	})

	r.Group(func(pr chi.Router) {
		pr.Use(mw.RequireAuth, mw.RequireRoles("dept_leader"))
		pr.Post("/facilitator-proposals/{id}/dept-leader-approve", h.ApproveByDeptLeader)
		pr.Post("/facilitator-proposals/{id}/dept-leader-reject", h.RejectByDeptLeader)
	})

	r.Group(func(pr chi.Router) {
		pr.Use(mw.RequireAuth, mw.RequireRoles("academic_leader"))
		pr.Post("/facilitator-proposals/{id}/academic-leader-approve", h.ApproveByAcademicLeader)
		pr.Post("/facilitator-proposals/{id}/academic-leader-reject", h.RejectByAcademicLeader)
	})
}
```

- [ ] **Step 2: Add handler methods for each route**

Each handler decodes JSON, calls service, renders response/error.

- [ ] **Step 3: Run integration smoke test against running api**

```bash
cd backend && go run ./cmd/api &
sleep 2
curl -X POST localhost:8080/auth/register -d '{"name":"A","email":"a@x.com","phone":"+62","password":"supersecret","source":"b2c"}'
```

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(identity): mount HTTP routes with RBAC"
```

---

## Task 11: Verify all identity tests + lint

- [ ] **Step 1:** `cd backend && go test -race ./domains/identity/... ./internal/middleware/...`
- [ ] **Step 2:** `cd backend && golangci-lint run ./domains/identity/...`
- [ ] **Step 3:** Remove `GAPS.md`. Commit cleanup.

```bash
rm backend/domains/identity/GAPS.md
git commit -am "chore(identity): remove gap audit"
```

---

## Verification

End-to-end smoke:
1. `make docker-up && make migrate-up && make api`
2. Register student via curl → expect 201 + user in DB
3. Login → expect token
4. Update profile with all required fields → expect `profile_complete = true` + event in bus log
5. Create TeamMember → expect 201 + `team_member.created` event
6. Propose facilitator (course_creator JWT) → expect proposal pending
7. Approve via dept_leader → academic_leader sequence → expect `facilitator.approved` event
