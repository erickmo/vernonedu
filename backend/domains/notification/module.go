package notification

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
)

// roleAdmin is the role string required for template management endpoints.
const roleAdmin = "admin"

// Module wires all notification domain providers and invocations into fx.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// RegisterRoutes mounts all notification HTTP routes onto the chi router.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)
	adminMW := mw.RequireRole(roleAdmin)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		// User-facing notification routes
		r.Get("/api/v1/notifications", h.ListNotifications)
		r.Get("/api/v1/notifications/unread-count", h.CountUnread)
		r.Put("/api/v1/notifications/{id}/read", h.MarkRead)
		r.Get("/api/v1/notifications/preferences", h.ListPreferences)
		r.Put("/api/v1/notifications/preferences", h.UpsertPreference)

		// Admin-only template management routes
		r.Group(func(r chi.Router) {
			r.Use(adminMW)
			r.Get("/api/v1/notification-templates", h.ListTemplates)
			r.Post("/api/v1/notification-templates", h.CreateTemplate)
			r.Put("/api/v1/notification-templates/{id}", h.UpdateTemplate)
			r.Delete("/api/v1/notification-templates/{id}", h.DeleteTemplate)
		})
	})
}
