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

	"github.com/vernonedu/vernonedu2/backend/domains/team_member"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// buildTeamMemberRouter creates a test router with the given actor role injected.
func buildTeamMemberRouter(svc *team_member.Service, actorID uuid.UUID, actorRole string) http.Handler {
	h := team_member.NewHandler(svc)
	r := chi.NewRouter()

	// Inject user context middleware
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: actorID, Role: actorRole}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})

	r.Get("/api/v1/team-members", h.ListTeamMembers)
	r.Post("/api/v1/team-members", h.CreateTeamMember)
	r.Get("/api/v1/team-members/{id}", h.GetTeamMember)

	r.With(mw.RequireRole("vernonedu_admin")).Post("/api/v1/fee-tiers", h.CreateFeeTier)
	r.Get("/api/v1/fee-tiers", h.ListFeeTiers)

	r.Post("/api/v1/facilitator-proposals", h.CreateProposal)
	r.Get("/api/v1/facilitator-proposals/{id}", h.GetProposal)
	r.Post("/api/v1/facilitator-proposals/{id}/dept-review", h.DeptLeaderReview)
	r.Post("/api/v1/facilitator-proposals/{id}/academic-review", h.AcademicLeaderReview)

	return r
}

// TestTeamMember_CreateFeeTier_ForbiddenForCourseCreator verifies RBAC denies course_creator.
func TestTeamMember_CreateFeeTier_ForbiddenForCourseCreator(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	actorID := uuid.New()
	router := buildTeamMemberRouter(svc, actorID, "course_creator")

	body := `{"name":"Tier Basic","amount_per_class":"500000"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/fee-tiers", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

// TestTeamMember_CreateFeeTier_AllowedForAdmin verifies vernonedu_admin can create fee tiers.
func TestTeamMember_CreateFeeTier_AllowedForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)

	// Seed admin user in DB so created_by FK resolves
	var adminID uuid.UUID
	err := pool.QueryRow(t.Context(), `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('admin_ft@t.local','x','vernonedu_admin') RETURNING id`).Scan(&adminID)
	require.NoError(t, err)

	router := buildTeamMemberRouter(svc, adminID, "vernonedu_admin")

	body := `{"name":"Tier A","amount_per_class":"500000"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/fee-tiers", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusCreated, w.Code)
}

// TestTeamMember_ListTeamMembers_Authenticated verifies authenticated list returns 200.
func TestTeamMember_ListTeamMembers_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	router := buildTeamMemberRouter(svc, uuid.New(), "vernonedu_admin")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/team-members", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

// TestTeamMember_GetProposal_NotFound verifies 404 for unknown proposal ID.
func TestTeamMember_GetProposal_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	router := buildTeamMemberRouter(svc, uuid.New(), "vernonedu_admin")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/facilitator-proposals/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}
