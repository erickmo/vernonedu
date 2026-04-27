package finance

import (
	"bytes"
	"context"
	"crypto/sha512"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"time"
)

// Payment provider name constants.
const (
	ProviderMidtrans = "midtrans"
	ProviderFake     = "fake"
)

// Webhook (provider-side) status strings.
const (
	WebhookStatusSettled = "settlement"
	WebhookStatusCapture = "capture"
	WebhookStatusPending = "pending"
	WebhookStatusDeny    = "deny"
	WebhookStatusExpire  = "expire"
	WebhookStatusCancel  = "cancel"
)

// WebhookOutcome is the normalized result of a verified gateway callback.
type WebhookOutcome string

const (
	OutcomeSettled WebhookOutcome = "settled"
	OutcomeFailed  WebhookOutcome = "failed"
	OutcomePending WebhookOutcome = "pending"
)

// ErrInvalidSignature is returned when a webhook payload fails verification.
var ErrInvalidSignature = errors.New("invalid webhook signature")

// ChargeResult is the normalized response from CreateCharge.
type ChargeResult struct {
	RedirectURL string
	ProviderRef string
}

// WebhookResult is the normalized response from HandleWebhook.
// ProviderRef carries the gateway-assigned identifier used to resolve
// the matching invoice row.
type WebhookResult struct {
	ProviderRef string
	Outcome     WebhookOutcome
}

// PaymentGateway abstracts the external payment provider.
type PaymentGateway interface {
	Name() string
	CreateCharge(ctx context.Context, inv *Invoice) (*ChargeResult, error)
	HandleWebhook(ctx context.Context, payload []byte, signature string) (*WebhookResult, error)
}

// ---------- Midtrans implementation ----------

const (
	midtransSnapSandboxURL = "https://app.sandbox.midtrans.com/snap/v1/transactions"
	midtransSnapProdURL    = "https://app.midtrans.com/snap/v1/transactions"
	midtransEnvProduction  = "production"
	httpTimeoutSeconds     = 15
)

// MidtransGateway calls Midtrans Snap API.
// TODO(prod): replace HTTP stub with the official Midtrans Go SDK and add
// proper retry/observability once production credentials are issued.
type MidtransGateway struct {
	serverKey string
	clientKey string
	env       string
	client    *http.Client
}

// NewMidtransGateway constructs a Midtrans-backed PaymentGateway.
func NewMidtransGateway(serverKey, clientKey, env string) *MidtransGateway {
	return &MidtransGateway{
		serverKey: serverKey,
		clientKey: clientKey,
		env:       env,
		client:    &http.Client{Timeout: time.Duration(httpTimeoutSeconds) * time.Second},
	}
}

// Name returns provider identifier.
func (m *MidtransGateway) Name() string { return ProviderMidtrans }

func (m *MidtransGateway) snapURL() string {
	if m.env == midtransEnvProduction {
		return midtransSnapProdURL
	}
	return midtransSnapSandboxURL
}

// CreateCharge calls Snap API and returns redirect URL + provider order id.
func (m *MidtransGateway) CreateCharge(ctx context.Context, inv *Invoice) (*ChargeResult, error) {
	body := map[string]any{
		"transaction_details": map[string]any{
			"order_id":     inv.InvoiceNumber,
			"gross_amount": inv.TotalAmount.IntPart(),
		},
	}
	raw, err := json.Marshal(body)
	if err != nil {
		return nil, fmt.Errorf("midtrans marshal: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, m.snapURL(), bytes.NewReader(raw))
	if err != nil {
		return nil, fmt.Errorf("midtrans request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	req.SetBasicAuth(m.serverKey, "")

	resp, err := m.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("midtrans http: %w", err)
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 300 {
		return nil, fmt.Errorf("midtrans status %d: %s", resp.StatusCode, string(respBody))
	}

	var parsed struct {
		Token       string `json:"token"`
		RedirectURL string `json:"redirect_url"`
	}
	if err := json.Unmarshal(respBody, &parsed); err != nil {
		return nil, fmt.Errorf("midtrans decode: %w", err)
	}

	return &ChargeResult{RedirectURL: parsed.RedirectURL, ProviderRef: inv.InvoiceNumber}, nil
}

// midtransWebhookPayload mirrors the relevant subset of Midtrans HTTP notification.
type midtransWebhookPayload struct {
	OrderID           string `json:"order_id"`
	StatusCode        string `json:"status_code"`
	GrossAmount       string `json:"gross_amount"`
	SignatureKey      string `json:"signature_key"`
	TransactionStatus string `json:"transaction_status"`
	FraudStatus       string `json:"fraud_status"`
}

// HandleWebhook verifies Midtrans signature and returns the normalized outcome.
func (m *MidtransGateway) HandleWebhook(ctx context.Context, payload []byte, _ string) (*WebhookResult, error) {
	var p midtransWebhookPayload
	if err := json.Unmarshal(payload, &p); err != nil {
		return nil, fmt.Errorf("midtrans webhook decode: %w", err)
	}
	if !m.verifySignature(p) {
		return nil, ErrInvalidSignature
	}
	return &WebhookResult{
		ProviderRef: p.OrderID,
		Outcome:     classifyMidtransStatus(p.TransactionStatus),
	}, nil
}

// verifySignature reproduces Midtrans signature scheme:
//
//	sha512(order_id + status_code + gross_amount + server_key)
func (m *MidtransGateway) verifySignature(p midtransWebhookPayload) bool {
	raw := p.OrderID + p.StatusCode + p.GrossAmount + m.serverKey
	sum := sha512.Sum512([]byte(raw))
	return hex.EncodeToString(sum[:]) == p.SignatureKey
}

func classifyMidtransStatus(s string) WebhookOutcome {
	switch s {
	case WebhookStatusSettled, WebhookStatusCapture:
		return OutcomeSettled
	case WebhookStatusDeny, WebhookStatusExpire, WebhookStatusCancel:
		return OutcomeFailed
	default:
		return OutcomePending
	}
}

// ---------- Fake implementation (tests / local dev) ----------

// FakeGateway is a deterministic, in-memory PaymentGateway for tests.
// Webhook signatures are accepted only when they exactly match the
// configured secret. ProviderRef equals invoice_number.
type FakeGateway struct {
	signatureSecret string
	redirectBase    string
}

// NewFakeGateway constructs an in-memory PaymentGateway for tests/dev.
func NewFakeGateway(signatureSecret, redirectBase string) *FakeGateway {
	if redirectBase == "" {
		redirectBase = "https://fake.local/pay/"
	}
	return &FakeGateway{signatureSecret: signatureSecret, redirectBase: redirectBase}
}

// Name returns provider identifier.
func (f *FakeGateway) Name() string { return ProviderFake }

// CreateCharge returns a synthetic redirect URL and provider ref.
func (f *FakeGateway) CreateCharge(_ context.Context, inv *Invoice) (*ChargeResult, error) {
	return &ChargeResult{
		RedirectURL: f.redirectBase + inv.InvoiceNumber,
		ProviderRef: inv.InvoiceNumber,
	}, nil
}

// fakeWebhookPayload is the test payload shape consumed by FakeGateway.
type fakeWebhookPayload struct {
	OrderID string `json:"order_id"`
	Status  string `json:"status"` // settled|failed|pending
}

// HandleWebhook accepts plaintext-signature payloads where signature == secret.
func (f *FakeGateway) HandleWebhook(_ context.Context, payload []byte, signature string) (*WebhookResult, error) {
	if signature != f.signatureSecret {
		return nil, ErrInvalidSignature
	}
	var p fakeWebhookPayload
	if err := json.Unmarshal(payload, &p); err != nil {
		return nil, fmt.Errorf("fake webhook decode: %w", err)
	}
	return &WebhookResult{ProviderRef: p.OrderID, Outcome: WebhookOutcome(p.Status)}, nil
}

