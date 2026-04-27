package team_member

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
)

// Module wires team_member domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// RegisterRoutes mounts team_member HTTP routes.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		// Team member routes
		r.Post("/api/v1/team-members", h.CreateTeamMember)
		r.Get("/api/v1/team-members", h.ListTeamMembers)
		r.Get("/api/v1/team-members/{id}", h.GetTeamMember)

		// Fee tier routes (admin only enforced by RequireRole middleware per route)
		r.With(mw.RequireRole(roleVernonAdmin)).Post("/api/v1/fee-tiers", h.CreateFeeTier)
		r.Get("/api/v1/fee-tiers", h.ListFeeTiers)

		// Facilitator proposal routes
		r.Post("/api/v1/facilitator-proposals", h.CreateProposal)
		r.Get("/api/v1/facilitator-proposals/{id}", h.GetProposal)
		r.Post("/api/v1/facilitator-proposals/{id}/dept-review", h.DeptLeaderReview)
		r.Post("/api/v1/facilitator-proposals/{id}/academic-review", h.AcademicLeaderReview)
	})
}
