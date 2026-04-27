package platform

import (
	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/crypto"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
)

// Module wires platform domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(NewEmailSender),
	fx.Provide(NewInAppSender),
	fx.Provide(NewPushSender),
	fx.Provide(NewSenders),
	fx.Provide(provideTokenExchanger),
	fx.Provide(provideCalendarCipher),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// provideTokenExchanger constructs a Google OAuth exchanger from config, or
// nil when client credentials are not configured (dev/test environments).
func provideTokenExchanger(cfg *config.Config) TokenExchanger {
	return NewGoogleTokenExchanger(
		cfg.Calendar.OAuth.GoogleClientID,
		cfg.Calendar.OAuth.GoogleClientSecret,
		cfg.Calendar.OAuth.GoogleRedirectURL,
	)
}

// provideCalendarCipher constructs the AES-GCM cipher from config, or nil when
// no encryption key is configured. Returns no error to keep startup tolerant
// in environments that don't use calendar sync.
func provideCalendarCipher(cfg *config.Config) (*crypto.AESGCM, error) {
	if cfg.Calendar.EncryptionKeyHex == "" {
		return nil, nil
	}
	return crypto.NewAESGCMFromHex(cfg.Calendar.EncryptionKeyHex)
}

// RegisterRoutes mounts platform HTTP routes.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		r.Get("/api/v1/notifications", h.ListMyNotifications)
		r.Post("/api/v1/notifications/{id}/read", h.MarkRead)
	})

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)
		r.Use(mw.RequireRole("vernonedu_admin"))

		r.Post("/api/v1/notification-templates", h.CreateTemplate)
		r.Patch("/api/v1/notification-templates/{id}/deactivate", h.DeactivateTemplate)
	})
}
