package finance

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// MidtransSignatureHeader is the HTTP header carrying the webhook signature.
const MidtransSignatureHeader = "X-Signature"

// Handler holds finance HTTP handlers.
type Handler struct {
	svc *Service
}

// NewHandler constructs finance Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) GetPayment(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid payment id"))
		return
	}

	p, err := h.svc.GetPaymentByID(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(p)
}

func (h *Handler) ListPaymentTerms(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid payment id"))
		return
	}

	terms, err := h.svc.ListPaymentTerms(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(terms)
}

func (h *Handler) ConfirmTransaction(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid transaction id"))
		return
	}

	if err := h.svc.ConfirmTransaction(r.Context(), id, uc.ID); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) GetInvoice(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid invoice id"))
		return
	}

	inv, err := h.svc.GetInvoiceByID(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(inv)
}

// PayInvoice initiates a gateway charge for the invoice and returns the
// redirect URL the client should use to complete payment.
func (h *Handler) PayInvoice(w http.ResponseWriter, r *http.Request) {
	if mw.GetUserContext(r.Context()) == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid invoice id"))
		return
	}

	redirectURL, err := h.svc.InitiateInvoicePayment(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]string{"redirect_url": redirectURL})
}

// MidtransWebhook receives an HTTP notification from Midtrans, verifies the
// signature, and applies the resulting state change to the invoice.
func (h *Handler) MidtransWebhook(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid body"))
		return
	}
	defer r.Body.Close()

	signature := r.Header.Get(MidtransSignatureHeader)
	if err := h.svc.ProcessGatewayWebhook(r.Context(), body, signature); err != nil {
		if errors.Is(err, ErrInvalidSignature) {
			apperrors.Render(w, apperrors.New("INVALID_SIGNATURE", "invalid webhook signature", http.StatusUnauthorized))
			return
		}
		apperrors.Render(w, err)
		return
	}
	w.WriteHeader(http.StatusOK)
}

func (h *Handler) SendInvoice(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid invoice id"))
		return
	}

	if err := h.svc.SendInvoice(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
