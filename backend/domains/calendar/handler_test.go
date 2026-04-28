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

func newCalendarRouter(t *testing.T) (http.Handler, uuid.UUID) {
	t.Helper()
	pool := newTestPool(t)
	t.Cleanup(func() { pool.Close() })
	resetSchemas(t, pool)
	actorID := seedUser(t, pool)
	bus := events.NewBus(zap.NewNop())
	svc := calendar.NewService(calendar.NewRepository(pool), bus, zap.NewNop())
	return buildCalendarRouter(svc, actorID), actorID
}

func TestCalendar_ListEvents_Authenticated(t *testing.T) {
	router, _ := newCalendarRouter(t)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/calendar", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestCalendar_CreateEvent_Authenticated(t *testing.T) {
	router, _ := newCalendarRouter(t)

	body := `{"title":"Team Sync","event_type":"staff_meeting","start_at":"2026-05-01T09:00:00Z","end_at":"2026-05-01T10:00:00Z"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/calendar", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusCreated, w.Code)
}

func TestCalendar_GetEvent_NotFound(t *testing.T) {
	router, _ := newCalendarRouter(t)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/calendar/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

func TestCalendar_ExportUserICal_Authenticated(t *testing.T) {
	router, _ := newCalendarRouter(t)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/calendar/export/ical", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusOK, w.Code)
}

func TestCalendar_GetSync_NotFound(t *testing.T) {
	router, _ := newCalendarRouter(t)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/calendar/sync", http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}
