package calendar

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
)

var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

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
	})
}
