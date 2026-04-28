//go:build integration

package partnerships_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/vernonedu/vernonedu2/backend/domains/partnerships"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildPartnershipsRouter(svc *partnerships.Service, actorID uuid.UUID) http.Handler {
	h := partnerships.NewHandler(svc)
	r := chi.NewRouter()
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: actorID, Role: "vernonedu_admin"}
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

func newPartnershipsService(t *testing.T, pool *pgxpool.Pool) *partnerships.Service {
	t.Helper()
	repo := partnerships.NewRepository(pool)
	bus := events.NewBus(zap.NewNop())
	return partnerships.NewService(repo, bus, zap.NewNop())
}

func TestPartnerships_ListPartners_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	actorID := uuid.New()
	svc := newPartnershipsService(t, pool)
	router := buildPartnershipsRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/partners", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestPartnerships_GetPartner_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	actorID := uuid.New()
	svc := newPartnershipsService(t, pool)
	router := buildPartnershipsRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/partners/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

func TestPartnerships_ListFranchisees_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	actorID := uuid.New()
	svc := newPartnershipsService(t, pool)
	router := buildPartnershipsRouter(svc, actorID)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/franchisees", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestPartnerships_CreatePartner_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	actorID := uuid.New()
	svc := newPartnershipsService(t, pool)
	router := buildPartnershipsRouter(svc, actorID)

	body := `{"name":"Test Corp","type":"university","contact_name":"John","contact_email":"john@corp.com","contact_phone":"08123"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/partners", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusCreated, w.Code)
}
