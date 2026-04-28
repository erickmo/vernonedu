package module

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
	"go.uber.org/zap"
)

const (
	roleAdmin         = "vernonedu_admin"
	roleCourseCreator = "course_creator"
	roleDeptLeader    = "dept_leader"
	roleFacilitator   = "facilitator"
)

// Module wires the module domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(registerSubscriptions),
)

func registerSubscriptions(bus events.Bus, svc *Service, log *zap.Logger) {
	RegisterSubscriptions(bus, svc, log)
}

// RegisterRoutes mounts module HTTP routes.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	manageModule   := mw.RequireRole(roleAdmin, roleCourseCreator)
	manageBatchCfg := mw.RequireRole(roleAdmin, roleDeptLeader, roleCourseCreator)
	manageCoverage := mw.RequireRole(roleAdmin, roleCourseCreator, roleFacilitator)
	viewCoverage   := mw.RequireRole(roleAdmin, roleDeptLeader, roleCourseCreator, roleFacilitator)
	viewProgress   := mw.RequireRole(roleAdmin, roleDeptLeader, roleCourseCreator)
	studentAccess  := mw.RequireRole("student")

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		// Module management
		r.With(manageModule).Post("/api/v1/courses/{id}/modules", h.CreateModule)
		r.With(manageModule).Patch("/api/v1/courses/{id}/modules/{module_id}", h.UpdateModule)

		// Version management
		r.With(manageModule).Post("/api/v1/modules/{id}/versions", h.CreateVersion)
		r.With(manageModule).Post("/api/v1/modules/{id}/versions/{ver_id}/publish", h.PublishVersion)

		// Asset management
		r.With(manageModule).Post("/api/v1/modules/{id}/versions/{ver_id}/assets", h.CreateAsset)
		r.With(manageModule).Patch("/api/v1/modules/{id}/versions/{ver_id}/assets/{asset_id}", h.UpdateAsset)
		r.With(manageModule).Delete("/api/v1/modules/{id}/versions/{ver_id}/assets/{asset_id}", h.DeleteAsset)

		// Batch config
		r.With(manageBatchCfg).Get("/api/v1/batches/{id}/module-configs", h.ListBatchModuleConfigs)
		r.With(manageBatchCfg).Put("/api/v1/batches/{id}/module-configs/{module_id}", h.UpsertBatchModuleConfig)

		// Class coverage
		r.With(viewCoverage).Get("/api/v1/classes/{id}/coverage", h.ListCoverage)
		r.With(manageCoverage).Post("/api/v1/classes/{id}/coverage", h.CreateCoverage)
		r.With(manageCoverage).Patch("/api/v1/classes/{id}/coverage/{cov_id}", h.UpdateCoverage)
		r.With(manageCoverage).Delete("/api/v1/classes/{id}/coverage/{cov_id}", h.DeleteCoverage)
		r.With(viewProgress).Get("/api/v1/batches/{id}/progress", h.GetBatchProgress)

		// Student access
		r.With(studentAccess).Get("/api/v1/enrollments/{id}/modules", h.GetStudentModules)
		r.With(studentAccess).Get("/api/v1/enrollments/{id}/modules/{module_id}", h.GetStudentModule)
	})
}
