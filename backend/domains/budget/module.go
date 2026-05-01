package budget

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
)

const (
	roleVernonAdmin   = "vernonedu_admin"
	roleCourseCreator = "course_creator"
)

// Module wires budget domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// RegisterRoutes mounts all budget HTTP routes under JWT auth.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)
	manageTemplate    := mw.RequireRole(roleCourseCreator, roleVernonAdmin)
	manageBatch       := mw.RequireRole(roleCourseCreator, roleVernonAdmin)
	manageRealization := mw.RequireRole(roleVernonAdmin)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		// Course budget templates — read: any auth; write: course_creator or vernonedu_admin
		r.Get("/api/v1/courses/{course_id}/budget-templates", h.ListTemplateItems)
		r.Get("/api/v1/courses/{course_id}/budget-templates/{id}", h.GetTemplateItem)
		r.With(manageTemplate).Post("/api/v1/courses/{course_id}/budget-templates", h.CreateTemplateItem)
		r.With(manageTemplate).Put("/api/v1/courses/{course_id}/budget-templates/{id}", h.UpdateTemplateItem)
		r.With(manageTemplate).Delete("/api/v1/courses/{course_id}/budget-templates/{id}", h.DeleteTemplateItem)

		// Batch budget items — read: any auth; write: course_creator or vernonedu_admin
		r.Get("/api/v1/batches/{batch_id}/budget-items", h.ListBatchItems)
		r.Get("/api/v1/batches/{batch_id}/budget-items/{id}", h.GetBatchItem)
		r.With(manageBatch).Post("/api/v1/batches/{batch_id}/budget-items", h.CreateBatchItem)
		r.With(manageBatch).Put("/api/v1/batches/{batch_id}/budget-items/{id}", h.UpdateBatchItem)
		r.With(manageBatch).Delete("/api/v1/batches/{batch_id}/budget-items/{id}", h.DeleteBatchItem)

		// Realizations — read: any auth; write: vernonedu_admin only
		r.Get("/api/v1/budget-items/{item_id}/realizations", h.ListRealizations)
		r.Get("/api/v1/budget-items/{item_id}/realizations/{id}", h.GetRealization)
		r.With(manageRealization).Post("/api/v1/budget-items/{item_id}/realizations", h.CreateRealization)
		r.With(manageRealization).Put("/api/v1/budget-items/{item_id}/realizations/{id}", h.UpdateRealization)
		r.With(manageRealization).Delete("/api/v1/budget-items/{item_id}/realizations/{id}", h.DeleteRealization)

		// Summary
		r.Get("/api/v1/batches/{batch_id}/budget-summary", h.GetBatchSummary)
	})
}
