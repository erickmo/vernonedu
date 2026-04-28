//go:build integration

package franchise_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"

	"github.com/vernonedu/vernonedu2/backend/domains/franchise"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

func buildFranchiseRouter(svc *franchise.Service, role string) http.Handler {
	h := franchise.NewHandler(svc)
	r := chi.NewRouter()

	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: uuid.New(), Role: role}
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
	r.Get("/api/v1/me/franchisee", h.GetMyFranchisee)
	r.Get("/api/v1/royalty-records/{franchiseeID}/all", h.ListRoyaltyRecords)

	return r
}

func buildFranchiseRouterNoAuth(svc *franchise.Service) http.Handler {
	h := franchise.NewHandler(svc)
	r := chi.NewRouter()
	r.Get("/api/v1/me/franchisee", h.GetMyFranchisee)
	r.Get("/api/v1/royalty-records/{franchiseeID}/all", h.ListRoyaltyRecords)
	return r
}

func TestFranchise_ListFranchisees_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	router := buildFranchiseRouter(svc, "vernonedu_admin")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/franchisees", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestFranchise_GetFranchisee_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	router := buildFranchiseRouter(svc, "vernonedu_admin")

	id := uuid.New()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/franchisees/"+id.String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

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
