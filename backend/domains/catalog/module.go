package catalog

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"github.com/vernonedu/vernonedu2/backend/internal/roles"
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

// RegisterRoutes mounts catalog HTTP routes.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)
	manage := mw.RequireRole(roles.Admin, roles.CourseCreator)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		r.Get("/api/v1/courses", h.ListCourses)
		r.With(manage).Post("/api/v1/courses", h.CreateCourse)
		r.Get("/api/v1/courses/{id}", h.GetCourse)
		r.With(manage).Patch("/api/v1/courses/{id}", h.UpdateCourse)
		r.Get("/api/v1/courses/{id}/batches", h.ListBatchesByCourseID)

		r.With(manage).Post("/api/v1/batches", h.CreateBatch)
		r.Get("/api/v1/batches", h.ListBatches)
		r.Get("/api/v1/batches/{id}", h.GetBatch)
		r.With(manage).Post("/api/v1/batches/{id}/open", h.OpenBatch)
		r.With(manage).Post("/api/v1/batches/{id}/close", h.CloseBatch)
		r.With(manage).Patch("/api/v1/batches/{id}/status", h.PatchBatchStatus)

		r.Get("/api/v1/batches/{batchID}/classes", h.ListClasses)
		r.With(mw.RequireRole(roles.Admin, roles.CourseCreator, roles.Facilitator)).Post("/api/v1/classes", h.CreateClass)
	})
}
