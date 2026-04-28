//go:build integration

package profit_split_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/require"

	"github.com/vernonedu/vernonedu2/backend/domains/profit_split"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// seedGlobalSettings seeds the global split settings row required for GetGlobalSettings to return 200.
func seedGlobalSettings(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()
	ctx := context.Background()

	var userID uuid.UUID
	err := pool.QueryRow(ctx, `
		INSERT INTO identity.users (email, password_hash, role)
		VALUES ('ceo.handler@t.local','x','ceo')
		RETURNING id`).Scan(&userID)
	require.NoError(t, err)

	_, err = pool.Exec(ctx, `
		INSERT INTO profit_split.global_settings (vernonedu_pct, course_creator_pct, dept_leader_pct, updated_by)
		VALUES (50, 30, 20, $1)`, userID)
	require.NoError(t, err)
}

func buildProfitSplitRouter(svc *profit_split.Service, role string) http.Handler {
	h := profit_split.NewHandler(svc)
	r := chi.NewRouter()

	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: uuid.New(), Role: role}
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
	seedGlobalSettings(t, pool)

	svc := newService(t, pool)
	router := buildProfitSplitRouter(svc, "ceo")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/profit-split/settings", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestProfitSplit_GetCourseOverride_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	router := buildProfitSplitRouter(svc, "ceo")

	courseID := uuid.New()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/profit-split/overrides/"+courseID.String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

func TestProfitSplit_GetBatchSplitRecord_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newService(t, pool)
	router := buildProfitSplitRouter(svc, "ceo")

	batchID := uuid.New()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/profit-split/batches/"+batchID.String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}
