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

func buildNotificationRouter(svc *notification.Service, actorID uuid.UUID, role string) http.Handler {
	h := notification.NewHandler(svc)
	r := chi.NewRouter()

	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			uc := &mw.UserContext{ID: actorID, Role: role}
			next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
		})
	})

	adminMW := mw.RequireRole("admin")

	// User routes
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

// --- Admin-only: forbidden for non-admin ---

func TestNotification_ListTemplates_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool, "student")

	bus := events.NewBus(zap.NewNop())
	svc := notification.NewService(notification.NewRepository(pool), bus, zap.NewNop())
	router := buildNotificationRouter(svc, actorID, "student")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/notification-templates", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestNotification_CreateTemplate_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool, "student")

	bus := events.NewBus(zap.NewNop())
	svc := notification.NewService(notification.NewRepository(pool), bus, zap.NewNop())
	router := buildNotificationRouter(svc, actorID, "student")

	body := `{"key":"test.key","channel":"in_app","body":"Hello"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/notification-templates", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

func TestNotification_UpdateTemplate_ForbiddenForStudent(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool, "student")

	bus := events.NewBus(zap.NewNop())
	svc := notification.NewService(notification.NewRepository(pool), bus, zap.NewNop())
	router := buildNotificationRouter(svc, actorID, "student")

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
	actorID := seedUser(t, pool, "student")

	bus := events.NewBus(zap.NewNop())
	svc := notification.NewService(notification.NewRepository(pool), bus, zap.NewNop())
	router := buildNotificationRouter(svc, actorID, "student")

	req := httptest.NewRequest(http.MethodDelete, "/api/v1/notification-templates/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusForbidden, w.Code)
}

// --- Admin-only: allowed for admin ---

func TestNotification_CreateTemplate_AllowedForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool, "admin")

	bus := events.NewBus(zap.NewNop())
	svc := notification.NewService(notification.NewRepository(pool), bus, zap.NewNop())
	router := buildNotificationRouter(svc, actorID, "admin")

	body := `{"key":"welcome.email","channel":"in_app","body":"Welcome {{name}}"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/notification-templates", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusCreated, w.Code)
}

func TestNotification_ListTemplates_AllowedForAdmin(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool, "admin")

	bus := events.NewBus(zap.NewNop())
	svc := notification.NewService(notification.NewRepository(pool), bus, zap.NewNop())
	router := buildNotificationRouter(svc, actorID, "admin")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/notification-templates", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

// --- User routes: accessible to any authenticated user ---

func TestNotification_ListNotifications_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool, "student")

	bus := events.NewBus(zap.NewNop())
	svc := notification.NewService(notification.NewRepository(pool), bus, zap.NewNop())
	router := buildNotificationRouter(svc, actorID, "student")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/notifications", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestNotification_CountUnread_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool, "student")

	bus := events.NewBus(zap.NewNop())
	svc := notification.NewService(notification.NewRepository(pool), bus, zap.NewNop())
	router := buildNotificationRouter(svc, actorID, "student")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/notifications/unread-count", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestNotification_ListPreferences_Authenticated(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)
	actorID := seedUser(t, pool, "student")

	bus := events.NewBus(zap.NewNop())
	svc := notification.NewService(notification.NewRepository(pool), bus, zap.NewNop())
	router := buildNotificationRouter(svc, actorID, "student")

	req := httptest.NewRequest(http.MethodGet, "/api/v1/notifications/preferences", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}
