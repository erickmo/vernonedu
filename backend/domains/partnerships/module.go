package partnerships

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
)

// Module wires partnerships domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// RegisterRoutes mounts partnerships HTTP routes.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		r.Get("/api/v1/partners", h.ListPartners)
		r.Post("/api/v1/partners", h.CreatePartner)
		r.Get("/api/v1/partners/{id}", h.GetPartner)

		r.Post("/api/v1/agreements", h.CreateAgreement)
		r.Post("/api/v1/agreements/{id}/activate", h.ActivateAgreement)

		r.Get("/api/v1/franchisees", h.ListFranchisees)
	})
}
