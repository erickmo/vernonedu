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
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// provideCatalogReader returns a nil CatalogReader placeholder. Cross-domain
// wiring to the catalog service is deferred to a follow-up task; until then,
// the enrollment.completed listener silently skips auto-issue.
func provideCatalogReader() CatalogReader { return nil }

// RegisterRoutes mounts credentialing HTTP routes.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	// Public verification endpoint — no auth required.
	r.Get("/api/v1/certificates/verify/{number}", h.VerifyCertificate)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		r.Get("/api/v1/enrollments/{enrollmentID}/certificates", h.ListCertificates)
		r.Post("/api/v1/certificates/{id}/actions", h.RequestAction)
		r.Post("/api/v1/certificate-actions/{id}/approve", h.ApproveActionRequest)
	})
}
