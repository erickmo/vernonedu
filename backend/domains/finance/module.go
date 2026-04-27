package finance

import (
	"os"

	"github.com/go-chi/chi/v5"
	"github.com/vernonedu/vernonedu2/backend/internal/config"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"go.uber.org/fx"
)

// Env var selecting the payment provider implementation.
const (
	envPaymentProvider     = "VERNON_PAYMENT_PROVIDER"
	envFakeWebhookSecret   = "VERNON_FAKE_WEBHOOK_SECRET"
	defaultFakeSecret      = "fake-secret"
	defaultProvider        = ProviderFake
)

// Module wires finance domain via FX.
var Module = fx.Options(
	fx.Provide(NewRepository),
	fx.Provide(ProvidePaymentGateway),
	fx.Provide(NewService),
	fx.Provide(NewHandler),
	fx.Invoke(RegisterRoutes),
	fx.Invoke(RegisterSubscriptions),
)

// ProvidePaymentGateway selects the gateway implementation based on
// VERNON_PAYMENT_PROVIDER (defaults to fake for local/dev safety).
func ProvidePaymentGateway(cfg *config.Config) PaymentGateway {
	provider := os.Getenv(envPaymentProvider)
	if provider == "" {
		provider = defaultProvider
	}
	switch provider {
	case ProviderMidtrans:
		return NewMidtransGateway(cfg.Midtrans.ServerKey, cfg.Midtrans.ClientKey, cfg.Midtrans.Env)
	default:
		secret := os.Getenv(envFakeWebhookSecret)
		if secret == "" {
			secret = defaultFakeSecret
		}
		return NewFakeGateway(secret, "")
	}
}

// RegisterRoutes mounts finance HTTP routes.
func RegisterRoutes(r *chi.Mux, h *Handler, cfg *config.Config, _ events.Bus) {
	jwtMW := mw.JWT(cfg.JWT.Secret)

	// Webhook is unauthenticated (public from gateway), signature-verified.
	r.Post("/api/v1/finance/webhooks/midtrans", h.MidtransWebhook)

	r.Group(func(r chi.Router) {
		r.Use(jwtMW)

		r.Get("/api/v1/payments/{id}", h.GetPayment)
		r.Get("/api/v1/payments/{id}/terms", h.ListPaymentTerms)
		r.Post("/api/v1/transactions/{id}/confirm", h.ConfirmTransaction)

		r.Get("/api/v1/invoices/{id}", h.GetInvoice)
		r.Post("/api/v1/invoices/{id}/send", h.SendInvoice)
		r.Post("/api/v1/finance/invoices/{id}/pay", h.PayInvoice)
	})
}
