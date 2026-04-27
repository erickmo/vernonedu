package credentialing

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
)

// Module wires credentialing domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(provideCatalogReader),
	fx.Provide(provideIdentityReader),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// provideCatalogReader returns a nil CatalogReader placeholder. Cross-domain
// wiring to the catalog service is deferred to a follow-up task; until then,
// the enrollment.completed listener silently skips auto-issue.
func provideCatalogReader() CatalogReader { return nil }

// provideIdentityReader returns a nil IdentityReader placeholder. Cross-domain
// wiring to the identity/student service is deferred to a follow-up task;
// until then, certificate downloads are disabled (returns ErrForbidden).
func provideIdentityReader() IdentityReader { return nil }

// RegisterRoutes mounts credentialing HTTP routes per the domain spec.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	// Public verification endpoint — no auth required.
	r.Get("/api/v1/cert/verify/{number}", h.VerifyCertificate)

	// Authenticated (any role). Ownership / row-scope is enforced inside the
	// service layer where applicable (e.g., DownloadCertificate verifies the
	// caller owns the cert; ListMyCertificates resolves the caller's student).
	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		r.Get("/api/v1/enrollments/{enrollmentID}/certificates", h.ListCertificates)
		r.Get("/api/v1/students/me/certificates", h.ListMyCertificates)
		r.Get("/api/v1/students/me/certificates/{id}/download", h.DownloadMyCertificate)
		r.Get("/api/v1/courses/{id}/certificate-configs", h.ListCertificateConfigs)
	})

	// Admin-tier: open revoke/reissue request.
	r.Group(func(r chi.Router) {
		r.Use(jwtMW, mw.RequireRoles("admin", "vernonedu_admin"))
		r.Post("/api/v1/certificates/{id}/actions", h.RequestAction)
	})

	// Approval gate: academic_leader / ceo approve or reject pending requests.
	r.Group(func(r chi.Router) {
		r.Use(jwtMW, mw.RequireRoles("academic_leader", "ceo"))
		r.Post("/api/v1/certificate-actions/{id}/approve", h.ApproveAction)
		r.Post("/api/v1/certificate-actions/{id}/reject", h.RejectAction)
	})

	// VernonEdu admin: certificate type lifecycle.
	r.Group(func(r chi.Router) {
		r.Use(jwtMW, mw.RequireRoles("vernonedu_admin"))
		r.Post("/api/v1/certificate-types", h.CreateCertificateType)
		r.Patch("/api/v1/certificate-types/{id}/deactivate", h.DeactivateCertificateType)
	})

	// Course creator / admin: course-config CRUD. Ownership of the course is
	// enforced by the catalog domain when this handler is wired through it.
	r.Group(func(r chi.Router) {
		r.Use(jwtMW, mw.RequireRoles("course_creator", "admin", "vernonedu_admin"))
		r.Post("/api/v1/courses/{id}/certificate-configs", h.AddCertificateConfig)
	})
}
