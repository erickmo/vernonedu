package voucher

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
)

// Module wires voucher domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// RegisterRoutes mounts voucher HTTP routes.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)
	adminMW := mw.RequireRole("admin", "vernonedu_admin")

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		// Admin-only routes
		r.Group(func(r chi.Router) {
			r.Use(adminMW)
			r.Post("/api/v1/vouchers", h.CreateVoucher)
			r.Get("/api/v1/vouchers/{id}", h.GetVoucher)
			r.Get("/api/v1/vouchers", h.ListVouchers)
			r.Patch("/api/v1/vouchers/{id}/deactivate", h.DeactivateVoucher)
		})

		// Any authenticated user (student redemption)
		r.Post("/api/v1/vouchers/apply", h.ApplyVoucher)

		// Student viewing their own assigned vouchers
		r.Get("/api/v1/students/{studentID}/vouchers", h.ListMyVouchers)
	})
}
