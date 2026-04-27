package identity

import (
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
	"go.uber.org/zap"
)

// Module wires identity domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(provideService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// provideService adapts NewService to fx by reading JWT settings from config.
func provideService(repo Repository, bus events.Bus, log *zap.Logger, cfg *config.Config) *Service {
	expiry := time.Duration(cfg.JWT.ExpiryHours) * time.Hour
	return NewService(repo, bus, log, cfg.JWT.Secret, expiry)
}

// RegisterRoutes mounts identity HTTP routes on the Chi router.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	r.Post("/api/v1/auth/register", h.Register)
	r.Post("/api/v1/auth/login", h.Login)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)
		r.Get("/api/v1/auth/me", h.GetMe)

		r.Get("/api/v1/students", h.ListStudents)
		r.Get("/api/v1/students/{id}", h.GetStudent)

		r.Delete("/api/v1/users/{id}", h.DeactivateUser)
		r.Get("/api/v1/departments", h.ListDepartments)
	})
}
