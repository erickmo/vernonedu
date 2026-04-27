package identity

import (
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
	"go.uber.org/zap"
)

// Module wires identity domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(provideService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// provideService adapts NewService to fx by reading JWT settings from config.
func provideService(repo Repository, bus events.Bus, log *zap.Logger, cfg *config.Config) *Service {
	expiry := time.Duration(cfg.JWT.ExpiryHours) * time.Hour
	return NewService(repo, bus, log, cfg.JWT.Secret, expiry)
}

// RegisterRoutes mounts identity HTTP routes on the Chi router.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	// Public
	r.Post("/api/v1/auth/register", h.Register)
	r.Post("/api/v1/auth/login", h.Login)

	// Authenticated (any role)
	r.Group(func(r chi.Router) {
		r.Use(jwtMW)
		r.Get("/api/v1/auth/me", h.GetMe)
		r.Get("/api/v1/students/me", h.GetMyStudent)
		r.Put("/api/v1/students/me/profile", h.UpdateOwnProfile)

		r.Get("/api/v1/students", h.ListStudents)
		r.Get("/api/v1/students/{id}", h.GetStudent)
		r.Delete("/api/v1/users/{id}", h.DeactivateUser)
		r.Get("/api/v1/departments", h.ListDepartments)
	})

	// Admin (vernonedu_admin or admin)
	r.Group(func(r chi.Router) {
		r.Use(jwtMW, mw.RequireRoles("vernonedu_admin", "admin"))
		r.Post("/api/v1/team-members", h.CreateTeamMember)
		r.Patch("/api/v1/team-members/{id}/status", h.UpdateTeamMemberStatus)
		r.Delete("/api/v1/team-members/{id}", h.DeactivateTeamMember)
		r.Post("/api/v1/fee-tiers", h.CreateFeeTier)
		r.Get("/api/v1/fee-tiers", h.ListFeeTiers)
		r.Patch("/api/v1/fee-tiers/{id}/deactivate", h.DeactivateFeeTier)
	})

	// Course creator
	r.Group(func(r chi.Router) {
		r.Use(jwtMW, mw.RequireRoles("course_creator"))
		r.Post("/api/v1/facilitator-proposals", h.ProposeFacilitator)
	})

	// Department leader
	r.Group(func(r chi.Router) {
		r.Use(jwtMW, mw.RequireRoles("dept_leader"))
		r.Post("/api/v1/facilitator-proposals/{id}/dept-leader-approve", h.ApproveByDeptLeader)
		r.Post("/api/v1/facilitator-proposals/{id}/dept-leader-reject", h.RejectByDeptLeader)
	})

	// Academic leader
	r.Group(func(r chi.Router) {
		r.Use(jwtMW, mw.RequireRoles("academic_leader"))
		r.Post("/api/v1/facilitator-proposals/{id}/academic-leader-approve", h.ApproveByAcademicLeader)
		r.Post("/api/v1/facilitator-proposals/{id}/academic-leader-reject", h.RejectByAcademicLeader)
	})
}
