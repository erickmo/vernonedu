package credentialing

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// Handler holds credentialing HTTP handlers.
type Handler struct {
	svc *Service
}

// NewHandler constructs credentialing Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) VerifyCertificate(w http.ResponseWriter, r *http.Request) {
	number := chi.URLParam(r, "number")
	if number == "" {
		apperrors.Render(w, apperrors.Validationf("certificate number required"))
		return
	}

	result, err := h.svc.Verify(r.Context(), number)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(result)
}

func (h *Handler) ListCertificates(w http.ResponseWriter, r *http.Request) {
	enrollmentID, err := uuid.Parse(chi.URLParam(r, "enrollmentID"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid enrollment id"))
		return
	}

	certs, err := h.svc.ListCertificatesByEnrollment(r.Context(), enrollmentID)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(certs)
}

func (h *Handler) RequestAction(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	certID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid certificate id"))
		return
	}

	var req struct {
		Action string `json:"action"`
		Reason string `json:"reason"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	actionReq, err := h.svc.RequestAction(r.Context(), RequestActionInput{
		StudentCertificateID: certID,
		Action:               CertAction(req.Action),
		Reason:               req.Reason,
		RequestedBy:          uc.ID,
	})
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(actionReq)
}

func (h *Handler) ApproveAction(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	reqID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request id"))
		return
	}

	if err := h.svc.ApproveAction(r.Context(), reqID, uc.ID); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
