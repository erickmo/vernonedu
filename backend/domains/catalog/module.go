package catalog

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
)

// Module wires catalog domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// RegisterRoutes mounts catalog HTTP routes with role-based access control.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	// Authenticated reads — any role.
	r.Group(func(r chi.Router) {
		r.Use(jwtMW)
		r.Get("/api/v1/courses", h.ListCourses)
		r.Get("/api/v1/courses/{id}", h.GetCourse)
		r.Get("/api/v1/batches", h.ListBatches)
		r.Get("/api/v1/batches/{id}", h.GetBatch)
		r.Get("/api/v1/batches/{batchID}/classes", h.ListClasses)
		r.Get("/api/v1/batches/{batchID}/modules", h.ListBatchModules)
	})

	// course_creator + admin family. Handler-level (own) checks where required.
	r.Group(func(r chi.Router) {
		r.Use(jwtMW, mw.RequireRoles("course_creator", "admin", "vernonedu_admin"))
		r.Post("/api/v1/courses", h.CreateCourse)
		r.Put("/api/v1/courses/{id}", h.UpdateCourse)
		r.Post("/api/v1/courses/{id}/format-configs", h.AddFormatConfig)
		r.Post("/api/v1/courses/{courseID}/batches", h.CreateBatch)
		r.Post("/api/v1/batches", h.CreateBatch)
		r.Post("/api/v1/batches/{id}/classes", h.CreateClass)
		r.Post("/api/v1/classes/{id}/reschedule", h.RescheduleClass)
		r.Post("/api/v1/courses/{courseID}/cost-templates", h.CreateCostTemplate)
		r.Get("/api/v1/batches/{batchID}/cost-line-items", h.ListBatchCostLineItems)
		r.Post("/api/v1/courses/{courseID}/modules", h.CreateModule)
		r.Post("/api/v1/modules/{id}/versions", h.CreateModuleVersion)
		r.Post("/api/v1/modules/versions/{vid}/publish", h.PublishModuleVersion)
	})

	// admin / vernonedu_admin only.
	r.Group(func(r chi.Router) {
		r.Use(jwtMW, mw.RequireRoles("admin", "vernonedu_admin"))
		r.Post("/api/v1/batches/{id}/open", h.OpenBatch)
		r.Post("/api/v1/batches/{id}/move-to-ongoing", h.MoveToOngoing)
		r.Post("/api/v1/batches/{id}/close", h.CloseBatch)
		r.Post("/api/v1/classes/{id}/cancel", h.CancelClass)
	})

	// dept_leader + course_creator (own) + admin.
	r.Group(func(r chi.Router) {
		r.Use(jwtMW, mw.RequireRoles("dept_leader", "course_creator", "admin", "vernonedu_admin"))
		r.Post("/api/v1/classes/{id}/instructor", h.AssignInstructor)
		r.Post("/api/v1/batches/{batchID}/modules/{modID}/lock", h.LockBatchToVersion)
	})
}
