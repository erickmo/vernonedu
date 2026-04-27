package franchise

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
)

// Module wires franchise domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// RegisterRoutes mounts franchise HTTP routes.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		// Franchisee routes
		r.Post("/api/v1/franchisees", h.CreateFranchisee)
		r.Get("/api/v1/franchisees", h.ListFranchisees)
		r.Get("/api/v1/franchisees/{id}", h.GetFranchisee)

		// Franchise agreement routes
		r.Post("/api/v1/franchise-agreements", h.CreateAgreement)
		r.Get("/api/v1/franchise-agreements/{franchiseeID}", h.GetAgreement)

		// Branch other revenue routes
		r.Post("/api/v1/franchise-revenues", h.AddBranchOtherRevenue)

		// Royalty record routes
		r.Post("/api/v1/royalty-records", h.CreateRoyaltyRecord)
		r.Get("/api/v1/royalty-records/{franchiseeID}/{period}", h.GetRoyaltyRecord)
		r.Post("/api/v1/royalty-records/{id}/mark-paid", h.MarkRoyaltyPaid)
	})
}
