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

	require.Equal(t, http.StatusNotFound, w.Code)
}
