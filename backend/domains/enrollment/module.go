package enrollment

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
)

// Module wires enrollment domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(provideCatalogReader),
	fx.Provide(provideAgreementReader),
	fx.Provide(provideFinanceReader),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// provideCatalogReader returns a nil CatalogReader placeholder. Cross-domain
// wiring to the catalog service is deferred to a follow-up task; until then,
// Enroll will fail validation if invoked.
func provideCatalogReader() CatalogReader { return nil }

// provideAgreementReader returns a nil PartnershipsReader placeholder.
// The service treats nil as "no active agreement" and falls back to B2C.
func provideAgreementReader() PartnershipsReader { return nil }

// provideFinanceReader returns a nil FinanceReader placeholder. Cross-domain
// wiring to the finance service is deferred; until then, credit application
// is skipped silently when StudentCreditID is supplied.
func provideFinanceReader() FinanceReader { return nil }

// RegisterRoutes mounts enrollment HTTP routes.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	// Authenticated (any role).
	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		r.Post("/api/v1/enrollments", h.CreateEnrollment)
		r.Get("/api/v1/enrollments/me", h.ListMyEnrollments)
		r.Get("/api/v1/enrollments/{id}", h.GetEnrollment)
		r.Get("/api/v1/vouchers/me", h.ListMyVouchers)
		r.Post("/api/v1/vouchers/redeem", h.RedeemVoucher)
	})

	// Admin only.
	r.Group(func(r chi.Router) {
		r.Use(jwtMW, mw.RequireRoles("admin", "vernonedu_admin"))

		r.Patch("/api/v1/enrollments/{id}/complete", h.CompleteEnrollment)
		r.Patch("/api/v1/enrollments/{id}/drop", h.DropEnrollment)
		r.Get("/api/v1/students/{studentID}/enrollments", h.ListEnrollmentsByStudent)
		r.Post("/api/v1/vouchers", h.CreateVoucher)
		r.Patch("/api/v1/vouchers/{id}/assign", h.AssignVoucher)
		r.Patch("/api/v1/vouchers/{id}/deactivate", h.DeactivateVoucher)
	})
}
