//go:build integration

package finance_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"

	"github.com/vernonedu/vernonedu2/backend/domains/finance"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
	"github.com/jackc/pgx/v5/pgxpool"
	"go.uber.org/zap"
)

func newFinanceSvc(t *testing.T, pool *pgxpool.Pool) *finance.Service {
	t.Helper()
	bus := events.NewBus(zap.NewNop())
	gw := finance.NewFakeGateway("test-secret", "")
	return finance.NewService(finance.NewRepository(pool), bus, gw, zap.NewNop())
}

func buildFinanceRouter(svc *finance.Service, actorID uuid.UUID) http.Handler {
	h := finance.NewHandler(svc)
	r := chi.NewRouter()

	// Public webhook — no auth
	r.Post("/api/v1/finance/webhooks/midtrans", h.MidtransWebhook)

	// JWT-protected routes (actor injected via middleware)
	r.Group(func(r chi.Router) {
		r.Use(func(next http.Handler) http.Handler {
			return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
				uc := &mw.UserContext{ID: actorID, Role: "vernonedu_admin"}
				next.ServeHTTP(w, req.WithContext(mw.WithUserContext(req.Context(), uc)))
			})
		})

		r.Get("/api/v1/payments/{id}", h.GetPayment)
		r.Get("/api/v1/payments/{id}/terms", h.ListPaymentTerms)
		r.Post("/api/v1/transactions/{id}/confirm", h.ConfirmTransaction)
		r.Get("/api/v1/invoices/{id}", h.GetInvoice)
		r.Post("/api/v1/invoices/{id}/send", h.SendInvoice)
		r.Post("/api/v1/finance/invoices/{id}/pay", h.PayInvoice)
	})

	return r
}

// TestFinance_GetPayment_NotFound verifies 404 for unknown payment ID.
func TestFinance_GetPayment_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newFinanceSvc(t, pool)
	router := buildFinanceRouter(svc, uuid.New())

	req := httptest.NewRequest(http.MethodGet, "/api/v1/payments/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

// TestFinance_GetInvoice_NotFound verifies 404 for unknown invoice ID.
func TestFinance_GetInvoice_NotFound(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newFinanceSvc(t, pool)
	router := buildFinanceRouter(svc, uuid.New())

	req := httptest.NewRequest(http.MethodGet, "/api/v1/invoices/"+uuid.New().String(), http.NoBody)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	require.Equal(t, http.StatusNotFound, w.Code)
}

// TestFinance_MidtransWebhook_InvalidPayload verifies the webhook does not return 500
// when given an invalid payload or missing/wrong signature.
// The FakeGateway returns ErrInvalidSignature (→ 401) when signature does not match.
func TestFinance_MidtransWebhook_InvalidPayload(t *testing.T) {
	pool := newTestPool(t)
	defer pool.Close()
	resetSchemas(t, pool)

	svc := newFinanceSvc(t, pool)
	router := buildFinanceRouter(svc, uuid.New())

	body := `{"this":"is","not":"a valid webhook"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/finance/webhooks/midtrans", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	// Deliberately omit the X-Signature header to trigger invalid signature path
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	// Must not be 500 — invalid signature → 401
	require.NotEqual(t, http.StatusInternalServerError, w.Code)
	require.Equal(t, http.StatusUnauthorized, w.Code)
}
