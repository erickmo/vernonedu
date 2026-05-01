package enrollment

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
)

// Module wires enrollment domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// RegisterRoutes mounts enrollment HTTP routes.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		r.Post("/api/v1/enrollments", h.CreateEnrollment)
		r.Get("/api/v1/enrollments/{id}", h.GetEnrollment)
		r.Post("/api/v1/enrollments/{id}/drop", h.DropEnrollment)
		r.Post("/api/v1/enrollments/{id}/complete", h.CompleteEnrollment)
		r.Get("/api/v1/students/{studentID}/enrollments", h.ListEnrollmentsByStudent)
	})
}
