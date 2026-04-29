package module

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"github.com/vernonedu/vernonedu2/backend/internal/roles"
	"go.uber.org/fx"
)

// Module wires the module domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// RegisterRoutes mounts module HTTP routes.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)
		registerModuleRoutes(r, h)
		registerBatchRoutes(r, h)
		registerCoverageRoutes(r, h)
		registerStudentRoutes(r, h)
		registerVersionRoutes(r, h)
	})
}

func registerModuleRoutes(r chi.Router, h *Handler) {
	manage := mw.RequireRole(roles.Admin, roles.CourseCreator)
	view := mw.RequireRole(roles.Admin, roles.DeptLeader, roles.CourseCreator, roles.Facilitator, roles.Student)
	r.With(manage).Post("/api/v1/courses/{id}/modules", h.CreateModule)
	r.With(view).Get("/api/v1/courses/{id}/modules", h.ListModules)
	r.With(manage).Patch("/api/v1/courses/{id}/modules/{module_id}", h.UpdateModule)
	r.With(manage).Post("/api/v1/modules/{id}/versions", h.CreateVersion)
	r.With(view).Get("/api/v1/modules/{id}/versions", h.ListVersions)
	r.With(manage).Post("/api/v1/modules/{id}/versions/{ver_id}/publish", h.PublishVersion)
	r.With(manage).Post("/api/v1/modules/{id}/versions/{ver_id}/assets", h.CreateAsset)
	r.With(manage).Patch("/api/v1/modules/{id}/versions/{ver_id}/assets/{asset_id}", h.UpdateAsset)
	r.With(manage).Delete("/api/v1/modules/{id}/versions/{ver_id}/assets/{asset_id}", h.DeleteAsset)
}

func registerBatchRoutes(r chi.Router, h *Handler) {
	manage := mw.RequireRole(roles.Admin, roles.DeptLeader, roles.CourseCreator)
	r.With(manage).Get("/api/v1/batches/{id}/module-configs", h.ListBatchModuleConfigs)
	r.With(manage).Put("/api/v1/batches/{id}/module-configs/{module_id}", h.UpsertBatchModuleConfig)
	r.With(mw.RequireRole(roles.Admin, roles.DeptLeader, roles.CourseCreator)).Get("/api/v1/batches/{id}/progress", h.GetBatchProgress)
}

func registerCoverageRoutes(r chi.Router, h *Handler) {
	view   := mw.RequireRole(roles.Admin, roles.DeptLeader, roles.CourseCreator, roles.Facilitator)
	manage := mw.RequireRole(roles.Admin, roles.CourseCreator, roles.Facilitator)
	r.With(view).Get("/api/v1/classes/{id}/coverage", h.ListCoverage)
	r.With(manage).Post("/api/v1/classes/{id}/coverage", h.CreateCoverage)
	r.With(manage).Patch("/api/v1/classes/{id}/coverage/{cov_id}", h.UpdateCoverage)
	r.With(manage).Delete("/api/v1/classes/{id}/coverage/{cov_id}", h.DeleteCoverage)
}

func registerStudentRoutes(r chi.Router, h *Handler) {
	student := mw.RequireRole(roles.Student)
	r.With(student).Get("/api/v1/enrollments/{id}/modules", h.GetStudentModules)
	r.With(student).Get("/api/v1/enrollments/{id}/modules/{module_id}", h.GetStudentModule)
}

func registerVersionRoutes(r chi.Router, h *Handler) {
	view   := mw.RequireRole(roles.Admin, roles.DeptLeader, roles.CourseCreator, roles.Facilitator, roles.Student)
	manage := mw.RequireRole(roles.Admin, roles.CourseCreator)

	r.With(view).Get("/api/v1/module-versions/{id}/assets", h.ListAssetsByVersion)
	r.With(manage).Post("/api/v1/module-versions/{id}/publish", h.PublishVersionByVersionID)
	r.With(manage).Post("/api/v1/module-assets", h.CreateAssetByVersionID)
}
