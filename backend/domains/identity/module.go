package identity

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
)

const (
	roleAdmin          = "admin"
	roleCEO            = "ceo"
	roleVernonEduAdmin = "vernonedu_admin"
	roleStudent        = "student"
)

// Module wires identity domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// RegisterRoutes mounts identity HTTP routes on the Chi router.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW          := mw.JWT(cfg.JWT.Secret)
	manageStudents := mw.RequireRole(roleAdmin, roleCEO, roleVernonEduAdmin)
	studentSelf    := mw.RequireRole(roleStudent)

	r.Post("/api/v1/auth/register", h.Register)
	r.Post("/api/v1/auth/login", h.Login)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		r.Get("/api/v1/auth/me", h.GetMe)

		// Admin — student management
		r.With(manageStudents).Get("/api/v1/students", h.ListStudents)
		r.With(manageStudents).Get("/api/v1/students/{id}", h.GetStudent)
		r.With(manageStudents).Put("/api/v1/students/{id}", h.UpdateStudent)
		r.With(manageStudents).Get("/api/v1/students/{id}/profile", h.GetStudentProfileByID)
		r.With(manageStudents).Put("/api/v1/students/{id}/profile", h.UpdateStudentProfileByAdmin)

		// Student — self-service
		r.With(studentSelf).Get("/api/v1/me/student", h.GetMyStudent)
		r.With(studentSelf).Put("/api/v1/me/student/profile", h.UpdateMyStudentProfile)

		r.With(manageStudents).Delete("/api/v1/users/{id}", h.DeactivateUser)
		r.Get("/api/v1/departments", h.ListDepartments)
	})
}
