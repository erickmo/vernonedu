package profit_split

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
	"go.uber.org/zap"
)

// Module wires profit_split domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// RegisterRoutes mounts profit_split HTTP routes.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus, _ *zap.Logger) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		r.Get("/api/v1/profit-split/settings", h.GetGlobalSettings)
		r.Put("/api/v1/profit-split/settings", h.UpdateGlobalSettings)

		r.Post("/api/v1/profit-split/overrides", h.CreateCourseOverride)
		r.Get("/api/v1/profit-split/overrides/{courseID}", h.GetCourseOverride)

		r.Post("/api/v1/profit-split/extra-revenue", h.AddExtraRevenue)
		r.Post("/api/v1/profit-split/extra-revenue/{id}/approve", h.ApproveExtraRevenue)
		r.Post("/api/v1/profit-split/extra-revenue/{id}/reject", h.RejectExtraRevenue)

		r.Post("/api/v1/profit-split/batch-costs", h.CreateBatchCostLineItem)
		r.Delete("/api/v1/profit-split/batch-costs/{id}", h.RemoveBatchCostLineItem)

		r.Get("/api/v1/profit-split/batches/{batchID}", h.GetBatchSplitRecord)

		r.Post("/api/v1/profit-split/period-bonuses", h.CalculatePeriodBonus)
		r.Get("/api/v1/profit-split/period-bonuses/{period}", h.GetPeriodBonus)
	})
}
