package partnerships

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	mw "github.com/vernonedu/vernonedu2/backend/internal/middleware"
)

// Handler holds partnerships HTTP handlers.
type Handler struct {
	svc *Service
}

// NewHandler constructs partnerships Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) CreatePartner(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var p Partner
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}

	if err := h.svc.CreatePartner(r.Context(), &p); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(p)
}

func (h *Handler) GetPartner(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid partner id"))
		return
	}

	p, err := h.svc.GetPartner(r.Context(), id)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(p)
}

func (h *Handler) ListPartners(w http.ResponseWriter, r *http.Request) {
	var status *PartnerStatus
	if s := r.URL.Query().Get("status"); s != "" {
		ps := PartnerStatus(s)
		status = &ps
	}

	partners, err := h.svc.ListPartners(r.Context(), status)
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(partners)
}

func (h *Handler) CreateAgreement(w http.ResponseWriter, r *http.Request) {
	uc := mw.GetUserContext(r.Context())
	if uc == nil {
		apperrors.Render(w, apperrors.ErrUnauthorized)
		return
	}

	var a PartnershipAgreement
	if err := json.NewDecoder(r.Body).Decode(&a); err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid request body"))
		return
	}
	a.CreatedBy = uc.ID

	if err := h.svc.CreateAgreement(r.Context(), &a); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(a)
}

func (h *Handler) ListFranchisees(w http.ResponseWriter, r *http.Request) {
	franchisees, err := h.svc.ListFranchisees(r.Context())
	if err != nil {
		apperrors.Render(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(franchisees)
}

func (h *Handler) ActivateAgreement(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		apperrors.Render(w, apperrors.Validationf("invalid agreement id"))
		return
	}

	if err := h.svc.ActivateAgreement(r.Context(), id); err != nil {
		apperrors.Render(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
