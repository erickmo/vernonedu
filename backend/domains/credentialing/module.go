package credentialing

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
)

// Module wires credentialing domain via FX.
// Note: PDFRenderer, CertStorage and verification base URL must be supplied
// by the entrypoint (cmd/api or cmd/worker) — see internal/worker.Module.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// RegisterRoutes mounts credentialing HTTP routes.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	// Public verification endpoints — no auth required.
	r.Get("/api/v1/certificates/verify/{number}", h.VerifyCertificate)
	r.Get("/api/v1/certificates/verify-hash/{hash}", h.VerifyByHash)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		r.Get("/api/v1/enrollments/{enrollmentID}/certificates", h.ListCertificates)
		r.Get("/api/v1/certificates/{id}/download", h.DownloadCertificate)
		r.Post("/api/v1/certificates/{id}/actions", h.RequestAction)
		r.Post("/api/v1/certificate-actions/{id}/approve", h.ApproveActionRequest)
	})
}
